-- ScorePreview.lua
-- Shows potential score before playing hand

local ScorePreview = {}

function ScorePreview.calculate(selectedCards, cutCard)
    if #selectedCards ~= 4 or not cutCard then
        return nil
    end
    
    -- Create card list with cut card
    local cards = {}
    for _, c in ipairs(selectedCards) do
        table.insert(cards, c)
    end
    table.insert(cards, cutCard)
    
    -- Convert to engine cards
    local engineCards = {}
    for _, c in ipairs(cards) do
        if type(c) == "userdata" then
            table.insert(engineCards, c)
        else
            table.insert(engineCards, Card.new(c.rank, c.suit))
        end
    end
    
    -- Get boss rules
    local bossRules = BossManager and BossManager:getEffects() or nil
    
    -- Evaluate hand
    local handResult = cribbage.evaluate(engineCards)
    local score = cribbage.score(engineCards, 0, 0, bossRules)
    
    -- Get enhancement effects
    local imprintEffects = EnhancementManager and EnhancementManager:resolveImprints(selectedCards, "on_score") or {chips = 0, mult = 0, x_mult = 1, gold = 0}
    local augmentEffects = EnhancementManager and EnhancementManager:resolveAugments(handResult, engineCards) or {chips = 0, mult = 0}
    local warpEffects = EnhancementManager and EnhancementManager:resolveWarps() or {retrigger = 0, cut_bonus = 0, score_penalty = 1.0}
    local jokerEffects = JokerManager and JokerManager:applyEffects(engineCards, "on_score") or {addedChips = 0, addedTempMult = 0, addedPermMult = 0}
    
    -- Calculate final score
    local finalChips = score.baseChips + augmentEffects.chips + jokerEffects.addedChips + imprintEffects.chips + warpEffects.cut_bonus
    local totalTempMult = score.tempMultiplier + augmentEffects.mult + jokerEffects.addedTempMult + imprintEffects.mult
    local totalPermMult = score.permMultiplier + jokerEffects.addedPermMult
    local finalMult = (1 + totalTempMult + totalPermMult) * imprintEffects.x_mult
    local finalScore = math.floor(finalChips * finalMult * warpEffects.score_penalty)
    
    if warpEffects.retrigger > 0 then
        finalScore = finalScore * (1 + warpEffects.retrigger)
    end
    
    return {
        total = finalScore,
        chips = finalChips,
        mult = finalMult,
        breakdown = {
            base = score.baseChips,
            augments = augmentEffects.chips,
            jokers = jokerEffects.addedChips,
            imprints = imprintEffects.chips
        },
        categories = handResult
    }
end

function ScorePreview.draw(x, y, preview, font, smallFont)
    if not preview then return end
    
    -- Background
    graphics.drawRect(x, y, 200, 120, { r = 0.1, g = 0.1, b = 0.2, a = 0.9 }, true)
    
    -- Border
    graphics.drawRect(x, y, 200, 120, { r = 0.5, g = 0.7, b = 0.9, a = 1 }, false)
    
    -- Title
    graphics.print(smallFont or font, "Score Preview", x + 10, y + 5, { r = 1, g = 1, b = 1, a = 1 })
    
    -- Total score (large)
    graphics.print(font, tostring(preview.total), x + 70, y + 30, { r = 1, g = 0.9, b = 0.3, a = 1 })
    
    -- Breakdown
    local detailY = y + 60
    graphics.print(smallFont or font, string.format("Chips: %d", math.floor(preview.chips)), x + 10, detailY, { r = 0.8, g = 0.8, b = 0.8, a = 1 })
    graphics.print(smallFont or font, string.format("Mult: %.2fx", preview.mult), x + 10, detailY + 20, { r = 0.8, g = 0.8, b = 0.8, a = 1 })
    
    -- Hint
    graphics.print(smallFont or font, "(Select 4 cards)", x + 10, detailY + 40, { r = 0.6, g = 0.6, b = 0.6, a = 1 })
end

return ScorePreview
