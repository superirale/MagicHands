-- UIButton.lua
local UIElement = require("UI.elements.UIElement")
local UIButton = class(UIElement)

function UIButton:init(layout_name, text, font, onClick)
    UIElement.init(self, layout_name)
    self.text = text or "Button"
    self.font = font
    self.onClick = onClick
    self.isHoveredState = false
    self.bgColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
    self.hoverColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    self.textColor = { r = 1, g = 1, b = 1, a = 1 }
end

function UIButton:update(dt, mx, my, isPressed)
    if not self.visible then return end

    -- Use passed input or fallback to global
    local x, y = mx, my
    local pressed = isPressed

    if not x or not y then
        x, y = input.getMousePosition()
        pressed = input.isPressed("mouse_left")
    end

    -- Check Hover
    self.isHoveredState = self:isHovered(x, y)

    -- Check Click ("mouse_left")
    if self.isHoveredState and pressed and not self.wasClicked then
        self.wasClicked = true
        if self.onClick then self.onClick() end
    elseif not pressed then
        self.wasClicked = false
    end
end

function UIButton:draw()
    if not self.visible then return end

    local color = self.isHoveredState and self.hoverColor or self.bgColor

    -- Draw Background
    graphics.drawRect(self.x, self.y, self.width, self.height, color, true)

    -- Draw Border
    graphics.drawRect(self.x, self.y, self.width, self.height, { r = 1, g = 1, b = 1, a = 0.5 }, false)

    -- Draw Text (Centered)
    if self.font then
        graphics.print(self.font, self.text, self.x + 10, self.y + 10, self.textColor)
    end
end

return UIButton
