-- CriblageGameScene.lua
-- Main gameplay scene logic

-- Load subsystems
local CardView = require("visuals/CardView")
local HUD = require("ui/HUD")
local ShopUI = require("ui/ShopUI")
local BlindPreview = require("ui/BlindPreview")
local DeckView = require("ui/DeckView")
local UIButton = require("UI.elements.UIButton")
local CampaignState = require("criblage/CampaignState")
local JokerManager = require("criblage/JokerManager")
local BossManager = require("criblage/BossManager")
local EnhancementManager = require("criblage/EnhancementManager")
local EffectManager = require("visuals/EffectManager")
local AudioManager = require("audio/AudioManager")
local Camera = require("Camera")
local GameSceneLayout = require("scenes/GameSceneLayout")
print("GameSceneLayout loaded successfully!")

-- Phase 3: Meta-progression & Polish
local MagicHandsAchievements = require("Systems/MagicHandsAchievements")
local UnlockSystem = require("Systems/UnlockSystem")
local UndoSystem = require("Systems/UndoSystem")
local CollectionUI = require("UI/CollectionUI")
local TierIndicator = require("UI/TierIndicator")
local ScorePreview = require("UI/ScorePreview")
local AchievementNotification = require("UI/AchievementNotification")
local RunStatsPanel = require("UI/RunStatsPanel")

-- QA Automation Bot (optional)
local AutoPlay = nil
if AUTOPLAY_MODE then
    AutoPlay = require("Systems/AutoPlay")
    print("AutoPlay Mode: ENABLED")
end

local UILayout = require("UI.UILayout")
GameScene = class()

function GameScene:init()
    print("Initializing Game Scene (Constructor)...")
    
    -- Store reference resolution (what we design for)
    self.referenceWidth = 1280
    self.referenceHeight = 720

    -- Initialize Camera (1280x720 fixed viewport)
    self.camera = Camera({ viewportWidth = 1280, viewportHeight = 720 })
    
    -- CRITICAL: Set viewport immediately
    graphics.setViewport(1280, 720)
    print("GameScene: Viewport set to 1280x720")
    
    -- Calculate initial UI scale factor
    local winW, winH = graphics.getWindowSize()
    self.uiScale = math.min(winW / self.referenceWidth, winH / self.referenceHeight)
    print(string.format("GameScene UI Scale: %.2f (screen: %dx%d)", self.uiScale, winW, winH))

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
    self.state = "DEAL" -- DEAL, PLAY, SCORE, SHOP, BLIND_PREVIEW, DECK_VIEW
    self.state = "DEAL" -- DEAL, PLAY, SCORE, SHOP, BLIND_PREVIEW, DECK_VIEW
    self.hand = {}
    -- Crib is now tracked in CampaignState for persistence
    self.cutCard = nil
    self.pendingShopItem = nil -- For spectral actions

    -- Visual Components
    -- Initialize UI Layout (Instance)
    self.uiLayout = UILayout(1280, 720)

    -- Visual Components
    self.cardViews = {}
    self.cutCardView = nil
    -- Pass layout to UIs
    self.shopUI = ShopUI(self.font, self.uiLayout)
    self.blindPreview = BlindPreview(self.font, self.smallFont, self.uiLayout)
    self.deckView = DeckView(self.font, self.smallFont, self.cardAtlas, self.uiLayout)
    self.hud = HUD(self.font, self.smallFont, self.uiLayout)

    -- Phase 3 UIs
    self.collectionUI = CollectionUI(self.font, self.smallFont, self.uiLayout)
    self.achievementNotification = AchievementNotification(self.font, self.smallFont)
    self.runStatsPanel = RunStatsPanel(self.font, self.smallFont)

    -- Score preview state
    self.scorePreviewData = nil -- Stores calculated preview data

    -- Note: ScorePreview and TierIndicator are modules with static functions
    -- They are used directly via ScorePreview.calculate() and TierIndicator.draw()

    -- UI visibility flags
    self.showCollection = false
    self.showRunStats = false

    print("Phase 3 systems initialized successfully!")

    -- Mouse State
    self.lastMouseState = { x = 0, y = 0, left = false }

    -- Drag State
    self.draggingView = nil
    self.dragOffset = { x = 0, y = 0 }
    self.dragStartX = 0
    self.dragStartY = 0

    -- Add to Crib Button
    self.addToCribButton = UIButton(nil, "Add to Crib", self.font, function()
        self:addSelectedCardsToCrib()
    end)
    self.addToCribButton.bgColor = { r = 0.2, g = 0.6, b = 0.3, a = 1 }
    self.addToCribButton.hoverColor = { r = 0.3, g = 0.8, b = 0.4, a = 1 }
    self.addToCribButton.visible = false -- Only show during DEAL state
    self:updateAddToCribButtonPosition()  -- Set initial scaled position

    -- Initialize AutoPlay if enabled
    if AutoPlay and AUTOPLAY_MODE then
        AutoPlay:init(AUTOPLAY_RUNS or 100, AUTOPLAY_STRATEGY or "Random")
    end

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

function GameScene:scale(value)
    return value * self.uiScale
end

function GameScene:updateAddToCribButtonPosition()
    -- Use layout system for positioning
    local buttonLayout = GameSceneLayout.getPosition("addToCribButton")
    self.addToCribButton.x = buttonLayout.x
    self.addToCribButton.y = buttonLayout.y
    self.addToCribButton.width = buttonLayout.width
    self.addToCribButton.height = buttonLayout.height
end

function GameScene:addSelectedCardsToCrib()
    -- Add selected cards to crib (max 2, cannot replace)
    if #CampaignState.crib >= 2 then
        log.warn("Crib is full (max 2 cards)")
        return
    end

    -- Find selected cards
    local selectedCards = {}
    for i, view in ipairs(self.cardViews) do
        if view.selected then
            table.insert(selectedCards, { view = view, index = i })
        end
    end

    -- Check how many we can add
    local spaceLeft = 2 - #CampaignState.crib
    if #selectedCards == 0 then
        log.warn("No cards selected")
        return
    end

    if #selectedCards > spaceLeft then
        log.warn("Too many cards selected. Can only add " .. spaceLeft .. " more card(s) to crib")
        return
    end

    -- Count how many cards we're adding
    local numCardsToAdd = #selectedCards

    -- Check if deck has enough cards
    if not self.deckList or #self.deckList < numCardsToAdd then
        log.warn("Not enough cards in deck to replace (" ..
            #self.deckList .. " available, " .. numCardsToAdd .. " needed)")
        return
    end

    -- Add selected cards to crib
    for _, cardInfo in ipairs(selectedCards) do
        local card = cardInfo.view.card
        table.insert(CampaignState.crib, card)
    end

    -- Remove from hand (iterate backwards to avoid index issues)
    for i = #selectedCards, 1, -1 do
        local cardInfo = selectedCards[i]
        table.remove(self.hand, cardInfo.index)
    end

    -- Deal replacement cards from deck
    for i = 1, numCardsToAdd do
        local newCard = table.remove(self.deckList)
        if newCard then
            table.insert(self.hand, newCard)
        end
    end

    -- Rebuild views
    self:rebuildHandViews()
    self:rebuildCribViews()

    log.info("Added " .. numCardsToAdd .. " card(s) to crib and dealt " .. numCardsToAdd .. " replacement(s)")
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

    -- Draw 6 cards (+ bonus for first blind only)
    self.hand = {}
    self.draggingView = nil -- Clear any stale drag state
    self.dragStartX = 0
    self.dragStartY = 0

    local baseHandSize = 6
    local handSizeBonus = 0
    
    -- Apply first blind hand bonus ONLY on the very first hand of blind 1
    if CampaignState.firstBlindHandBonus and CampaignState.firstBlindHandBonus > 0 and 
       CampaignState.currentBlind == 1 and CampaignState.handsRemaining == 4 then
        handSizeBonus = CampaignState.firstBlindHandBonus
        print("✨ First Blind Bonus: +" .. handSizeBonus .. " cards in hand!")
    end
    
    for i = 1, (baseHandSize + handSizeBonus) do
        table.insert(self.hand, table.remove(self.deckList))
    end

    -- Cut card
    self.cutCard = table.remove(self.deckList)

    -- Create visual cards using layout system
    self.cardViews = {}
    -- Rebuild crib views from CampaignState (don't reset crib - it persists!)
    self:rebuildCribViews()
    
    -- Position hand cards using relative layout
    local startX, startY, spacing = GameSceneLayout.getCenteredHandPosition(#self.hand)
    print(string.format("Hand cards: startX=%.0f, startY=%.0f, spacing=%.0f, count=%d", 
        startX, startY, spacing, #self.hand))
    for i, card in ipairs(self.hand) do
        local x = startX + (i - 1) * spacing
        local view = CardView(card, x, startY, self.cardAtlas, self.smallFont)
        table.insert(self.cardViews, view)
    end

    -- Create cut card view using layout system
    local cutX, cutY = GameSceneLayout.getPosition("cutCard")
    print(string.format("Cut card: x=%.0f, y=%.0f", cutX, cutY))
    self.cutCardView = CardView(self.cutCard, cutX, cutY, self.cardAtlas, self.smallFont)

    self.state = "PLAY"
    print("Hand dealt: " .. #self.hand .. " cards")
end

function GameScene:rebuildCribViews()
    self.cribViews = {}
    local CardView = require("visuals/CardView")
    
    -- Position crib cards using layout system
    for i, card in ipairs(CampaignState.crib) do
        local x, y = GameSceneLayout.getPosition("crib", {slotIndex = i})
        print(string.format("Crib card %d: x=%.0f, y=%.0f", i, x, y))
        local view = CardView(card, x, y, self.cardAtlas, self.smallFont)
        table.insert(self.cribViews, view)
    end
end

function GameScene:update(dt)
    -- Initialize if missing (Fallback)
    if not self.hud then
        print("Late initialization of GameScene...")
        self:init()
    end
    
    -- AutoPlay bot update
    if AutoPlay and AutoPlay.enabled then
        AutoPlay:update(self, dt)
    end

    -- Check for window resize to update viewport scaling and UI Layout
    local winW, winH = graphics.getWindowSize()
    if winW ~= self.lastWinW or winH ~= self.lastWinH then
        print("DEBUG GameScene: Resize detected " .. winW .. "x" .. winH)
        self.lastWinW = winW
        self.lastWinH = winH

        -- Recalculate UI scale factor
        self.uiScale = math.min(winW / self.referenceWidth, winH / self.referenceHeight)
        print(string.format("GameScene UI Scale updated: %.2f", self.uiScale))

        -- Re-apply viewport to force zoom recalculation in C++
        if self.camera and self.camera.viewportWidth and self.camera.viewportHeight then
            graphics.setViewport(self.camera.viewportWidth, self.camera.viewportHeight)
            print("Camera: Window resized to " .. winW .. "x" .. winH .. ". Re-applying viewport.")
        end

        -- Update UI Layout
        if self.uiLayout then
            print("DEBUG GameScene: Updating UILayout size")
            self.uiLayout:updateScreenSize(winW, winH)
        end
        
        -- Update "Add to Crib" button position
        self:updateAddToCribButtonPosition()
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

    -- Phase 3: Update systems
    self.achievementNotification:update(dt)

    -- Handle global keyboard shortcuts
    if input.isPressed("c") then
        self.showCollection = not self.showCollection
        if self.showCollection then
            self.collectionUI:open()
        else
            self.collectionUI:close()
        end
    end

    if input.isPressed("tab") then
        self.showRunStats = not self.showRunStats
    end

    if input.isPressed("z") and self.state == "PLAY" then
        local success, action = UndoSystem:undo()
        if success then
            print("Undo: " .. action.type)
            -- TODO: Actually apply the undo (restore state)
        else
            print("Nothing to undo")
        end
    end

    -- Input Handling (Simple click detection)
    local mx, my = input.getMousePosition()

    -- Use correct API for mouse button
    local mLeft = input.isMouseButtonPressed("left")

    local clicked = mLeft

    -- Update Add to Crib button (only visible when crib is not full and has cards in hand)
    if #self.hand > 0 and #CampaignState.crib < 2 then
        self.addToCribButton.visible = true
        self.addToCribButton:update(dt, mx, my, clicked)

        -- Update button text to show progress
        self.addToCribButton.text = "Add to Crib (" .. #CampaignState.crib .. "/2)"
    else
        self.addToCribButton.visible = false
    end


    -- Handle Collection UI if open (takes priority)
    if self.showCollection then
        local action = self.collectionUI:update(dt, mx, my, clicked)
        if action == "close" then
            self.showCollection = false
        end
        return -- Don't process other input when collection is open
    end

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
        elseif action == "select_card" or action == "select_card_for_imprint" then
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
        -- Update Score Preview
        local selectedCards = {}
        for i, view in ipairs(self.cardViews) do
            if view.selected then
                table.insert(selectedCards, self.hand[i])
            end
        end

        if #selectedCards == 4 and self.cutCard then
            -- Calculate score preview
            self.scorePreviewData = ScorePreview.calculate(selectedCards, self.cutCard)
        else
            self.scorePreviewData = nil
        end

        -- Handle Dragging State
        if self.draggingView then
            -- Update Position
            self.draggingView.currentX = mx - self.dragOffset.x
            self.draggingView.currentY = my - self.dragOffset.y

            -- Release Drag
            if not mLeft then
                -- Check Drop in Crib (980, 480, 240x160 approx for entire visual area)
                if mx > 980 and mx < 1220 and my > 480 and my < 640 and #CampaignState.crib < 2 then
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
                    table.insert(CampaignState.crib, card)

                    -- Rebuild Views
                    self:rebuildHandViews()
                    self:rebuildCribViews()

                    -- AudioManager:playPlace()
                else
                    -- Normal Click/Drop Logic
                    local dist = math.abs(mx - self.dragStartX) + math.abs(my - self.dragStartY)
                    if dist < 5 then
                        -- Track undo state before selection change
                        UndoSystem:saveState("card_selection", {
                            wasSelected = self.draggingView.selected
                        })

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

    -- DEBUG: Enhancement System
    if input.isPressed("p") then
        local success, msg = EnhancementManager:addEnhancement("planet_fifteen", "augment")
        print("DEBUG: " .. msg)
    end
    if input.isPressed("l") then
        local success, msg = EnhancementManager:addEnhancement("spectral_echo", "warp")
        print("DEBUG: " .. msg)
    end
    if input.isPressed("j") then
        local success, msg = JokerManager:addJoker("lucky_seven")
        print("DEBUG: " .. msg)
    end
    if input.isPressed("b") then
        BossManager:activateBoss("the_counter")
        print("DEBUG: Activated Boss The Counter")
    end

    if input.isPressed("t") then
        package.loaded["content.scripts.tests.JokerTests"] = nil -- Force reload for iteration
        local tests = require "content.scripts.tests.JokerTests"
        tests.run()
    end

    -- Phase 3: JSON Loading Test (press 'y')
    if input.isPressed("y") then
        package.loaded["content.scripts.tests.TestJSONLoading"] = nil
        local jsonTest = require "content.scripts.tests.TestJSONLoading"
    end

    if self.state == "GAME_OVER" then
        if input.isPressed("r") then
            -- Restart Game
            print("Restarting game...")
            -- For MVP, a simple reload or reset state
            CampaignState:init()
            self:enter()
            self.state = "PLAY"
        end
    end

    self.lastMouseState = { x = mx, y = my, left = mLeft }
end

function GameScene:playHand()
    local selectedCards = {}
    for i, view in ipairs(self.cardViews) do
        if view.selected then
            table.insert(selectedCards, self.hand[i])
        end
    end

    -- Check for warp_infinity (no hand limit)
    local warpEffects = EnhancementManager:resolveWarps()
    local hasInfinity = false
    local hasPhantom = false
    
    if warpEffects.active_warps then
        for _, warpId in ipairs(warpEffects.active_warps) do
            if warpId == "warp_infinity" then
                hasInfinity = true
            elseif warpId == "warp_phantom" then
                hasPhantom = true
            end
        end
    end
    
    if not hasInfinity and #selectedCards ~= 4 then
        print("Must select exactly 4 cards")
        return
    elseif hasInfinity and #selectedCards < 1 then
        print("Must select at least 1 card")
        return
    end
    
    if hasInfinity and #selectedCards > 4 then
        print("♾️ Warp Infinity: Playing " .. #selectedCards .. " cards (no limit)!")
    end
    
    -- WARP: Phantom - Track discarded cards for scoring
    local phantomCards = {}
    if hasPhantom and self.discardedThisTurn and #self.discardedThisTurn > 0 then
        print("👻 Warp Phantom: Discarded cards (" .. #self.discardedThisTurn .. ") count for scoring!")
        for _, card in ipairs(self.discardedThisTurn) do
            table.insert(phantomCards, card)
        end
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

    -- 1. Get Boss Rules (from Boss + Warps)
    local bossRules = BossManager:getEffects()
    
    -- Add warp-specific boss rules (for engine warps)
    local warpEffects = EnhancementManager:resolveWarps()
    if warpEffects.active_warps then
        for _, warpId in ipairs(warpEffects.active_warps) do
            -- Check if this warp requires a boss rule for C++ scoring
            if warpId == "warp_blaze" or warpId == "warp_mirror" or 
               warpId == "warp_inversion" or warpId == "warp_wildfire" then
                table.insert(bossRules, warpId)
                print("🔥 Engine Warp Active: " .. warpId)
            end
        end
    end

    -- 2. Base Score (Hand Result) with Boss Rules applied
    local handResult = cribbage.evaluate(engineCards)
    local score = cribbage.score(engineCards, 0, 0, bossRules) -- Pass rules here

    -- 3. Resolve Card Imprints (Pillar 3)
    local imprintEffects = EnhancementManager:resolveImprints(selectedCards, "score")

    -- 4. Resolve Hand Augments (Pillar 3)
    local augmentEffects = EnhancementManager:resolveAugments(handResult, engineCards)

    -- 5. Resolve Rule Warps (Pillar 3)
    local warpEffects = EnhancementManager:resolveWarps()

    -- 6. Resolve Jokers & Stacks (Pillar 1 & 2)
    -- JokerManager logic now includes stacking simulation
    -- PASS engineCards (C++ objects) because applyEffects calls C++ bindings
    local jokerEffects = JokerManager:applyEffects(engineCards, "on_score")


    -- 7. Final Score Aggregation


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

    -- Apply Warp: Mult Multiplier (Ascension - double all mult)
    if warpEffects.mult_multiplier > 1.0 then
        totalTempMult = totalTempMult * warpEffects.mult_multiplier
        totalPermMult = totalPermMult * warpEffects.mult_multiplier
    end

    -- Final calculation (with XMult from Imprints)
    local finalMult = (1 + totalTempMult + totalPermMult) * imprintEffects.x_mult

    local finalScore = math.floor(finalChips * finalMult)

    -- Apply Warp: Score Penalty (The Void) and Score Multipliers (Fortune, Gambit, Greed)
    local totalScoreMultiplier = warpEffects.score_penalty * warpEffects.score_multiplier
    if totalScoreMultiplier ~= 1.0 then
        finalScore = math.floor(finalScore * totalScoreMultiplier)
    end
    
    -- Apply Warp: Score to Gold (Greed - 10% of score becomes gold)
    if warpEffects.score_to_gold_pct > 0 then
        local goldGain = math.floor(finalScore * warpEffects.score_to_gold_pct)
        if goldGain > 0 then
            Economy:addGold(goldGain)
            print("Warp Greed: Converted " .. goldGain .. "g from score")
        end
    end
    
    -- Apply Warp: Hand Cost (Fortune - costs 5g per hand)
    if warpEffects.hand_cost > 0 then
        if Economy:spend(warpEffects.hand_cost) then
            print("Warp Fortune: Paid " .. warpEffects.hand_cost .. "g for hand")
        else
            print("WARN: Not enough gold for Warp Fortune cost!")
        end
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

    -- NEW: Score the crib on the last hand only
    local cribScore = 0
    if CampaignState:isLastHand() and #CampaignState.crib == 2 then
        -- Build crib cards for scoring (2 player cards + 2 random + cut = 5 cards)
        local cribCards = {}          -- C++ Card objects for engine
        local cribCardsLua = {}       -- Lua table cards for imprint resolution

        print("DEBUG: Building crib hand for scoring")
        print("DEBUG: Crib has " .. #CampaignState.crib .. " player-selected cards")

        for i, c in ipairs(CampaignState.crib) do
            print("DEBUG: Crib card " .. i .. " type: " .. type(c))
            if type(c) == "table" then
                if c.rank and c.suit then
                    print("DEBUG: Converting table card: " .. c.rank .. " of " .. c.suit)
                    local card = Card.new(c.rank, c.suit)
                    print("DEBUG: Card.new returned type: " .. type(card))
                    if card then
                        table.insert(cribCards, card)
                        table.insert(cribCardsLua, c)  -- Keep original table for imprints
                    else
                        print("ERROR: Card.new returned nil for " .. c.rank .. " of " .. c.suit)
                    end
                else
                    print("ERROR: Crib card is table but missing rank or suit")
                end
            else
                -- Card is already a userdata Card object
                print("DEBUG: Using existing Card object")
                table.insert(cribCards, c)
                -- Try to find corresponding lua table in original crib
                table.insert(cribCardsLua, CampaignState.crib[i])
            end
        end

        -- Add 2 random cards from the deck to fill the crib
        print("DEBUG: Adding 2 random cards from deck to crib")
        print("DEBUG: Deck size: " .. #self.deckList)
        local availableCards = {}
        for _, card in ipairs(self.deckList) do
            if card then
                table.insert(availableCards, card)
            end
        end
        print("DEBUG: Available cards after filtering: " .. #availableCards)

        -- Randomly select 2 cards
        for i = 1, 2 do
            if #availableCards > 0 then
                local randomIndex = math.random(1, #availableCards)
                local randomCard = table.remove(availableCards, randomIndex)

                if randomCard then
                    if type(randomCard) == "table" then
                        if randomCard.rank and randomCard.suit then
                            print("DEBUG: Adding random card: " .. randomCard.rank .. " of " .. randomCard.suit)
                            local card = Card.new(randomCard.rank, randomCard.suit)
                            if card then
                                table.insert(cribCards, card)
                                table.insert(cribCardsLua, randomCard)
                            end
                        end
                    else
                        table.insert(cribCards, randomCard)
                        -- For userdata, create a table representation
                        table.insert(cribCardsLua, randomCard)
                    end
                else
                    print("ERROR: Random card is nil")
                end
            end
        end

        -- Add cut card to make it a proper hand
        print("DEBUG: Cut card type: " .. type(self.cutCard))
        if type(self.cutCard) == "table" then
            if self.cutCard.rank and self.cutCard.suit then
                print("DEBUG: Converting cut card: " .. self.cutCard.rank .. " of " .. self.cutCard.suit)
                local cutCard = Card.new(self.cutCard.rank, self.cutCard.suit)
                print("DEBUG: Cut Card.new returned type: " .. type(cutCard))
                if cutCard then
                    table.insert(cribCards, cutCard)
                    table.insert(cribCardsLua, self.cutCard)
                else
                    print("ERROR: Card.new returned nil for cut card " ..
                        self.cutCard.rank .. " of " .. self.cutCard.suit)
                end
            else
                print("ERROR: Cut card is table but missing rank or suit")
            end
        else
            print("DEBUG: Using existing cut Card object")
            table.insert(cribCards, self.cutCard)
            table.insert(cribCardsLua, self.cutCard)
        end

        print("DEBUG: Total cards for crib scoring: " .. #cribCards)

        -- Only score if we have exactly 5 cards (4 crib + 1 cut)
        if #cribCards == 5 then
            -- Apply FULL scoring pipeline to crib (same as main hand)
            print("--- CRIB SCORING PIPELINE ---")
            
            -- 1. Base Score (with Boss Rules)
            local cribHandResult = cribbage.evaluate(cribCards)
            local cribBaseScore = cribbage.score(cribCards, 0, 0, bossRules)
            
            -- 2. Resolve Card Imprints for crib cards
            local cribImprintEffects = EnhancementManager:resolveImprints(cribCardsLua, "score")
            
            -- 3. Resolve Hand Augments (Planets) for crib patterns
            local cribAugmentEffects = EnhancementManager:resolveAugments(cribHandResult, cribCards)
            
            -- 4. Resolve Rule Warps (use same warp effects as main hand)
            -- Note: Warps are global, so we reuse the same warpEffects
            
            -- 5. Resolve Jokers & Stacks for crib patterns
            local cribJokerEffects = JokerManager:applyEffects(cribCards, "on_score")
            
            -- 6. Aggregate Crib Score (same formula as main hand)
            local cribFinalChips = cribBaseScore.baseChips + cribAugmentEffects.chips + 
                                   cribJokerEffects.addedChips + cribImprintEffects.chips
            
            -- Apply Warp: Cut Bonus (Ghost Cut)
            if warpEffects.cut_bonus > 0 then
                cribFinalChips = cribFinalChips + warpEffects.cut_bonus
            end

            local cribTotalTempMult = cribBaseScore.tempMultiplier + cribAugmentEffects.mult + cribJokerEffects.addedTempMult + cribImprintEffects.mult
            local cribTotalPermMult = cribBaseScore.permMultiplier + cribJokerEffects.addedPermMult

            -- Apply Warp: Mult Multiplier (Ascension - double all mult)
            if warpEffects.mult_multiplier > 1.0 then
                cribTotalTempMult = cribTotalTempMult * warpEffects.mult_multiplier
                cribTotalPermMult = cribTotalPermMult * warpEffects.mult_multiplier
            end

            local cribFinalMult = (1 + cribTotalTempMult + cribTotalPermMult) * cribImprintEffects.x_mult

            local cribFinalScore = math.floor(cribFinalChips * cribFinalMult)

            -- Apply Warp: Score Penalty (The Void) and Score Multipliers (Fortune, Gambit, Greed)
            local totalScoreMultiplier = warpEffects.score_penalty * warpEffects.score_multiplier
            if totalScoreMultiplier ~= 1.0 then
                cribFinalScore = math.floor(cribFinalScore * totalScoreMultiplier)
            end

            -- Apply Warp: Retrigger (The Echo) - Simplified as 2x score for MVP
            if warpEffects.retrigger > 0 then
                cribFinalScore = cribFinalScore * (1 + warpEffects.retrigger)
            end
            
            -- Sum multipliers
            local cribTotalTempMult = cribBaseScore.tempMultiplier + cribAugmentEffects.mult + 
                                      cribJokerEffects.addedTempMult + cribImprintEffects.mult
            local cribTotalPermMult = cribBaseScore.permMultiplier + cribJokerEffects.addedPermMult
            
            -- Final calculation (with XMult from Imprints)
            local cribFinalMult = (1 + cribTotalTempMult + cribTotalPermMult) * cribImprintEffects.x_mult
            
            cribScore = math.floor(cribFinalChips * cribFinalMult)
            
            -- Apply Warp: Score Penalty (The Void)
            if warpEffects.score_penalty ~= 1.0 then
                cribScore = math.floor(cribScore * warpEffects.score_penalty)
            end
            
            -- Apply Warp: Retrigger (The Echo)
            if warpEffects.retrigger > 0 then
                cribScore = cribScore * (1 + warpEffects.retrigger)
            end
            
            -- Handle Imprint Gold from crib cards
            if cribImprintEffects.gold > 0 then
                Economy:addGold(cribImprintEffects.gold)
                print("Earned " .. cribImprintEffects.gold .. "g from Crib Imprints")
            end

            -- Add crib score to final score
            finalScore = finalScore + cribScore

            print("--- CRIB SCORE BREAKDOWN ---")
            print("Crib Base: " .. cribBaseScore.baseChips .. " x " .. 
                  (1 + cribBaseScore.tempMultiplier + cribBaseScore.permMultiplier))
            print("Crib Augments: +" .. cribAugmentEffects.chips .. " Chips, +" .. 
                  cribAugmentEffects.mult .. " Mult")
            print("Crib Jokers: +" .. cribJokerEffects.addedChips .. " Chips, +" .. 
                  (cribJokerEffects.addedTempMult + cribJokerEffects.addedPermMult) .. " Mult")
            print("Crib Imprints: +" .. cribImprintEffects.chips .. " Chips, +" .. 
                  cribImprintEffects.mult .. " Mult, x" .. cribImprintEffects.x_mult)
            print("Crib Final Score: " .. cribScore)
            print("-----------------------------")
        else
            print("ERROR: Expected 5 cards for crib scoring but got " .. #cribCards)
        end
    end

    -- Debug: Show joker effects
    print("--- SCORE BREAKDOWN ---")
    print("Base: " .. score.baseChips .. " x " .. (1 + score.tempMultiplier + score.permMultiplier))
    print("Augments: +" .. augmentEffects.chips .. " Chips, +" .. augmentEffects.mult .. " Mult")
    print("Jokers: +" ..
        jokerEffects.addedChips .. " Chips, +" .. (jokerEffects.addedTempMult + jokerEffects.addedPermMult) .. " Mult")
    print("Warps: Cut Bonus " .. warpEffects.cut_bonus .. ", Retrigger " .. warpEffects.retrigger)
    print("-----------------------")

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

    -- Emit hand scored event for achievements
    events.emit("hand_scored", {
        score = finalScore,
        handTotal = self:calculateHandTotal(selectedCards),
        categoriesScored = {
            fifteens = score.baseChips > 0 and handResult.fifteens and #handResult.fifteens or 0,
            pairs = score.baseChips > 0 and handResult.pairs and #handResult.pairs or 0,
            runs = score.baseChips > 0 and handResult.runs and #handResult.runs or 0,
            flushes = score.baseChips > 0 and handResult.flushCount or 0,
            nobs = score.baseChips > 0 and handResult.hasNobs and 1 or 0
        }
    })

    -- WARP: Time Warp - Score crib BEFORE hand
    local hasTimeWarp = false
    if warpEffects.active_warps then
        for _, warpId in ipairs(warpEffects.active_warps) do
            if warpId == "warp_time" then
                hasTimeWarp = true
                break
            end
        end
    end
    
    if hasTimeWarp and cribScore > 0 then
        print("⏰ Warp Time: Scoring crib BEFORE hand!")
        print("Crib scored first: " .. cribScore)
        CampaignState.currentScore = CampaignState.currentScore + cribScore
    end

    -- Check campaign result
    local result, reward = CampaignState:playHand(finalScore)

    if result == "win" then
        print("Blind Cleared! entering shop...")

        -- Emit blind won event for achievements
        local currentBlind = CampaignState:getCurrentBlind()
        events.emit("blind_won", {
            blindType = currentBlind.type or "small",
            act = CampaignState.currentAct,
            bossId = BossManager.activeBoss and BossManager.activeBoss.id or nil,
            score = finalScore
        })

        self.state = "SHOP"
        self.shopUI:open(reward)
    elseif result == "loss" then
        print("GAME OVER")
        self.state = "GAME_OVER"

        -- Emit run complete event
        events.emit("run_complete", { won = false })
    else
        -- High enough for demo to just refresh hand
        self:startNewHand()
    end
end

function GameScene:calculateHandTotal(cards)
    local total = 0
    for _, card in ipairs(cards) do
        local val = 0
        if card.rank == "A" then
            val = 1
        elseif card.rank == "J" or card.rank == "Q" or card.rank == "K" then
            val = 10
        else
            val = tonumber(card.rank) or 0
        end
        total = total + val
    end
    return total
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
    local action = item.action
    local itemId = item.itemId
    local shopIndex = item.itemIndex

    -- Handle different types of card selection
    if action == "select_card" then
        -- Deck Sculptor: Remove or Clone card
        local success, msg = Shop:applySculptor(shopIndex, index, itemId)
        if success then
            print(msg)
            -- Payment is handled in applySculptor
        else
            print("Failed: " .. msg)
        end
    elseif action == "select_card_for_imprint" then
        -- Card Imprint: Apply imprint to card
        if not cardData or not cardData.id then
            print("Invalid card data")
            self.state = "SHOP"
            return
        end

        local success, msg = Shop:applyImprint(shopIndex, cardData.id)
        if success then
            print("Imprinted " .. cardData.id .. " with " .. itemId)
            -- Payment is handled in applyImprint
        else
            print("Failed to imprint: " .. msg)
        end
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

        -- Track discarded cards for warp_phantom
        self.discardedThisTurn = self.discardedThisTurn or {}
        for _, idx in ipairs(indicesToRemove) do
            table.insert(self.discardedThisTurn, self.hand[idx])
        end

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
        
        -- WARP: Chaos - Reshuffle after discard
        local warpEffects = EnhancementManager:resolveWarps()
        if warpEffects.active_warps then
            for _, warpId in ipairs(warpEffects.active_warps) do
                if warpId == "warp_chaos" then
                    print("🌀 Warp Chaos: Reshuffling deck after discard!")
                    -- Reshuffle remaining deck
                    for i = #self.deckList, 2, -1 do
                        local j = math.random(i)
                        self.deckList[i], self.deckList[j] = self.deckList[j], self.deckList[i]
                    end
                end
            end
        end

        -- 4. Recreate visuals (Full redraw of HAND views only, Preserving Cut Card View)
        self.cardViews = {}
        local startX = 200
        local startY = 500
        local spacing = 110
        
        local CardView = require("visuals/CardView")
        
        for i, card in ipairs(self.hand) do
            local view = CardView(card, startX + (i - 1) * spacing, startY, self.cardAtlas, self.smallFont)
            table.insert(self.cardViews, view)
        end

        print("Discard used. " .. CampaignState.discardsRemaining .. " left.")
    else
        print("No discards remaining")
    end
end

function GameScene:draw()
    -- Safety check for initialization
    if not self.camera or not self.hud then
        return
    end
    
    -- Draw UI (Reset Camera to 0,0 so UI scales with Zoom but stays fixed relative to screen)
    local gameCamX, gameCamY = self.camera:getPosition()
    graphics.setCamera(0, 0)

    -- Draw Background (screenSpace = false to use zoom, but clamped to 0,0)
    graphics.drawRect(0, 0, 1280, 720, { r = 0.1, g = 0.3, b = 0.2, a = 1.0 }, false)

    -- Crib Placeholder UI
    graphics.print(self.font, "CRIB", 1000, 450, { r = 1, g = 1, b = 1, a = 0.5 })
    graphics.drawRect(980, 480, 110, 150, { r = 0, g = 0, b = 0, a = 0.3 }, true)
    graphics.drawRect(1100, 480, 110, 150, { r = 0, g = 0, b = 0, a = 0.3 }, true)

    if self.hud then
        -- Draw HUD
        self.hud:draw(CampaignState)

        -- Phase 3: Draw keyboard shortcuts helper text
        if self.state == "PLAY" then
            local shortcutX, shortcutY = GameSceneLayout.getPosition("shortcuts")
            graphics.print(self.smallFont, "[C] Collection  [TAB] Stats  [Z] Undo", shortcutX, shortcutY,
                { r = 0.7, g = 0.7, b = 0.7, a = 0.8 })
        end

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

        -- Draw Add to Crib button
        self.addToCribButton:draw()

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

        -- Phase 3: Draw Score Preview (in PLAY state)
        if self.state == "PLAY" and self.scorePreviewData then
            ScorePreview.draw(850, 300, self.scorePreviewData, self.font, self.smallFont)
        end

        -- Phase 3: Draw Tier Indicators on Jokers
        if JokerManager and JokerManager.slots then
            for i, joker in ipairs(JokerManager.slots) do
                if joker.stack and joker.stack > 1 then
                    -- Draw tier indicator (x position based on joker slot)
                    local tierX = 50 + (i - 1) * 80
                    local tierY = 100
                    TierIndicator.draw(tierX, tierY, joker.stack, self.smallFont, joker.stack, "small")
                end
            end
        end

        -- Phase 3: Draw Run Stats Panel (TAB toggle)
        if self.showRunStats and self.runStatsPanel then
            self.runStatsPanel:draw()
        end

        -- Phase 3: Draw Collection UI (C toggle)
        if self.showCollection and self.collectionUI then
            self.collectionUI:draw()
        end

        -- Phase 3: Draw Achievement Notifications (always on top)
        if self.achievementNotification then
            self.achievementNotification:draw()
        end

        -- Draw Game Over
        if self.state == "GAME_OVER" then
            graphics.print(self.font, "GAME OVER", 500, 300, { r = 1, g = 0, b = 0, a = 1 })
            graphics.print(self.smallFont, "Press R to Restart", 530, 350)
            graphics.print(self.smallFont, "Press C to view Collection", 490, 380)
            graphics.print(self.smallFont, "Press TAB to view Stats", 510, 410)

            if input.isPressed("r") then
                -- Reset stats for new run
                if self.runStatsPanel then
                    self.runStatsPanel:reset()
                end

                CampaignState:init()
                self:startNewHand()
            end
        end
    else
        graphics.print(self.font or 0, "Loading UI...", 600, 360, { r = 1, g = 1, b = 1, a = 1 })
    end
end
