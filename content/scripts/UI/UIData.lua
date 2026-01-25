-- UIData.lua
-- Stores the state of the UI/HUD

UIData = {
    -- Health
    health = 100,
    maxHealth = 100,
    displayHealth = 100, -- For tweening
    
    -- Hunger (Phase 2)
    hunger = 100,
    maxHunger = 100,
    displayHunger = 100,
    
    -- Sanity (Phase 2)
    sanity = 100,
    maxSanity = 100,
    displaySanity = 100,
    
    -- Resources
    gold = 0,
    casts = 3,
    maxCasts = 3
}

return UIData
