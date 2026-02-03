-- TierIndicator.lua
-- Visual indicator for joker tier levels (1-5)

local TierIndicator = {}

-- Tier colors (progressively more vibrant)
TierIndicator.colors = {
    [1] = { r = 0.6, g = 0.6, b = 0.6, a = 1.0 }, -- Base: Gray
    [2] = { r = 0.4, g = 0.7, b = 0.4, a = 1.0 }, -- Amplified: Green
    [3] = { r = 0.4, g = 0.6, b = 0.9, a = 1.0 }, -- Synergy: Blue
    [4] = { r = 0.8, g = 0.4, b = 0.8, a = 1.0 }, -- Rule Bend: Purple
    [5] = { r = 1.0, g = 0.8, b = 0.2, a = 1.0 }  -- Ascension: Gold
}

-- Tier names
TierIndicator.names = {
    [1] = "Base",
    [2] = "Amplified",
    [3] = "Synergy",
    [4] = "Rule Bend",
    [5] = "Ascension"
}

-- Draw a tier badge on a joker card
function TierIndicator.draw(x, y, tier, font, stack, size)
    size = size or "normal" -- "small", "normal", "large"

    -- Clamp tier to 1-5
    tier = math.max(1, math.min(5, tier or 1))

    local badgeW = 40
    local badgeH = 25

    if size == "small" then
        badgeW = 30
        badgeH = 20
    elseif size == "large" then
        badgeW = 50
        badgeH = 30
    end

    local color = TierIndicator.colors[tier]

    -- Draw badge background (filled rectangle)
    graphics.drawRect(x, y, badgeW, badgeH, color, true)

    -- Draw border
    graphics.drawRect(x, y, badgeW, badgeH, { r = 1, g = 1, b = 1, a = 1 }, false)

    -- Draw tier number or stack indicator
    local text = "T" .. tier
    if stack and stack > 1 then
        text = "x" .. stack
    end

    -- Center text
    local textX = x + 8
    local textY = y + 5
    graphics.print(font, text, textX, textY, { r = 1, g = 1, b = 1, a = 1 })

    -- NEW: Automatic Glow and Aura for high tiers
    local time = os.clock()
    if tier >= 3 then
        TierIndicator.drawGlow(x, y, badgeW, badgeH, tier, time)
    end
    if tier == 5 then
        TierIndicator.drawAscensionAura(x, y, badgeW, badgeH, time)
    end
end

-- Draw tier glow effect (for tier 3+)
function TierIndicator.drawGlow(x, y, w, h, tier, time)
    if tier < 3 then return end

    local color = TierIndicator.colors[tier]
    local pulse = math.abs(math.sin(time or 0) * 2) * 0.3 + 0.3

    -- Draw glow as multiple border rectangles
    local glowColor = { r = color.r, g = color.g, b = color.b, a = pulse }
    graphics.drawRect(x - 2, y - 2, w + 4, h + 4, glowColor, false)

    glowColor.a = pulse * 0.5
    graphics.drawRect(x - 4, y - 4, w + 8, h + 8, glowColor, false)
end

-- Draw ascension aura (tier 5 only)
function TierIndicator.drawAscensionAura(x, y, w, h, time)
    local pulse = math.abs(math.sin(time * 3)) * 0.5 + 0.5

    -- Golden rotating particles
    for i = 1, 8 do
        local angle = (time + i / 8) * math.pi * 2
        local radius = 60 + math.sin(time * 2 + i) * 10
        local px = x + w / 2 + math.cos(angle) * radius
        local py = y + h / 2 + math.sin(angle) * radius

        graphics.setColor(1, 0.9, 0.3, pulse)
        graphics.circle("fill", px, py, 3)
    end
end

-- Get tier tooltip text
function TierIndicator.getTooltip(tier, jokerId)
    tier = math.max(1, math.min(5, tier or 1))
    local name = TierIndicator.names[tier]

    return string.format("Tier %d: %s", tier, name)
end

return TierIndicator
