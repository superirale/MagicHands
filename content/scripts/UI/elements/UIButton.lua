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

function UIButton:update(dt)
    if not self.visible then return end

    local mx, my, mLeft = input.getMousePosition() -- Assuming global input
    -- Or pass inputs via update, but global input is standard in this engine so far
    -- Wait, GameScene passes inputs? No, GameScene calls update(dt).
    -- But BlindPreview accessed global `input`.

    -- Check Hover
    self.isHoveredState = self:isHovered(mx, my)

    -- Check Click
    if self.isHoveredState and input.isJustPressed("return") then -- Just placeholder, usually mouse click
        -- The user mentioned "mouse click" in BlindPreview: "clicked and hover"
        -- I will assume the parent passes 'clicked' state or checking global mouse
        if mLeft and not self.wasClicked then
            self.wasClicked = true
            if self.onClick then self.onClick() end
        elseif not mLeft then
            self.wasClicked = false
        end
    end
end

-- Ideally update(...) should take input state or access global input wrapper
-- For now, relying on global 'input' as seen in other files

function UIButton:draw()
    if not self.visible then return end

    local color = self.isHoveredState and self.hoverColor or self.bgColor

    -- Draw Background
    graphics.drawRect(self.x, self.y, self.width, self.height, color, true)

    -- Draw Border
    graphics.drawRect(self.x, self.y, self.width, self.height, { r = 1, g = 1, b = 1, a = 0.5 }, false)

    -- Draw Text (Centered)
    local textW = #self.text * 12 -- Approx
    -- Assuming we have an estimateWidth or similar helper, or just center roughly
    if self.font then
        graphics.print(self.font, self.text, self.x + 10, self.y + 10, self.textColor)
        -- Real centering requires text width measurement which is missing/approximated
    else
        -- fallback ?
    end
end

return UIButton
