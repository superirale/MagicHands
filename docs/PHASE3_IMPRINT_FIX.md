# Phase 3 - Imprint Validation Fix

**Date**: January 28, 2026  
**Build**: v0.3.8  
**Status**: ✅ **FIXED**

---

## Issue: Imprints Failed to Apply

**Error**: "Failed to imprint: Item is not an imprint"

### Root Cause

The `Shop:applyImprint()` function was only checking for **3 specific imprints**:
- gold_inlay
- lucky_pips  
- steel_plating

This was hardcoded from Phase 1, but Phase 2 added **25 total imprints**. The validation rejected the other 22 imprints!

### Original Code (Broken)

```lua
-- Line 266-267 in Shop.lua
if item.type ~= "enhancement" or not string.find(item.id, "inlay") and 
   not string.find(item.id, "pips") and not string.find(item.id, "plating") then
    return false, "Item is not an imprint"
end
```

This only recognized:
- ✅ gold_**inlay**
- ✅ lucky_**pips**
- ✅ steel_**plating**
- ❌ All other 22 imprints rejected!

---

## Fix Applied

Replaced hardcoded checks with comprehensive imprint lookup table:

```lua
-- Known imprints (all 25 from Phase 2)
local imprints = {
    gold_inlay = true, lucky_pips = true, steel_plating = true, mint = true, tax = true,
    investment = true, insurance = true, dividend = true, echo = true, cascade = true,
    fractal = true, resonance = true, spark = true, ripple = true, pulse = true,
    crown = true, underdog = true, clutch = true, opener = true, majority = true,
    minority = true, wildcard_imprint = true, suit_shifter = true, mimic = true, nullifier = true
}

if item.type ~= "enhancement" or not imprints[item.id] then
    return false, "Item is not an imprint"
end
```

Now all 25 imprints are recognized! ✅

---

## All 25 Imprints

### Phase 1 (3 imprints)
1. gold_inlay
2. lucky_pips
3. steel_plating

### Phase 2 (22 additional imprints)
4. mint
5. tax
6. investment
7. insurance
8. dividend
9. echo
10. cascade
11. fractal
12. resonance
13. spark
14. ripple
15. pulse
16. crown
17. underdog
18. clutch
19. opener
20. majority
21. minority
22. wildcard_imprint
23. suit_shifter
24. mimic
25. nullifier

---

## Testing

### Before Fix
- ❌ Only 3 imprints worked (12% success rate)
- ❌ 22 imprints failed with "not an imprint" error
- ❌ Purchasing imprints wasted gold

### After Fix
- ✅ All 25 imprints work (100% success rate)
- ✅ Card selection opens for all imprints
- ✅ Imprints apply correctly to cards

---

## Related Code

### Shop Purchase Flow
1. Shop generates items with `type = "enhancement"` (line 128)
2. Player clicks to purchase
3. For non-planet, non-spectral enhancements → trigger card selection (line 229)
4. Player selects card
5. `Shop:applyImprint()` validates and applies (line 258)

### Validation Points
- ✅ Line 128: Items marked as "enhancement"
- ✅ Line 223-229: Card selection triggered for imprints
- ✅ Line 266-268: Imprint validation (NOW FIXED)

---

## Files Modified

**Shop.lua** - Line 266-268: Updated imprint validation logic

---

## Impact

**Critical Fix**: This bug prevented 88% of imprints from being usable!

Players could purchase imprints but couldn't apply them, wasting gold. This is now fixed - all 25 imprints work correctly.

---

## Lessons Learned

1. **Avoid Hardcoding**: Don't hardcode specific item names for validation
2. **Use Lookup Tables**: Centralize item lists for maintainability
3. **Test All Content**: Phase 2 added 22 imprints but validation wasn't updated
4. **Defensive Coding**: Should have used a shared constant for imprint lists

---

## Recommended Improvement

Consider creating a shared `ContentDefinitions.lua` file:

```lua
-- content/scripts/config/ContentDefinitions.lua
ContentDefinitions = {
    imprints = {
        "gold_inlay", "lucky_pips", "steel_plating", "mint", "tax",
        "investment", "insurance", "dividend", "echo", "cascade",
        -- ... all 25 imprints
    },
    planets = { ... },
    warps = { ... }
}
```

Then reference this in Shop.lua, UnlockSystem.lua, and ShopUI.lua instead of duplicating the lists.

---

**Status**: ✅ Fixed in v0.3.8  
**All 25 imprints now functional!**
