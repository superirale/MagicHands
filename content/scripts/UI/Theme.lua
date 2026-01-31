-- Theme.lua
-- Centralized theme system for consistent UI styling

Theme = {
    current = "default",
    
    themes = {
        default = {
            colors = {
                -- Primary palette
                primary = { r = 0.3, g = 0.5, b = 0.8, a = 1 },
                primaryHover = { r = 0.4, g = 0.6, b = 0.9, a = 1 },
                primaryActive = { r = 0.2, g = 0.4, b = 0.7, a = 1 },
                
                secondary = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
                secondaryHover = { r = 0.6, g = 0.6, b = 0.6, a = 1 },
                secondaryActive = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
                
                -- Semantic colors
                danger = { r = 0.8, g = 0.3, b = 0.3, a = 1 },
                dangerHover = { r = 0.9, g = 0.4, b = 0.4, a = 1 },
                dangerActive = { r = 0.7, g = 0.2, b = 0.2, a = 1 },
                
                success = { r = 0.3, g = 0.8, b = 0.4, a = 1 },
                successHover = { r = 0.4, g = 0.9, b = 0.5, a = 1 },
                successActive = { r = 0.2, g = 0.7, b = 0.3, a = 1 },
                
                warning = { r = 0.9, g = 0.8, b = 0.2, a = 1 },
                warningHover = { r = 1, g = 0.9, b = 0.3, a = 1 },
                warningActive = { r = 0.8, g = 0.7, b = 0.1, a = 1 },
                
                info = { r = 0.4, g = 0.6, b = 0.8, a = 1 },
                infoHover = { r = 0.5, g = 0.7, b = 0.9, a = 1 },
                infoActive = { r = 0.3, g = 0.5, b = 0.7, a = 1 },
                
                -- Text colors
                text = { r = 1, g = 1, b = 1, a = 1 },
                textMuted = { r = 0.7, g = 0.7, b = 0.7, a = 1 },
                textDisabled = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
                textInverse = { r = 0, g = 0, b = 0, a = 1 },
                
                -- Background colors
                background = { r = 0.05, g = 0.05, b = 0.08, a = 0.95 },
                backgroundDark = { r = 0.02, g = 0.02, b = 0.05, a = 1 },
                panelBg = { r = 0.15, g = 0.15, b = 0.18, a = 1 },
                panelBgHover = { r = 0.2, g = 0.2, b = 0.23, a = 1 },
                panelBgActive = { r = 0.1, g = 0.1, b = 0.13, a = 1 },
                
                -- Rarity colors (for cards)
                rarityCommon = { r = 0.4, g = 0.6, b = 0.8, a = 1 },
                rarityUncommon = { r = 0.2, g = 0.7, b = 0.4, a = 1 },
                rarityRare = { r = 0.8, g = 0.3, b = 0.3, a = 1 },
                rarityLegendary = { r = 0.9, g = 0.8, b = 0.2, a = 1 },
                rarityEnhancement = { r = 0.5, g = 0.4, b = 0.8, a = 1 },
                
                -- Special colors
                gold = { r = 1, g = 0.8, b = 0.2, a = 1 },
                goldDark = { r = 0.8, g = 0.6, b = 0.1, a = 1 },
                silver = { r = 0.75, g = 0.75, b = 0.8, a = 1 },
                bronze = { r = 0.8, g = 0.5, b = 0.2, a = 1 },
                
                -- UI elements
                border = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
                borderLight = { r = 0.7, g = 0.7, b = 0.7, a = 1 },
                borderDark = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
                shadow = { r = 0, g = 0, b = 0, a = 0.5 },
                overlay = { r = 0, g = 0, b = 0, a = 0.7 },
                overlayLight = { r = 0, g = 0, b = 0, a = 0.3 },
                
                -- Special shop/economy colors
                shopReroll = { r = 0.3, g = 0.3, b = 0.8, a = 1 },
                shopRerollHover = { r = 0.4, g = 0.4, b = 0.9, a = 1 },
                shopSell = { r = 0.6, g = 0.4, b = 0.1, a = 1 },
                shopSellHover = { r = 0.8, g = 0.5, b = 0.2, a = 1 },
                shopSellMode = { r = 0.8, g = 0.3, b = 0.1, a = 1 }
            },
            
            fonts = {
                default = "UI_FONT",
                title = "UI_FONT",
                mono = "UI_FONT"
            },
            
            sizes = {
                -- Base sizes (will be scaled by UIScale)
                buttonHeight = 60,
                buttonHeightSmall = 40,
                buttonHeightLarge = 80,
                
                cardWidth = 220,
                cardHeight = 300,
                cardWidthSmall = 160,
                cardHeightSmall = 220,
                
                -- Spacing
                padding = 10,
                paddingSmall = 5,
                paddingLarge = 20,
                spacing = 10,
                spacingSmall = 5,
                spacingLarge = 20,
                
                -- Typography
                fontSizeSmall = 16,
                fontSizeDefault = 20,
                fontSizeLarge = 28,
                fontSizeTitle = 36,
                fontSizeHuge = 48,
                lineHeight = 1.4,
                
                -- Borders
                borderWidth = 2,
                borderRadius = 4,
                
                -- Card specific
                cardHeaderHeight = 50,
                cardFooterHeight = 40,
                cardPadding = 10,
                cardLineSpacing = 20,
                
                -- Joker slots
                jokerSlotWidth = 120,
                jokerSlotHeight = 40,
                jokerSlotSpacing = 10
            },
            
            animation = {
                durationFast = 0.15,
                durationNormal = 0.3,
                durationSlow = 0.5,
                easingDefault = "easeOutQuad"
            }
        },
        
        -- Deuteranopia (green-blind) friendly theme
        deuteranopia = {
            colors = {
                -- Adjust reds and greens to be more distinguishable
                primary = { r = 0.3, g = 0.5, b = 0.8, a = 1 },
                primaryHover = { r = 0.4, g = 0.6, b = 0.9, a = 1 },
                primaryActive = { r = 0.2, g = 0.4, b = 0.7, a = 1 },
                
                secondary = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
                secondaryHover = { r = 0.6, g = 0.6, b = 0.6, a = 1 },
                secondaryActive = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
                
                -- Use blue/yellow instead of red/green for semantic colors
                danger = { r = 0.8, g = 0.2, b = 0.2, a = 1 },  -- Keep red
                dangerHover = { r = 0.9, g = 0.3, b = 0.3, a = 1 },
                dangerActive = { r = 0.7, g = 0.1, b = 0.1, a = 1 },
                
                success = { r = 0.2, g = 0.5, b = 0.8, a = 1 },  -- Blue instead of green
                successHover = { r = 0.3, g = 0.6, b = 0.9, a = 1 },
                successActive = { r = 0.1, g = 0.4, b = 0.7, a = 1 },
                
                warning = { r = 0.9, g = 0.8, b = 0.2, a = 1 },
                warningHover = { r = 1, g = 0.9, b = 0.3, a = 1 },
                warningActive = { r = 0.8, g = 0.7, b = 0.1, a = 1 },
                
                info = { r = 0.4, g = 0.6, b = 0.8, a = 1 },
                infoHover = { r = 0.5, g = 0.7, b = 0.9, a = 1 },
                infoActive = { r = 0.3, g = 0.5, b = 0.7, a = 1 },
                
                -- Copy rest from default
                text = { r = 1, g = 1, b = 1, a = 1 },
                textMuted = { r = 0.7, g = 0.7, b = 0.7, a = 1 },
                textDisabled = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
                textInverse = { r = 0, g = 0, b = 0, a = 1 },
                
                background = { r = 0.05, g = 0.05, b = 0.08, a = 0.95 },
                backgroundDark = { r = 0.02, g = 0.02, b = 0.05, a = 1 },
                panelBg = { r = 0.15, g = 0.15, b = 0.18, a = 1 },
                panelBgHover = { r = 0.2, g = 0.2, b = 0.23, a = 1 },
                panelBgActive = { r = 0.1, g = 0.1, b = 0.13, a = 1 },
                
                rarityCommon = { r = 0.4, g = 0.6, b = 0.8, a = 1 },
                rarityUncommon = { r = 0.5, g = 0.5, b = 0.7, a = 1 },  -- Purple instead of green
                rarityRare = { r = 0.8, g = 0.3, b = 0.3, a = 1 },
                rarityLegendary = { r = 0.9, g = 0.8, b = 0.2, a = 1 },
                rarityEnhancement = { r = 0.5, g = 0.4, b = 0.8, a = 1 },
                
                gold = { r = 1, g = 0.8, b = 0.2, a = 1 },
                goldDark = { r = 0.8, g = 0.6, b = 0.1, a = 1 },
                silver = { r = 0.75, g = 0.75, b = 0.8, a = 1 },
                bronze = { r = 0.8, g = 0.5, b = 0.2, a = 1 },
                
                border = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
                borderLight = { r = 0.7, g = 0.7, b = 0.7, a = 1 },
                borderDark = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
                shadow = { r = 0, g = 0, b = 0, a = 0.5 },
                overlay = { r = 0, g = 0, b = 0, a = 0.7 },
                overlayLight = { r = 0, g = 0, b = 0, a = 0.3 },
                
                shopReroll = { r = 0.3, g = 0.3, b = 0.8, a = 1 },
                shopRerollHover = { r = 0.4, g = 0.4, b = 0.9, a = 1 },
                shopSell = { r = 0.6, g = 0.4, b = 0.1, a = 1 },
                shopSellHover = { r = 0.8, g = 0.5, b = 0.2, a = 1 },
                shopSellMode = { r = 0.8, g = 0.3, b = 0.1, a = 1 }
            },
            
            -- Copy sizes, fonts, animation from default
            fonts = {
                default = "UI_FONT",
                title = "UI_FONT",
                mono = "UI_FONT"
            },
            
            sizes = {
                buttonHeight = 60,
                buttonHeightSmall = 40,
                buttonHeightLarge = 80,
                cardWidth = 220,
                cardHeight = 300,
                cardWidthSmall = 160,
                cardHeightSmall = 220,
                padding = 10,
                paddingSmall = 5,
                paddingLarge = 20,
                spacing = 10,
                spacingSmall = 5,
                spacingLarge = 20,
                fontSizeSmall = 16,
                fontSizeDefault = 20,
                fontSizeLarge = 28,
                fontSizeTitle = 36,
                fontSizeHuge = 48,
                lineHeight = 1.4,
                borderWidth = 2,
                borderRadius = 4,
                cardHeaderHeight = 50,
                cardFooterHeight = 40,
                cardPadding = 10,
                cardLineSpacing = 20,
                jokerSlotWidth = 120,
                jokerSlotHeight = 40,
                jokerSlotSpacing = 10
            },
            
            animation = {
                durationFast = 0.15,
                durationNormal = 0.3,
                durationSlow = 0.5,
                easingDefault = "easeOutQuad"
            }
        }
    }
}

-- Get theme value by dot notation path
-- Example: Theme.get("colors.primary") or Theme.get("sizes.padding")
function Theme.get(path)
    local keys = {}
    for key in string.gmatch(path, "[^.]+") do
        table.insert(keys, key)
    end
    
    local value = Theme.themes[Theme.current]
    for _, key in ipairs(keys) do
        if value == nil then
            log.warn("Theme path not found: " .. path)
            return nil
        end
        value = value[key]
    end
    
    return value
end

-- Get rarity color (backward compatibility helper)
function Theme.getRarityColor(rarity)
    local colorKey = "rarity" .. rarity:sub(1,1):upper() .. rarity:sub(2)
    return Theme.get("colors." .. colorKey) or Theme.get("colors.rarityCommon")
end

-- Set active theme
function Theme.setTheme(name)
    if Theme.themes[name] then
        Theme.current = name
        log.info("Theme changed to: " .. name)
        
        -- Trigger theme change event if available
        if EventSystem then
            local event = EventData("theme_changed")
            event:SetString("theme", name)
            EventSystem:Instance().Emit(event)
        end
        
        return true
    else
        log.error("Theme not found: " .. name)
        return false
    end
end

-- Get list of available themes
function Theme.getThemes()
    local themeList = {}
    for name, _ in pairs(Theme.themes) do
        table.insert(themeList, name)
    end
    return themeList
end

-- Copy color table (for modifications)
function Theme.copyColor(color)
    if not color then
        print("WARNING: Theme.copyColor called with nil color")
        return { r = 0, g = 0, b = 0, a = 1 }  -- Return black as fallback
    end
    return { r = color.r, g = color.g, b = color.b, a = color.a }
end

-- Lighten color by percentage (0.0 to 1.0)
function Theme.lighten(color, amount)
    local newColor = Theme.copyColor(color)
    newColor.r = math.min(1, newColor.r + amount)
    newColor.g = math.min(1, newColor.g + amount)
    newColor.b = math.min(1, newColor.b + amount)
    return newColor
end

-- Darken color by percentage (0.0 to 1.0)
function Theme.darken(color, amount)
    local newColor = Theme.copyColor(color)
    newColor.r = math.max(0, newColor.r - amount)
    newColor.g = math.max(0, newColor.g - amount)
    newColor.b = math.max(0, newColor.b - amount)
    return newColor
end

-- Set alpha for color
function Theme.withAlpha(color, alpha)
    local newColor = Theme.copyColor(color)
    newColor.a = alpha
    return newColor
end

return Theme
