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
        flush = { chips = 10, mult = 0.2 },
        nobs = { chips = 10, mult = 0.5 },
        three_kind = { chips = 20, mult = 0.3 }
    },

    imprintDefinitions = {
        gold_inlay = { gold = 3 },
        lucky_pips = { mult = 20, gold = 20, chance = 0.2 },
        steel_plating = { x_mult = 1.5, trigger = "on_held" }
    },

    warpDefinitions = {
        spectral_ghost = { cut_bonus = 20 },
        spectral_echo = { retrigger = 1 },
        spectral_void = { free_discard = true, score_penalty = 0.9 }
    }
}

function EnhancementManager:init()
    self.augments = {}
    self.warps = {}
    self.imprints = {}
end

-- Imprints (Card Mods)
function EnhancementManager:imprintCard(card, imprintId)
    -- Card must have a unique ID mechanism.
    -- For MVP, we'll hash rank/suit if UUID missing (limited persistence)
    -- But ideal is unique ID. We'll fallback to rank_suit for now.
    local id = card.id or (card.rank .. "_" .. card.suit)
    self.imprints[id] = imprintId
    return true, "Imprinted " .. imprintId
end

function EnhancementManager:getImprint(card)
    if not card or not card.rank or not card.suit then return nil end
    local id = card.id or (card.rank .. "_" .. card.suit)
    return self.imprints[id]
end

function EnhancementManager:resolveImprints(cards, context)
    local bonus = { chips = 0, mult = 0, x_mult = 1, gold = 0 }

    for _, card in ipairs(cards) do
        local imprintId = self:getImprint(card)
        if imprintId then
            local def = self.imprintDefinitions[imprintId]
            if def then
                -- Check context triggers
                local valid = false
                if context == "score" and (not def.trigger or def.trigger == "on_score") then valid = true end
                if context == "held" and def.trigger == "on_held" then valid = true end

                if valid then
                    -- Handle Chance
                    if def.chance and math.random() > def.chance then
                        valid = false
                    end
                end

                if valid then
                    if def.chips then bonus.chips = bonus.chips + def.chips end
                    if def.mult then bonus.mult = bonus.mult + def.mult end
                    if def.x_mult then bonus.x_mult = bonus.x_mult * def.x_mult end
                    if def.gold then bonus.gold = bonus.gold + def.gold end
                end
            end
        end
    end

    return bonus
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

    if handResult.flushCount and handResult.flushCount >= 4 then
        apply("flush", 1)
    end

    if handResult.hasNobs then apply("nobs", 1) end
    -- Three of a Kind check (depends on handResult structure, assuming similar to pairs)
    if handResult.threeKind then apply("three_kind", 1) end

    return bonus
end

-- Rule Warps (Spectral-like)
function EnhancementManager:addWarp(warpId)
    if #self.warps >= 3 then
        return false, "Max warps active (3/3)"
    end

    for _, w in ipairs(self.warps) do
        if w == warpId then return false, "Warp already active" end
    end

    table.insert(self.warps, warpId)
    return true, "Reality Warped: " .. warpId
end

function EnhancementManager:resolveWarps()
    local effects = {
        cut_bonus = 0,
        retrigger = 0,
        free_discard = false,
        score_penalty = 1.0
    }

    for _, warpId in ipairs(self.warps) do
        local def = self.warpDefinitions[warpId]
        if def then
            if def.cut_bonus then effects.cut_bonus = effects.cut_bonus + def.cut_bonus end
            if def.retrigger then effects.retrigger = effects.retrigger + def.retrigger end
            if def.free_discard then effects.free_discard = true end
            if def.score_penalty then effects.score_penalty = effects.score_penalty * def.score_penalty end
        end
    end

    return effects
end

return EnhancementManager
