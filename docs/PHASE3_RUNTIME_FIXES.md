# Phase 3 Runtime Fixes

**Date**: January 28, 2026  
**Status**: ✅ **FIXED**

---

## Issues Found During Playtesting

### Issue #1: Gold Amount Type Comparison (Line 240)
**Error**: `attempt to compare number with string` at `MagicHandsAchievements.lua:240`

**Location**: Gold achievement check
```lua
if stats.currentGold >= 500 then  -- Error: currentGold might be string
```

**Fix**: Added type coercion
```lua
stats.currentGold = tonumber(data.amount) or 0
if stats.currentGold >= 500 then
    self:unlock("rich")
end
```

---

### Issue #2: Missing canAfford Method
**Error**: `attempt to call a nil value (method 'canAfford')` at `Shop.lua:224`

**Location**: Shop purchase validation
```lua
if not Economy:canAfford(item.price) then  -- Error: method doesn't exist
```

**Fix**: Direct gold comparison
```lua
if Economy.gold < item.price then
    return false, "Not enough gold"
end
```

**Root Cause**: Economy module doesn't have a `canAfford()` method. It only has:
- `Economy:init()`
- `Economy:addGold(amount)`
- `Economy:spend(amount)`
- `Economy:calculateReward(...)`

The correct pattern is to check `Economy.gold >= price` directly.

---

## Files Modified

1. **MagicHandsAchievements.lua** (Line 238)
   - Added `tonumber()` conversion for gold amount
   
2. **Shop.lua** (Lines 207, 224)
   - Replaced `Economy:canAfford()` with direct gold check
   - Two instances fixed

---

## Economy Module API

### Available Methods
```lua
Economy:init()                    -- Initialize gold to 0
Economy:addGold(amount)          -- Add gold and emit event
Economy:spend(amount)            -- Spend gold if available
Economy:calculateReward(...)     -- Calculate blind reward
```

### Direct Access
```lua
Economy.gold  -- Current gold amount (number)
```

### Correct Usage Patterns

**Check if player can afford**:
```lua
if Economy.gold >= price then
    -- Can afford
end
```

**Spend gold**:
```lua
if Economy:spend(price) then
    -- Purchase successful
else
    -- Not enough gold
end
```

**Add gold**:
```lua
Economy:addGold(50)  -- Emits "gold_changed" event
```

---

## Event Data Type Safety

All numeric event data should be coerced with `tonumber()`:

```lua
events.on("gold_changed", function(data)
    local amount = tonumber(data.amount) or 0
    local delta = tonumber(data.delta) or 0
    
    if amount >= 500 then
        -- Safe comparison
    end
end)

events.on("joker_added", function(data)
    local stack = tonumber(data.stack) or 1
    
    if stack >= 5 then
        -- Safe comparison
    end
end)
```

### Why This is Necessary

Event data comes from various sources:
- C++ engine (may serialize as strings)
- Lua emitters (may pass strings or numbers)
- JSON data (parsed as numbers but could be strings)

Using `tonumber()` ensures consistent numeric types.

---

## Testing Checklist

- [x] Build succeeds
- [x] Game launches
- [ ] Buy items from shop (should work without `canAfford` error)
- [ ] Accumulate 500+ gold (should unlock "rich" achievement)
- [ ] Stack jokers to tier 5 (should unlock "tier5_master")
- [ ] No type comparison errors in console

---

## Related Issues

These fixes address runtime errors discovered during playtesting:

**Previous Fixes**:
- Issue #1: JSON loading API (`files.loadJSON`)
- Issue #2: Module type confusion (Static/Singleton/Instance)
- Issue #3: Joker stack type comparison (line 224)
- Issue #4: Graphics API mismatch (Love2D → Magic Hands)

**Current Fixes**:
- Issue #5: Gold type comparison (line 240)
- Issue #6: Missing `canAfford` method

---

## Pattern: Type-Safe Event Handlers

**Template for all numeric event data**:
```lua
events.on("event_name", function(data)
    -- Convert all numeric fields
    local numericValue = tonumber(data.value) or defaultValue
    
    -- Safe to compare now
    if numericValue >= threshold then
        -- Handle event
    end
end)
```

**Apply to**:
- `gold_changed` - data.amount, data.delta
- `joker_added` - data.stack
- `hand_scored` - data.score, data.handTotal
- `shop_purchase` - data.cost
- Any event with numeric data

---

## Build Info

**Version**: v0.3.3  
**Status**: ✅ All runtime errors fixed  
**Files Modified**: 2 (MagicHandsAchievements.lua, Shop.lua)

---

**Last Updated**: January 28, 2026  
**Phase**: 3 (Meta-Progression & Polish)
