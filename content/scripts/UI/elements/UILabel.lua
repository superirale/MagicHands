-- UILabel.lua
local UIElement = require("UI.elements.UIElement")
local UILabel = class(UIElement)

function UILabel:init(layout_name, text, font, color)
    UIElement.init(self, layout_name)
    self.text = text or ""
    self.font = font
    self.color = color or { r = 1, g = 1, b = 1, a = 1 }
    self.align = "left" -- left, center, right
end

function UILabel:setText(text)
    self.text = text
end

function UILabel:setAlign(align)
    -- Valid values: "left", "center", "right"
    self.align = align
end

function UILabel:draw()
    if not self.visible or not self.font then return end

    local textW, textH, baselineOffset = graphics.getTextSize(self.font, self.text)
    
    -- Calculate x position based on alignment
    local x = self.x
    if self.align == "center" then
        x = self.x + (self.width - textW) / 2
    elseif self.align == "right" then
        x = self.x + self.width - textW
    end
    
    -- Center vertically within the label's height using baseline offset
    local y = self.y + (self.height - textH) / 2 + baselineOffset
    
    graphics.print(self.font, self.text, x, y, self.color)
end

return UILabel
