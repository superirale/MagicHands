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

    -- Build list of paths
    local paths = {}
    for _, aug in ipairs(self.augments) do
        for i = 1, aug.count do
            table.insert(paths, self.basePath .. aug.id .. ".json")
        end
    end

    -- Using the binding to evaluate effects
    -- We pass "on_score" as trigger
    if #paths > 0 and engineCards then
        -- Note: joker.applyEffects returns { addedChips, addedTempMult, addedPermMult, ignoresCaps }
        local result = joker.applyEffects(paths, engineCards, "on_score")

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
function EnhancementManager:resolveImprints(cards, trigger)
    local effects = { chips = 0, mult = 0, x_mult = 1, gold = 0 }
    -- Stub for Phase 3
    return effects
end

return EnhancementManager
