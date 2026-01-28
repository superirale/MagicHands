-- UICard.lua
local UIElement = require("UI.elements.UIElement")
local UICard = class(UIElement)

function UICard:init(layout_name, jokerData, font, onClick)
    UIElement.init(self, layout_name)
    self.jokerData = jokerData
    self.font = font
    self.onClick = onClick
    self.isHoveredState = false
    self.width = 220
    self.height = 300

    -- Visual config
    self.colors = {
        bg = { r = 0.15, g = 0.15, b = 0.18, a = 1 },
        hoverBg = { r = 0.2, g = 0.2, b = 0.23, a = 1 },
        text = { r = 1, g = 1, b = 1, a = 1 },
        desc = { r = 0.9, g = 0.9, b = 0.9, a = 1 },
        priceBg = { r = 0, g = 0, b = 0, a = 0.3 },
        buyText = { r = 0.4, g = 1, b = 0.4, a = 1 },
        shadow = { r = 0, g = 0, b = 0, a = 0.5 }
    }

    self.rarityColors = {
        common      = { r = 0.4, g = 0.6, b = 0.8, a = 1 },
        uncommon    = { r = 0.2, g = 0.7, b = 0.4, a = 1 },
        rare        = { r = 0.8, g = 0.3, b = 0.3, a = 1 },
        legendary   = { r = 0.9, g = 0.8, b = 0.2, a = 1 },
        enhancement = { r = 0.5, g = 0.4, b = 0.8, a = 1 },
        default     = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
    }
    
    -- Padding configuration for description section
    self.padding = {
        top = 20,      -- Space from header to description
        left = 10,     -- Left padding for description text
        right = 10,    -- Right padding for description text
        bottom = 10,   -- Space from description to footer
        lineSpacing = 20  -- Space between description lines
    }
end

-- Set padding for description section
function UICard:setPadding(top, left, right, bottom, lineSpacing)
    if top then self.padding.top = top end
    if left then self.padding.left = left end
    if right then self.padding.right = right end
    if bottom then self.padding.bottom = bottom end
    if lineSpacing then self.padding.lineSpacing = lineSpacing end
end

-- Get the available content area for description (accounting for header, footer, and padding)
function UICard:getContentArea()
    local headerHeight = 50
    local footerHeight = 40
    local contentHeight = self.height - headerHeight - footerHeight - self.padding.top - self.padding.bottom
    local contentWidth = self.width - self.padding.left - self.padding.right
    return contentWidth, contentHeight
end

-- Text wrapping helper using accurate text measurement
function UICard:wrapText(text, maxWidth, fontId)
    if not text or text == "" then return {} end
    if not fontId then return { text } end
    
    local lines = {}
    local words = {}

    -- Safe word splitting
    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end

    if #words == 0 then return { text } end

    local currentLine = ""

    for _, word in ipairs(words) do
        local testLine = currentLine == "" and word or (currentLine .. " " .. word)
        local lineWidth = graphics.getTextSize(fontId, testLine) -- Only need width (first return value)
        
        -- If adding word exceeds width, push current line and start new one
        if lineWidth > maxWidth then
            if currentLine ~= "" then
                table.insert(lines, currentLine)
                currentLine = word
            else
                -- Single word is too long, add it anyway to avoid infinite loop
                table.insert(lines, word)
                currentLine = ""
            end
        else
            currentLine = testLine
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    return lines
end

function UICard:update(dt, mx, my, isPressed)
    if not self.visible then return end

    -- Use passed input or fallback to global
    local x, y = mx, my
    local pressed = isPressed

    if not x or not y then
        x, y = input.getMousePosition()
        pressed = input.isPressed("mouse_left")
    end

    self.isHoveredState = self:isHovered(x, y)

    if self.isHoveredState and pressed and not self.wasClicked then
        self.wasClicked = true
        if self.onClick then self.onClick() end
    elseif not pressed then
        self.wasClicked = false
    end
end

function UICard:draw()
    if not self.visible then return end

    local rarityColor = self.rarityColors[self.jokerData.rarity] or self.rarityColors.default
    local bgColor = self.isHoveredState and self.colors.hoverBg or self.colors.bg

    -- Outline on hover
    if self.isHoveredState then
        graphics.drawRect(self.x - 2, self.y - 2, self.width + 4, self.height + 4, rarityColor, true)
    end

    -- Main Body
    graphics.drawRect(self.x, self.y, self.width, self.height, bgColor, true)

    -- Header (Rarity)
    local headerHeight = 50
    graphics.drawRect(self.x, self.y, self.width, headerHeight, rarityColor, true)
    
    -- Title (Properly Centered)
    if self.font then
        local textW, textH, baselineOffset = graphics.getTextSize(self.font, self.jokerData.name)
        local tx = self.x + (self.width - textW) / 2
        -- Center the text vertically: position the baseline so the visual center of text is in center of header
        local ty = self.y + (headerHeight - textH) / 2 + baselineOffset

        -- Shadow for depth
        graphics.print(self.font, self.jokerData.name, tx + 1, ty + 1, self.colors.shadow)
        graphics.print(self.font, self.jokerData.name, tx, ty, self.colors.text)
    end

    -- Description (Wrapped with padding)
    local descY = self.y + headerHeight + self.padding.top
    local descX = self.x + self.padding.left
    local availableWidth = self.width - self.padding.left - self.padding.right
    
    local descLines = self:wrapText(self.jokerData.desc, availableWidth, self.font)
    for i, line in ipairs(descLines) do
        graphics.print(self.font, line, descX, descY + (i - 1) * self.padding.lineSpacing, self.colors.desc)
    end

    -- Footer / Price
    local priceH = 40
    local priceY = self.y + self.height - priceH
    graphics.drawRect(self.x, priceY, self.width, priceH, self.colors.priceBg, true)

    local priceColor = { r = 1, g = 0.8, b = 0.2, a = 1 }

    if Economy and Economy.gold < self.jokerData.price then
        priceColor = { r = 0.8, g = 0.2, b = 0.2, a = 1 }
    end

    graphics.print(self.font, self.jokerData.price .. "g", self.x + 15, priceY + 8, priceColor)

    -- BUY Text on Hover
    if self.isHoveredState then
        graphics.print(self.font, "BUY", self.x + self.width - 60, priceY + 8, self.colors.buyText)
    end
end

return UICard
