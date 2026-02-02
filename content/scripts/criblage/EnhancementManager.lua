-- EnhancementManager.lua
-- Manages inventory of non-Joker enhancements (Planets, Spectrals)

EnhancementManager = {
    augments = {}, -- List of {id="string", count=int}
    warps = {},    -- List of {id="string"}

    basePath = "content/data/enhancements/"
}

function EnhancementManager:init()
    self.augments = {}
    self.warps = {}
end

function EnhancementManager:addEnhancement(id, type)
    if type == "augment" or type == "planet" then
        for _, aug in ipairs(self.augments) do
            if aug.id == id then
                aug.count = aug.count + 1
                return true, "Upgraded " .. id
            end
        end
        table.insert(self.augments, { id = id, count = 1 })
        return true, "Added Augment " .. id
    elseif type == "warp" or type == "spectral" then
        -- Check duplicates for warps?
        for _, w in ipairs(self.warps) do
            if w.id == id then return false, "Warp already active" end
        end
        table.insert(self.warps, { id = id })
        return true, "Added Warp " .. id
    end
    return false, "Unknown type"
end

-- Resolve Augments (Planets)
-- Uses C++ Joker engine to calculate effects based on Hand Result
function EnhancementManager:resolveAugments(handResult, engineCards)
    local effects = { chips = 0, mult = 0 }

    if #self.augments == 0 then return effects end

    -- Build list of paths and counts (planets are stackable)
    local paths = {}
    local stackCounts = {}

    for _, aug in ipairs(self.augments) do
        table.insert(paths, self.basePath .. aug.id .. ".json")
        table.insert(stackCounts, aug.count)
    end

    -- Using the binding to evaluate effects with stack counts
    -- We pass "on_score" as trigger
    if #paths > 0 and engineCards then
        -- Note: joker.applyEffects returns { addedChips, addedTempMult, addedPermMult, ignoresCaps }
        local result = joker.applyEffects(paths, engineCards, "on_score", stackCounts)

        if result then
            effects.chips = result.addedChips
            effects.mult = result.addedTempMult + result.addedPermMult
        end
    end

    return effects
end

-- Resolve Warps (Spectrals)
-- Returns table of warp specific modifiers
function EnhancementManager:resolveWarps()
    local effects = {
        retrigger = 0,
        cut_bonus = 0,
        score_penalty = 1.0,
        score_multiplier = 1.0,
        mult_multiplier = 1.0,
        free_discard = false,
        hand_cost = 0,
        score_to_gold_pct = 0,
        active_warps = {} -- Store active warp IDs for complex logic
    }

    -- Load warp effects dynamically from JSON
    for _, warp in ipairs(self.warps) do
        -- Check if it's a sculptor spectral (they're in spectrals/ not warps/)
        local sculptors = {
            spectral_ascend = true,
            spectral_collapse = true,
            spectral_remove = true,
            spectral_clone = true,
            spectral_split = true,
            spectral_purge = true,
            spectral_rainbow = true,
            spectral_fusion = true
        }

        local path
        if sculptors[warp.id] then
            path = "content/data/spectrals/" .. warp.id .. ".json"
        else
            path = "content/data/warps/" .. warp.id .. ".json"
        end
        local data = files and files.loadJSON and files.loadJSON(path)

        if data and data.effect then
            table.insert(effects.active_warps, warp.id)

            -- Apply simple numeric effects from JSON
            if data.effect.retrigger then
                effects.retrigger = effects.retrigger + data.effect.retrigger
            end
            if data.effect.cut_bonus then
                effects.cut_bonus = effects.cut_bonus + data.effect.cut_bonus
            end
            if data.effect.score_penalty then
                effects.score_penalty = effects.score_penalty * data.effect.score_penalty
            end
            if data.effect.free_discard then
                effects.free_discard = true
            end

            -- Advanced warp effects (Lua-compatible)
            if data.effect.type == "double_mult" then
                -- warp_ascension: Double all mult
                effects.mult_multiplier = effects.mult_multiplier * 2.0
            elseif data.effect.type == "fortune" then
                -- warp_fortune: Score x1.5 but costs 5g per hand
                effects.score_multiplier = effects.score_multiplier * 1.5
                effects.hand_cost = effects.hand_cost + 5
            elseif data.effect.type == "gambit" then
                -- warp_gambit: 50% chance for 3x or 0.5x
                if math.random() < 0.5 then
                    effects.score_multiplier = effects.score_multiplier * 3.0
                else
                    effects.score_multiplier = effects.score_multiplier * 0.5
                end
            elseif data.effect.type == "score_to_gold" then
                -- warp_greed: 2% of score → gold
                effects.score_to_gold_pct = 0.02
                effects.score_penalty = effects.score_penalty * 0.95 -- Slightly less penalty for lower gain
            end

            -- Complex warps that need special handling (flagged for GameScene)
            -- These are marked in active_warps and handled in gameplay logic
            if data.effect.type == "blaze" or
                data.effect.type == "chaos_shuffle" or
                data.effect.type == "no_limit" or
                data.effect.type == "invert_values" or
                data.effect.type == "mirror_categories" or
                data.effect.type == "phantom" or
                data.effect.type == "crib_first" or
                data.effect.type == "wild_fives" then
                -- These warps require C++ or deep gameplay changes
                -- They are tracked in active_warps for GameScene to handle
            end
        else
            -- Fallback warning for missing JSON
            print("WARN: Warp " .. warp.id .. " JSON not found at " .. path)
        end
    end

    return effects
end

-- Resolve Imprints (Card specific)
-- @param cards: Array of card objects with .id and .imprints array
-- @param trigger: Event trigger (e.g., "on_score", "on_held")
-- @return effects table with chips, mult, x_mult, gold
function EnhancementManager:resolveImprints(cards, trigger)
    local effects = { chips = 0, mult = 0, x_mult = 1.0, gold = 0 }

    if not cards then
        return effects
    end

    -- Track loaded imprint definitions (cache)
    local imprintCache = {}

    -- For each card, check its imprints
    for _, card in ipairs(cards) do
        if card.imprints and #card.imprints > 0 then
            for _, imprintId in ipairs(card.imprints) do
                -- Load imprint definition if not cached
                if not imprintCache[imprintId] then
                    local path = "content/data/imprints/" .. imprintId .. ".json"
                    local data = files and files.loadJSON and files.loadJSON(path) or nil
                    if data then
                        imprintCache[imprintId] = data
                    else
                        LOG_WARN("Failed to load imprint: " .. imprintId)
                    end
                end

                -- Apply imprint effect if trigger matches
                local imprint = imprintCache[imprintId]
                if imprint and imprint.trigger == trigger then
                    local effect = imprint.effect

                    -- Check chance (for lucky_pips type effects)
                    local shouldApply = true
                    if imprint.chance then
                        shouldApply = (math.random() < imprint.chance)
                    end

                    if shouldApply and effect then
                        -- Apply effects
                        if effect.chips then
                            effects.chips = effects.chips + effect.chips
                        end
                        if effect.mult then
                            effects.mult = effects.mult + effect.mult
                        end
                        if effect.x_mult then
                            effects.x_mult = effects.x_mult * effect.x_mult
                        end
                        if effect.gold then
                            effects.gold = effects.gold + effect.gold
                        end
                    end
                end
            end
        end
    end

    return effects
end

return EnhancementManager
