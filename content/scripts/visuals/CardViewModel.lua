-- CardViewModel.lua
-- Presentation logic layer between card data and view
-- Implements MVVM pattern: separates business logic from rendering

local UIEvents = require("UI/UIEvents")

local CardViewModel = class()

--- Create a new CardViewModel
--- @param card table Card data {rank, suit, enhancement}
--- @param viewportX number X position in viewport space
--- @param viewportY number Y position in viewport space
--- @param index number Card index in hand
function CardViewModel:init(card, viewportX, viewportY, index)
    -- Model data (immutable from view perspective)
    self.card = card
    self.index = index
    
    -- Presentation state
    self.viewportX = viewportX
    self.viewportY = viewportY
    self.width = 100
    self.height = 140
    
    -- Interaction state
    self.isSelected = false
    self.isHovered = false
    self.isDragging = false
    
    -- Animation state
    self.targetX = viewportX
    self.targetY = viewportY
    self.currentX = viewportX
    self.currentY = viewportY
    self.animationSpeed = 15  -- Lerp factor
    
    -- Drag offset (for smooth dragging)
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    
    -- Visual state
    self.elevation = 0  -- Y offset for hover/selection
    self.targetElevation = 0
end

--- Update ViewModel (animation, state transitions)
--- @param dt number Delta time
function CardViewModel:update(dt)
    -- Update elevation based on state
    if self.isDragging then
        self.targetElevation = 0  -- Dragged cards don't use elevation
    elseif self.isSelected then
        self.targetElevation = -30  -- Selected cards rise up
    elseif self.isHovered then
        self.targetElevation = -10  -- Hovered cards rise slightly
    else
        self.targetElevation = 0
    end
    
    -- Smooth elevation transition
    self.elevation = self.elevation + (self.targetElevation - self.elevation) * self.animationSpeed * dt
    
    -- Smooth position transition (only when not dragging)
    if not self.isDragging then
        self.currentX = self.currentX + (self.targetX - self.currentX) * self.animationSpeed * dt
        self.currentY = self.currentY + (self.targetY - self.currentY) * self.animationSpeed * dt
    end
end

--- Set target position for animation
--- @param x number Target X in viewport space
--- @param y number Target Y in viewport space
function CardViewModel:setTargetPosition(x, y)
    self.targetX = x
    self.targetY = y
end

--- Set current position immediately (no animation)
--- @param x number X in viewport space
--- @param y number Y in viewport space
function CardViewModel:setPosition(x, y)
    self.viewportX = x
    self.viewportY = y
    self.targetX = x
    self.targetY = y
    self.currentX = x
    self.currentY = y
end

--- Get render position (current position + elevation)
--- @return number x X coordinate for rendering
--- @return number y Y coordinate for rendering
function CardViewModel:getRenderPosition()
    return self.currentX, self.currentY + self.elevation
end

--- Check if viewport point is hovering over card
--- @param viewportX number X in viewport space
--- @param viewportY number Y in viewport space
--- @return boolean isHovered True if hovering
function CardViewModel:hitTest(viewportX, viewportY)
    local renderX, renderY = self:getRenderPosition()
    return viewportX >= renderX and viewportX <= renderX + self.width and
           viewportY >= renderY and viewportY <= renderY + self.height
end

--- Handle input events (mouse/touch)
--- @param eventType string "hover" | "click" | "dragStart" | "drag" | "dragEnd"
--- @param viewportX number X in viewport space
--- @param viewportY number Y in viewport space
function CardViewModel:handleInput(eventType, viewportX, viewportY)
    if eventType == "hover" then
        if self:hitTest(viewportX, viewportY) then
            if not self.isHovered then
                self.isHovered = true
                UIEvents.emit("card:hover", { cardIndex = self.index, x = viewportX, y = viewportY })
            end
        else
            self.isHovered = false
        end
        
    elseif eventType == "click" and not self.isDragging then
        if self:hitTest(viewportX, viewportY) then
            self:toggleSelection()
        end
        
    elseif eventType == "dragStart" then
        if self:hitTest(viewportX, viewportY) then
            self.isDragging = true
            local renderX, renderY = self:getRenderPosition()
            self.dragOffsetX = viewportX - renderX
            self.dragOffsetY = viewportY - renderY
            
            UIEvents.emit("card:dragStart", {
                cardIndex = self.index,
                startX = viewportX,
                startY = viewportY
            })
        end
        
    elseif eventType == "drag" and self.isDragging then
        self.currentX = viewportX - self.dragOffsetX
        self.currentY = viewportY - self.dragOffsetY
        
        UIEvents.emit("card:drag", {
            cardIndex = self.index,
            x = self.currentX,
            y = self.currentY
        })
        
    elseif eventType == "dragEnd" and self.isDragging then
        self.isDragging = false
        
        UIEvents.emit("card:dragEnd", {
            cardIndex = self.index,
            x = viewportX,
            y = viewportY
        })
    end
end

--- Toggle card selection
function CardViewModel:toggleSelection()
    self.isSelected = not self.isSelected
    
    if self.isSelected then
        UIEvents.emit("card:selected", { cardIndex = self.index })
    else
        UIEvents.emit("card:deselected", { cardIndex = self.index })
    end
end

--- Set selection state explicitly
--- @param selected boolean New selection state
function CardViewModel:setSelected(selected)
    if self.isSelected ~= selected then
        self.isSelected = selected
        
        if selected then
            UIEvents.emit("card:selected", { cardIndex = self.index })
        else
            UIEvents.emit("card:deselected", { cardIndex = self.index })
        end
    end
end

--- Get card data for rendering
--- @return table card Card data {rank, suit, enhancement}
function CardViewModel:getCard()
    return self.card
end

--- Update card data (when card changes)
--- @param card table New card data
function CardViewModel:setCard(card)
    self.card = card
end

--- Get interaction state
--- @return table state {isSelected, isHovered, isDragging}
function CardViewModel:getState()
    return {
        isSelected = self.isSelected,
        isHovered = self.isHovered,
        isDragging = self.isDragging
    }
end

--- Reset to default state
function CardViewModel:reset()
    self.isSelected = false
    self.isHovered = false
    self.isDragging = false
    self.elevation = 0
    self.targetElevation = 0
end

return CardViewModel
