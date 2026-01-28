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

function UILabel:draw()
    if not self.visible then return end

    local x = self.x
    -- Alignment logic could go here if we had text width
    graphics.print(self.font, self.text, x, self.y, self.color)
end

return UILabel
