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
        score_penalty = 1.0
    }

    for _, warp in ipairs(self.warps) do
        if warp.id == "spectral_echo" then
            effects.retrigger = effects.retrigger + 1 -- Simple implementation
        elseif warp.id == "spectral_void" then
            effects.score_penalty = 0.75              -- Example
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
