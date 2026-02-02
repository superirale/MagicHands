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
local ScoringUtils = require("utils/ScoringUtils")

-- NEW: Refactored UI Architecture
local CoordinateSystem = require("UI/CoordinateSystem")
local UIEvents = require("UI/UIEvents")
local UILayer = require("UI/UILayer")
local LayoutManager = require("UI/LayoutManager")
local InputHandler = require("UI/InputHandler")
local CardViewModel = require("visuals/CardViewModel")
local CardViewRefactored = require("visuals/CardViewRefactored")
print("[GameScene] New UI architecture loaded!")

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

    -- NEW: Initialize Coordinate System (FIRST - before anything else)
    local winW, winH = graphics.getWindowSize()
    CoordinateSystem.init(winW, winH)
    print("[GameScene] CoordinateSystem initialized: " .. winW .. "x" .. winH)

    -- NEW: Initialize Input Handler
    self.inputHandler = InputHandler()
    print("[GameScene] InputHandler initialized")

    -- NEW: Setup Rendering Pipeline
    self.renderPipeline = UILayer.createStandardPipeline()
    print("[GameScene] Rendering pipeline created")

    -- NEW: Setup Layout Manager
    self.layoutManager = LayoutManager.Container(self.referenceWidth, self.referenceHeight)
    print("[GameScene] LayoutManager initialized")

    -- Initialize Camera (1280x720 fixed viewport)
    self.camera = Camera({ viewportWidth = 1280, viewportHeight = 720 })

    -- CRITICAL: Set viewport immediately
    graphics.setViewport(1280, 720)
    print("GameScene: Viewport set to 1280x720")

    -- Calculate initial UI scale factor (kept for backward compatibility)
    self.uiScale = CoordinateSystem.getScale()
    print(string.format("GameScene UI Scale: %.2f (screen: %dx%d)", self.uiScale, winW, winH))

    -- NEW: Setup UI Event Listeners
    self:setupEventListeners()
    print("[GameScene] UI event listeners registered")

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
    self:updateAddToCribButtonPosition() -- Set initial scaled position

    -- Initialize AutoPlay if enabled
    if AutoPlay and AUTOPLAY_MODE then
        AutoPlay:init(AUTOPLAY_RUNS or 100, AUTOPLAY_STRATEGY or "Random")
    end

    print("Game Scene initialized!")

    -- NEW: Track if using new architecture for cards
    self.useNewCardSystem = true
    self.cardViewModels = {} -- New system: CardViewModels
    -- self.cardViews remains for backward compatibility
end

--- NEW: Setup UI Event Listeners
function GameScene:setupEventListeners()
    -- Card selection events
    UIEvents.on("card:selected", function(data)
        self:onCardSelected(data.cardIndex)
    end)

    UIEvents.on("card:deselected", function(data)
        self:onCardDeselected(data.cardIndex)
    end)

    -- Card drag events
    UIEvents.on("card:dragStart", function(data)
        self:onCardDragStart(data.cardIndex, data.startX, data.startY)
    end)

    UIEvents.on("card:dragEnd", function(data)
        self:onCardDragEnd(data.cardIndex, data.x, data.y)
    end)

    -- Input shortcuts
    UIEvents.on("input:confirm", function()
        if self.state == "PLAY" then
            self:playHand()
        end
    end)

    UIEvents.on("input:discard", function()
        if self.state == "PLAY" then
            self:discardSelected()
        end
    end)

    UIEvents.on("input:sortByRank", function()
        if self.state == "PLAY" then
            self:sortHand("rank")
        end
    end)

    UIEvents.on("input:sortBySuit", function()
        if self.state == "PLAY" then
            self:sortHand("suit")
        end
    end)

    UIEvents.on("input:click", function(data)
        self:onCardClicked(data.viewportX, data.viewportY, data.button)
    end)

    UIEvents.on("input:dragStart", function(data)
        self:onInputDragStart(data.viewportX, data.viewportY)
    end)

    UIEvents.on("input:drag", function(data)
        self:onInputDrag(data.viewportX, data.viewportY)
    end)

    UIEvents.on("input:dragEnd", function(data)
        self:onInputDragEnd(data.viewportX, data.viewportY)
    end)
end

--- NEW: Input drag start handler
function GameScene:onInputDragStart(x, y)
    if self.state ~= "PLAY" or not self.useNewCardSystem then return end

    for i, vm in ipairs(self.cardViewModels) do
        if vm:hitTest(x, y) then
            print("[GameScene] Input drag start on card: " .. i)
            vm:handleInput("dragStart", x, y)
            self.draggingCardIndex = i
            break
        end
    end
end

--- NEW: Input drag handler
function GameScene:onInputDrag(x, y)
    if not self.draggingCardIndex or not self.cardViewModels[self.draggingCardIndex] then return end
    local vm = self.cardViewModels[self.draggingCardIndex]
    vm:handleInput("drag", x, y)
end

--- NEW: Input drag end handler
function GameScene:onInputDragEnd(x, y)
    if not self.draggingCardIndex or not self.cardViewModels[self.draggingCardIndex] then return end
    local vm = self.cardViewModels[self.draggingCardIndex]
    vm:handleInput("dragEnd", x, y)
    self.draggingCardIndex = nil
end

--- NEW: Card clicked handler
function GameScene:onCardClicked(x, y, button)
    if self.state ~= "PLAY" or not self.useNewCardSystem then return end
    if button ~= "left" then return end

    for i, vm in ipairs(self.cardViewModels) do
        if vm:hitTest(x, y) then
            print("[GameScene] Card clicked: " .. i)
            vm:handleInput("click", x, y)
            break
        end
    end
end

--- NEW: Card selection handler
function GameScene:onCardSelected(cardIndex)
    print("[GameScene] Card selected: " .. cardIndex)
    -- Spawn sparkles effect
    if self.cardViewModels[cardIndex] then
        local vm = self.cardViewModels[cardIndex]
        local x, y = vm:getRenderPosition()
        EffectManager:spawnSparkles(x + 50, y + 70, 5)
    end
end

--- NEW: Card deselection handler
function GameScene:onCardDeselected(cardIndex)
    print("[GameScene] Card deselected: " .. cardIndex)
end

--- NEW: Card drag start handler
function GameScene:onCardDragStart(cardIndex, startX, startY)
    print("[GameScene] Drag start: " .. cardIndex)
    self.draggingCardIndex = cardIndex
end

--- NEW: Card drag end handler (drop logic)
function GameScene:onCardDragEnd(cardIndex, x, y)
    print("[GameScene] Drag end: " .. cardIndex .. " at " .. x .. ", " .. y)

    -- Check if dropped in crib zone
    if x > 980 and x < 1220 and y > 480 and y < 640 and #CampaignState.crib < 2 then
        -- Add card to crib
        local card = self.hand[cardIndex]
        if card then
            table.remove(self.hand, cardIndex)
            table.insert(CampaignState.crib, card)

            -- Deal replacement card from deck
            if self.deckList and #self.deckList > 0 then
                local newCard = table.remove(self.deckList)
                if newCard then
                    table.insert(self.hand, newCard)
                    print("[GameScene] Dealt replacement card")
                end
            end

            -- Rebuild views
            self:rebuildHandViews()
            self:rebuildCribViews()

            print("[GameScene] Card added to crib")
        end
    else
        -- Snap back or Reorder
        print("[GameScene] Card released in hand area or snapped back")

        -- Calculate hand area bounds
        local startX, handY, spacing = GameSceneLayout.getCenteredHandPosition(#self.hand)

        -- If dropped near the hand Y axis
        if y > handY - 100 and y < handY + 250 then
            -- Calculate which slot it's closest to
            local relativeX = x - startX
            local newIndex = math.floor((relativeX + spacing / 2) / spacing) + 1
            newIndex = math.max(1, math.min(#self.hand, newIndex))

            if newIndex ~= cardIndex then
                print("[GameScene] Reordering card from " .. cardIndex .. " to " .. newIndex)
                local card = table.remove(self.hand, cardIndex)
                table.insert(self.hand, newIndex, card)

                -- Rebuild views to reflect new order
                self:rebuildHandViews()
            else
                if self.cardViewModels[cardIndex] then
                    self:repositionCards()
                end
            end
        else
            -- Snap back to original position
            if self.cardViewModels[cardIndex] then
                self:repositionCards()
            end
        end
    end

    self.draggingCardIndex = nil
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

    -- Convert to screen space
    local sx, sy = CoordinateSystem.viewportToScreen(buttonLayout.x, buttonLayout.y)
    local sw = CoordinateSystem.scaleSize(buttonLayout.width)
    local sh = CoordinateSystem.scaleSize(buttonLayout.height)

    self.addToCribButton.x = sx
    self.addToCribButton.y = sy
    self.addToCribButton.width = sw
    self.addToCribButton.height = sh
end

function GameScene:addSelectedCardsToCrib()
    -- Add selected cards to crib (max 2, cannot replace)
    if #CampaignState.crib >= 2 then
        log.warn("Crib is full (max 2 cards)")
        return
    end

    -- Find selected cards
    local selectedCards = {}
    if self.useNewCardSystem then
        for i, vm in ipairs(self.cardViewModels) do
            if vm.isSelected then
                table.insert(selectedCards, { card = vm.card, index = i })
            end
        end
    else
        for i, view in ipairs(self.cardViews) do
            if view.selected then
                table.insert(selectedCards, { card = view.card, index = i })
            end
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
        table.insert(CampaignState.crib, cardInfo.card)
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

    -- NEW: Create visual cards using CardViewModel
    if self.useNewCardSystem then
        self.cardViewModels = {}

        -- Position hand cards using relative layout
        local startX, startY, spacing = GameSceneLayout.getCenteredHandPosition(#self.hand)
        print(string.format("[NEW] Hand cards: startX=%.0f, startY=%.0f, spacing=%.0f, count=%d",
            startX, startY, spacing, #self.hand))

        for i, card in ipairs(self.hand) do
            local x = startX + (i - 1) * spacing
            local vm = CardViewModel(card, x, startY, i)
            table.insert(self.cardViewModels, vm)
        end

        -- Create cut card view model
        local cutX, cutY = GameSceneLayout.getPosition("cutCard")
        print(string.format("[NEW] Cut card: x=%.0f, y=%.0f", cutX, cutY))
        self.cutCardViewModel = CardViewModel(self.cutCard, cutX, cutY, 0)
    else
        -- OLD: Legacy CardView system (backward compatibility)
        self.cardViews = {}

        local startX, startY, spacing = GameSceneLayout.getCenteredHandPosition(#self.hand)
        for i, card in ipairs(self.hand) do
            local x = startX + (i - 1) * spacing
            local view = CardView(card, x, startY, self.cardAtlas, self.smallFont)
            table.insert(self.cardViews, view)
        end

        local cutX, cutY = GameSceneLayout.getPosition("cutCard")
        self.cutCardView = CardView(self.cutCard, cutX, cutY, self.cardAtlas, self.smallFont)
    end

    -- Rebuild crib views from CampaignState (don't reset crib - it persists!)
    self:rebuildCribViews()

    self.state = "PLAY"
    print("Hand dealt: " .. #self.hand .. " cards")
end

function GameScene:rebuildCribViews()
    self.cribViews = {}
    local CardView = require("visuals/CardView")

    -- Position crib cards using layout system
    for i, card in ipairs(CampaignState.crib) do
        local x, y = GameSceneLayout.getPosition("crib", { slotIndex = i })
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

    -- NEW: Process input via InputHandler
    if self.inputHandler then
        self.inputHandler:update(dt)
    end

    -- Check for window resize to update viewport scaling and UI Layout
    local winW, winH = graphics.getWindowSize()
    if winW ~= self.lastWinW or winH ~= self.lastWinH then
        print("DEBUG GameScene: Resize detected " .. winW .. "x" .. winH)
        self.lastWinW = winW
        self.lastWinH = winH

        -- NEW: Update CoordinateSystem
        CoordinateSystem.updateScreenSize(winW, winH)

        -- Recalculate UI scale factor
        self.uiScale = CoordinateSystem.getScale()
        print(string.format("GameScene UI Scale updated: %.2f", self.uiScale))

        -- Re-apply viewport to force zoom recalculation in C++
        if self.camera and self.camera.viewportWidth and self.camera.viewportHeight then
            graphics.setViewport(self.camera.viewportWidth, self.camera.viewportHeight)
            print("Camera: Window resized to " .. winW .. "x" .. winH .. ". Re-applying viewport.")
        end

        -- Update UI Layout (old system)
        if self.uiLayout then
            print("DEBUG GameScene: Updating UILayout size")
            self.uiLayout:updateScreenSize(winW, winH)
        end

        -- NEW: Update LayoutManager
        if self.layoutManager then
            self.layoutManager:setSize(self.referenceWidth, self.referenceHeight)
        end

        -- Update "Add to Crib" button position
        self:updateAddToCribButtonPosition()

        -- NEW: Reposition cards
        if self.useNewCardSystem then
            self:repositionCards()
        end
    end

    -- NEW: Update CardViewModels (animation)
    if self.useNewCardSystem and self.state == "PLAY" then
        -- Get viewport mouse position from InputHandler
        local viewportX, viewportY = 0, 0
        if self.inputHandler then
            viewportX, viewportY = self.inputHandler:getMousePosition()
        end

        for i, vm in ipairs(self.cardViewModels) do
            vm:update(dt)

            -- Handle hover
            vm:handleInput("hover", viewportX, viewportY)
        end

        -- Handle dragging
        if self.draggingCardIndex and self.cardViewModels[self.draggingCardIndex] then
            local vm = self.cardViewModels[self.draggingCardIndex]
            if vm.isDragging then
                vm:handleInput("drag", viewportX, viewportY)
            end
        end

        -- Update cut card
        if self.cutCardViewModel then
            self.cutCardViewModel:update(dt)
        end
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
        -- NEW: Use new input system or fallback to old
        if self.useNewCardSystem then
            -- NEW SYSTEM: Input handled via UIEvents and InputHandler
            -- Update Score Preview
            -- Calculate effective cards for preview
            local effectiveCards = {}
            for i, vm in ipairs(self.cardViewModels) do
                if vm.isSelected then table.insert(effectiveCards, self.hand[i]) end
            end

            local warpEffects = EnhancementManager:resolveWarps()
            local hasPhantom = false
            local hasInfinity = false
            if warpEffects.active_warps then
                for _, w in ipairs(warpEffects.active_warps) do
                    if w == "warp_phantom" then
                        hasPhantom = true
                    elseif w == "warp_infinity" then
                        hasInfinity = true
                    end
                end
            end

            if hasPhantom and self.discardedThisTurn then
                for _, c in ipairs(self.discardedThisTurn) do table.insert(effectiveCards, c) end
            end

            -- Preview condition
            local canPreview = false
            if hasInfinity then
                canPreview = (#effectiveCards >= 1)
            else
                canPreview = (#effectiveCards == 4)
            end

            if canPreview and self.cutCard then
                self.scorePreviewData = ScorePreview.calculate(effectiveCards, self.cutCard)
            else
                self.scorePreviewData = nil
            end
        else
            -- OLD SYSTEM: Legacy input handling
            local effectiveCards = {}
            for i, view in ipairs(self.cardViews) do
                if view.selected then table.insert(effectiveCards, self.hand[i]) end
            end

            -- Simple fallback for legacy: just check 4 cards
            if #effectiveCards == 4 and self.cutCard then
                self.scorePreviewData = ScorePreview.calculate(effectiveCards, self.cutCard)
            else
                self.scorePreviewData = nil
            end
        end

        -- OLD: Handle Dragging State (legacy system)
        if not self.useNewCardSystem and self.draggingView then
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

        -- OLD: Update Targets & Logic (legacy system only)
        if not self.useNewCardSystem then
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
        end

        -- Play Button Logic (handled by UIEvents in new system, kept for compatibility)
        if not self.useNewCardSystem then
            if input.isPressed("return") then
                self:playHand()
            end

            -- Discard Button Logic
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

    -- NEW: Get selected cards from CardViewModels or old CardViews
    if self.useNewCardSystem then
        for i, vm in ipairs(self.cardViewModels) do
            if vm.isSelected then
                table.insert(selectedCards, self.hand[i])
            end
        end
    else
        for i, view in ipairs(self.cardViews) do
            if view.selected then
                table.insert(selectedCards, self.hand[i])
            end
        end
    end

    -- Check for Selection
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

    -- WARP: Phantom - Track discarded cards for scoring
    if hasPhantom and self.discardedThisTurn and #self.discardedThisTurn > 0 then
        print("👻 Warp Phantom: Adding discarded cards to score!")
        for _, card in ipairs(self.discardedThisTurn) do
            table.insert(selectedCards, card)
        end
    end

    -- 1. Main Hand Scoring
    local scoreResult = ScoringUtils.calculateScore(selectedCards, self.cutCard)
    local finalScore = scoreResult.total
    local mainHandResult = scoreResult.handResult
    local mainScoreBase = scoreResult.breakdown.baseChips

    -- Side Effects
    if scoreResult.warpEffects.score_to_gold_pct > 0 then
        local goldGain = math.floor(finalScore * scoreResult.warpEffects.score_to_gold_pct)
        if goldGain > 0 then
            Economy:addGold(goldGain)
            print("Warp Greed: Converted " .. goldGain .. "g from score")
        end
    end

    if scoreResult.warpEffects.hand_cost > 0 then
        if Economy:spend(scoreResult.warpEffects.hand_cost) then
            print("Warp Fortune: Paid " .. scoreResult.warpEffects.hand_cost .. "g for hand")
        else
            print("WARN: Not enough gold for Warp Fortune!")
        end
    end

    if scoreResult.imprintEffects.gold > 0 then
        Economy:addGold(scoreResult.imprintEffects.gold)
        print("Earned " .. scoreResult.imprintEffects.gold .. "g from Imprints")
    end

    -- 2. Crib Scoring (Last hand of blind only)
    local cribScore = 0
    if CampaignState:isLastHand() and #CampaignState.crib == 2 then
        local cribCards = {}
        for _, c in ipairs(CampaignState.crib) do table.insert(cribCards, c) end

        local availableCards = {}
        for _, card in ipairs(self.deckList) do table.insert(availableCards, card) end

        for i = 1, 2 do
            if #availableCards > 0 then
                local randomIndex = math.random(1, #availableCards)
                table.insert(cribCards, table.remove(availableCards, randomIndex))
            end
        end

        local cribResult = ScoringUtils.calculateScore(cribCards, self.cutCard)
        cribScore = cribResult.total
        finalScore = finalScore + cribScore

        print("--- CRIB SCORE BREAKDOWN ---")
        print("Crib Total: " .. cribScore)
        print("-----------------------------")

        if cribResult.imprintEffects.gold > 0 then
            Economy:addGold(cribResult.imprintEffects.gold)
            print("Earned " .. cribResult.imprintEffects.gold .. "g from Crib Imprints")
        end
    end

    -- 3. Visuals and Events
    print(string.format("Scored: %d (Chips: %d, Mult: %.2f)", finalScore, scoreResult.chips, scoreResult.mult))
    EffectManager:spawnChips(640, 360, 20)
    if finalScore > 50 then EffectManager:shake(5, 0.5) end

    events.emit("hand_scored", {
        score = finalScore,
        handTotal = self:calculateHandTotal(selectedCards),
        categoriesScored = {
            fifteens = mainScoreBase > 0 and mainHandResult.fifteens and #mainHandResult.fifteens or 0,
            pairs = mainScoreBase > 0 and mainHandResult.pairs and #mainHandResult.pairs or 0,
            runs = mainScoreBase > 0 and mainHandResult.runs and #mainHandResult.runs or 0,
            flushes = mainScoreBase > 0 and mainHandResult.flushCount or 0,
            nobs = mainScoreBase > 0 and mainHandResult.hasNobs and 1 or 0
        }
    })

    -- Time Warp: score crib before hand
    local hasTimeWarp = false
    if scoreResult.warpEffects.active_warps then
        for _, w in ipairs(scoreResult.warpEffects.active_warps) do
            if w == "warp_time" then
                hasTimeWarp = true; break
            end
        end
    end
    if hasTimeWarp and cribScore > 0 then
        CampaignState.currentScore = CampaignState.currentScore + cribScore
    end

    -- 4. Result Processing
    local result, reward = CampaignState:playHand(finalScore)

    if result == "win" then
        print("Blind Cleared!")
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
    else
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
    if self.useNewCardSystem then
        self:repositionCards()
    else
        self:rebuildHandViews()
    end
    -- AudioManager:playDeal()
end

--- NEW: Reposition cards (for sorting, resize, etc.)
function GameScene:repositionCards()
    if not self.useNewCardSystem then return end

    local numCards = #self.hand
    local startX, handY, spacing = GameSceneLayout.getCenteredHandPosition(numCards)

    for i, vm in ipairs(self.cardViewModels) do
        local targetX = startX + (i - 1) * spacing
        vm:setTargetPosition(targetX, handY)
        -- Update the VM's internal index to keep track of its position in the hand
        vm.index = i
    end
end

function GameScene:rebuildHandViews()
    if self.useNewCardSystem then
        self.cardViewModels = {}
        local numCards = #self.hand
        local startX, startY, spacing = GameSceneLayout.getCenteredHandPosition(numCards)

        for i, card in ipairs(self.hand) do
            local x = startX + (i - 1) * spacing
            local vm = CardViewModel(card, x, startY, i)
            table.insert(self.cardViewModels, vm)
        end
    else
        self.cardViews = {}
        local numCards = #self.hand
        local startX, startY, spacing = GameSceneLayout.getCenteredHandPosition(numCards)
        local CardView = require("visuals/CardView")

        for i, card in ipairs(self.hand) do
            local view = CardView(card, startX + (i - 1) * spacing, startY, self.cardAtlas, self.smallFont)
            table.insert(self.cardViews, view)
        end
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
        local indicesToRemove = {}

        -- NEW: Get selected cards from CardViewModels or old CardViews
        if self.useNewCardSystem then
            for i, vm in ipairs(self.cardViewModels) do
                if vm.isSelected then
                    table.insert(indicesToRemove, i)
                end
            end
        else
            for i, view in ipairs(self.cardViews) do
                if view.selected then
                    table.insert(indicesToRemove, i)
                end
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
        if self.useNewCardSystem then
            -- NEW: Rebuild CardViewModels
            self.cardViewModels = {}
            local startX, startY, spacing = GameSceneLayout.getCenteredHandPosition(#self.hand)

            for i, card in ipairs(self.hand) do
                local x = startX + (i - 1) * spacing
                local vm = CardViewModel(card, x, startY, i)
                table.insert(self.cardViewModels, vm)
            end
        else
            -- OLD: Legacy CardView system
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

    -- Draw Background
    local winW, winH = graphics.getWindowSize()
    graphics.drawRect(0, 0, winW, winH, { r = 0.1, g = 0.3, b = 0.2, a = 1.0 }, false)

    -- Crib Placeholder UI
    local cribX, cribY = CoordinateSystem.viewportToScreen(1000, 450)
    graphics.print(self.font, "CRIB", cribX, cribY, { r = 1, g = 1, b = 1, a = 0.5 })

    local slot1X, slot1Y = CoordinateSystem.viewportToScreen(980, 480)
    local slot2X, slot2Y = CoordinateSystem.viewportToScreen(1100, 480)
    local slotW, slotH = CoordinateSystem.scaleSize(110), CoordinateSystem.scaleSize(150)

    graphics.drawRect(slot1X, slot1Y, slotW, slotH, { r = 0, g = 0, b = 0, a = 0.3 }, true)
    graphics.drawRect(slot2X, slot2Y, slotW, slotH, { r = 0, g = 0, b = 0, a = 0.3 }, true)

    if self.hud then
        -- Draw HUD
        self.hud:draw(CampaignState)

        -- Phase 3: Draw keyboard shortcuts helper text
        if self.state == "PLAY" then
            local shortcutX, shortcutY = GameSceneLayout.getPosition("shortcuts")
            local sx, sy = CoordinateSystem.viewportToScreen(shortcutX, shortcutY)
            graphics.print(self.smallFont, "[C] Collection  [TAB] Stats  [Z] Undo", sx, sy,
                { r = 0.7, g = 0.7, b = 0.7, a = 0.8 })
        end

        -- NEW: Draw cards using new system
        if self.useNewCardSystem then
            -- Draw cut card
            if self.cutCardViewModel then
                CardViewRefactored.draw(self.cutCardViewModel, self.cardAtlas, self.smallFont)
            end

            -- Draw hand cards
            for _, vm in ipairs(self.cardViewModels) do
                CardViewRefactored.draw(vm, self.cardAtlas, self.smallFont)
            end

            -- Draw crib cards (still using old system for now)
            for _, view in ipairs(self.cribViews) do
                view:draw()
            end
        else
            -- OLD: Legacy rendering
            if self.cutCardView then
                self.cutCardView:draw()
            end

            for _, view in ipairs(self.cardViews) do
                view:draw()
            end
            for _, view in ipairs(self.cribViews) do
                view:draw()
            end
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
            local px, py = CoordinateSystem.viewportToScreen(850, 300)
            ScorePreview.draw(px, py, self.scorePreviewData, self.font, self.smallFont)
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
