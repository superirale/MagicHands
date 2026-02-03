-- Boss Manager System
local BossManager = {
    bosses = {},
    activeBoss = nil
}

function BossManager:init()
    self.activeBoss = nil
    self.bosses = {}
    -- In a real engine we'd list files, for now we hardcode the known IDs
    self.knownBosses = {
        "the_counter", "the_skunk", "thirty_one", "the_dealer",
        "the_purist", "the_auditor", "the_breaker", "the_collapser",
        "the_drain", "the_minimalist_boss", "the_tyrant", "the_wall"
    }
end

function BossManager:loadBoss(bossId)
    local path = "content/data/bosses/" .. bossId .. ".json"

    if files and files.loadJSON then
        local data = files.loadJSON(path)
        if data then
            -- Wrap in simplified format if it's missing effects array (for Lua side)
            if not data.effects and data.effect then
                data.effects = { data.effect }
            end
            return data
        end
        print("ERROR: Failed to load boss JSON: " .. path)
    end

    -- Fallback for tests if filesystem not ready
    local boss = nil
    if bossId == "the_counter" then
        boss = { id = "the_counter", name = "The Counter", description = "Fifteens score 0", effects = { "fifteens_disabled" } }
    elseif bossId == "the_skunk" then
        boss = { id = "the_skunk", name = "The Skunk", description = "Multipliers disabled", effects = { "multipliers_disabled" } }
    elseif bossId == "thirty_one" then
        boss = { id = "thirty_one", name = "Thirty-One", description = "Only pairs/runs score", effects = { "fifteens_disabled", "flush_disabled", "nobs_disabled" } }
    elseif bossId == "the_dealer" then
        boss = { id = "the_dealer", name = "The Dealer", description = "-100 chips per discard", effects = { "discard_penalty" } }
    elseif bossId == "the_purist" then
        boss = { id = "the_purist", name = "The Purist", description = "Rule Warps disabled", effects = { "warps_disabled" } }
    elseif bossId == "the_auditor" then
        boss = { id = "the_auditor", name = "The Auditor", description = "Hand Augments halved", effects = { "halve_augments" } }
    elseif bossId == "the_breaker" then
        boss = { id = "the_breaker", name = "The Breaker", description = "Imprinted cards shatter", effects = { "imprint_shatter" } }
    elseif bossId == "the_collapser" then
        boss = { id = "the_collapser", name = "The Collapser", description = "Duplicate Jokers increase Blind scaling", effects = { "stack_scaling" } }
    elseif bossId == "the_drain" then
        boss = { id = "the_drain", name = "The Drain", description = "Lose 2g per hand played", effects = { "gold_drain" } }
    elseif bossId == "the_minimalist_boss" then
        boss = { id = "the_minimalist_boss", name = "The Minimalist", description = "Hand size reduced by 1", effects = { "hand_size_reduced" } }
    elseif bossId == "the_tyrant" then
        boss = { id = "the_tyrant", name = "The Tyrant", description = "Jokers disabled", effects = { "jokers_disabled" } }
    elseif bossId == "the_wall" then
        boss = { id = "the_wall", name = "The Wall", description = "Required score x1.5", effects = { "scale_blind" } }
    end

    return boss
end

function BossManager:selectBossForAct(act)
    -- Simple selection logic:
    -- Act 1: Simpler bosses
    -- Act 2+: Complex counter-bosses
    local candidates = {}
    if act == 1 then
        candidates = { "the_counter", "the_skunk", "the_dealer", "the_drain", "the_minimalist_boss" }
    else
        candidates = { "the_purist", "the_auditor", "the_breaker", "the_collapser", "the_tyrant", "the_wall",
            "thirty_one" }
    end

    local selectedId = candidates[math.random(#candidates)]
    self:activateBoss(selectedId)
    return self.activeBoss
end

function BossManager:activateBoss(bossId)
    self.activeBoss = self:loadBoss(bossId)
    if self.activeBoss then
        print("Activated Boss: " .. self.activeBoss.name)
    end
end

function BossManager:clearBoss()
    self.activeBoss = nil
end

function BossManager:getEffects()
    if self.activeBoss and self.activeBoss.effects then
        return self.activeBoss.effects
    end
    return {}
end

-- Deprecated: C++ handles this now
function BossManager:applyRules(scoreResult, context)
    return scoreResult
end

return BossManager
