-- AutoPlayStrategies.lua
-- AI decision-making strategies for QA bot

local AutoPlayStrategies = {}

-- Helper function to check if table contains value
local function table_contains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

-- Get strategy by name
function AutoPlayStrategies:getStrategy(name)
    if name == "Random" then
        return self.Random
    elseif name == "FifteenEngine" then
        return self.FifteenEngine
    elseif name == "PairExplosion" then
        return self.PairExplosion
    elseif name == "Optimal" then
        return self.Optimal
    else
        print("WARNING: Unknown strategy '" .. name .. "', defaulting to Random")
        return self.Random
    end
end

-- ===========================================
-- Strategy 1: Random (Baseline)
-- ===========================================
AutoPlayStrategies.Random = {
    name = "Random",
    
    selectCardsForCrib = function(self, hand)
        if not hand or #hand < 2 then return {} end
        
        local indices = {}
        local attempts = 0
        while #indices < 2 and attempts < 100 do
            local idx = math.random(1, #hand)
            if not table_contains(indices, idx) then
                table.insert(indices, idx)
            end
            attempts = attempts + 1
        end
        return indices
    end,
    
    selectCardsToPlay = function(self, hand)
        if not hand or #hand < 4 then
            -- Return all available cards
            local all = {}
            for i = 1, #hand do
                table.insert(all, i)
            end
            return all
        end
        
        local indices = {}
        local attempts = 0
        while #indices < math.min(4, #hand) and attempts < 100 do
            local idx = math.random(1, #hand)
            if not table_contains(indices, idx) then
                table.insert(indices, idx)
            end
            attempts = attempts + 1
        end
        return indices
    end,
    
    selectShopItem = function(self, shopItems, gold)
        if not shopItems or #shopItems == 0 then return nil end
        
        -- Find affordable items
        local affordable = {}
        for i, item in ipairs(shopItems) do
            if item.cost and item.cost <= gold then
                table.insert(affordable, i)
            end
        end
        
        if #affordable == 0 then return nil end
        return affordable[math.random(1, #affordable)]
    end,
    
    shouldReroll = function(self, gold, shopItems)
        return math.random() < 0.2 and gold >= 5
    end,
    
    shouldSellJoker = function(self, jokers)
        return false  -- Never sell randomly
    end
}

-- ===========================================
-- Strategy 2: Fifteen Engine (Rule-Based)
-- ===========================================
AutoPlayStrategies.FifteenEngine = {
    name = "FifteenEngine",
    
    selectCardsForCrib = function(self, hand)
        if not hand or #hand < 2 then return {} end
        
        -- Prefer 5s and 10-value cards for crib (good for fifteens)
        local good_for_fifteen = {}
        for i, card in ipairs(hand) do
            if card.rank == "5" or card.rank == "10" or 
               card.rank == "J" or card.rank == "Q" or card.rank == "K" then
                table.insert(good_for_fifteen, i)
            end
        end
        
        -- Take first 2 good cards
        if #good_for_fifteen >= 2 then
            return {good_for_fifteen[1], good_for_fifteen[2]}
        end
        
        -- Fall back to random if not enough good cards
        return AutoPlayStrategies.Random:selectCardsForCrib(hand)
    end,
    
    selectCardsToPlay = function(self, hand)
        -- For now, just play all available cards
        -- TODO: Implement fifteen detection logic
        local all = {}
        for i = 1, math.min(4, #hand) do
            table.insert(all, i)
        end
        return all
    end,
    
    selectShopItem = function(self, shopItems, gold)
        if not shopItems or #shopItems == 0 then return nil end
        
        -- Prefer jokers/planets that boost fifteens
        for i, item in ipairs(shopItems) do
            if item.cost and item.cost <= gold then
                local name = string.lower(item.name or "")
                if string.match(name, "fifteen") or string.match(name, "15") then
                    return i
                end
            end
        end
        
        -- Fall back to random affordable item
        return AutoPlayStrategies.Random:selectShopItem(shopItems, gold)
    end,
    
    shouldReroll = function(self, gold, shopItems)
        if gold < 5 then return false end
        
        -- Reroll if no fifteen-related items
        for _, item in ipairs(shopItems or {}) do
            local name = string.lower(item.name or "")
            if string.match(name, "fifteen") then
                return false
            end
        end
        return true
    end,
    
    shouldSellJoker = function(self, jokers)
        return false
    end
}

-- ===========================================
-- Strategy 4: Optimal (Mathematical)
-- ===========================================
AutoPlayStrategies.Optimal = {
    name = "Optimal",
    
    selectCardsForCrib = function(self, hand)
        if not hand or #hand < 6 then 
            return AutoPlayStrategies.Random:selectCardsForCrib(hand)
        end
        
        -- Try all 15 combinations of 2 cards to discard from 6
        -- C(6,2) = 15 combinations - very fast
        local bestScore = -999
        local bestIndices = {1, 2}
        
        for i = 1, 5 do
            for j = i + 1, 6 do
                -- Build remaining 4-card hand (excluding i and j)
                local remainingHand = {}
                for k = 1, 6 do
                    if k ~= i and k ~= j then
                        table.insert(remainingHand, hand[k])
                    end
                end
                
                -- Quick evaluate (simplified scoring)
                local score = self:quickEvaluate(remainingHand)
                
                if score > bestScore then
                    bestScore = score
                    bestIndices = {i, j}
                end
            end
        end
        
        return bestIndices
    end,
    
    quickEvaluate = function(self, cards)
        if not cards or #cards < 4 then return 0 end
        
        local score = 0
        
        -- Count pairs (most important for cribbage)
        local ranks = {}
        for _, card in ipairs(cards) do
            ranks[card.rank] = (ranks[card.rank] or 0) + 1
        end
        for _, count in pairs(ranks) do
            if count == 2 then score = score + 2 end
            if count == 3 then score = score + 6 end
            if count == 4 then score = score + 12 end
        end
        
        -- Count potential fifteens (most common combinations)
        local values = {}
        for _, card in ipairs(cards) do
            local val = tonumber(card.rank) or 
                       (card.rank == "A" and 1) or
                       10  -- J,Q,K are all 10
            table.insert(values, val)
        end
        
        -- Check all 2-card fifteens (C(4,2) = 6 combinations)
        for i = 1, 3 do
            for j = i + 1, 4 do
                if values[i] + values[j] == 15 then
                    score = score + 2
                end
            end
        end
        
        -- Check 3-card fifteens (C(4,3) = 4 combinations)
        for i = 1, 2 do
            for j = i + 1, 3 do
                for k = j + 1, 4 do
                    if values[i] + values[j] + values[k] == 15 then
                        score = score + 2
                    end
                end
            end
        end
        
        -- Check 4-card fifteen
        if values[1] + values[2] + values[3] + values[4] == 15 then
            score = score + 2
        end
        
        return score
    end,
    
    selectCardsToPlay = function(self, hand)
        -- Always play all 4 cards (no choice in this game)
        local all = {}
        for i = 1, math.min(4, #hand) do
            table.insert(all, i)
        end
        return all
    end,
    
    selectShopItem = function(self, shopItems, gold)
        if not shopItems or #shopItems == 0 then return nil end
        
        -- Buy the first affordable item
        -- TODO: Implement value calculation
        for i, item in ipairs(shopItems) do
            if item.price and item.price <= gold then
                return i
            end
        end
        
        return nil
    end,
    
    shouldReroll = function(self, gold, shopItems)
        -- Don't reroll, we'll buy anything affordable
        return false
    end,
    
    shouldSellJoker = function(self, jokers)
        return false
    end
}

return AutoPlayStrategies
