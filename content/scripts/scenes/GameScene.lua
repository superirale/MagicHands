-- CriblageGameScene.lua
-- Main gameplay scene logic

-- Load subsystems
local CardView = require("visuals/CardView")
local HUD = require("ui/HUD")
local ShopUI = require("ui/ShopUI")
local BlindPreview = require("ui/BlindPreview")
local DeckView = require("ui/DeckView")
local CampaignState = require("criblage/CampaignState")
local JokerManager = require("criblage/JokerManager")
local BossManager = require("criblage/BossManager")
local EnhancementManager = require("criblage/EnhancementManager")
local EffectManager = require("visuals/EffectManager")
local AudioManager = require("audio/AudioManager")

GameScene = class()

function GameScene:init()
    print("Initializing Game Scene (Constructor)...")

    -- Initialize Campaign
    CampaignState:init()

    -- Initialize Effects
    EffectManager:init() -- Verify particles global exists
    -- AudioManager:init()

    -- Load Assets
    self.cardAtlas = graphics.loadTexture("content/images/cards_sheet.png")
    if self.cardAtlas then
        local w, h = graphics.getTextureSize(self.cardAtlas)
        print("DEBUG: Card Atlas Loaded. ID: " .. tostring(self.cardAtlas) .. " Size: " .. w .. "x" .. h)
    else
        print("ERROR: Failed to load cards_sheet.png")
    end

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
    self.state = "DEAL"        -- DEAL, PLAY, SCORE, SHOP, BLIND_PREVIEW, DECK_VIEW
    self.state = "DEAL"        -- DEAL, PLAY, SCORE, SHOP, BLIND_PREVIEW, DECK_VIEW
    self.hand = {}
    self.crib = {}             -- New Crib Data
    self.cutCard = nil
    self.pendingShopItem = nil -- For spectral actions

    -- Visual Components
    self.cardViews = {}
    self.cutCardView = nil
    self.shopUI = ShopUI(self.font)
    self.blindPreview = BlindPreview(self.font, self.smallFont)
    self.deckView = DeckView(self.font, self.smallFont, self.cardAtlas)
    self.hud = HUD(self.font, self.smallFont)

    if not self.hud then
        print("ERROR: HUD failed to initialize!")
    else
        print("HUD initialized successfully")
    end

    -- Mouse State
    self.lastMouseState = { x = 0, y = 0, left = false }

    -- Drag State
    self.draggingView = nil
    self.dragOffset = { x = 0, y = 0 }
    self.dragStartX = 0
    self.dragStartY = 0

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

    -- Get persistent deck from CampaignState
    -- self.deck = Deck.new() -- OLD
    -- self.deck:shuffle() -- OLD

    -- We get a table of cards from CampaignState
    -- We need to wrap it in a Deck object if your Deck class logic requires it,
    -- OR just treat self.deck as a list if methods like 'draw' allow it.
    -- Looking at previous code: `self.deck = Deck.new()`
    -- Let's check Deck.lua usage. Ah, I don't see Deck.lua, wait.
    -- User said "Deck.lua does not exist" in my thought process earlier?
    -- No, I listed checking for Deck.lua and found ZERO results.
    -- BUT GameScene line 77: `self.deck = Deck.new()` implies Deck is global or loaded.
    -- It might be engine provided or I missed it.
    -- Line 81: `self.deck:drawMultiple(6)`
    -- To facilitate custom deck, I should implement a simple Deck helper here or in Lua if the engine one is rigid.
    -- Or better: Just implement manual drawing from the array returned by CampaignState.

    local deckList = CampaignState:getDeck()

    -- Shuffle manually
    for i = #deckList, 2, -1 do
        local j = math.random(i)
        deckList[i], deckList[j] = deckList[j], deckList[i]
    end

    self.deckList = deckList -- Store as list

    -- Draw 6 cards
    self.hand = {}
    self.draggingView = nil -- Clear any stale drag state
    self.dragStartX = 0
    self.dragStartY = 0

    for i = 1, 6 do
        table.insert(self.hand, table.remove(self.deckList))
    end

    -- Cut card
    self.cutCard = table.remove(self.deckList)

    -- Create visual cards
    self.cardViews = {}
    self.cribViews = {} -- New Crib Views
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

function GameScene:rebuildCribViews()
    self.cribViews = {}
    local startX = 990
    local startY = 490
    local spacing = 120 -- Spacing for 2 slots (980, 1100)

    local CardView = require("visuals/CardView")
    for i, card in ipairs(self.crib) do
        local view = CardView(card, startX + (i - 1) * spacing, startY, self.cardAtlas, self.smallFont)
        table.insert(self.cribViews, view)
    end
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
            0.25, -- Curvature (Boosted)
            0.35, -- Scanline Strength (Boosted)
            0.005 -- Chromatic Aberration
        })
    end

    -- Update Effects
    EffectManager:update(dt)

    -- Input Handling (Simple click detection)
    local mx, my = input.getMousePosition()

    -- Use correct API for mouse button
    local mLeft = input.isMouseButtonPressed("left")

    local clicked = mLeft


    -- Pass input to Shop if active
    if self.state == "SHOP" then
        local result = self.shopUI:update(dt, mx, my, clicked)
        -- Handle result table or legacy boolean
        local action = nil
        if type(result) == "table" then
            action = result.action
        elseif result == true then
            action = "close"
        end

        if action == "close" then
            -- Shop closed, show blind preview
            self.state = "BLIND_PREVIEW"

            -- Prepare preview data
            local nextBlind = CampaignState:getNextBlind()
            local required = blind.getRequiredScore(nextBlind, CampaignState.difficulty)
            local rewardBase = 35
            if nextBlind.type == "big" then rewardBase = 50 end
            if nextBlind.type == "boss" then rewardBase = 100 end

            self.blindPreview:show(nextBlind, rewardBase)
        elseif action == "select_card" then
            -- Enter DeckView mode
            self.state = "DECK_VIEW"
            self.pendingShopItem = result
            self.deckView:show(CampaignState.masterDeck, "SELECT",
                function(index, cardData) self:onDeckCardSelected(index, cardData) end,
                function() self.state = "SHOP" end -- On close/cancel
            )
        end
    elseif self.state == "DECK_VIEW" then
        self.deckView:update(dt)
    elseif self.state == "BLIND_PREVIEW" then
        if self.blindPreview:update(dt, mx, my, clicked) then
            self.state = "DEAL"
            self:startNewHand()
        end
    elseif self.state == "PLAY" then
        -- Handle Dragging State
        if self.draggingView then
            -- Update Position
            self.draggingView.currentX = mx - self.dragOffset.x
            self.draggingView.currentY = my - self.dragOffset.y

            -- Release Drag
            if not mLeft then
                -- Check Drop in Crib (980, 480, 240x160 approx for entire visual area)
                if mx > 980 and mx < 1220 and my > 480 and my < 640 and #self.crib < 2 then
                    -- Move Card to Crib
                    local card = self.draggingView.card

                    -- Remove from Hand
                    for k, c in ipairs(self.hand) do
                        if c == card then
                            table.remove(self.hand, k)
                            break
                        end
                    end

                    -- Add to Crib
                    table.insert(self.crib, card)

                    -- Rebuild Views
                    self:rebuildHandViews()
                    self:rebuildCribViews()

                    -- AudioManager:playPlace()
                else
                    -- Normal Click/Drop Logic
                    local dist = math.abs(mx - self.dragStartX) + math.abs(my - self.dragStartY)
                    if dist < 5 then
                        self.draggingView:toggleSelected()
                        if self.draggingView.selected then
                            EffectManager:spawnSparkles(self.draggingView.x + self.draggingView.width / 2,
                                self.draggingView.y + self.draggingView.height / 2, 5)
                        end
                    end
                    -- If dragged but not to crib, it snaps back via rebuild/update loop
                end

                self.draggingView.isDragging = false
                self.draggingView = nil
            end
        end

        -- Handle Card Interaction
        local startX = 200
        local spacing = 110

        -- Sort views by X to handle reordering dynamically
        if self.draggingView then
            table.sort(self.cardViews, function(a, b) return a.currentX < b.currentX end)

            -- Sync self.hand to match visual order
            self.hand = {}
            for _, view in ipairs(self.cardViews) do
                table.insert(self.hand, view.card)
            end
        end

        -- Update Targets & Logic
        for i, view in ipairs(self.cardViews) do
            -- Start Dragging
            if clicked and not self.draggingView and view:isHovered(mx, my) then
                self.draggingView = view
                view.isDragging = true
                self.dragOffset.x = mx - view.currentX
                self.dragOffset.y = my - view.currentY
                self.dragStartX = mx
                self.dragStartY = my

                -- AudioManager:playHover() -- Pickup sound
            end

            -- Set Target Layout (Grid)
            view.targetX = startX + (i - 1) * spacing
            -- Target Y handled inside CardView based on selection

            view:update(dt, mx, my, clicked)
        end

        -- Play Button Logic (Simulated by pressing Enter for now)
        if input.isPressed("return") then
            self:playHand()
        end

        -- Discard Button Logic (Simulated by pressing Backspace)
        if input.isPressed("backspace") then
            self:discardSelected()
        end

        -- Sorting Keys
        if input.isPressed("1") then
            self:sortHand("rank")
        end
        if input.isPressed("2") then
            self:sortHand("suit")
        end
    end

    self.lastMouseState = { x = mx, y = my, left = mLeft }
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
    -- We need to convert Lua tables to C++ Card objects for the engine
    local engineCards = {}
    for _, c in ipairs(selectedCards) do
        -- Check if it's already a userdata (legacy) or table (new)
        if type(c) == "userdata" then
            table.insert(engineCards, c) -- Should not happen with new system but safety first
        else
            -- Convert table {rank="A", suit="H"} to Card.new("A", "H")
            -- We might need to handle rank conversion if Card.new expects specific strings
            -- CardBindings says: "Ace"/"A", "2".."10", "Jack"/"J", "Queen"/"Q", "King"/"K"
            -- Suits: "Hearts"/"H", "Diamonds"/"D", etc.
            -- Our tables use "A", "2", "3"... "H", "D"... matches bindings!
            table.insert(engineCards, Card.new(c.rank, c.suit))
        end
    end

    -- 1. Base Score (Hand Result)
    local handResult = cribbage.evaluate(engineCards)
    local score = cribbage.score(engineCards)

    -- 2. Resolve Card Imprints (Pillar 3)
    local imprintEffects = EnhancementManager:resolveImprints(selectedCards, "score")

    -- 3. Resolve Hand Augments (Pillar 3)
    local augmentEffects = EnhancementManager:resolveAugments(handResult)

    -- 4. Resolve Rule Warps (Pillar 3)
    local warpEffects = EnhancementManager:resolveWarps()

    -- 5. Resolve Jokers & Stacks (Pillar 1 & 2)
    -- JokerManager logic now includes stacking simulation
    -- PASS engineCards (C++ objects) because applyEffects calls C++ bindings
    local jokerEffects = JokerManager:applyEffects(engineCards, "on_score")

    -- 6. Apply Boss Rules (Counterplay Layer)
    score = BossManager:applyRules(score, "score")


    -- 7. Final Score Aggregation
    -- Formula: (Base + Enhancements + Imprints + JokerChips + Warps)
    local finalChips = score.baseChips + augmentEffects.chips + jokerEffects.addedChips + imprintEffects.chips

    -- Apply Warp: Cut Bonus (Ghost Cut)
    if warpEffects.cut_bonus > 0 then
        finalChips = finalChips + warpEffects.cut_bonus
    end

    -- Summing linear multipliers
    local totalTempMult = score.tempMultiplier + augmentEffects.mult + jokerEffects.addedTempMult + imprintEffects.mult
    local totalPermMult = score.permMultiplier + jokerEffects.addedPermMult

    -- Final calculation (with XMult from Imprints)
    local finalMult = (1 + totalTempMult + totalPermMult) * imprintEffects.x_mult

    local finalScore = math.floor(finalChips * finalMult)

    -- Apply Warp: Score Penalty (The Void)
    if warpEffects.score_penalty ~= 1.0 then
        finalScore = math.floor(finalScore * warpEffects.score_penalty)
    end

    -- Apply Warp: Retrigger (The Echo) - Simplified as 2x score for MVP
    if warpEffects.retrigger > 0 then
        finalScore = finalScore * (1 + warpEffects.retrigger)
    end

    -- Handle Imprint Gold (e.g. Gold Inlay)
    if imprintEffects.gold > 0 then
        Economy:addGold(imprintEffects.gold)
        print("Earned " .. imprintEffects.gold .. "g from Imprints")
    end

    -- Debug: Show joker effects
    if jokerEffects.addedChips > 0 or jokerEffects.addedTempMult > 0 then
        print(string.format("Joker effects: +%d chips, +%.2f mult", jokerEffects.addedChips, jokerEffects.addedTempMult))
    end
    print("Scored: " .. finalScore)

    -- Visual FX: Chip Burst!
    -- Spawn centered or distributed? Let's center for now
    EffectManager:spawnChips(640, 360, 20) -- 20 particles
    -- AudioManager:playScore()

    -- Screen Shake for impact
    if finalScore > 50 then
        EffectManager:shake(5, 0.5)
    end

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

function GameScene:sortHand(criteria)
    if #self.hand == 0 then return end

    local function getRankVal(rStr)
        if rStr == "A" then return 1 end
        if rStr == "J" then return 11 end
        if rStr == "Q" then return 12 end
        if rStr == "K" then return 13 end
        return tonumber(rStr) or 0
    end

    local function getSuitVal(sStr)
        -- Spades(3) > Hearts(2) > Clubs(1) > Diamonds(0)
        if sStr == "S" then return 4 end
        if sStr == "H" then return 3 end
        if sStr == "C" then return 2 end
        if sStr == "D" then return 1 end
        return 0
    end

    table.sort(self.hand, function(a, b)
        local ra, rb = getRankVal(a.rank), getRankVal(b.rank)
        local sa, sb = getSuitVal(a.suit), getSuitVal(b.suit)

        if criteria == "rank" then
            if ra ~= rb then return ra < rb end
            return sa < sb
        elseif criteria == "suit" then
            if sa ~= sb then return sa < sb end
            return ra < rb
        end
        return false
    end)

    -- Rebuild Views
    self:rebuildHandViews()
    -- AudioManager:playDeal()
end

function GameScene:rebuildHandViews()
    self.cardViews = {}
    local startX = 200
    local startY = 500
    local spacing = 110
    local CardView = require("visuals/CardView")

    for i, card in ipairs(self.hand) do
        local view = CardView(card, startX + (i - 1) * spacing, startY, self.cardAtlas, self.smallFont)
        table.insert(self.cardViews, view)
    end
end

function GameScene:onDeckCardSelected(index, cardData)
    if not self.pendingShopItem then return end

    local item = self.pendingShopItem
    local action = item.action -- "select_card"
    local itemId = item.itemId

    -- Apply Effect
    if itemId == "spectral_remove" then
        CampaignState:removeCard(index)
        print("Removed card at index " .. index)
    elseif itemId == "spectral_clone" then
        CampaignState:duplicateCard(index)
        print("Duplicated card at index " .. index)
    end

    -- Finalize Purchase (Manual)
    -- We need to find the item in shop again (by index) or trust the index is valid
    local shopIndex = item.itemIndex
    local shopItem = Shop.jokers[shopIndex]

    if shopItem and shopItem.id == itemId then
        Economy:spend(shopItem.price)
        table.remove(Shop.jokers, shopIndex)
    end

    -- Clear state
    self.pendingShopItem = nil
    self.state = "SHOP"
end

function GameScene:discardSelected()
    -- MVP Discard Logic via CampaignState
    if CampaignState:useDiscard() then
        -- 1. Identify indices to remove
        -- We removed table.insert(..., 1, i) which reverses it.
        -- Let's stick to simple list of indices and sort descending to remove safely.
        local indicesToRemove = {}
        for i, view in ipairs(self.cardViews) do
            if view.selected then
                table.insert(indicesToRemove, i)
            end
        end

        if #indicesToRemove == 0 then return end

        -- Sort descending (biggest index first) so removal doesn't shift lower indices
        table.sort(indicesToRemove, function(a, b) return a > b end)

        -- 2. Remove from hand data
        for _, idx in ipairs(indicesToRemove) do
            table.remove(self.hand, idx)
        end

        -- 3. Draw new cards from CURRENT deck list (Preserving Deck State)
        if not self.deckList then
            print("Error: No deck list found!")
            return
        end

        while #self.hand < 6 and #self.deckList > 0 do
            table.insert(self.hand, table.remove(self.deckList))
        end

        -- AudioManager:playDeal()

        -- 4. Recreate visuals (Full redraw of HAND views only, Preserving Cut Card View)
        self.cardViews = {}
        local startX = 200
        local startY = 500
        local spacing = 110

        -- Asset/Font ref must be available (self.cardAtlas, self.smallFont)
        local CardView = require("visuals/CardView")

        for i, card in ipairs(self.hand) do
            local view = CardView(card, startX + (i - 1) * spacing, startY, self.cardAtlas, self.smallFont)
            table.insert(self.cardViews, view)
        end

        print("Discard used. " .. CampaignState.discardsRemaining .. " left.")
    end
end

function GameScene:draw()
    -- Draw Background
    graphics.drawRect(0, 0, 1280, 720, { r = 0.1, g = 0.3, b = 0.2, a = 1.0 }, true)

    -- Crib Placeholder UI
    graphics.print(self.font, "CRIB", 1000, 450, { r = 1, g = 1, b = 1, a = 0.5 })
    graphics.drawRect(980, 480, 110, 150, { r = 0, g = 0, b = 0, a = 0.3 }, true)
    graphics.drawRect(1100, 480, 110, 150, { r = 0, g = 0, b = 0, a = 0.3 }, true)

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
        for _, view in ipairs(self.cribViews) do
            view:draw()
        end

        -- Draw Shop if active
        if self.state == "SHOP" then
            self.shopUI:draw()
        end

        -- Draw Blind Preview (Overlay)
        if self.state == "BLIND_PREVIEW" and self.blindPreview then
            self.blindPreview:draw()
        end

        -- Draw DeckView (Overlay)
        if self.state == "DECK_VIEW" and self.deckView then
            self.deckView:draw()
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
