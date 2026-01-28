-- UILabel.lua
local UIElement = require("UI.elements.UIElement")
local UILabel = class(UIElement)

function UILabel:init(layout_name, text, font, color)
    UIElement.init(self, layout_name)
    self.text = text or ""
    self.font = font
    self.color = color or { r = 1, g = 1, b = 1, a = 1 }
    self.align = "left" -- Horizontal alignment: left, center, right
    self.valign = "middle" -- Vertical alignment: top, middle, bottom
    self.wrap = true -- Enable text wrapping by default
    self.lineSpacing = 18 -- Spacing between wrapped lines
end

function UILabel:setText(text)
    self.text = text
end

function UILabel:setAlign(align)
    -- Valid values: "left", "center", "right"
    self.align = align
end

function UILabel:setVerticalAlign(valign)
    -- Valid values: "top", "middle", "bottom"
    self.valign = valign
end

function UILabel:setWrap(wrap, lineSpacing)
    self.wrap = wrap
    if lineSpacing then
        self.lineSpacing = lineSpacing
    end
end

-- Text wrapping helper using accurate text measurement
function UILabel:wrapText(text, maxWidth)
    if not text or text == "" or not self.font then return { text } end
    if not self.wrap or maxWidth <= 0 then return { text } end
    
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
        local lineWidth = graphics.getTextSize(self.font, testLine)
        
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

function UILabel:draw()
    if not self.visible or not self.font or not self.text or self.text == "" then return end

    -- Wrap text if enabled and width is set
    local lines = self:wrapText(self.text, self.width)
    
    -- Calculate total text height for all lines
    local totalTextHeight = 0
    if #lines > 1 then
        -- Multiple lines: use line spacing
        totalTextHeight = (#lines - 1) * self.lineSpacing
        -- Add height of first line for baseline calculation
        local _, firstLineH, firstLineBaseline = graphics.getTextSize(self.font, lines[1])
        totalTextHeight = totalTextHeight + firstLineH
    else
        -- Single line: use actual text height
        local _, textH = graphics.getTextSize(self.font, lines[1])
        totalTextHeight = textH
    end
    
    -- Calculate starting Y position based on vertical alignment
    local startY = self.y
    if self.height > 0 then
        if self.valign == "middle" then
            -- Center the entire text block vertically
            startY = self.y + (self.height - totalTextHeight) / 2
        elseif self.valign == "top" then
            startY = self.y
        elseif self.valign == "bottom" then
            startY = self.y + self.height - totalTextHeight
        else
            -- Default to middle
            startY = self.y + (self.height - totalTextHeight) / 2
        end
    end
    
    -- Draw each line
    for i, line in ipairs(lines) do
        local lineW, lineH, baselineOffset = graphics.getTextSize(self.font, line)
        
        -- Calculate x position based on alignment
        local x = self.x
        if self.width > 0 then
            if self.align == "center" then
                x = self.x + (self.width - lineW) / 2
            elseif self.align == "right" then
                x = self.x + self.width - lineW
            end
        end
        
        -- Calculate y position for this line
        local y = startY + (i - 1) * self.lineSpacing + baselineOffset
        
        graphics.print(self.font, line, x, y, self.color)
    end
end

return UILabel
