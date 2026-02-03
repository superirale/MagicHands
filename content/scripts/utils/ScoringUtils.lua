-- ScoringUtils.lua
-- Unified scoring logic for preview and actual play

local ScoringUtils = {}

local BossManager = require("criblage/BossManager")
local EnhancementManager = require("criblage/EnhancementManager")
local JokerManager = require("criblage/JokerManager")

--- Calculate the total score for a hand
--- @param selectedCards table Array of 4 (or more with infinity) cards from hand
--- @param cutCard table The cut card
--- @param deterministic boolean If true, returns average values for random effects
--- @return table Detailed results including total, chips, mult, and side-effects
function ScoringUtils.calculateScore(selectedCards, cutCard, deterministic)
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
            local newCard = Card.new(c.rank, c.suit)
            if newCard then
                table.insert(engineCards, newCard)
            end
        end
    end

    -- 2. Resolve Rules & Bosses
    -- 2. Resolve Rules, Bosses & Warps
    local activeBossEffects = BossManager and BossManager:getEffects() or {}
    local bossRules = {}
    for _, rule in ipairs(activeBossEffects) do table.insert(bossRules, rule) end

    -- GDD: The Purist disables Rule Warps
    local warpsDisabled = false
    for _, rule in ipairs(bossRules) do
        if rule == "warps_disabled" then
            warpsDisabled = true
            break
        end
    end

    local warpEffects = {
        retrigger = 0,
        cut_bonus = 0,
        score_penalty = 1.0,
        score_multiplier = 1.0,
        mult_multiplier = 1.0,
        hand_cost = 0,
        score_to_gold_pct = 0,
        active_warps = {}
    }

    if not warpsDisabled and EnhancementManager then
        warpEffects = EnhancementManager:resolveWarps(deterministic)
    elseif warpsDisabled then
        print("THE PURIST: Rule Warps are disabled!")
    end

    -- Add warp-specific rules for C++ engine
    if warpEffects.active_warps then
        for _, warpId in ipairs(warpEffects.active_warps) do
            if warpId == "warp_blaze" or warpId == "warp_mirror" or
                warpId == "warp_inversion" or warpId == "warp_wildfire" then
                table.insert(bossRules, warpId)
            end
        end
    end

    -- 3. Engine Evaluation (Base)
    local evaluateResult = cribbage.evaluate(engineCards)
    -- We pass empty rules for base score, then apply refinements
    local baseScore = cribbage.score(engineCards, 0, 0, {})

    -- GDD SECTION 4: GLOBAL RESOLUTION ORDER

    -- 1. Card Imprints (Individual card effects)
    local imprintEffects = EnhancementManager:resolveImprints(selectedCards, "on_score", deterministic)

    -- 2. Hand Augments (Category upgrades like planets)
    local augmentEffects = EnhancementManager:resolveAugments(evaluateResult, engineCards)

    -- 3. Rule Warps (Systemic shifts) - Already resolved in Step 2 as warpEffects

    -- 4. Jokers & Set Bonuses (Slot-based modifiers)
    local jokersDisabled = false
    for _, rule in ipairs(bossRules) do
        if rule == "jokers_disabled" then
            jokersDisabled = true
            break
        end
    end

    local jokerEffects = {
        addedChips = 0,
        addedTempMult = 0,
        addedPermMult = 0,
        ignoresCaps = false
    }

    if not jokersDisabled then
        jokerEffects = JokerManager:applyEffects(engineCards, "on_score")
    elseif jokersDisabled then
        print("THE TYRANT: Jokers are disabled!")
    end

    -- 5. Boss Modifiers (Late-stage counters)
    local bossEffects = {
        chips_multiplier = 1.0,
        mult_multiplier = 1.0,
        flat_chips_bonus = 0
    }

    local activeBossEffects = BossManager and BossManager:getEffects() or {}
    for _, effectId in ipairs(activeBossEffects) do
        -- Future implementation of boss logic:
        if effectId == "halve_augments" or effectId == "the_auditor" then
            augmentEffects.chips = augmentEffects.chips * 0.5
            augmentEffects.mult = augmentEffects.mult * 0.5
        end
    end

    -- 6. Final Calculation (Summation & Clamps)

    -- Chips Calculation
    local finalChips = baseScore.baseChips
    finalChips = finalChips + imprintEffects.chips -- Step 1
    finalChips = finalChips + augmentEffects.chips -- Step 2

    -- Apply Warp Chip Adjustments (Step 3)
    if warpEffects.cut_bonus > 0 then
        finalChips = finalChips + warpEffects.cut_bonus
    end

    finalChips = finalChips + jokerEffects.addedChips -- Step 4

    -- Apply Boss Chip Multipliers (Step 5)
    finalChips = finalChips * bossEffects.chips_multiplier

    -- Multiplier Calculation
    local totalTempMult = baseScore.tempMultiplier
    local totalPermMult = baseScore.permMultiplier

    totalTempMult = totalTempMult + imprintEffects.mult -- Step 1
    totalTempMult = totalTempMult + augmentEffects.mult -- Step 2

    -- Apply Warp Multiplier Modifiers (Step 3)
    if warpEffects.mult_multiplier > 1.0 then
        totalTempMult = totalTempMult * warpEffects.mult_multiplier
        totalPermMult = totalPermMult * warpEffects.mult_multiplier
    end

    totalTempMult = totalTempMult + jokerEffects.addedTempMult -- Step 4
    totalPermMult = totalPermMult + jokerEffects.addedPermMult

    -- Final Score Assembly
    local finalMult = (1 + totalTempMult + totalPermMult) * imprintEffects.x_mult
    local finalScore = math.floor(finalChips * finalMult)

    -- Final Systemic Adjustments (Warps again often override final score)
    local totalScoreMultiplier = warpEffects.score_penalty * warpEffects.score_multiplier
    if totalScoreMultiplier ~= 1.0 then
        finalScore = math.floor(finalScore * totalScoreMultiplier)
    end

    -- Apply Retrigger (Echo Warp)
    if warpEffects.retrigger > 0 then
        finalScore = finalScore * (1 + warpEffects.retrigger)
    end

    return {
        total = finalScore,
        chips = finalChips,
        mult = finalMult,
        warpEffects = warpEffects,
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
