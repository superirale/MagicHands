-- Enhancement Manager
-- Handles Hand Augments, Rule Warps, and Card Imprints (Pillar 3)

local EnhancementManager = {
    augments = {}, -- { category = "pairs", level = 1 }
    warps = {},    -- List of active warp IDs
    imprints = {}, -- map[card_unique_id] -> { imprint_id, ... }

    -- Definitions cache (Mocked for MVP until JSON loader bound)
    definitions = {
        pairs = { chips = 5, mult = 0.1 },
        runs = { chips = 8, mult = 0.1 },
        fifteens = { chips = 5, mult = 0.2 },
        flush = { chips = 10, mult = 0.2 }
    }
}

function EnhancementManager:init()
    self.augments = {}
    self.warps = {}
    self.imprints = {}
end

-- Hand Augments (Planet-like)
function EnhancementManager:addAugment(category)
    if not self.augments[category] then
        self.augments[category] = 0
    end
    self.augments[category] = self.augments[category] + 1
    return true, "Level Up! " .. category
end

function EnhancementManager:resolveAugments(handResult)
    local bonus = { chips = 0, mult = 0 }

    -- Iterate over known categories in handResult
    -- handResult keys: pairs, runs, fifteens, flushCount, hasNobs

    -- Helper to apply bonus
    local function apply(catName, count)
        if count > 0 and self.augments[catName] then
            local level = self.augments[catName]
            local def = self.definitions[catName]
            if def then
                bonus.chips = bonus.chips + (level * def.chips)
                bonus.mult = bonus.mult + (level * def.mult)
            end
        end
    end

    if handResult.pairs then apply("pairs", #handResult.pairs) end
    if handResult.runs then apply("runs", #handResult.runs) end
    if handResult.fifteens then apply("fifteens", #handResult.fifteens) end

    -- Flush special case (count is integer, not list)
    if handResult.flushCount and handResult.flushCount >= 4 then
        apply("flush", 1)
    end

    return bonus
end

-- Rule Warps (Spectral-like)
function EnhancementManager:addWarp(warpId)
    -- Check max 3 active
    if #self.warps >= 3 then
        return false, "Max warps active"
    end
    table.insert(self.warps, warpId)
    return true
end

function EnhancementManager:resolveWarps()
    -- Return global rule modifiers
    -- e.g. { all_fives_wild = true }
    return {}
end

return EnhancementManager
