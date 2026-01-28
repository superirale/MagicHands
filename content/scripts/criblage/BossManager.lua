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

    -- Actually we can probably just use standard io if allowed, or hardcode simple loading
    -- Let's try to load via strict mapping first if JSON isn't available

    if files and files.loadJSON then
        local data = files.loadJSON(path)
        if data then
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
