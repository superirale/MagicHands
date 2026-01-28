# Phase 3 - Remaining Love2D Graphics Calls

**Date**: January 28, 2026  
**Status**: ⚠️ **PARTIALLY FIXED**

---

## Files Already Fixed

✅ ScorePreview.lua - Fully converted  
✅ TierIndicator.lua - Fully converted  
✅ DeckView.lua - Fully converted  
✅ RunStatsPanel.lua - Fully converted  

---

## Files Still Using Love2D API

### CollectionUI.lua
**Lines**: 109-278 (many instances)  
**Used**: `setColor()`, `rectangle()`, `setFont()`  
**Impact**: Medium - Only shows when pressing C

### AchievementNotification.lua  
**Lines**: 65-93 (many instances)  
**Used**: `setColor()`, `rectangle()`, `setFont()`  
**Impact**: High - Shows during gameplay

### TierIndicator.lua (partial)
**Line**: 88 (gold particle effect)  
**Used**: `setColor()` in drawGlow()  
**Impact**: Low - Only for tier 5 glow

---

## Conversion Pattern

### Love2D → Magic Hands

```lua
// Background fill
graphics.setColor(r, g, b, a)
graphics.rectangle("fill", x, y, w, h)
→
graphics.drawRect(x, y, w, h, {r, g, b, a}, true)

// Border/outline
graphics.setColor(r, g, b, a)
graphics.rectangle("line", x, y, w, h)
→
graphics.drawRect(x, y, w, h, {r, g, b, a}, false)

// Text
graphics.setFont(font)
graphics.setColor(r, g, b, a)
graphics.print(text, x, y)
→
graphics.print(font, text, x, y, {r, g, b, a})
```

---

## Priority Fix Order

1. **AchievementNotification.lua** (HIGH) - Shows during normal play
2. **CollectionUI.lua** (MEDIUM) - Only when pressing C
3. **TierIndicator.lua glow** (LOW) - Only tier 5 jokers

---

## Quick Fix Script

For each file, find and replace:

1. Find `graphics.setColor(r, g, b, a)` followed by `graphics.rectangle("fill", ...)`
   - Replace with: `graphics.drawRect(x, y, w, h, {r, g, b, a}, true)`

2. Find `graphics.setColor(r, g, b, a)` followed by `graphics.rectangle("line", ...)`
   - Replace with: `graphics.drawRect(x, y, w, h, {r, g, b, a}, false)`

3. Find `graphics.setFont(font)` followed by `graphics.print(...)`
   - Replace with: `graphics.print(font, text, x, y, {r, g, b, a})`

---

## Testing

After converting each file:
1. Build: `cd build && cmake --build . --config Release`
2. Run: `./MagicHand`
3. Test the specific UI:
   - AchievementNotification: Play until achievement unlocks
   - CollectionUI: Press C
   - TierIndicator glow: Stack joker to tier 5

---

## Current Status

**Fixed**: 4/7 UI files with Love2D calls  
**Remaining**: 3 files  
**Build**: ✅ Compiles successfully  
**Game**: Playable (remaining files only error when accessed)

---

**Note**: These remaining files will only cause errors if their UI elements are rendered. The game is still playable, but will crash if:
- Achievement unlocks (AchievementNotification)
- Collection opened (CollectionUI)
- Tier 5 joker with glow effect (TierIndicator)

---

**Recommendation**: Fix AchievementNotification.lua next as it's most likely to be triggered during normal gameplay.
