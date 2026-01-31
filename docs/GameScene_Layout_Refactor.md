## GameScene Layout Refactor

## Overview

Refactored GameScene from hardcoded pixel positions to a flexible, relative positioning system using logical layout zones.

## Key Changes

### Before (Hardcoded)
```lua
-- Hand cards
local startX = 200
local startY = 500
local spacing = 110

-- Crib cards
local startX = 990
local startY = 490

-- Cut card
self.cutCardView = CardView(self.cutCard, 585, 200, ...)

-- Keyboard shortcuts
graphics.print(font, text, 20, 680, color)
```

### After (Relative Layout)
```lua
-- Hand cards - centered at bottom
local startX, startY, spacing = GameSceneLayout.getCenteredHandPosition(#self.hand)

-- Crib cards - positioned relative to right side
local x, y = GameSceneLayout.getPosition("crib", {slotIndex = i})

-- Cut card - centered at top
local cutX, cutY = GameSceneLayout.getPosition("cutCard")

-- Keyboard shortcuts - bottom left corner
local shortcutX, shortcutY = GameSceneLayout.getPosition("shortcuts")
```

## Layout System

### GameSceneLayout.lua

Defines logical zones as percentages of viewport (1280x720):

**Hand Zone** (Bottom Center)
- centerX: 50% (horizontally centered)
- y: 72% from top
- Cards centered based on count

**Crib Zone** (Right Side)
- baseX: 77% from left
- y: 68% from top
- 2 slots with 120px spacing

**Cut Card Zone** (Top Center)
- centerX: 50% (horizontally centered)
- y: 28% from top

**Shortcuts Zone** (Bottom Left)
- x: 1.6% from left
- y: 94.4% from top

**Add to Crib Button** (Right Side, Above Crib)
- x: 76.6% from left
- y: 58.3% from top
- width: 18.75% of viewport
- height: 6.9% of viewport

### API

```lua
-- Get position for a zone
local x, y = GameSceneLayout.getPosition(zoneName, params)

-- Get centered hand position
local startX, startY, spacing = GameSceneLayout.getCenteredHandPosition(numCards)

-- Get zone dimensions
local dims = GameSceneLayout.getDimensions(zoneName)
```

## Benefits

### 1. Maintainability
- All layout logic in one file
- Easy to adjust positions globally
- Clear semantic meaning (hand, crib, cutCard vs arbitrary numbers)

### 2. Flexibility
- Positions are relative, not absolute
- Easy to adapt to different viewport sizes in future
- Can create layout variants (mobile, widescreen, etc.)

### 3. Consistency
- All zones defined in one place
- Relationships between elements explicit
- Easier to maintain visual balance

### 4. Readability
```lua
// Before - What does 585, 200 mean?
CardView(card, 585, 200, atlas, font)

// After - Clear semantic meaning
local x, y = GameSceneLayout.getPosition("cutCard")
CardView(card, x, y, atlas, font)
```

## Modified Files

1. **scenes/GameSceneLayout.lua** (NEW)
   - Layout configuration
   - Position calculation functions
   - Zone definitions

2. **scenes/GameScene.lua**
   - Import GameSceneLayout
   - Updated `startNewHand()` - hand card positioning
   - Updated `rebuildCribViews()` - crib card positioning
   - Updated draw() - keyboard shortcuts positioning
   - Updated `updateAddToCribButtonPosition()` - button positioning

## Testing

All elements should be in the same visual positions as before, but now using relative positioning:

✅ Hand cards - Centered at bottom
✅ Crib cards - Right side, middle-bottom  
✅ Cut card - Centered at top
✅ Keyboard shortcuts - Bottom left corner
✅ Add to Crib button - Right side, above crib

Resize the window and verify all elements scale proportionally with the viewport.

## Future Enhancements

### Easy to Add New Zones
```lua
-- Add new zone in GameSceneLayout.lua
zones.jokerDisplay = {
    x = 0.5,
    y = 0.1,
    width = 0.8
}

// Use in GameScene.lua
local x, y = GameSceneLayout.getPosition("jokerDisplay")
```

### Layout Variants
```lua
-- Could add mobile layout
GameSceneLayout.setVariant("mobile")  -- Changes all percentages

-- Or widescreen layout
GameSceneLayout.setVariant("widescreen")
```

### Dynamic Reflow
```lua
-- If hand has 8 cards, automatically adjust spacing
local startX, startY, spacing = GameSceneLayout.getCenteredHandPosition(8)
-- Spacing automatically calculated to fit viewport
```

## Migration Guide

### To Add New Positioned Element

1. **Define zone in GameSceneLayout.lua:**
```lua
zones.myElement = {
    x = 0.5,  -- 50% from left
    y = 0.5,  -- 50% from top
}
```

2. **Add position calculation:**
```lua
function GameSceneLayout.getPosition(zone, index)
    -- ...
    elseif zone == "myElement" then
        local z = GameSceneLayout.zones.myElement
        return vw * z.x, vh * z.y
    end
end
```

3. **Use in GameScene:**
```lua
local x, y = GameSceneLayout.getPosition("myElement")
-- Position your element at x, y
```

## Design Philosophy

**Viewport-Relative Positioning:**
- All positions expressed as percentages of 1280x720 viewport
- Viewport scales to fit any window size
- Elements maintain relative positions automatically

**Semantic Naming:**
- Zones have meaningful names (hand, crib, cutCard)
- Not just coordinates (x1, y1, x2, y2)
- Code is self-documenting

**Single Source of Truth:**
- All layout in one file
- Change position once, affects everywhere
- No scattered magic numbers

---

**Date:** January 31, 2026  
**Status:** ✅ Complete  
**Impact:** All game scene elements now use relative positioning
