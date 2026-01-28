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

-- ...

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

        -- Highlight if mode is select
        if self.mode == "SELECT" then
            local mx, my = input.getMousePosition()
            local w, h = 71, 96
            if item.view.width then w = item.view.width end
            if item.view.height then h = item.view.height end

            if mx >= item.view.x and mx <= item.view.x + w and my >= item.view.y and my <= item.view.y + h then
                graphics.drawRect(item.view.x, item.view.y, w, h, { r = 1, g = 1, b = 0, a = 0.5 }, false)
            end
        end
    end
end

return DeckView
