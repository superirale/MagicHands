-- AutoPlayStats.lua
-- Comprehensive statistics tracking for QA bot runs

local AutoPlayStats = {}

function AutoPlayStats:init()
    self.currentRun = {
        runId = nil,
        startTime = os.time(),
        endTime = nil,
        durationSeconds = 0,
        strategy = nil,
        
        -- Outcome
        outcome = "in_progress",  -- "win", "loss", "crash"
        actReached = 1,
        blindReached = 1,  -- 1=small, 2=big, 3=boss
        finalScore = 0,
        
        -- Basic stats
        handsPlayed = 0,
        discardsUsed = 0,
        goldEarned = 0,
        goldSpent = 0,
        rerollsUsed = 0,
        
        -- Collections
        jokersAcquired = {},
        jokersStacked = {},
        jokersMaxTier = {},
        planetsAcquired = {},
        warpsActive = {},
        imprintsApplied = {},
        sculptorsUsed = {},
        
        -- Hand scoring history
        handScores = {},        -- [{handNum, score, breakdown, timestamp}]
        cribScores = {},        -- [{blindNum, score, timestamp}]
        bestHandScore = 0,
        worstHandScore = 999999,
        averageHandScore = 0,
        
        -- Boss encounters
        bossesEncountered = {},
        bossesFaced = {},
        bossesDefeated = {},
        
        -- Achievements (if tracked)
        achievementsUnlocked = {},
        
        -- Errors (will be merged from AutoPlayErrors)
        errors = {},
        warnings = {},
        logicErrors = {},
        
        -- Performance
        frameTimesMs = {},
        avgFrameTime = 0,
        maxFrameTime = 0,
        minFrameTime = 999999,
        
        -- Decisions (comprehensive tracking)
        decisions = {}  -- [{type, timestamp, options, selected, reasoning}]
    }
end

-- Record a hand being scored
function AutoPlayStats:recordHandScored(handNum, score, breakdown)
    -- If handNum not provided, increment from current count
    if not handNum or handNum <= self.currentRun.handsPlayed then
        self.currentRun.handsPlayed = self.currentRun.handsPlayed + 1
        handNum = self.currentRun.handsPlayed
    else
        self.currentRun.handsPlayed = handNum
    end
    
    -- Ensure score is a number
    score = tonumber(score) or 0
    
    local record = {
        handNum = handNum,
        score = score,
        breakdown = breakdown or {},
        timestamp = os.time()
    }
    
    table.insert(self.currentRun.handScores, record)
    
    -- Update best/worst
    if score > self.currentRun.bestHandScore then
        self.currentRun.bestHandScore = score
    end
    if score < self.currentRun.worstHandScore and score > 0 then
        self.currentRun.worstHandScore = score
    end
end

-- Record crib scoring
function AutoPlayStats:recordCribScored(blindNum, score)
    local record = {
        blindNum = blindNum,
        score = score,
        timestamp = os.time()
    }
    
    table.insert(self.currentRun.cribScores, record)
end

-- Record a decision made by the bot
function AutoPlayStats:recordDecision(decisionType, options, selected, reasoning)
    local record = {
        type = decisionType,
        timestamp = os.time(),
        options = options or {},
        selected = selected,
        reasoning = reasoning or "none"
    }
    
    table.insert(self.currentRun.decisions, record)
end

-- Record joker acquisition
function AutoPlayStats:recordJokerAcquired(jokerId, cost)
    table.insert(self.currentRun.jokersAcquired, jokerId)
    
    if cost then
        self.currentRun.goldSpent = self.currentRun.goldSpent + cost
    end
end

-- Record joker stacking
function AutoPlayStats:recordJokerStacked(jokerId, newStack)
    self.currentRun.jokersStacked[jokerId] = newStack
    
    -- Track max tier
    if not self.currentRun.jokersMaxTier[jokerId] or 
       newStack > self.currentRun.jokersMaxTier[jokerId] then
        self.currentRun.jokersMaxTier[jokerId] = newStack
    end
end

-- Record planet acquisition
function AutoPlayStats:recordPlanetAcquired(planetId, cost)
    table.insert(self.currentRun.planetsAcquired, planetId)
    
    if cost then
        self.currentRun.goldSpent = self.currentRun.goldSpent + cost
    end
end

-- Record warp activation
function AutoPlayStats:recordWarpActivated(warpId)
    table.insert(self.currentRun.warpsActive, warpId)
end

-- Record imprint application
function AutoPlayStats:recordImprintApplied(cardId, imprintId)
    table.insert(self.currentRun.imprintsApplied, {
        cardId = cardId,
        imprintId = imprintId,
        timestamp = os.time()
    })
end

-- Record sculptor use
function AutoPlayStats:recordSculptorUsed(sculptorId)
    table.insert(self.currentRun.sculptorsUsed, sculptorId)
end

-- Record boss encounter
function AutoPlayStats:recordBossEncountered(bossId, act)
    table.insert(self.currentRun.bossesEncountered, {
        bossId = bossId,
        act = act,
        timestamp = os.time()
    })
end

-- Record boss defeated
function AutoPlayStats:recordBossDefeated(bossId)
    table.insert(self.currentRun.bossesDefeated, bossId)
end

-- Record gold earned
function AutoPlayStats:recordGoldEarned(amount)
    self.currentRun.goldEarned = self.currentRun.goldEarned + amount
end

-- Record gold spent
function AutoPlayStats:recordGoldSpent(amount)
    self.currentRun.goldSpent = self.currentRun.goldSpent + amount
end

-- Record discard used
function AutoPlayStats:recordDiscardUsed()
    self.currentRun.discardsUsed = self.currentRun.discardsUsed + 1
end

-- Record reroll
function AutoPlayStats:recordReroll()
    self.currentRun.rerollsUsed = self.currentRun.rerollsUsed + 1
end

-- Record frame time for performance tracking
function AutoPlayStats:recordFrameTime(deltaMs)
    table.insert(self.currentRun.frameTimesMs, deltaMs)
    
    if deltaMs > self.currentRun.maxFrameTime then
        self.currentRun.maxFrameTime = deltaMs
    end
    if deltaMs < self.currentRun.minFrameTime then
        self.currentRun.minFrameTime = deltaMs
    end
end

-- Record achievement unlock
function AutoPlayStats:recordAchievement(achievementId)
    table.insert(self.currentRun.achievementsUnlocked, {
        id = achievementId,
        timestamp = os.time()
    })
end

-- Finalize run and calculate averages
function AutoPlayStats:finalize(outcome, actReached, blindReached, finalScore)
    self.currentRun.outcome = outcome
    self.currentRun.endTime = os.time()
    self.currentRun.durationSeconds = self.currentRun.endTime - self.currentRun.startTime
    self.currentRun.actReached = actReached or 1
    self.currentRun.blindReached = blindReached or 1
    self.currentRun.finalScore = finalScore or 0
    
    -- Calculate average hand score
    if #self.currentRun.handScores > 0 then
        local totalScore = 0
        for _, hand in ipairs(self.currentRun.handScores) do
            totalScore = totalScore + hand.score
        end
        self.currentRun.averageHandScore = totalScore / #self.currentRun.handScores
    end
    
    -- Calculate average frame time
    if #self.currentRun.frameTimesMs > 0 then
        local sum = 0
        for _, ft in ipairs(self.currentRun.frameTimesMs) do
            sum = sum + ft
        end
        self.currentRun.avgFrameTime = sum / #self.currentRun.frameTimesMs
    end
    
    return self.currentRun
end

-- Convert run data to JSON-compatible table
function AutoPlayStats:toJSON()
    -- Return a copy of currentRun with simple types only
    local data = {}
    
    for k, v in pairs(self.currentRun) do
        -- Skip frameTimesMs array (too large for JSON)
        if k ~= "frameTimesMs" then
            data[k] = v
        end
    end
    
    return data
end

-- Reset for new run
function AutoPlayStats:reset()
    self:init()
end

return AutoPlayStats
