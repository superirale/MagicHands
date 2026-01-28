-- MagicHandsAchievements.lua
-- Roguelike-specific achievement system for Magic Hands

local MagicHandsAchievements = {}

-- Load achievement definitions from JSON
local achievementDefs = {}
local achievements = {}
local stats = {
    blindsWon = 0,
    act1Complete = 0,
    act2Complete = 0,
    act3Complete = 0,
    highestScore = 0,
    highestHandScore = 0,
    totalItemsBought = 0,
    rerollsThisRun = 0,
    bossesDefeated = {},
    jokersStacked = {},
    nobsScored = 0,
    categoriesUsed = {},
    winStreak = 0,
    currentStreak = 0,
    deckSize = 52,
    sculptorsUsed = 0,
    currentGold = 0,
    discardsUsed = 0,
    handsPlayed = 0
}

-- Initialize the achievement system
function MagicHandsAchievements:init()
    print("MagicHandsAchievements: Initializing...")
    
    -- Load achievements from JSON
    local achievementsData = loadJSON("content/data/achievements.json")
    if achievementsData and achievementsData.achievements then
        achievementDefs = achievementsData.achievements
        
        -- Initialize achievement state
        for _, achDef in ipairs(achievementDefs) do
            achievements[achDef.id] = {
                id = achDef.id,
                name = achDef.name,
                description = achDef.description,
                category = achDef.category,
                reward = achDef.reward,
                hidden = achDef.hidden or false,
                unlocked = false,
                unlockedAt = nil
            }
        end
        
        print("Loaded " .. #achievementDefs .. " achievement definitions")
    else
        LOG_WARN("Failed to load achievements.json")
    end
    
    -- Register event listeners
    self:registerListeners()
    
    print("MagicHandsAchievements: Initialized with " .. self:count() .. " achievements")
end

-- Register all event listeners
function MagicHandsAchievements:registerListeners()
    -- Blind completion
    events.on("blind_won", function(data)
        stats.blindsWon = stats.blindsWon + 1
        stats.discardsUsed = 0
        stats.handsPlayed = 0
        
        if stats.blindsWon == 1 then
            self:unlock("first_win")
        end
        
        -- Track act completion
        if data.blindType == "boss" then
            if data.act == 1 then
                stats.act1Complete = stats.act1Complete + 1
                self:unlock("act1_complete")
            elseif data.act == 2 then
                stats.act2Complete = stats.act2Complete + 1
                self:unlock("act2_complete")
            elseif data.act == 3 then
                stats.act3Complete = stats.act3Complete + 1
                self:unlock("act3_complete")
            end
            
            -- Boss defeated
            if data.bossId then
                stats.bossesDefeated[data.bossId] = true
                
                if data.bossId == "the_purist" then
                    self:unlock("the_purist_defeated")
                end
                
                -- Check if all bosses defeated
                local bossCount = 0
                for _ in pairs(stats.bossesDefeated) do
                    bossCount = bossCount + 1
                end
                if bossCount >= 12 then
                    self:unlock("boss_hunter")
                end
            end
        end
        
        -- Check for category-specific wins
        if data.onlyCategory then
            if data.onlyCategory == "fifteens" then
                self:unlock("fifteen_master")
            elseif data.onlyCategory == "pairs" then
                self:unlock("pair_master")
            elseif data.onlyCategory == "runs" then
                self:unlock("run_master")
            elseif data.onlyCategory == "flushes" then
                self:unlock("flush_master")
            end
        end
        
        -- No discards achievement
        if stats.discardsUsed == 0 then
            self:unlock("no_discards")
        end
        
        -- One shot achievement
        if stats.handsPlayed == 1 then
            self:unlock("one_hand")
        end
        
        -- Deck size achievements
        if stats.deckSize <= 40 then
            self:unlock("minimalist")
        elseif stats.deckSize >= 65 then
            self:unlock("maximalist")
        end
    end)
    
    -- Scoring achievements
    events.on("hand_scored", function(data)
        stats.handsPlayed = stats.handsPlayed + 1
        local score = data.score or 0
        
        if score > stats.highestHandScore then
            stats.highestHandScore = score
        end
        
        -- Score milestones
        if score >= 5000 then
            self:unlock("high_scorer")
        end
        if score >= 10000 then
            self:unlock("mega_scorer")
        end
        if score >= 25000 then
            self:unlock("ultra_scorer")
        end
        if score >= 50000 then
            self:unlock("the_architect")
        end
        
        -- Lucky seven
        if score == 777 then
            self:unlock("lucky_seven")
        end
        
        -- Blackjack
        if data.handTotal == 21 then
            self:unlock("blackjack")
        end
        
        -- Category achievements
        if data.categoriesScored then
            local catCount = 0
            for cat, val in pairs(data.categoriesScored) do
                if val > 0 then
                    catCount = catCount + 1
                    stats.categoriesUsed[cat] = (stats.categoriesUsed[cat] or 0) + 1
                end
            end
            
            if catCount >= 3 then
                self:unlock("combo_master")
            end
            if catCount >= 5 then
                self:unlock("perfect_hand")
            end
            
            -- Nobs tracking
            if data.categoriesScored.nobs and data.categoriesScored.nobs > 0 then
                stats.nobsScored = stats.nobsScored + 1
                if stats.nobsScored >= 10 then
                    self:unlock("nobs_master")
                end
            end
        end
    end)
    
    -- Joker achievements
    events.on("joker_added", function(data)
        if data.stack then
            stats.jokersStacked[data.id] = data.stack
            
            if data.stack >= 5 then
                self:unlock("tier5_master")
            end
        end
    end)
    
    events.on("joker_slots_full", function(data)
        self:unlock("joker_collector")
    end)
    
    -- Economy achievements
    events.on("gold_changed", function(data)
        stats.currentGold = data.amount
        
        if stats.currentGold >= 500 then
            self:unlock("rich")
        end
    end)
    
    events.on("shop_purchase", function(data)
        stats.totalItemsBought = stats.totalItemsBought + 1
        
        if stats.totalItemsBought >= 50 then
            self:unlock("shopaholic")
        end
    end)
    
    events.on("shop_reroll", function(data)
        stats.rerollsThisRun = stats.rerollsThisRun + 1
        
        if stats.rerollsThisRun >= 20 then
            self:unlock("reroll_master")
        end
    end)
    
    -- Imprint achievements
    events.on("imprints_count", function(data)
        if data.count >= 10 then
            self:unlock("imprint_master")
        end
    end)
    
    -- Sculptor achievements
    events.on("sculptor_used", function(data)
        stats.sculptorsUsed = stats.sculptorsUsed + 1
        
        if stats.sculptorsUsed >= 5 then
            self:unlock("sculptor")
        end
        
        -- Update deck size
        if data.newDeckSize then
            stats.deckSize = data.newDeckSize
        end
    end)
    
    -- Planet achievements
    events.on("planet_count", function(data)
        if data.unique >= 10 then
            self:unlock("planet_collector")
        end
    end)
    
    -- Warp achievements
    events.on("warp_count", function(data)
        if data.active >= 3 then
            self:unlock("warp_master")
        end
        
        if data.hasGambit and data.won then
            self:unlock("risky_business")
        end
    end)
    
    -- Run completion
    events.on("run_complete", function(data)
        if data.won then
            stats.currentStreak = stats.currentStreak + 1
            if stats.currentStreak > stats.winStreak then
                stats.winStreak = stats.currentStreak
            end
            
            if stats.currentStreak >= 3 then
                self:unlock("win_streak_3")
            end
            if stats.currentStreak >= 10 then
                self:unlock("win_streak_10")
            end
        else
            stats.currentStreak = 0
        end
        
        -- Reset run stats
        stats.rerollsThisRun = 0
        stats.nobsScored = 0
        stats.sculptorsUsed = 0
        stats.discardsUsed = 0
        stats.handsPlayed = 0
        stats.deckSize = 52
    end)
    
    -- Discard tracking
    events.on("discard_used", function(data)
        stats.discardsUsed = stats.discardsUsed + 1
    end)
    
    -- Collection tracking
    events.on("collection_progress", function(data)
        if data.planets == 21 then
            self:unlock("all_planets")
        end
        if data.jokers == 40 then
            self:unlock("all_jokers")
        end
        if data.total == 121 then
            self:unlock("completionist")
        end
    end)
end

-- Unlock an achievement
function MagicHandsAchievements:unlock(id)
    local ach = achievements[id]
    if ach and not ach.unlocked then
        ach.unlocked = true
        ach.unlockedAt = os.time()
        
        print("🏆 Achievement Unlocked: " .. ach.name)
        
        -- Emit achievement event for UI/rewards
        events.emit("achievement_unlocked", {
            id = id,
            name = ach.name,
            description = ach.description,
            reward = ach.reward
        })
        
        -- Apply reward if applicable
        if ach.reward and UnlockSystem then
            UnlockSystem:processAchievementReward(ach.reward)
        end
    end
end

-- Check if an achievement is unlocked
function MagicHandsAchievements:isUnlocked(id)
    local ach = achievements[id]
    return ach and ach.unlocked
end

-- Get all achievements
function MagicHandsAchievements:getAll()
    return achievements
end

-- Get achievements by category
function MagicHandsAchievements:getByCategory(category)
    local result = {}
    for _, ach in pairs(achievements) do
        if ach.category == category then
            table.insert(result, ach)
        end
    end
    return result
end

-- Count total achievements
function MagicHandsAchievements:count()
    local count = 0
    for _ in pairs(achievements) do
        count = count + 1
    end
    return count
end

-- Count unlocked achievements
function MagicHandsAchievements:countUnlocked()
    local count = 0
    for _, ach in pairs(achievements) do
        if ach.unlocked then
            count = count + 1
        end
    end
    return count
end

-- Get progress percentage
function MagicHandsAchievements:getProgress()
    local total = self:count()
    local unlocked = self:countUnlocked()
    return total > 0 and (unlocked / total * 100) or 0
end

-- Get statistics
function MagicHandsAchievements:getStats()
    return stats
end

-- Save achievement data
function MagicHandsAchievements:serialize()
    local unlockedList = {}
    for id, ach in pairs(achievements) do
        if ach.unlocked then
            table.insert(unlockedList, {
                id = id,
                unlockedAt = ach.unlockedAt
            })
        end
    end
    return {
        unlocked = unlockedList,
        stats = stats
    }
end

-- Load achievement data
function MagicHandsAchievements:deserialize(data)
    if data.unlocked then
        for _, entry in ipairs(data.unlocked) do
            if achievements[entry.id] then
                achievements[entry.id].unlocked = true
                achievements[entry.id].unlockedAt = entry.unlockedAt
            end
        end
    end
    if data.stats then
        for key, value in pairs(data.stats) do
            stats[key] = value
        end
    end
end

return MagicHandsAchievements
