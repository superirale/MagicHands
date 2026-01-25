-- UIDefinitions.lua
-- Declarative UI element definitions (Hades-style)
-- Uses C++ layout system for consistent positioning

-- Get base position from C++ layout system
local function getSurvivalStatsPosition()
    local region = layout.get("SurvivalStats")
    if region then
        return region.x, region.y
    end
    return 20, 20 -- Fallback
end

local baseX, baseY = getSurvivalStatsPosition()
local barSpacing = 30 -- Height of each bar row

UIDefinitions = {
    -- Health Bar System (border is base, fill draws on top)
    HealthBarBorder = {
        Graphic = "ui_bar_border",
        X = baseX,
        Y = baseY,
        Width = 200,
        Height = 24,
        ZOrder = 1, -- Draw FIRST (background frame)
    },

    HealthBarBackground = {
        Graphic = "ui_bar_bg",
        X = baseX + 2, -- Inside the border
        Y = baseY + 2,
        Width = 196,
        Height = 20,
        ZOrder = 5, -- Draw second
    },

    HealthBarFill = {
        Graphic = "ui_bar_fill",
        X = baseX + 2,
        Y = baseY + 2,
        Width = 196, -- Dynamic, updated in UI.lua
        Height = 20,
        ZOrder = 10, -- Draw LAST (on top, visible)
    },

    -- Health text removed (Phase 2)

    -- Hunger Bar (Phase 2)
    HungerBarBorder = {
        Graphic = "ui_bar_border",
        X = baseX,
        Y = baseY + barSpacing, -- Below health bar
        Width = 200,
        Height = 24,
        ZOrder = 1,
    },

    HungerBarBackground = {
        Graphic = "ui_bar_bg",
        X = baseX + 2,
        Y = baseY + barSpacing + 2,
        Width = 196,
        Height = 20,
        ZOrder = 5,
    },

    HungerBarFill = {
        Graphic = "hunger_bar_fill", -- Green colored bar
        X = baseX + 2,
        Y = baseY + barSpacing + 2,
        Width = 196,
        Height = 20,
        ZOrder = 10,
    },

    -- Hunger text removed (Phase 2)

    -- Sanity Bar (Phase 2)
    SanityBarBorder = {
        Graphic = "ui_bar_border",
        X = baseX,
        Y = baseY + barSpacing * 2, -- Below hunger bar
        Width = 200,
        Height = 24,
        ZOrder = 1,
    },

    SanityBarBackground = {
        Graphic = "ui_bar_bg",
        X = baseX + 2,
        Y = baseY + barSpacing * 2 + 2,
        Width = 196,
        Height = 20,
        ZOrder = 5,
    },

    SanityBarFill = {
        Graphic = "sanity_bar_fill", -- Blue colored bar
        X = baseX + 2,
        Y = baseY + barSpacing * 2 + 2,
        Width = 196,
        Height = 20,
        ZOrder = 10,
    },

    -- Sanity text removed (Phase 2)

    -- Ammo/Cast Icons
    AmmoIcon1 = {
        Graphic = "ui_ammo_simple",
        X = 20,
        Y = 54,
        Width = 24,
        Height = 24,
        ZOrder = 1,
    },

    AmmoIcon2 = {
        InheritFrom = "AmmoIcon1",
        X = 48,
    },

    AmmoIcon3 = {
        InheritFrom = "AmmoIcon1",
        X = 76,
    },

    -- Subtitles (example from Hades)
    SubtitlesBacking = {
        Graphic = "ui_bar_bg",
        X = 640,
        Y = 650,
        Width = 600,
        Height = 60,
        Justification = "Center",
        FadeOpacity = 0.0,
        FadeTarget = 0.0,
    },

    SubtitlesText = {
        AttachTo = "SubtitlesBacking",
        OffsetX = -280,
        OffsetY = 15,
        Font = "content/fonts/font.ttf",
        FontSize = 22,
        TextRed = 0.9,
        TextGreen = 0.9,
        TextBlue = 0.9,
        Width = 560,
        FadeOpacity = 0.0,
        FadeTarget = 0.0,
        Text = "",
    },
}

return UIDefinitions
