-- AchievementSystem.lua
-- Example usage of the event system for tracking achievements

AchievementSystem = {}

-- Achievement definitions
local achievements = {
    first_blood = { 
        name = "First Blood", 
        description = "Kill your first enemy",
        unlocked = false 
    },
    survivor = { 
        name = "Survivor", 
        description = "Survive 10 days",
        unlocked = false 
    },
    hoarder = { 
        name = "Hoarder", 
        description = "Collect 100 items",
        unlocked = false 
    },
    lumberjack = {
        name = "Lumberjack",
        description = "Chop down 50 trees",
        unlocked = false
    },
    miner = {
        name = "Miner",
        description = "Mine 30 rocks",
        unlocked = false
    },
    chef = {
        name = "Chef",
        description = "Craft 10 food items",
        unlocked = false
    },
    builder = {
        name = "Builder",
        description = "Place 5 structures",
        unlocked = false
    },
    boss_slayer = {
        name = "Boss Slayer",
        description = "Defeat a boss",
        unlocked = false
    }
}

-- Statistics tracking
local stats = {
    enemiesKilled = 0,
    itemsCollected = 0,
    daysAlive = 0,
    treesChopped = 0,
    rocksMined = 0,
    foodCrafted = 0,
    structuresPlaced = 0,
    bossesKilled = 0,
}

-- Initialize the achievement system
function AchievementSystem.init()
    print("AchievementSystem: Initializing...")
    
    -- Listen for enemy kills
    events.on("enemy_killed", function(data)
        stats.enemiesKilled = stats.enemiesKilled + 1
        
        -- First Blood achievement
        if stats.enemiesKilled == 1 then
            AchievementSystem.unlock("first_blood")
        end
        
        -- Boss Slayer achievement
        if data.isBoss then
            stats.bossesKilled = stats.bossesKilled + 1
            AchievementSystem.unlock("boss_slayer")
        end
    end)
    
    -- Listen for day changes
    events.on("day_changed", function(data)
        local day = tonumber(data.day) or (stats.daysAlive + 1)
        stats.daysAlive = day
        
        -- Survivor achievement
        if stats.daysAlive >= 10 then
            AchievementSystem.unlock("survivor")
        end
    end)
    
    -- Listen for item pickups
    events.on("item_picked_up", function(data)
        local quantity = data.quantity or 1
        stats.itemsCollected = stats.itemsCollected + quantity
        
        -- Hoarder achievement
        if stats.itemsCollected >= 100 then
            AchievementSystem.unlock("hoarder")
        end
    end)
    
    -- Listen for resource harvesting
    events.on("resource_harvested", function(data)
        if data.resourceType == "tree" then
            stats.treesChopped = stats.treesChopped + 1
            if stats.treesChopped >= 50 then
                AchievementSystem.unlock("lumberjack")
            end
        elseif data.resourceType == "rock" then
            stats.rocksMined = stats.rocksMined + 1
            if stats.rocksMined >= 30 then
                AchievementSystem.unlock("miner")
            end
        end
    end)
    
    -- Listen for crafting
    events.on("item_crafted", function(data)
        -- Check if it's a food item (simplified check)
        local foodItems = { cooked_meat = true, berry_jam = true, veggie_stew = true }
        if foodItems[data.id] then
            stats.foodCrafted = stats.foodCrafted + 1
            if stats.foodCrafted >= 10 then
                AchievementSystem.unlock("chef")
            end
        end
    end)
    
    -- Listen for structure placement
    events.on("structure_placed", function(data)
        stats.structuresPlaced = stats.structuresPlaced + 1
        if stats.structuresPlaced >= 5 then
            AchievementSystem.unlock("builder")
        end
    end)
    
    print("AchievementSystem: Initialized with " .. AchievementSystem.count() .. " achievements")
end

-- Unlock an achievement
function AchievementSystem.unlock(id)
    local ach = achievements[id]
    if ach and not ach.unlocked then
        ach.unlocked = true
        print("🏆 Achievement Unlocked: " .. ach.name)
        
        -- Emit achievement event for other systems (e.g., notifications, save system)
        events.emit("achievement_unlocked", { 
            id = id, 
            name = ach.name,
            description = ach.description
        })
    end
end

-- Check if an achievement is unlocked
function AchievementSystem.isUnlocked(id)
    local ach = achievements[id]
    return ach and ach.unlocked
end

-- Get all achievements
function AchievementSystem.getAll()
    return achievements
end

-- Count total achievements
function AchievementSystem.count()
    local count = 0
    for _ in pairs(achievements) do
        count = count + 1
    end
    return count
end

-- Count unlocked achievements
function AchievementSystem.countUnlocked()
    local count = 0
    for _, ach in pairs(achievements) do
        if ach.unlocked then
            count = count + 1
        end
    end
    return count
end

-- Get statistics
function AchievementSystem.getStats()
    return stats
end

-- Save achievement data (for save system integration)
function AchievementSystem.serialize()
    local unlockedList = {}
    for id, ach in pairs(achievements) do
        if ach.unlocked then
            table.insert(unlockedList, id)
        end
    end
    return {
        unlocked = unlockedList,
        stats = stats
    }
end

-- Load achievement data (for save system integration)
function AchievementSystem.deserialize(data)
    if data.unlocked then
        for _, id in ipairs(data.unlocked) do
            if achievements[id] then
                achievements[id].unlocked = true
            end
        end
    end
    if data.stats then
        stats = data.stats
    end
end

return AchievementSystem
