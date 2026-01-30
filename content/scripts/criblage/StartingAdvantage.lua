-- StartingAdvantage.lua
-- Manages random starting bonuses (roguelike blessings)

local StartingAdvantage = {}

-- Define all possible starting advantages
StartingAdvantage.types = {
    gold = {
        name = "Extra Gold",
        description = "Start with bonus gold",
        options = {10, 20, 30, 40, 50}
    },
    joker = {
        name = "Starting Item",
        description = "Begin with a free joker or enhancement",
        maxCost = 50  -- Only items that cost ≤50g
    },
    hand = {
        name = "Larger Hand",
        description = "Extra cards in hand for the first blind",
        options = {1, 2, 3}
    }
}

-- Select a random advantage type
function StartingAdvantage:rollAdvantage()
    local advantageTypes = {"gold", "joker", "hand"}
    local selectedType = advantageTypes[math.random(#advantageTypes)]
    
    local advantage = {
        type = selectedType,
        value = nil,
        description = ""
    }
    
    if selectedType == "gold" then
        advantage.value = self.types.gold.options[math.random(#self.types.gold.options)]
        advantage.description = "Start with +" .. advantage.value .. "g"
        
    elseif selectedType == "joker" then
        -- Select random item from affordable pool
        local affordableItems = self:getAffordableItems(self.types.joker.maxCost)
        if #affordableItems > 0 then
            local selected = affordableItems[math.random(#affordableItems)]
            advantage.value = selected.id
            advantage.itemType = selected.type
            advantage.description = "Start with " .. selected.id
        else
            -- Fallback to gold if no affordable items
            advantage.type = "gold"
            advantage.value = 20
            advantage.description = "Start with +20g (fallback)"
        end
        
    elseif selectedType == "hand" then
        advantage.value = self.types.hand.options[math.random(#self.types.hand.options)]
        advantage.description = "+" .. advantage.value .. " cards in hand (first blind only)"
    end
    
    return advantage
end

-- Get list of affordable jokers and enhancements
function StartingAdvantage:getAffordableItems(maxCost)
    local items = {}
    
    -- Add common jokers (20g)
    local commonJokers = {
        "fifteen_fever", "lucky_seven", "big_hand", "face_card_fan", 
        "even_stevens", "low_roller"
    }
    for _, id in ipairs(commonJokers) do
        table.insert(items, {id = id, type = "joker", cost = 20})
    end
    
    -- Add enhancements (30g)
    local enhancements = {
        "planet_pair", "planet_run", "planet_fifteen", "planet_flush",
        "spectral_echo", "spectral_ghost", "spectral_void"
    }
    for _, id in ipairs(enhancements) do
        if 30 <= maxCost then
            table.insert(items, {id = id, type = "enhancement", cost = 30})
        end
    end
    
    return items
end

-- Apply the advantage to the game state
function StartingAdvantage:apply(advantage, campaignState)
    if not advantage then return false end
    
    if advantage.type == "gold" then
        -- Add bonus gold
        local Economy = require("criblage/Economy")
        Economy:addGold(advantage.value)
        print("✨ Starting Advantage: " .. advantage.description)
        return true
        
    elseif advantage.type == "joker" then
        -- Add starting item
        if advantage.itemType == "joker" then
            local JokerManager = require("criblage/JokerManager")
            local success = JokerManager:addJoker(advantage.value)
            if success then
                print("✨ Starting Advantage: " .. advantage.description)
                return true
            end
        elseif advantage.itemType == "enhancement" then
            local EnhancementManager = require("criblage/EnhancementManager")
            -- Determine enhancement type
            local enhancementType = "warp"
            if string.find(advantage.value, "planet") then
                enhancementType = "augment"
            elseif string.find(advantage.value, "spectral") then
                enhancementType = "warp"
            end
            
            local success = EnhancementManager:addEnhancement(advantage.value, enhancementType)
            if success then
                print("✨ Starting Advantage: " .. advantage.description)
                return true
            end
        end
        
    elseif advantage.type == "hand" then
        -- Store bonus for first blind
        if campaignState then
            campaignState.firstBlindHandBonus = advantage.value
            print("✨ Starting Advantage: " .. advantage.description)
            return true
        end
    end
    
    return false
end

-- Get description for UI display
function StartingAdvantage:getDescription(advantage)
    if not advantage then return "No advantage" end
    return advantage.description or "Unknown advantage"
end

return StartingAdvantage
