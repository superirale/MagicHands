-- CardViewRefactored.lua
-- Pure rendering layer for cards (no logic, just presentation)
-- Works with CardViewModel for MVVM pattern

local CardViewRefactored = {}

-- Sprite atlas constants
CardViewRefactored.ATLAS_WIDTH = 1024
CardViewRefactored.ATLAS_HEIGHT = 1024
CardViewRefactored.CARD_WIDTH_ATLAS = CardViewRefactored.ATLAS_WIDTH / 13
CardViewRefactored.CARD_HEIGHT_ATLAS = CardViewRefactored.ATLAS_HEIGHT / 4

-- Card sprite layout (generated sheet)
-- Row 0: Spades (s=3)
-- Row 1: Clubs (s=2)
-- Row 2: Hearts (s=0)
-- Row 3: Diamonds (s=1)
CardViewRefactored.SUIT_TO_ROW = { [0] = 2, [1] = 3, [2] = 1, [3] = 0 }

--- Draw a card using its ViewModel
--- @param viewModel CardViewModel The card view model
--- @param atlas number Texture ID for card sprite sheet
--- @param font number Font for enhancement labels
function CardViewRefactored.draw(viewModel, atlas, font)
    local card = viewModel:getCard()
    local state = viewModel:getState()
    local renderX, renderY = viewModel:getRenderPosition()
    local width = viewModel.width
    local height = viewModel.height
    
    -- Get sprite coordinates
    local spriteX, spriteY = CardViewRefactored.getSpriteCoords(card)
    
    -- Draw card sprite
    graphics.drawSub(
        atlas,
        renderX, renderY, width, height,  -- Destination (viewport space)
        spriteX, spriteY,  -- Source (atlas pixels)
        CardViewRefactored.CARD_WIDTH_ATLAS,
        CardViewRefactored.CARD_HEIGHT_ATLAS
    )
    
    -- Draw selection highlight
    if state.isSelected then
        graphics.drawRect(
            renderX - 2, renderY - 2,
            width + 4, height + 4,
            { r = 1, g = 1, b = 0.2, a = 0.5 },
            true  -- filled
        )
    end
    
    -- Draw hover highlight
    if state.isHovered and not state.isSelected then
        graphics.drawRect(
            renderX - 1, renderY - 1,
            width + 2, height + 2,
            { r = 1, g = 1, b = 1, a = 0.3 },
            false  -- outline
        )
    end
    
    -- Draw dragging indicator
    if state.isDragging then
        graphics.drawRect(
            renderX, renderY,
            width, height,
            { r = 0.5, g = 0.5, b = 1, a = 0.4 },
            false
        )
    end
    
    -- Draw enhancement label (if card has enhancement)
    if card.enhancement then
        local label, color = CardViewRefactored.getEnhancementVisuals(card.enhancement)
        if label then
            local textWidth = 40  -- Approximate width for centering
            graphics.print(
                font,
                label,
                renderX + (width - textWidth) / 2,
                renderY + height - 20,
                color
            )
        end
    end
end

--- Get sprite atlas coordinates for a card
--- @param card table Card data {rank, suit}
--- @return number x X coordinate in atlas (pixels)
--- @return number y Y coordinate in atlas (pixels)
function CardViewRefactored.getSpriteCoords(card)
    local rankInt = CardViewRefactored.getRankValue(card.rank)
    local suitInt = CardViewRefactored.getSuitValue(card.suit)
    
    local col = rankInt - 1  -- 0-12
    local row = CardViewRefactored.SUIT_TO_ROW[suitInt]
    
    local x = col * CardViewRefactored.CARD_WIDTH_ATLAS
    local y = row * CardViewRefactored.CARD_HEIGHT_ATLAS
    
    return x, y
end

--- Convert rank string to integer (1-13)
--- @param rank string Rank string ("A", "2"-"10", "J", "Q", "K")
--- @return number value Rank value (1-13)
function CardViewRefactored.getRankValue(rank)
    if rank == "A" then return 1 end
    if rank == "J" then return 11 end
    if rank == "Q" then return 12 end
    if rank == "K" then return 13 end
    return tonumber(rank) or 1
end

--- Convert suit string to integer (0-3)
--- @param suit string Suit string ("H", "D", "C", "S")
--- @return number value Suit value (0=Hearts, 1=Diamonds, 2=Clubs, 3=Spades)
function CardViewRefactored.getSuitValue(suit)
    if suit == "H" then return 0 end
    if suit == "D" then return 1 end
    if suit == "C" then return 2 end
    if suit == "S" then return 3 end
    return 0
end

--- Get enhancement visuals (label and color)
--- @param enhancement string Enhancement ID
--- @return string|nil label Display label
--- @return table|nil color RGBA color table
function CardViewRefactored.getEnhancementVisuals(enhancement)
    if enhancement == "planet_gold" then
        return "GOLD", { r = 1, g = 0.8, b = 0, a = 1 }
    elseif enhancement == "planet_mult" then
        return "MULT", { r = 1, g = 0.2, b = 0.2, a = 1 }
    elseif enhancement == "planet_steel" then
        return "STEEL", { r = 0.7, g = 0.7, b = 0.8, a = 1 }
    elseif enhancement == "planet_stone" then
        return "STONE", { r = 0.5, g = 0.5, b = 0.5, a = 1 }
    else
        return "ENH", { r = 1, g = 1, b = 1, a = 1 }
    end
end

--- DEBUG: Draw card bounds and center point
--- @param viewModel CardViewModel The card view model
function CardViewRefactored.debugDraw(viewModel)
    local renderX, renderY = viewModel:getRenderPosition()
    local width = viewModel.width
    local height = viewModel.height
    
    -- Draw bounds
    graphics.drawRect(renderX, renderY, width, height, {r=0, g=1, b=0, a=0.5}, false)
    
    -- Draw center point
    local centerX = renderX + width / 2
    local centerY = renderY + height / 2
    graphics.drawRect(centerX - 2, centerY - 2, 4, 4, {r=1, g=0, b=0, a=1}, true)
    
    -- Draw target position
    local targetX, targetY = viewModel.targetX, viewModel.targetY
    graphics.drawRect(targetX - 1, targetY - 1, 2, 2, {r=0, g=0, b=1, a=1}, true)
end

return CardViewRefactored
