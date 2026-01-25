-- CriblageGameScene.lua
-- Main gameplay scene logic

-- Load subsystems
local CardView = require("visuals/CardView")
local HUD = require("ui/HUD")
local ShopUI = require("ui/ShopUI")
local CampaignState = require("criblage/CampaignState")
local JokerManager = require("criblage/JokerManager")

GameScene = class()

function GameScene:init()
    print("Initializing Game Scene (Constructor)...")

    -- Initialize Campaign
    CampaignState:init()

    -- Load Assets
    self.cardAtlas = graphics.loadTexture("content/images/cards_sheet.png")
    self.font = graphics.loadFont("content/fonts/font.ttf", 24)
    self.smallFont = graphics.loadFont("content/fonts/font.ttf", 16)

    -- Load CRT Shader
    local shaderLoaded = graphics.loadShader("crt", "content/shaders/crt.metal")
    if shaderLoaded then
        print("CRT Shader Loaded successfully")
        graphics.enableShader("crt", true)
    else
        print("Failed to load CRT Shader")
    end
    self.time = 0

    -- Game State
    self.state = "DEAL" -- DEAL, PLAY, SCORE, SHOP, GAME_OVER
    self.hand = {}
    self.cutCard = nil

    -- Visual Components
    self.cardViews = {}
    self.cutCardView = nil
    self.shopUI = ShopUI(self.font)
    self.hud = HUD(self.font, self.smallFont)

    if not self.hud then
        print("ERROR: HUD failed to initialize!")
    else
        print("HUD initialized successfully")
    end

    -- Mouse State
    self.lastMouseState = { x = 0, y = 0, left = false }

    print("Game Scene initialized!")
end

function GameScene:onInit()
    -- Kept for SceneManager compatibility if needed, but init does the work
    print("GameScene:onInit called")
end

function GameScene:enter()
    print("Entered Game Scene")
    self:startNewHand()
end

function GameScene:startNewHand()
    print("Starting new hand...")

    -- Reset deck
    self.deck = Deck.new()
    self.deck:shuffle()

    -- Draw 6 cards (standard criblage hand size)
    self.hand = self.deck:drawMultiple(6)
    self.cutCard = self.deck:draw()

    -- Create visual cards
    self.cardViews = {}
    local startX = 200
    local startY = 500
    local spacing = 110

    for i, card in ipairs(self.hand) do
        local view = CardView(card, startX + (i - 1) * spacing, startY, self.cardAtlas, self.smallFont)
        table.insert(self.cardViews, view)
    end

    -- Create cut card view (displayed at top center)
    self.cutCardView = CardView(self.cutCard, 585, 200, self.cardAtlas, self.smallFont)

    self.state = "PLAY"
    print("Hand dealt: " .. #self.hand .. " cards")
end

function GameScene:update(dt)
    -- Initialize if missing (Fallback)
    if not self.hud then
        print("Late initialization of GameScene...")
        self:init()
    end

    -- Update CRT Shader
    if self.time then
        self.time = self.time + dt
        -- Format: { time, distortion, scanStrength, chromaStr }
        graphics.setShaderUniform("crt", {
            self.time,
            0.15, -- Curvature
            0.15, -- Scanline Strength
            0.003 -- Chromatic Aberration
        })
    end

    -- Input Handling (Simple click detection)
    local mx, my = input.getMousePosition()

    -- Use correct API for mouse button
    local mLeft = input.isMouseButtonPressed("left")

    local clicked = mLeft


    -- Pass input to Shop if active
    if self.state == "SHOP" then
        if self.shopUI:update(dt, mx, my, clicked) then
            -- Shop closed, next blind
            self.state = "DEAL"
            self:startNewHand()
        end
    elseif self.state == "PLAY" then
        -- Handle Card Interaction
        for _, view in ipairs(self.cardViews) do
            view:update(dt, mx, my, clicked)

            -- Toggle selection
            if clicked and view:isHovered(mx, my) then
                view:toggleSelected()
            end
        end

        -- Play Button Logic (Simulated by pressing Enter for now)
        if input.isPressed("return") then
            self:playHand()
        end

        -- Discard Button Logic (Simulated by pressing Backspace)
        if input.isPressed("backspace") then
            self:discardSelected()
        end
    end

    self.lastMouseState = { x = mx, y = my, left = mLeft }
end

function GameScene:discardSelected()
    if CampaignState.discardsRemaining <= 0 then
        print("No discards remaining!")
        return
    end

    -- Find selected indices
    local selectedIndices = {}
    for i, view in ipairs(self.cardViews) do
        if view.selected then
            table.insert(selectedIndices, i)
        end
    end

    if #selectedIndices > 0 then
        CampaignState:useDiscard()

        -- Remove cards and draw new ones
        -- (Simplified for MVP: Just replace selected cards)
        for _, index in ipairs(selectedIndices) do
            if not self.deck:isEmpty() then
                local newCard = self.deck:draw()
                self.hand[index] = newCard
                self.cardViews[index]:setCard(newCard)
                self.cardViews[index]:setSelected(false)
            end
        end
        print("Discard used. " .. CampaignState.discardsRemaining .. " left.")
    end
end

function GameScene:playHand()
    -- Gather selected cards
    local selectedCards = {}
    for i, view in ipairs(self.cardViews) do
        if view.selected then
            table.insert(selectedCards, self.hand[i])
        end
    end

    if #selectedCards ~= 4 then
        print("Must select exactly 4 cards to play!")
        return
    end

    -- Add cut card to make 5 cards total (required by cribbage API)
    table.insert(selectedCards, self.cutCard)

    -- Score the hand (now with 5 cards: 4 hand + 1 cut)
    local handResult = cribbage.evaluate(selectedCards)
    local jokerEffects = JokerManager:applyEffects(selectedCards, "on_score")
    local score = cribbage.score(selectedCards)


    -- Apply joker bonuses
    local finalChips = score.baseChips + jokerEffects.addedChips
    local finalMult = 1 + score.tempMultiplier + jokerEffects.addedTempMult
    local finalScore = math.floor(finalChips * finalMult)

    -- Debug: Show joker effects
    if jokerEffects.addedChips > 0 or jokerEffects.addedTempMult > 0 then
        print(string.format("Joker effects: +%d chips, +%.2f mult", jokerEffects.addedChips, jokerEffects.addedTempMult))
    end
    print("Scored: " .. finalScore)

    -- Check campaign result
    local result, reward = CampaignState:playHand(finalScore)

    if result == "win" then
        print("Blind Cleared! entering shop...")
        self.state = "SHOP"
        self.shopUI:open(reward)
    elseif result == "loss" then
        print("GAME OVER")
        self.state = "GAME_OVER"
    else
        -- High enough for demo to just refresh hand
        self:startNewHand()
    end
end

function GameScene:draw()
    -- Draw Background
    graphics.drawRect(0, 0, 1280, 720, { r = 0.1, g = 0.3, b = 0.2, a = 1.0 }, true)

    if self.hud then
        -- Draw HUD
        self.hud:draw(CampaignState)

        -- Draw Cut Card
        if self.cutCardView then
            self.cutCardView:draw()
        end

        -- Draw Cards
        for _, view in ipairs(self.cardViews) do
            view:draw()
        end

        -- Draw Shop if active
        if self.state == "SHOP" then
            self.shopUI:draw()
        end

        -- Draw Game Over
        if self.state == "GAME_OVER" then
            graphics.print(self.font, "GAME OVER", 500, 300, { r = 1, g = 0, b = 0, a = 1 })
            graphics.print(self.smallFont, "Press R to Restart", 530, 350)

            if input.isPressed("r") then
                CampaignState:init()
                self:startNewHand()
            end
        end
    else
        graphics.print(self.font or 0, "Loading UI...", 600, 360, { r = 1, g = 1, b = 1, a = 1 })
    end
end
