-- UIButton.lua
local UIElement = require("UI.elements.UIElement")
local Theme = require("UI.Theme")
local UIButton = class(UIElement)

function UIButton:init(layout_name, text, font, onClick, style)
    UIElement.init(self, layout_name)
    self.text = text or "Button"
    self.font = font
    self.onClick = onClick
    self.isHoveredState = false
    self.style = style or "secondary"  -- "primary", "secondary", "danger", "success", "warning", "info"
    self.disabled = false
    
    -- Load colors from theme based on style
    self:updateThemeColors()
end

function UIButton:updateThemeColors()
    local stylePrefix = "colors." .. self.style
    self.bgColor = Theme.get(stylePrefix)
    self.hoverColor = Theme.get(stylePrefix .. "Hover")
    self.activeColor = Theme.get(stylePrefix .. "Active")
    self.textColor = Theme.get("colors.text")
    self.disabledColor = Theme.get("colors.textDisabled")
    
    -- Fallback to secondary if style not found
    if not self.bgColor then
        self.bgColor = Theme.get("colors.secondary")
        self.hoverColor = Theme.get("colors.secondaryHover")
        self.activeColor = Theme.get("colors.secondaryActive")
    end
end

function UIButton:setStyle(style)
    self.style = style
    self:updateThemeColors()
end

function UIButton:setDisabled(disabled)
    self.disabled = disabled
end

function UIButton:update(dt, mx, my, isPressed)
    if not self.visible or self.disabled then return end

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

    -- Determine color based on state
    local color
    if self.disabled then
        color = Theme.get("colors.panelBgActive")
    elseif self.wasClicked and self.isHoveredState then
        color = self.activeColor
    elseif self.isHoveredState then
        color = self.hoverColor
    else
        color = self.bgColor
    end

    -- Draw Background
    graphics.drawRect(self.x, self.y, self.width, self.height, color, true)

    -- Draw Border
    local borderColor = self.disabled and Theme.get("colors.borderDark") or Theme.get("colors.border")
    graphics.drawRect(self.x, self.y, self.width, self.height, borderColor, false)

    -- Draw Text (Properly Centered)
    if self.font then
        local textColor = self.disabled and self.disabledColor or self.textColor
        local textW, textH, baselineOffset = graphics.getTextSize(self.font, self.text)
        local tx = self.x + (self.width - textW) / 2
        local ty = self.y + (self.height - textH) / 2 + baselineOffset
        
        graphics.print(self.font, self.text, tx, ty, textColor)
    end
end

return UIButton
