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
end

-- Text wrapping helper
function UICard:wrapText(text, maxWidth, fontSize)
    if not text or text == "" then return {} end
    local lines = {}
    local words = {}

    -- Safe word splitting
    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end

    if #words == 0 then return { text } end

    -- Estimation: average char width approx 0.6 * fontSize
    local charWidth = fontSize * 0.6

    local currentLine = ""
    local currentLen = 0

    for _, word in ipairs(words) do
        local wordLen = #word * charWidth
        -- If adding word exceeds width, push current line
        if currentLen + wordLen + charWidth > maxWidth then
            table.insert(lines, currentLine)
            currentLine = word
            currentLen = wordLen
        else
            if currentLine == "" then
                currentLine = word
            else
                currentLine = currentLine .. " " .. word
            end
            currentLen = currentLen + wordLen + charWidth -- add space
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
    graphics.drawRect(self.x, self.y, self.width, 50, rarityColor, true)
    print("DEBUG: UICard:draw - Draw Title")
    -- Title
    if self.font then
        local fontSize = 24
        local charW = fontSize * 0.55
        local textW = #self.jokerData.name * charW
        local tx = self.x + (self.width - textW) / 2
        local ty = self.y + (50 - fontSize) / 2

        graphics.print(self.font, self.jokerData.name, tx + 1, ty + 1, self.colors.shadow)
        graphics.print(self.font, self.jokerData.name, tx, ty, self.colors.text)
    end

    -- Description (Wrapped)
    local descY = self.y + 70
    local descLines = self:wrapText(self.jokerData.desc, self.width - 20, 16)
    for i, line in ipairs(descLines) do
        graphics.print(self.font, line, self.x + 10, descY + (i - 1) * 20, self.colors.desc)
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
