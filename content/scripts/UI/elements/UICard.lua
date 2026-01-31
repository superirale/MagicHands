-- UICard.lua
local UIElement = require("UI.elements.UIElement")
local Theme = require("UI.Theme")
local UICard = class(UIElement)

function UICard:init(layout_name, jokerData, font, onClick)
    UIElement.init(self, layout_name)
    self.jokerData = jokerData
    self.font = font
    self.onClick = onClick
    self.isHoveredState = false
    
    -- Load sizes from theme
    self.width = Theme.get("sizes.cardWidth")
    self.height = Theme.get("sizes.cardHeight")

    -- Load colors from theme
    self.colors = {
        bg = Theme.get("colors.panelBg"),
        hoverBg = Theme.get("colors.panelBgHover"),
        text = Theme.get("colors.text"),
        desc = Theme.get("colors.textMuted"),
        priceBg = Theme.get("colors.overlayLight"),
        buyText = Theme.get("colors.success"),
        shadow = Theme.get("colors.shadow")
    }

    -- Get rarity colors from theme
    self.rarityColors = {
        common = Theme.get("colors.rarityCommon"),
        uncommon = Theme.get("colors.rarityUncommon"),
        rare = Theme.get("colors.rarityRare"),
        legendary = Theme.get("colors.rarityLegendary"),
        enhancement = Theme.get("colors.rarityEnhancement"),
        default = Theme.get("colors.secondary")
    }
    
    -- Load padding configuration from theme
    self.padding = {
        top = Theme.get("sizes.cardPadding") * 2,
        left = Theme.get("sizes.cardPadding"),
        right = Theme.get("sizes.cardPadding"),
        bottom = Theme.get("sizes.cardPadding"),
        lineSpacing = Theme.get("sizes.cardLineSpacing")
    }
    
    -- Cache header and footer heights from theme
    self.headerHeight = Theme.get("sizes.cardHeaderHeight")
    self.footerHeight = Theme.get("sizes.cardFooterHeight")
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
    local contentHeight = self.height - self.headerHeight - self.footerHeight - self.padding.top - self.padding.bottom
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
        local borderWidth = Theme.get("sizes.borderWidth")
        graphics.drawRect(self.x - borderWidth, self.y - borderWidth, 
                         self.width + borderWidth * 2, self.height + borderWidth * 2, 
                         rarityColor, true)
    end

    -- Main Body
    graphics.drawRect(self.x, self.y, self.width, self.height, bgColor, true)

    -- Header (Rarity)
    graphics.drawRect(self.x, self.y, self.width, self.headerHeight, rarityColor, true)
    
    -- Title (Properly Centered)
    if self.font then
        local textW, textH, baselineOffset = graphics.getTextSize(self.font, self.jokerData.name)
        local tx = self.x + (self.width - textW) / 2
        -- Center the text vertically: position the baseline so the visual center of text is in center of header
        local ty = self.y + (self.headerHeight - textH) / 2 + baselineOffset

        -- Shadow for depth
        graphics.print(self.font, self.jokerData.name, tx + 1, ty + 1, self.colors.shadow)
        graphics.print(self.font, self.jokerData.name, tx, ty, self.colors.text)
    end

    -- Description (Wrapped with padding)
    local descY = self.y + self.headerHeight + self.padding.top
    local descX = self.x + self.padding.left
    local availableWidth = self.width - self.padding.left - self.padding.right
    
    local descLines = self:wrapText(self.jokerData.desc, availableWidth, self.font)
    for i, line in ipairs(descLines) do
        graphics.print(self.font, line, descX, descY + (i - 1) * self.padding.lineSpacing, self.colors.desc)
    end

    -- Footer / Price
    local priceY = self.y + self.height - self.footerHeight
    graphics.drawRect(self.x, priceY, self.width, self.footerHeight, self.colors.priceBg, true)

    -- Determine price color based on affordability
    local priceColor = Theme.get("colors.gold")
    if Economy and Economy.gold < self.jokerData.price then
        priceColor = Theme.get("colors.danger")
    end

    -- Price text (left side, vertically centered)
    local priceText = self.jokerData.price .. "g"
    local priceW, priceTextH, priceBaselineOffset = graphics.getTextSize(self.font, priceText)
    local priceTX = self.x + Theme.get("sizes.padding") + 5
    local priceTY = priceY + (self.footerHeight - priceTextH) / 2 + priceBaselineOffset
    graphics.print(self.font, priceText, priceTX, priceTY, priceColor)

    -- BUY Text on Hover (right side, vertically centered)
    if self.isHoveredState then
        local buyText = "BUY"
        local buyW, buyTextH, buyBaselineOffset = graphics.getTextSize(self.font, buyText)
        local buyTX = self.x + self.width - buyW - Theme.get("sizes.padding") - 5
        local buyTY = priceY + (self.footerHeight - buyTextH) / 2 + buyBaselineOffset
        graphics.print(self.font, buyText, buyTX, buyTY, self.colors.buyText)
    end
end

return UICard
