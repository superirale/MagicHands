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
        "the_counter", "the_skunk",
        "thirty_one", "the_dealer"
    }
end

function BossManager:loadBoss(bossId)
    local path = "content/data/bosses/" .. bossId .. ".json"
    -- Mock loading for now since we don't have a JSON loader exposed to Lua yet?
    -- Actually we can probably just use standard io if allowed, or hardcode simple loading
    -- Let's try to load via strict mapping first if JSON isn't available

    -- For now, manual loading until JSON binding
    local boss = nil
    if bossId == "the_counter" then
        boss = { id = "the_counter", name = "The Counter", description = "Fifteens score 0", effects = { "fifteens_disabled" } }
    elseif bossId == "the_skunk" then
        boss = { id = "the_skunk", name = "The Skunk", description = "Multipliers disabled", effects = { "multipliers_disabled" } }
    elseif bossId == "thirty_one" then
        boss = { id = "thirty_one", name = "Thirty-One", description = "Only pairs/runs score", effects = { "fifteens_disabled", "flush_disabled", "nobs_disabled" } }
    elseif bossId == "the_dealer" then
        boss = { id = "the_dealer", name = "The Dealer", description = "-100 chips per discard", effects = { "discard_penalty" } }
    end

    return boss
end

function BossManager:selectBossForAct(act)
    -- Simple selection:
    -- Act 1: counter or skunk
    -- Act 2: thirty_one or dealer
    local candidates = {}
    if act == 1 then
        candidates = { "the_counter", "the_skunk" }
    elseif act == 2 then
        candidates = { "thirty_one", "the_dealer" }
    else
        candidates = { "the_counter" } -- Fallback
    end

    local selectedId = candidates[math.random(#candidates)]
    self.activeBoss = self:loadBoss(selectedId)
    return self.activeBoss
end

function BossManager:activateBoss(bossId)
    self.activeBoss = self:loadBoss(bossId)
end

function BossManager:clearBoss()
    self.activeBoss = nil
end

function BossManager:applyRules(scoreResult, context)
    if not self.activeBoss then return scoreResult end

    for _, effect in ipairs(self.activeBoss.effects) do
        if effect == "fifteens_disabled" then
            scoreResult.fifteenChips = 0
        elseif effect == "disable_mult" then
            scoreResult.tempMultiplier = 0
            scoreResult.permMultiplier = 0
        elseif effect == "only_pairs_runs" then
            scoreResult.fifteenChips = 0
            scoreResult.flushChips = 0
            scoreResult.nobsChips = 0
        end
    end

    -- Recalculate base chips
    scoreResult.baseChips = (scoreResult.fifteenChips or 0) +
        (scoreResult.pairChips or 0) +
        (scoreResult.runChips or 0) +
        (scoreResult.flushChips or 0) +
        (scoreResult.nobsChips or 0)

    -- Handle The Drain (Discard Penalty handled in discard flow, not scoring flow)
    -- But we need to support it if context is 'discard'
    if context == "discard" and effect == "gold_penalty" then
        local Economy = require("criblage/Economy")
        Economy:spend(rule.value)
        -- We won't block discard here, but player loses gold
    end

    return scoreResult
end

return BossManager
