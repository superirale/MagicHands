-- GameSceneLayout.lua
-- Defines logical layout zones for GameScene with relative positioning

local GameSceneLayout = {}

-- Viewport dimensions (fixed design space)
GameSceneLayout.VIEWPORT_WIDTH = 1280
GameSceneLayout.VIEWPORT_HEIGHT = 720

-- Layout zones as percentages and offsets
GameSceneLayout.zones = {
    -- Hand cards zone (bottom center)
    hand = {
        centerX = 0.5,  -- 50% from left (center)
        y = 0.72,       -- 72% from top (near bottom)
        cardSpacing = 110,
        cardWidth = 100,
        cardHeight = 140
    },
    
    -- Crib zone (right side, middle-bottom)
    crib = {
        baseX = 0.77,   -- 77% from left (right side)
        y = 0.68,       -- 68% from top
        cardSpacing = 120,
        slots = 2
    },
    
    -- Cut card zone (top center)
    cutCard = {
        centerX = 0.5,  -- 50% from left (center)
        y = 0.28,       -- 28% from top
    },
    
    -- Keyboard shortcuts (bottom left)
    shortcuts = {
        x = 0.016,      -- 1.6% from left (20px at 1280)
        y = 0.944,      -- 94.4% from top (680px at 720)
    },
    
    -- Add to Crib button (right side, above crib)
    addToCribButton = {
        x = 0.766,      -- 76.6% from left (980px at 1280)
        y = 0.583,      -- 58.3% from top (420px at 720)
        width = 0.1875, -- 18.75% of width (240px at 1280)
        height = 0.069  -- 6.9% of height (50px at 720)
    },
    
    -- HUD zone (top)
    hud = {
        y = 0.0,
        height = 0.15   -- 15% of screen
    },
    
    -- Score preview (left middle)
    scorePreview = {
        x = 0.05,
        y = 0.35
    }
}

-- Convert relative position to absolute viewport coordinates
function GameSceneLayout.getPosition(zone, index)
    local vw = GameSceneLayout.VIEWPORT_WIDTH
    local vh = GameSceneLayout.VIEWPORT_HEIGHT
    
    if zone == "hand" then
        local z = GameSceneLayout.zones.hand
        local numCards = index.count or 6
        local totalWidth = (numCards - 1) * z.cardSpacing
        local startX = (vw * z.centerX) - (totalWidth / 2)
        local x = startX + (index.cardIndex - 1) * z.cardSpacing
        local y = vh * z.y
        return x, y
        
    elseif zone == "crib" then
        local z = GameSceneLayout.zones.crib
        local baseX = vw * z.baseX
        local x = baseX + (index.slotIndex - 1) * z.cardSpacing
        local y = vh * z.y
        return x, y
        
    elseif zone == "cutCard" then
        local z = GameSceneLayout.zones.cutCard
        local x = (vw * z.centerX) - (GameSceneLayout.zones.hand.cardWidth / 2)
        local y = vh * z.y
        return x, y
        
    elseif zone == "shortcuts" then
        local z = GameSceneLayout.zones.shortcuts
        return vw * z.x, vh * z.y
        
    elseif zone == "addToCribButton" then
        local z = GameSceneLayout.zones.addToCribButton
        return {
            x = vw * z.x,
            y = vh * z.y,
            width = vw * z.width,
            height = vh * z.height
        }
    end
    
    return 0, 0
end

-- Get zone dimensions
function GameSceneLayout.getDimensions(zone)
    local vw = GameSceneLayout.VIEWPORT_WIDTH
    local vh = GameSceneLayout.VIEWPORT_HEIGHT
    
    if zone == "hand" then
        local z = GameSceneLayout.zones.hand
        return {
            cardSpacing = z.cardSpacing,
            cardWidth = z.cardWidth,
            cardHeight = z.cardHeight
        }
    elseif zone == "crib" then
        local z = GameSceneLayout.zones.crib
        return {
            cardSpacing = z.cardSpacing,
            slots = z.slots
        }
    end
    
    return {}
end

-- Calculate centered position for N cards
function GameSceneLayout.getCenteredHandPosition(numCards)
    local vw = GameSceneLayout.VIEWPORT_WIDTH
    local vh = GameSceneLayout.VIEWPORT_HEIGHT
    local z = GameSceneLayout.zones.hand
    
    local totalWidth = (numCards - 1) * z.cardSpacing
    local startX = (vw * z.centerX) - (totalWidth / 2)
    local y = vh * z.y
    
    return startX, y, z.cardSpacing
end

return GameSceneLayout
