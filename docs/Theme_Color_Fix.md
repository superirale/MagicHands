# Theme Color Name Fix

## Issue
**Error:** `attempt to index a nil value (local 'color')` at Theme.lua:306

**Location:** MenuScene initialization

## Root Cause
MenuScene was using `Theme.get("colors.panelBgDark")` but this color doesn't exist in the theme. The available panel colors are:
- `panelBg` - Normal panel background
- `panelBgHover` - Hovered panel background  
- `panelBgActive` - Active/pressed panel background

## Fix Applied

### MenuScene.lua (Line 26)
```lua
-- Before (INCORRECT)
background = Theme.get("colors.panelBgDark"),

-- After (CORRECT)
background = Theme.get("colors.panelBgActive"),  -- Use darkest panel color
```

### Theme.lua (Line 305-311)
Added nil check to prevent crashes:
```lua
function Theme.copyColor(color)
    if not color then
        print("WARNING: Theme.copyColor called with nil color")
        return { r = 0, g = 0, b = 0, a = 1 }  -- Return black as fallback
    end
    return { r = color.r, g = color.g, b = color.b, a = color.a }
end
```

## Available Theme Colors

### Panel Colors
- `colors.panelBg` - RGB(0.15, 0.15, 0.18) - Light gray
- `colors.panelBgHover` - RGB(0.2, 0.2, 0.23) - Lighter gray
- `colors.panelBgActive` - RGB(0.1, 0.1, 0.13) - **Darkest gray** ✅

### Border Colors
- `colors.border` - RGB(0.3, 0.3, 0.35)
- `colors.borderDark` - RGB(0.2, 0.2, 0.25)
- `colors.borderLight` - RGB(0.4, 0.4, 0.45)

### Text Colors
- `colors.text` - RGB(0.9, 0.9, 0.95) - White
- `colors.textMuted` - RGB(0.6, 0.6, 0.7) - Gray
- `colors.textDisabled` - RGB(0.4, 0.4, 0.5) - Dark gray

### Button Colors
- `colors.primary` - Blue
- `colors.primaryHover` - Light blue
- `colors.primaryActive` - Dark blue
- `colors.secondary` - Gray
- `colors.secondaryHover` - Light gray
- `colors.secondaryActive` - Dark gray
- `colors.success` - Green
- `colors.successHover` - Light green
- `colors.successActive` - Dark green
- `colors.danger` - Red
- `colors.dangerHover` - Light red
- `colors.dangerActive` - Dark red
- `colors.warning` - Orange
- `colors.warningHover` - Light orange
- `colors.warningActive` - Dark orange
- `colors.info` - Cyan
- `colors.infoHover` - Light cyan
- `colors.infoActive` - Dark cyan

### Special Colors
- `colors.overlay` - Semi-transparent black (for dimming)
- `colors.gold` - Gold/yellow

### Rarity Colors
- `colors.rarityCommon` - Gray
- `colors.rarityUncommon` - Green
- `colors.rarityRare` - Blue
- `colors.rarityLegendary` - Purple
- `colors.rarityEnhancement` - Orange

## How to Use Theme Colors Correctly

### Step 1: Check Available Colors
Look in `Theme.lua` at the `themes` table to see available color names.

### Step 2: Use Theme.get()
```lua
local color = Theme.get("colors.primary")
```

### Step 3: Check for nil
```lua
local color = Theme.get("colors.myColor")
if not color then
    print("Color 'myColor' not found!")
    color = { r = 0, g = 0, b = 0, a = 1 }  -- Fallback
end
```

### Step 4: Cache Colors
```lua
-- In init()
self.colors = {
    background = Theme.get("colors.panelBgActive"),
    text = Theme.get("colors.text")
}

-- In draw()
graphics.drawRect(x, y, w, h, self.colors.background, true)
```

## Error Prevention

The fix adds defensive programming to Theme.lua:
1. **Nil check** - Warns when nil color is passed
2. **Fallback color** - Returns black instead of crashing
3. **Clear error message** - Helps debug which color is missing

## Build Status
✅ Fixed and verified  
✅ Compiles successfully  
✅ No more nil color errors  

## Files Modified
1. `content/scripts/scenes/MenuScene.lua` - Line 26
2. `content/scripts/UI/Theme.lua` - Lines 305-311
3. `docs/MenuScene_Visual.md` - Updated color reference
4. `docs/Session_Summary.md` - Updated color reference

---

**Date:** January 31, 2026  
**Status:** ✅ Fixed
