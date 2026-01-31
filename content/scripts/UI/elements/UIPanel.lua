-- UIPanel.lua
-- Container panel with border and padding

local UIElement = require("UI.elements.UIElement")
local Theme = require("UI.Theme")
local UIPanel = class(UIElement)

function UIPanel:init(x, y, width, height, options)
    UIElement.init(self, nil)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 200
    self.height = height or 200
    
    options = options or {}
    
    -- Style options
    self.style = options.style or "default"  -- "default", "inset", "raised", "flat"
    self.padding = options.padding or Theme.get("sizes.padding")
    self.showBorder = options.showBorder ~= false  -- Default true
    self.backgroundColor = options.backgroundColor or Theme.get("colors.panelBg")
    self.borderColor = options.borderColor or Theme.get("colors.border")
    self.borderWidth = options.borderWidth or Theme.get("sizes.borderWidth")
    
    -- Children elements
    self.children = {}
end

-- Add child element to panel
function UIPanel:addChild(element)
    table.insert(self.children, element)
end

-- Remove child element
function UIPanel:removeChild(element)
    for i, child in ipairs(self.children) do
        if child == element then
            table.remove(self.children, i)
            return true
        end
    end
    return false
end

-- Clear all children
function UIPanel:clearChildren()
    self.children = {}
end

-- Set padding (all sides or individual)
function UIPanel:setPadding(top, right, bottom, left)
    if right == nil then
        -- Single value for all sides
        self.padding = top
    else
        -- Individual sides (not fully implemented, but placeholder)
        self.padding = top
    end
end

-- Get content area (area inside padding)
function UIPanel:getContentArea()
    return {
        x = self.x + self.padding,
        y = self.y + self.padding,
        width = self.width - self.padding * 2,
        height = self.height - self.padding * 2
    }
end

-- Update all children
function UIPanel:update(dt)
    if not self.visible then return end
    
    for _, child in ipairs(self.children) do
        if child.update then
            child:update(dt)
        end
    end
end

-- Draw panel and children
function UIPanel:draw()
    if not self.visible then return end
    
    -- Draw shadow (optional for depth)
    if self.style ~= "flat" then
        local shadowColor = Theme.get("colors.shadow")
        local shadowOffset = 4
        graphics.drawRect(self.x + shadowOffset, self.y + shadowOffset, 
                         self.width, self.height, shadowColor, true)
    end
    
    -- Draw background
    graphics.drawRect(self.x, self.y, self.width, self.height, self.backgroundColor, true)
    
    -- Draw border
    if self.showBorder then
        -- Draw border based on style
        if self.style == "inset" then
            -- Inset style: darker top/left, lighter bottom/right
            local darkBorder = Theme.darken(self.borderColor, 0.2)
            local lightBorder = Theme.lighten(self.borderColor, 0.2)
            
            -- Top border (dark)
            graphics.drawRect(self.x, self.y, self.width, self.borderWidth, darkBorder, true)
            -- Left border (dark)
            graphics.drawRect(self.x, self.y, self.borderWidth, self.height, darkBorder, true)
            -- Bottom border (light)
            graphics.drawRect(self.x, self.y + self.height - self.borderWidth, 
                            self.width, self.borderWidth, lightBorder, true)
            -- Right border (light)
            graphics.drawRect(self.x + self.width - self.borderWidth, self.y, 
                            self.borderWidth, self.height, lightBorder, true)
        elseif self.style == "raised" then
            -- Raised style: lighter top/left, darker bottom/right
            local darkBorder = Theme.darken(self.borderColor, 0.2)
            local lightBorder = Theme.lighten(self.borderColor, 0.2)
            
            -- Top border (light)
            graphics.drawRect(self.x, self.y, self.width, self.borderWidth, lightBorder, true)
            -- Left border (light)
            graphics.drawRect(self.x, self.y, self.borderWidth, self.height, lightBorder, true)
            -- Bottom border (dark)
            graphics.drawRect(self.x, self.y + self.height - self.borderWidth, 
                            self.width, self.borderWidth, darkBorder, true)
            -- Right border (dark)
            graphics.drawRect(self.x + self.width - self.borderWidth, self.y, 
                            self.borderWidth, self.height, darkBorder, true)
        else
            -- Default/flat: simple outline
            graphics.drawRect(self.x, self.y, self.width, self.height, self.borderColor, false)
        end
    end
    
    -- Draw children (with padding offset)
    local contentArea = self:getContentArea()
    for _, child in ipairs(self.children) do
        -- Offset child position by panel's content area
        -- Note: This assumes children have relative positioning
        if child.draw then
            -- Save original position
            local origX, origY = child.x, child.y
            
            -- Apply panel offset
            child.x = contentArea.x + (child.x or 0)
            child.y = contentArea.y + (child.y or 0)
            
            -- Draw child
            child:draw()
            
            -- Restore original position
            child.x = origX
            child.y = origY
        end
    end
end

-- Convenience function: create a styled panel
function UIPanel.create(style, x, y, width, height)
    local styles = {
        default = {},
        dark = {
            backgroundColor = Theme.get("colors.backgroundDark"),
            borderColor = Theme.get("colors.borderDark")
        },
        light = {
            backgroundColor = Theme.lighten(Theme.get("colors.panelBg"), 0.1),
            borderColor = Theme.get("colors.borderLight")
        },
        danger = {
            backgroundColor = Theme.withAlpha(Theme.get("colors.danger"), 0.2),
            borderColor = Theme.get("colors.danger")
        },
        success = {
            backgroundColor = Theme.withAlpha(Theme.get("colors.success"), 0.2),
            borderColor = Theme.get("colors.success")
        },
        warning = {
            backgroundColor = Theme.withAlpha(Theme.get("colors.warning"), 0.2),
            borderColor = Theme.get("colors.warning")
        }
    }
    
    local options = styles[style] or styles.default
    return UIPanel(x, y, width, height, options)
end

return UIPanel
