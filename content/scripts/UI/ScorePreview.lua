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

function ScorePreview.draw(x, y, preview, font)
    if not preview then return end
    
    graphics.setFont(font)
    
    -- Background
    graphics.setColor(0.1, 0.1, 0.2, 0.9)
    graphics.rectangle("fill", x, y, 200, 120, 5)
    
    -- Border
    graphics.setColor(0.5, 0.7, 0.9, 1)
    graphics.rectangle("line", x, y, 200, 120, 5)
    
    -- Title
    graphics.setColor(1, 1, 1, 1)
    graphics.print("Score Preview", x + 10, y + 5)
    
    -- Total score (large)
    graphics.setColor(1, 0.9, 0.3, 1)
    graphics.print(tostring(preview.total), x + 70, y + 30)
    
    -- Breakdown
    graphics.setColor(0.8, 0.8, 0.8, 1)
    local detailY = y + 60
    graphics.print(string.format("Chips: %d", preview.chips), x + 10, detailY)
    graphics.print(string.format("Mult: %.2fx", preview.mult), x + 10, detailY + 20)
    
    -- Hint
    graphics.setColor(0.6, 0.6, 0.6, 1)
    graphics.print("(Select 4 + crib)", x + 10, detailY + 40)
end

return ScorePreview
