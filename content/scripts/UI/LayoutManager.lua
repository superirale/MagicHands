-- LayoutManager.lua
-- Advanced responsive layout system with anchors, constraints, and flexbox-like behavior
-- Industry-standard approach for game UI positioning

local LayoutManager = {}

-- Anchor types (origin point for positioning)
LayoutManager.Anchor = {
    TopLeft = "TopLeft",
    Top = "Top",
    TopRight = "TopRight",
    Left = "Left",
    Center = "Center",
    Right = "Right",
    BottomLeft = "BottomLeft",
    Bottom = "Bottom",
    BottomRight = "BottomRight"
}

-- Layout container
LayoutManager.Container = class()

function LayoutManager.Container:init(width, height)
    self.width = width
    self.height = height
    self.children = {}
end

--- Add a child element to the container
--- @param id string Unique identifier for the element
--- @param config table Layout configuration
---   - anchor: Anchor type (default: TopLeft)
---   - x, y: Offset from anchor point (viewport units or percentage)
---   - width, height: Element dimensions
---   - padding: Padding around element { top, right, bottom, left }
---   - margin: Margin around element { top, right, bottom, left }
function LayoutManager.Container:add(id, config)
    config = config or {}
    
    self.children[id] = {
        id = id,
        anchor = config.anchor or LayoutManager.Anchor.TopLeft,
        x = config.x or 0,
        y = config.y or 0,
        width = config.width or 100,
        height = config.height or 100,
        padding = config.padding or { top = 0, right = 0, bottom = 0, left = 0 },
        margin = config.margin or { top = 0, right = 0, bottom = 0, left = 0 },
        visible = config.visible ~= false,  -- default to true
        zIndex = config.zIndex or 0,
        
        -- Calculated positions (updated by layout())
        calculatedX = 0,
        calculatedY = 0
    }
end

--- Remove a child element
function LayoutManager.Container:remove(id)
    self.children[id] = nil
end

--- Get a child element's calculated position
--- @param id string Element ID
--- @return number x Calculated X position
--- @return number y Calculated Y position
--- @return number w Width
--- @return number h Height
function LayoutManager.Container:get(id)
    local child = self.children[id]
    if not child then
        print("[LayoutManager] Warning: Element '" .. id .. "' not found")
        return 0, 0, 0, 0
    end
    
    return child.calculatedX, child.calculatedY, child.width, child.height
end

--- Update container size (call on resize)
function LayoutManager.Container:setSize(width, height)
    self.width = width
    self.height = height
    self:layout()  -- Recalculate positions
end

--- Calculate positions for all children based on anchors
function LayoutManager.Container:layout()
    for id, child in pairs(self.children) do
        if child.visible then
            local anchorX, anchorY = self:getAnchorPoint(child.anchor)
            
            -- Apply anchor offset
            child.calculatedX = anchorX + child.x + child.margin.left
            child.calculatedY = anchorY + child.y + child.margin.top
        end
    end
end

--- Get anchor point coordinates
--- @param anchor string Anchor type
--- @return number x X coordinate of anchor
--- @return number y Y coordinate of anchor
function LayoutManager.Container:getAnchorPoint(anchor)
    local x, y = 0, 0
    
    -- Horizontal
    if anchor:find("Left") then
        x = 0
    elseif anchor:find("Right") then
        x = self.width
    else  -- Center or just Top/Bottom
        x = self.width / 2
    end
    
    -- Vertical
    if anchor:find("Top") then
        y = 0
    elseif anchor:find("Bottom") then
        y = self.height
    else  -- Center or just Left/Right
        y = self.height / 2
    end
    
    return x, y
end

--- Get all children sorted by z-index (for rendering)
--- @return table children Array of child elements sorted by zIndex
function LayoutManager.Container:getSortedChildren()
    local sorted = {}
    for _, child in pairs(self.children) do
        if child.visible then
            table.insert(sorted, child)
        end
    end
    
    table.sort(sorted, function(a, b)
        return a.zIndex < b.zIndex
    end)
    
    return sorted
end

--- DEBUG: Draw layout guides
function LayoutManager.Container:debugDraw()
    -- Draw container bounds
    graphics.drawRect(0, 0, self.width, self.height, {r=0, g=1, b=0, a=0.2}, false)
    
    -- Draw anchor points
    local anchors = {
        LayoutManager.Anchor.TopLeft,
        LayoutManager.Anchor.Top,
        LayoutManager.Anchor.TopRight,
        LayoutManager.Anchor.Left,
        LayoutManager.Anchor.Center,
        LayoutManager.Anchor.Right,
        LayoutManager.Anchor.BottomLeft,
        LayoutManager.Anchor.Bottom,
        LayoutManager.Anchor.BottomRight
    }
    
    for _, anchor in ipairs(anchors) do
        local x, y = self:getAnchorPoint(anchor)
        graphics.drawRect(x - 3, y - 3, 6, 6, {r=1, g=0, b=0, a=1}, true)
    end
    
    -- Draw children bounds
    for id, child in pairs(self.children) do
        if child.visible then
            graphics.drawRect(
                child.calculatedX,
                child.calculatedY,
                child.width,
                child.height,
                {r=0, g=0.5, b=1, a=0.3},
                false
            )
        end
    end
end

-- Specialized layout functions for common patterns

--- Center multiple elements horizontally with spacing
--- @param ids table Array of element IDs to arrange
--- @param spacing number Space between elements
function LayoutManager.Container:centerHorizontal(ids, spacing)
    spacing = spacing or 10
    
    -- Calculate total width
    local totalWidth = 0
    for _, id in ipairs(ids) do
        local child = self.children[id]
        if child then
            totalWidth = totalWidth + child.width
        end
    end
    totalWidth = totalWidth + (spacing * (#ids - 1))
    
    -- Position elements
    local startX = (self.width - totalWidth) / 2
    local currentX = startX
    
    for _, id in ipairs(ids) do
        local child = self.children[id]
        if child then
            child.x = currentX - (self.width / 2)  -- Offset from center anchor
            child.anchor = LayoutManager.Anchor.Center
            currentX = currentX + child.width + spacing
        end
    end
    
    self:layout()
end

--- Stack elements vertically
--- @param ids table Array of element IDs to stack
--- @param spacing number Space between elements
--- @param anchor string Anchor point for stack (default: TopLeft)
function LayoutManager.Container:stackVertical(ids, spacing, anchor)
    spacing = spacing or 10
    anchor = anchor or LayoutManager.Anchor.TopLeft
    
    local currentY = 0
    for _, id in ipairs(ids) do
        local child = self.children[id]
        if child then
            child.anchor = anchor
            child.y = currentY
            currentY = currentY + child.height + spacing
        end
    end
    
    self:layout()
end

--- Create a grid layout
--- @param ids table Array of element IDs
--- @param columns number Number of columns
--- @param spacing number Space between elements
--- @param anchor string Starting anchor point
function LayoutManager.Container:grid(ids, columns, spacing, anchor)
    spacing = spacing or 10
    anchor = anchor or LayoutManager.Anchor.TopLeft
    
    local row = 0
    local col = 0
    
    for _, id in ipairs(ids) do
        local child = self.children[id]
        if child then
            child.anchor = anchor
            child.x = col * (child.width + spacing)
            child.y = row * (child.height + spacing)
            
            col = col + 1
            if col >= columns then
                col = 0
                row = row + 1
            end
        end
    end
    
    self:layout()
end

return LayoutManager
