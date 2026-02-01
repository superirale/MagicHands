-- GameSceneRefactorExample.lua
-- Example showing how to integrate the new UI architecture into GameScene
-- This is a REFERENCE IMPLEMENTATION showing the pattern, not a complete replacement

local CoordinateSystem = require("UI/CoordinateSystem")
local UIEvents = require("UI/UIEvents")
local UILayer = require("UI/UILayer")
local LayoutManager = require("UI/LayoutManager")
local InputHandler = require("UI/InputHandler")
local CardViewModel = require("visuals/CardViewModel")
local CardViewRefactored = require("visuals/CardViewRefactored")

local GameSceneRefactorExample = class()

function GameSceneRefactorExample:init()
    print("[GameSceneRefactorExample] Initializing with new architecture...")
    
    -- Initialize core systems
    local screenW, screenH = graphics.getWindowSize()
    CoordinateSystem.init(screenW, screenH)
    
    -- Setup rendering pipeline
    self.renderPipeline = UILayer.createStandardPipeline()
    
    -- Setup layout system
    self.layout = LayoutManager.Container(
        CoordinateSystem.VIEWPORT_WIDTH,
        CoordinateSystem.VIEWPORT_HEIGHT
    )
    
    -- Setup input handler
    self.inputHandler = InputHandler()
    
    -- Load assets
    self.cardAtlas = graphics.loadTexture("content/images/cards_sheet.png")
    self.font = graphics.loadFont("content/fonts/font.ttf", 24)
    self.smallFont = graphics.loadFont("content/fonts/font.ttf", 16)
    
    -- Initialize viewport
    graphics.setViewport(1280, 720)
    
    -- Game state
    self.hand = {}
    self.cardViewModels = {}
    
    -- Subscribe to UI events
    self:setupEventListeners()
    
    -- Setup initial layout
    self:setupLayout()
    
    -- Deal initial hand (example)
    self:dealHand()
    
    print("[GameSceneRefactorExample] Initialization complete!")
end

--- Setup UI event listeners
function GameSceneRefactorExample:setupEventListeners()
    -- Card selection
    UIEvents.on("card:selected", function(data)
        print("Card selected:", data.cardIndex)
        self:onCardSelected(data.cardIndex)
    end)
    
    UIEvents.on("card:deselected", function(data)
        print("Card deselected:", data.cardIndex)
        self:onCardDeselected(data.cardIndex)
    end)
    
    -- Card dragging
    UIEvents.on("card:dragStart", function(data)
        print("Drag start:", data.cardIndex)
        self:onDragStart(data.cardIndex)
    end)
    
    UIEvents.on("card:dragEnd", function(data)
        print("Drag end:", data.cardIndex, "at", data.x, data.y)
        self:onDragEnd(data.cardIndex, data.x, data.y)
    end)
    
    -- Input events
    UIEvents.on("input:confirm", function()
        self:playHand()
    end)
    
    UIEvents.on("input:discard", function()
        self:discardSelected()
    end)
    
    UIEvents.on("input:sortByRank", function()
        self:sortHand("rank")
    end)
    
    UIEvents.on("input:sortBySuit", function()
        self:sortHand("suit")
    end)
    
    -- Window resize
    UIEvents.on("ui:resize", function(data)
        self:onResize(data.screenWidth, data.screenHeight)
    end)
end

--- Setup initial layout for all UI elements
function GameSceneRefactorExample:setupLayout()
    -- Hand cards (centered at bottom)
    -- Will be updated when cards are dealt
    
    -- Cut card (top center)
    self.layout:add("cutCard", {
        anchor = LayoutManager.Anchor.Top,
        x = -50,  -- -50 from center to center the card
        y = 200,
        width = 100,
        height = 140,
        zIndex = 5
    })
    
    -- Crib slot 1 (right side)
    self.layout:add("crib1", {
        anchor = LayoutManager.Anchor.Right,
        x = -240,  -- 240px from right edge
        y = 300,
        width = 100,
        height = 140,
        zIndex = 5
    })
    
    -- Crib slot 2 (right side)
    self.layout:add("crib2", {
        anchor = LayoutManager.Anchor.Right,
        x = -120,  -- 120px from right edge
        y = 300,
        width = 100,
        height = 140,
        zIndex = 5
    })
    
    -- HUD elements (left side)
    self.layout:add("score", {
        anchor = LayoutManager.Anchor.TopLeft,
        x = 20,
        y = 20,
        width = 200,
        height = 100,
        zIndex = 10
    })
    
    -- Shortcuts (bottom left)
    self.layout:add("shortcuts", {
        anchor = LayoutManager.Anchor.BottomLeft,
        x = 20,
        y = -40,
        width = 400,
        height = 30,
        zIndex = 10
    })
    
    self.layout:layout()  -- Calculate positions
end

--- Deal a hand of cards (example)
function GameSceneRefactorExample:dealHand()
    -- Example: Create 6 cards
    local exampleCards = {
        {rank = "A", suit = "H"},
        {rank = "7", suit = "S"},
        {rank = "K", suit = "D"},
        {rank = "5", suit = "C"},
        {rank = "Q", suit = "H"},
        {rank = "3", suit = "S"}
    }
    
    self.hand = exampleCards
    self.cardViewModels = {}
    
    -- Calculate hand layout (centered at bottom)
    local numCards = #self.hand
    local cardSpacing = 110
    local totalWidth = (numCards - 1) * cardSpacing
    local startX = (1280 / 2) - (totalWidth / 2)
    local startY = 520  -- Bottom of screen
    
    -- Create view models for each card
    for i, card in ipairs(self.hand) do
        local x = startX + (i - 1) * cardSpacing
        local y = startY
        
        local vm = CardViewModel(card, x, y, i)
        table.insert(self.cardViewModels, vm)
        
        -- Add to layout system
        self.layout:add("handCard" .. i, {
            anchor = LayoutManager.Anchor.TopLeft,  -- Absolute positioning
            x = x,
            y = y,
            width = 100,
            height = 140,
            zIndex = i  -- Higher index = drawn on top
        })
    end
    
    self.layout:layout()
    
    print("[GameSceneRefactorExample] Dealt " .. numCards .. " cards")
end

--- Update game logic
function GameSceneRefactorExample:update(dt)
    -- Check for window resize
    local screenW, screenH = graphics.getWindowSize()
    if screenW ~= self.lastScreenW or screenH ~= self.lastScreenH then
        self.lastScreenW = screenW
        self.lastScreenH = screenH
        
        CoordinateSystem.updateScreenSize(screenW, screenH)
        graphics.setViewport(1280, 720)  -- Re-apply viewport
        
        UIEvents.emit("ui:resize", {
            screenWidth = screenW,
            screenHeight = screenH,
            scale = CoordinateSystem.getScale()
        })
    end
    
    -- Process input
    self.inputHandler:update(dt)
    
    -- Get viewport mouse position
    local viewportX, viewportY = self.inputHandler:getMousePosition()
    
    -- Update all card view models
    for i, vm in ipairs(self.cardViewModels) do
        vm:update(dt)
        
        -- Handle hover (check if mouse is over card)
        vm:handleInput("hover", viewportX, viewportY)
    end
    
    -- Handle dragging (only one card can be dragged at a time)
    if self.inputHandler:isDragging() then
        for i, vm in ipairs(self.cardViewModels) do
            if vm.isDragging then
                vm:handleInput("drag", viewportX, viewportY)
                break
            end
        end
    end
end

--- Render everything
function GameSceneRefactorExample:draw()
    -- Get viewport bounds for debug visualization
    local vpX, vpY, vpW, vpH = CoordinateSystem.getViewportBounds()
    
    -- Draw background
    graphics.drawRect(0, 0, 1280, 720, {r=0.1, g=0.3, b=0.2, a=1.0}, true)
    
    -- Draw hand cards using refactored view
    for i, vm in ipairs(self.cardViewModels) do
        CardViewRefactored.draw(vm, self.cardAtlas, self.smallFont)
    end
    
    -- Draw HUD elements
    self:drawHUD()
    
    -- DEBUG: Draw coordinate system visualization
    if input.isPressed("f1") then
        CoordinateSystem.debugDraw()
        self.layout:debugDraw()
    end
end

--- Draw HUD elements
function GameSceneRefactorExample:drawHUD()
    -- Score (example)
    local scoreX, scoreY = self.layout:get("score")
    graphics.print(self.font, "Score: 0", scoreX, scoreY, {r=1, g=1, b=1, a=1})
    
    -- Shortcuts
    local shortcutX, shortcutY = self.layout:get("shortcuts")
    graphics.print(self.smallFont, "[Enter] Play  [Backspace] Discard  [1] Sort Rank  [2] Sort Suit",
        shortcutX, shortcutY, {r=0.7, g=0.7, b=0.7, a=0.8})
end

--- Event handlers

function GameSceneRefactorExample:onCardSelected(cardIndex)
    -- Game logic: Track selected cards for scoring
    -- Visual feedback is handled automatically by ViewModel
end

function GameSceneRefactorExample:onCardDeselected(cardIndex)
    -- Game logic: Remove from selected list
end

function GameSceneRefactorExample:onDragStart(cardIndex)
    -- Game logic: Prepare for drop (e.g., show drop zones)
end

function GameSceneRefactorExample:onDragEnd(cardIndex, x, y)
    -- Game logic: Check if dropped in valid zone (crib, etc.)
    local crib1X, crib1Y, crib1W, crib1H = self.layout:get("crib1")
    
    -- Simple hit test
    if x >= crib1X and x <= crib1X + crib1W and
       y >= crib1Y and y <= crib1Y + crib1H then
        print("Dropped in crib slot 1!")
        -- Add card to crib logic here
    else
        -- Snap back to hand
        print("Snap back to hand")
    end
end

function GameSceneRefactorExample:onResize(screenWidth, screenHeight)
    -- Update layout on resize
    self.layout:setSize(1280, 720)  -- Viewport size stays same
    print("Resized to " .. screenWidth .. "x" .. screenHeight)
end

function GameSceneRefactorExample:playHand()
    -- Get selected cards
    local selectedIndices = {}
    for i, vm in ipairs(self.cardViewModels) do
        if vm.isSelected then
            table.insert(selectedIndices, i)
        end
    end
    
    if #selectedIndices ~= 4 then
        print("Must select exactly 4 cards")
        return
    end
    
    print("Playing hand with " .. #selectedIndices .. " cards")
    -- Score calculation logic here
end

function GameSceneRefactorExample:discardSelected()
    print("Discard selected cards")
    -- Discard logic here
end

function GameSceneRefactorExample:sortHand(criteria)
    print("Sorting hand by " .. criteria)
    
    local function compareCards(a, b)
        local aRank = CardViewRefactored.getRankValue(a.rank)
        local bRank = CardViewRefactored.getRankValue(b.rank)
        local aSuit = CardViewRefactored.getSuitValue(a.suit)
        local bSuit = CardViewRefactored.getSuitValue(b.suit)
        
        if criteria == "rank" then
            if aRank ~= bRank then return aRank < bRank end
            return aSuit < bSuit
        else  -- suit
            if aSuit ~= bSuit then return aSuit < bSuit end
            return aRank < bRank
        end
    end
    
    table.sort(self.hand, compareCards)
    
    -- Update view models with new positions
    self:repositionCards()
end

function GameSceneRefactorExample:repositionCards()
    local numCards = #self.hand
    local cardSpacing = 110
    local totalWidth = (numCards - 1) * cardSpacing
    local startX = (1280 / 2) - (totalWidth / 2)
    local startY = 520
    
    for i, vm in ipairs(self.cardViewModels) do
        local x = startX + (i - 1) * cardSpacing
        vm:setTargetPosition(x, startY)
    end
end

--- Cleanup
function GameSceneRefactorExample:destroy()
    UIEvents.clear()  -- Clear all event listeners
    print("[GameSceneRefactorExample] Cleaned up")
end

return GameSceneRefactorExample
