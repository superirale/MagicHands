# Phase 3 - Remaining Graphics API Fixes

**Date**: January 28, 2026  
**Status**: ⚠️ **PARTIALLY FIXED**

---

## What Happened

Phase 3 UI files were initially written using graphics function calls that **don't exist** in the Magic Hands engine's Lua bindings.

---

## Files Already Fixed

✅ ScorePreview.lua - Fully converted  
✅ TierIndicator.lua - Fully converted  
✅ DeckView.lua - Fully converted  
✅ RunStatsPanel.lua - Fully converted  

---

## Files Still Using Invalid Graphics API

### CollectionUI.lua
**Lines**: 109-278 (many instances)  
**Invalid Calls**: `setColor()`, `rectangle()`, `setFont()`  
**Impact**: Medium - Only shows when pressing C

### AchievementNotification.lua  
**Lines**: 65-93 (many instances)  
**Invalid Calls**: `setColor()`, `rectangle()`, `setFont()`  
**Impact**: High - Shows during gameplay

### TierIndicator.lua (partial)
**Line**: 88 (gold particle effect)  
**Invalid Calls**: `setColor()` in drawGlow()  
**Impact**: Low - Only for tier 5 glow

---

## The Problem: Invalid Function Calls

### What Doesn't Exist in Magic Hands Engine
```lua
graphics.setColor(r, g, b, a)      -- ❌ Not bound in C++
graphics.rectangle("fill", ...)     -- ❌ Not bound in C++
graphics.setFont(font)              -- ❌ Not bound in C++
graphics.circle("fill", ...)        -- ❌ Not bound in C++
```

### What Actually Exists (Correct Magic Hands API)
```lua
graphics.drawRect(x, y, w, h, {r, g, b, a}, filled)  -- ✅ Defined in C++
graphics.print(font, text, x, y, {r, g, b, a})       -- ✅ Defined in C++
```

---

## Conversion Pattern

### Invalid API → Correct API

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

## Why This Happened

When creating Phase 3 files, I mistakenly used graphics function patterns that aren't defined in the Magic Hands engine's C++ Lua bindings. The correct API is clearly defined in existing files like:
- `HUD.lua`
- `ShopUI.lua`
- `BlindPreview.lua`

These existing files all use `graphics.drawRect()` and `graphics.print()` correctly.

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

**Fixed**: 4/7 UI files with invalid graphics calls  
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
