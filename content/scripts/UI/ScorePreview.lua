local ScoringUtils = require("utils/ScoringUtils")
local ScorePreview = {}

function ScorePreview.calculate(selectedCards, cutCard)
    if #selectedCards ~= 4 or not cutCard then
        return nil
    end

    local scoreResult = ScoringUtils.calculateScore(selectedCards, cutCard)

    return {
        total = scoreResult.total,
        chips = scoreResult.chips,
        mult = scoreResult.mult,
        breakdown = {
            base = scoreResult.breakdown.baseChips,
            augments = scoreResult.breakdown.augmentChips,
            jokers = scoreResult.breakdown.jokerChips,
            imprints = scoreResult.breakdown.imprintChips
        },
        categories = scoreResult.handResult
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
    graphics.print(smallFont or font, string.format("Chips: %d", math.floor(preview.chips)), x + 10, detailY,
        { r = 0.8, g = 0.8, b = 0.8, a = 1 })
    graphics.print(smallFont or font, string.format("Mult: %.2fx", preview.mult), x + 10, detailY + 20,
        { r = 0.8, g = 0.8, b = 0.8, a = 1 })

    -- Hint
    graphics.print(smallFont or font, "(Select 4 cards)", x + 10, detailY + 40, { r = 0.6, g = 0.6, b = 0.6, a = 1 })
end

return ScorePreview
