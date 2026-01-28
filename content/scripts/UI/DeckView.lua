-- DeckView.lua
-- UI Component for viewing and interacting with the deck

local CardView = require("visuals/CardView")

local DeckView = class()

function DeckView:init(font, smallFont, cardAtlas, layout)
    self.font = font
    self.smallFont = smallFont
    self.cardAtlas = cardAtlas
    self.layout = layout
    self.visible = false
    self.cards = {}
    self.mode = "VIEW"        -- VIEW, SELECT
    self.onCardSelected = nil -- Callback
    self.onClose = nil        -- Callback
end

function DeckView:show(deck, mode, onCardSelected, onClose)
    self.visible = true
    self.mode = mode or "VIEW"
    self.onCardSelected = onCardSelected
    self.onClose = onClose
    
    -- Create card views for the deck
    self.cards = {}
    local cardWidth = 71
    local cardHeight = 96
    local padding = 20
    local cols = 8  -- Number of cards per row
    local startX = 100
    local startY = 130
    
    for i, cardData in ipairs(deck) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = startX + col * (cardWidth + padding)
        local y = startY + row * (cardHeight + padding)
        
        -- CardView constructor: init(card, x, y, atlas, font)
        local cardView = CardView(cardData, x, y, self.cardAtlas, self.smallFont)
        
        table.insert(self.cards, {
            cardData = cardData,
            view = cardView
        })
    end
end

function DeckView:hide()
    self.visible = false
    self.cards = {}
end

function DeckView:update(dt)
    if not self.visible then return end
    
    -- Handle input
    local mx, my = input.getMousePosition()
    
    -- Update card views (for animations/hover states)
    for _, item in ipairs(self.cards) do
        item.view:update(dt, mx, my, false)
    end
    
    -- Check for ESC or right click to close
    if input.isPressed("escape") or input.isMouseButtonPressed("right") then
        if self.onClose then
            self.onClose()
        end
        return
    end
    
    -- Handle card selection in SELECT mode
    if self.mode == "SELECT" and input.isMouseButtonPressed("left") then
        for i, item in ipairs(self.cards) do
            local w = item.view.width or 100
            local h = item.view.height or 140
            
            if mx >= item.view.x and mx <= item.view.x + w and 
               my >= item.view.y and my <= item.view.y + h then
                if self.onCardSelected then
                    self.onCardSelected(i, item.cardData)
                end
                return
            end
        end
    end
end

function DeckView:draw()
    if not self.visible then return end

    -- Dim background
    graphics.drawRect(0, 0, self.layout.screenWidth, self.layout.screenHeight, { r = 0, g = 0, b = 0, a = 0.8 }, true)

    -- Title
    local title = "Deck View"
    if self.mode == "SELECT" then title = "Select a Card" end
    graphics.print(self.font, title, 100, 50, { r = 1, g = 1, b = 1, a = 1 })

    graphics.print(self.smallFont, "Press ESC or Right Click to close", 100, 90, { r = 1, g = 1, b = 1, a = 1 })

    -- Draw cards
    for _, item in ipairs(self.cards) do
        item.view:draw()

        -- Highlight hovered card in SELECT mode
        if self.mode == "SELECT" and item.view.hovered then
            local w = item.view.width or 100
            local h = item.view.height or 140
            graphics.drawRect(item.view.x, item.view.y, w, h, { r = 1, g = 1, b = 0, a = 0.5 }, true)
        end
    end
end

return DeckView
