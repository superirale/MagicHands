-- UnlockSystem.lua
-- Progressive content unlocking system

local UnlockSystem = {}

-- Track unlocked content (persists across runs)
local unlockedContent = {
    jokers = {},
    planets = {},
    warps = {},
    imprints = {},
    sculptors = {},
    bosses = {},
    upgrades = {}
}

-- Starting unlocked content (minimal set)
local defaultUnlocks = {
    jokers = {"fifteen_fever", "lucky_seven", "big_hand", "pair_power", "run_master", 
              "nobs_hunter", "the_trio", "flush_king", "combo_king", "blackjack"},
    planets = {"planet_pair", "planet_run", "planet_fifteen", "planet_flush", "planet_noble"},
    warps = {"spectral_echo", "spectral_ghost", "spectral_void"},
    imprints = {"gold_inlay", "lucky_pips", "steel_plating"},
    sculptors = {"spectral_remove", "spectral_clone"},
    bosses = {"the_counter", "the_skunk", "thirty_one", "the_dealer", "the_wall", "the_drain"}
}

function UnlockSystem:init()
    print("UnlockSystem: Initializing...")
    
    -- Start with default unlocks
    for category, items in pairs(defaultUnlocks) do
        for _, itemId in ipairs(items) do
            self:unlock(category, itemId)
        end
    end
    
    print("UnlockSystem: Initialized with " .. self:getTotalUnlocked() .. " items unlocked")
end

-- Unlock content
function UnlockSystem:unlock(category, itemId)
    if not unlockedContent[category] then
        unlockedContent[category] = {}
    end
    
    if not unlockedContent[category][itemId] then
        unlockedContent[category][itemId] = true
        print("🔓 Unlocked: " .. itemId)
        
        events.emit("content_unlocked", {category = category, id = itemId})
        return true
    end
    return false
end

-- Check if content is unlocked
function UnlockSystem:isUnlocked(category, itemId)
    return unlockedContent[category] and unlockedContent[category][itemId] == true
end

-- Get all unlocked content in category
function UnlockSystem:getUnlocked(category)
    local result = {}
    if unlockedContent[category] then
        for id, _ in pairs(unlockedContent[category]) do
            table.insert(result, id)
        end
    end
    return result
end

-- Process achievement rewards
function UnlockSystem:processAchievementReward(reward)
    if reward == "unlock_5_random" then
        self:unlockRandom(5)
    elseif reward == "unlock_10_random" then
        self:unlockRandom(10)
    elseif reward == "unlock_15_random" then
        self:unlockRandom(15)
    elseif string.find(reward, "unlock_all_") then
        local category = string.gsub(reward, "unlock_all_", "")
        self:unlockAllInCategory(category)
    elseif string.find(reward, "unlock_") then
        local itemId = string.gsub(reward, "unlock_", "")
        self:unlockSpecific(itemId)
    elseif string.find(reward, "start_") then
        self:unlockUpgrade(reward)
    end
end

-- Unlock random items
function UnlockSystem:unlockRandom(count)
    local allContent = self:getAllLockedContent()
    for i = 1, math.min(count, #allContent) do
        local idx = math.random(#allContent)
        local item = table.remove(allContent, idx)
        self:unlock(item.category, item.id)
    end
end

-- Unlock specific item (determines category automatically)
function UnlockSystem:unlockSpecific(itemId)
    -- Determine category from item ID pattern
    local category = nil
    
    if string.find(itemId, "planet_") then
        category = "planets"
    elseif string.find(itemId, "spectral_") or string.find(itemId, "warp_") then
        if string.find(itemId, "remove") or string.find(itemId, "clone") or string.find(itemId, "ascend") or
           string.find(itemId, "collapse") or string.find(itemId, "split") or string.find(itemId, "purge") or
           string.find(itemId, "rainbow") or string.find(itemId, "fusion") then
            category = "sculptors"
        else
            category = "warps"
        end
    else
        -- Check against known imprints
        local imprints = {
            gold_inlay = true, lucky_pips = true, steel_plating = true, mint = true, tax = true,
            investment = true, insurance = true, dividend = true, echo = true, cascade = true,
            fractal = true, resonance = true, spark = true, ripple = true, pulse = true,
            crown = true, underdog = true, clutch = true, opener = true, majority = true,
            minority = true, wildcard_imprint = true, suit_shifter = true, mimic = true, nullifier = true
        }
        
        if imprints[itemId] then
            category = "imprints"
        else
            -- Default to jokers
            category = "jokers"
        end
    end
    
    if category then
        self:unlock(category, itemId)
    end
end

-- Unlock all in category
function UnlockSystem:unlockAllInCategory(category)
    if category == "tiered_jokers" then
        local tieredJokers = {"fifteen_fever_tiered", "lucky_seven_tiered", "pair_power_tiered", 
                              "run_master_tiered", "flush_king_tiered", "nobs_hunter_tiered",
                              "ace_power_tiered", "combo_king_tiered", "even_stevens_tiered", "blackjack_tiered"}
        for _, id in ipairs(tieredJokers) do
            self:unlock("jokers", id)
        end
    else
        -- Unlock all content from that category
        -- This would need to know all available content
        print("Unlock all in category: " .. category)
    end
end

-- Unlock upgrade
function UnlockSystem:unlockUpgrade(upgradeId)
    unlockedContent.upgrades[upgradeId] = true
    print("🎁 Upgrade Unlocked: " .. upgradeId)
end

-- Get all locked content
function UnlockSystem:getAllLockedContent()
    local allContent = {}
    
    -- Would need full content registry here
    -- For now, placeholder
    
    return allContent
end

-- Get total unlocked count
function UnlockSystem:getTotalUnlocked()
    local total = 0
    for category, items in pairs(unlockedContent) do
        if category ~= "upgrades" then
            for _ in pairs(items) do
                total = total + 1
            end
        end
    end
    return total
end

-- Serialize for saving
function UnlockSystem:serialize()
    return unlockedContent
end

-- Deserialize from save
function UnlockSystem:deserialize(data)
    if data then
        unlockedContent = data
    end
end

return UnlockSystem
