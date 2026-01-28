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

function UILabel:draw()
    if not self.visible or not self.font or not self.text or self.text == "" then return end

    local textW, textH, baselineOffset = graphics.getTextSize(self.font, self.text)
    
    -- Calculate x position based on alignment
    local x = self.x
    if self.width > 0 then
        if self.align == "center" then
            x = self.x + (self.width - textW) / 2
        elseif self.align == "right" then
            x = self.x + self.width - textW
        end
    end
    
    -- Calculate y position based on vertical alignment
    local y = self.y
    if self.height > 0 then
        if self.valign == "middle" then
            -- Center vertically within the label's height using baseline offset
            y = self.y + (self.height - textH) / 2 + baselineOffset
        elseif self.valign == "top" then
            -- Align to top with baseline offset
            y = self.y + baselineOffset
        elseif self.valign == "bottom" then
            -- Align to bottom
            y = self.y + self.height - textH + baselineOffset
        else
            -- Default to middle
            y = self.y + (self.height - textH) / 2 + baselineOffset
        end
    else
        -- No height specified, just use baseline offset for proper vertical positioning
        y = self.y + baselineOffset
    end
    
    graphics.print(self.font, self.text, x, y, self.color)
end

return UILabel
