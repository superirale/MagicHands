-- DeckView.lua
-- UI Component for viewing and interacting with the deck

local Theme = require("UI.Theme")
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
    self.selectedIndex = 1    -- For controller navigation
    
    -- Cache theme colors
    self.colors = {
        overlay = Theme.get("colors.overlay"),
        text = Theme.get("colors.text"),
        textMuted = Theme.get("colors.textMuted"),
        warning = Theme.get("colors.warning")
    }
end

function DeckView:show(deck, mode, onCardSelected, onClose)
    self.visible = true
    self.mode = mode or "VIEW"
    self.onCardSelected = onCardSelected
    self.onClose = onClose
    self.selectedIndex = 1  -- Reset selection
    
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
            view = cardView,
            col = col,
            row = row
        })
    end
end

function DeckView:hide()
    self.visible = false
    self.cards = {}
end

function DeckView:update(dt)
    if not self.visible then return end
    
    -- Handle input via InputManager
    local mx, my = inputmgr.getCursor()
    
    -- Update card views (for animations/hover states)
    for _, item in ipairs(self.cards) do
        item.view:update(dt, mx, my, false)
    end
    
    -- Controller navigation in SELECT mode
    if self.mode == "SELECT" and #self.cards > 0 then
        local cols = 8
        local currentRow = math.floor((self.selectedIndex - 1) / cols)
        local currentCol = (self.selectedIndex - 1) % cols
        
        -- Navigate with D-pad
        if inputmgr.isActionJustPressed("navigate_left") then
            if currentCol > 0 then
                self.selectedIndex = self.selectedIndex - 1
            end
        elseif inputmgr.isActionJustPressed("navigate_right") then
            if currentCol < cols - 1 and self.selectedIndex < #self.cards then
                self.selectedIndex = self.selectedIndex + 1
            end
        elseif inputmgr.isActionJustPressed("navigate_up") then
            if currentRow > 0 then
                self.selectedIndex = math.max(1, self.selectedIndex - cols)
            end
        elseif inputmgr.isActionJustPressed("navigate_down") then
            if currentRow < math.floor((#self.cards - 1) / cols) then
                self.selectedIndex = math.min(#self.cards, self.selectedIndex + cols)
            end
        end
        
        -- Confirm selection with controller
        if inputmgr.isActionJustPressed("confirm") then
            local item = self.cards[self.selectedIndex]
            if item and self.onCardSelected then
                self.onCardSelected(self.selectedIndex, item.cardData)
                return
            end
        end
    end
    
    -- Check for cancel to close
    if inputmgr.isActionJustPressed("cancel") or inputmgr.isActionJustPressed("open_menu") then
        if self.onClose then
            self.onClose()
        end
        return
    end
    
    -- Handle card selection with mouse in SELECT mode
    if self.mode == "SELECT" then
        -- Check for mouse clicks on cards (use old input API for mouse button)
        if input.isMouseButtonPressed("left") then
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
end

function DeckView:draw()
    if not self.visible then return end

    -- Dim background
    graphics.drawRect(0, 0, self.layout.screenWidth, self.layout.screenHeight, self.colors.overlay, true)

    -- Title
    local title = "Deck View"
    if self.mode == "SELECT" then title = "Select a Card" end
    graphics.print(self.font, title, 100, 50, self.colors.text)

    -- Close hint (show controller prompts if gamepad active)
    local hintText
    if inputmgr.isGamepad() then
        if self.mode == "SELECT" then
            hintText = "[B] Cancel   [D-Pad] Navigate   [A] Select"
        else
            hintText = "[B] Close"
        end
    else
        hintText = "Press ESC to close" .. (self.mode == "SELECT" and "   [Click] Select Card" or "")
    end
    graphics.print(self.smallFont, hintText, 100, 90, self.colors.textMuted)

    -- Draw cards
    for i, item in ipairs(self.cards) do
        item.view:draw()

        -- Highlight selected card (controller navigation)
        if self.mode == "SELECT" and i == self.selectedIndex then
            local w = item.view.width or 100
            local h = item.view.height or 140
            -- Draw selection border
            for j = 0, 2 do
                graphics.drawRect(item.view.x - j, item.view.y - j, w + j * 2, h + j * 2, self.colors.warning, false)
            end
        end

        -- Highlight hovered card in SELECT mode (mouse)
        if self.mode == "SELECT" and item.view.hovered then
            local w = item.view.width or 100
            local h = item.view.height or 140
            graphics.drawRect(item.view.x, item.view.y, w, h, Theme.withAlpha(self.colors.warning, 0.3), true)
        end
    end
end

return DeckView
