-- UIElement.lua
-- Base class for all UI widgets
local UIElement = class()

function UIElement:init(layout_name, x, y, width, height)
    self.layout_name = layout_name -- Optional: ID for UILayout lookups
    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or 0
    self.visible = true
    self.parent = nil
    self.children = {}
    self.style = {}
end

function UIElement:update(dt)
    if not self.visible then return end
    -- Update logic (animations, etc)
end

function UIElement:draw()
    if not self.visible then return end
    -- Override in subclasses
end

function UIElement:setPos(x, y)
    self.x = x
    self.y = y
end

function UIElement:setSize(w, h)
    self.width = w
    self.height = h
end

function UIElement:isHovered(mx, my)
    return self.visible and
        mx >= self.x and mx <= self.x + self.width and
        my >= self.y and my <= self.y + self.height
end

return UIElement
