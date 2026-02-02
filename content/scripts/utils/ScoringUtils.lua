-- ScoringUtils.lua
-- Unified scoring logic for preview and actual play

local ScoringUtils = {}

--- Calculate the total score for a hand
--- @param selectedCards table Array of 4 (or more with infinity) cards from hand
--- @param cutCard table The cut card
--- @return table Detailed results including total, chips, mult, and side-effects
function ScoringUtils.calculateScore(selectedCards, cutCard)
    -- 1. Preparation
    local cardsForScoring = {}
    for _, c in ipairs(selectedCards) do table.insert(cardsForScoring, c) end
    if cutCard then table.insert(cardsForScoring, cutCard) end

    -- Convert to engine cards for C++ evaluate/score
    local engineCards = {}
    for _, c in ipairs(cardsForScoring) do
        if type(c) == "userdata" then
            table.insert(engineCards, c)
        else
            table.insert(engineCards, Card.new(c.rank, c.suit))
        end
    end

    -- 2. Resolve Rules & Bosses
    local bossRules = BossManager and BossManager:getEffects() or {}
    local warpEffects = EnhancementManager and EnhancementManager:resolveWarps() or {
        retrigger = 0,
        cut_bonus = 0,
        score_penalty = 1.0,
        score_multiplier = 1.0,
        mult_multiplier = 1.0,
        hand_cost = 0,
        score_to_gold_pct = 0,
        active_warps = {}
    }

    -- Add warp-specific rules for C++ engine
    if warpEffects.active_warps then
        for _, warpId in ipairs(warpEffects.active_warps) do
            if warpId == "warp_blaze" or warpId == "warp_mirror" or
                warpId == "warp_inversion" or warpId == "warp_wildfire" then
                table.insert(bossRules, warpId)
            end
        end
    end

    -- 3. Engine Evaluation
    local evaluateResult = cribbage.evaluate(engineCards)
    local baseScore = cribbage.score(engineCards, 0, 0, bossRules)

    -- 4. Enhancement Resolution (Pillars)
    local imprintEffects = EnhancementManager:resolveImprints(selectedCards, "on_score")
    local augmentEffects = EnhancementManager:resolveAugments(evaluateResult, engineCards)
    local jokerEffects = JokerManager:applyEffects(engineCards, "on_score")

    -- 5. Final Calculation
    local finalChips = baseScore.baseChips + augmentEffects.chips + jokerEffects.addedChips + imprintEffects.chips
    if warpEffects.cut_bonus > 0 then
        finalChips = finalChips + warpEffects.cut_bonus
    end

    local totalTempMult = baseScore.tempMultiplier + augmentEffects.mult + jokerEffects.addedTempMult +
    imprintEffects.mult
    local totalPermMult = baseScore.permMultiplier + jokerEffects.addedPermMult

    -- Apply Warp: Mult Multiplier (Ascension)
    if warpEffects.mult_multiplier > 1.0 then
        totalTempMult = totalTempMult * warpEffects.mult_multiplier
        totalPermMult = totalPermMult * warpEffects.mult_multiplier
    end

    local finalMult = (1 + totalTempMult + totalPermMult) * imprintEffects.x_mult
    local finalScore = math.floor(finalChips * finalMult)

    -- Apply Score Multipliers (Fortune, Gambit, etc) and Penalties (Void)
    local totalScoreMultiplier = warpEffects.score_penalty * warpEffects.score_multiplier
    if totalScoreMultiplier ~= 1.0 then
        finalScore = math.floor(finalScore * totalScoreMultiplier)
    end

    -- Apply Retrigger (Echo)
    if warpEffects.retrigger > 0 then
        finalScore = finalScore * (1 + warpEffects.retrigger)
    end

    return {
        total = finalScore,
        chips = finalChips,
        mult = finalMult,
        warpEffects = warpEffects, -- Returned for side-effects in GameScene
        imprintEffects = imprintEffects,
        breakdown = {
            baseChips = baseScore.baseChips,
            augmentChips = augmentEffects.chips,
            jokerChips = jokerEffects.addedChips,
            imprintChips = imprintEffects.chips,
            baseMult = baseScore.tempMultiplier + baseScore.permMultiplier,
            augmentMult = augmentEffects.mult,
            jokerMult = jokerEffects.addedTempMult + jokerEffects.addedPermMult,
            imprintMult = imprintEffects.mult,
            xMult = imprintEffects.x_mult
        },
        handResult = evaluateResult
    }
end

return ScoringUtils
