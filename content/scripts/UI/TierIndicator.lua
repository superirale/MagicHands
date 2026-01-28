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
function TierIndicator.draw(x, y, tier, stack, size)
    size = size or "normal" -- "small", "normal", "large"
    
    -- Clamp tier to 1-5
    tier = math.max(1, math.min(5, tier or 1))
    
    local badgeSize = 20
    local fontSize = 14
    
    if size == "small" then
        badgeSize = 15
        fontSize = 10
    elseif size == "large" then
        badgeSize = 30
        fontSize = 18
    end
    
    local color = TierIndicator.colors[tier]
    
    -- Draw badge background
    graphics.setColor(color.r, color.g, color.b, 0.8)
    graphics.circle("fill", x, y, badgeSize)
    
    -- Draw border
    graphics.setColor(1, 1, 1, 1)
    graphics.circle("line", x, y, badgeSize)
    
    -- Draw tier number or stack indicator
    graphics.setColor(1, 1, 1, 1)
    local text = "x" .. tier
    if stack and stack > 1 then
        text = "x" .. stack
    end
    
    -- Center text
    local textX = x - (fontSize / 2)
    local textY = y - (fontSize / 2)
    graphics.print(text, textX, textY)
end

-- Draw tier glow effect (for tier 3+)
function TierIndicator.drawGlow(x, y, w, h, tier, time)
    if tier < 3 then return end
    
    local color = TierIndicator.colors[tier]
    local pulse = math.abs(math.sin(time * 2)) * 0.3 + 0.3
    
    graphics.setColor(color.r, color.g, color.b, pulse)
    graphics.rectangle("line", x - 2, y - 2, w + 4, h + 4, 3)
    graphics.rectangle("line", x - 4, y - 4, w + 8, h + 8, 5)
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
