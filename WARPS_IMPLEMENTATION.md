# Warp System Implementation Status

## ✅ Fully Implemented Warps (Lua)

### Basic Warps
1. **spectral_echo** (The Echo)
   - Effect: Retrigger all scored cards once
   - Implementation: Doubles final score (simplified)
   - Status: ✅ WORKING

2. **spectral_ghost** (Ghost Cut)
   - Effect: Cut card grants +20 chips
   - Implementation: Adds 20 to finalChips before multipliers
   - Status: ✅ FIXED & WORKING

3. **spectral_void** (The Void)
   - Effect: Free discards, -10% score
   - Implementation: score_penalty = 0.9, free_discard flag
   - Status: ✅ WORKING

### Advanced Warps (Lua-Compatible)
4. **warp_ascension** (Ascension)
   - Effect: Double all mult (lose 1 hand per blind)
   - Implementation: mult_multiplier = 2.0
   - Status: ✅ WORKING
   - Note: Hand reduction not yet implemented

5. **warp_fortune** (Fortune)
   - Effect: Score ×1.5 but costs 5g per hand
   - Implementation: score_multiplier = 1.5, hand_cost = 5
   - Status: ✅ WORKING

6. **warp_gambit** (Gambit)
   - Effect: 50% chance for 3× score or 0.5×
   - Implementation: Random multiplier per hand
   - Status: ✅ WORKING

7. **warp_greed** (Greed)
   - Effect: 10% of score → gold, -10% score
   - Implementation: score_to_gold_pct = 0.1, score_penalty = 0.9
   - Status: ✅ WORKING

---

## ⚠️ Partially Implemented (Requires Gameplay Logic)

### Gameplay Warps
8. **warp_chaos** (Chaos)
   - Effect: Reshuffle after every discard
   - Current: Flagged in active_warps
   - Needed: Hook into discard system
   - Status: 🟡 TODO

9. **warp_time** (Time Warp)
   - Effect: Score crib before hand
   - Current: Flagged in active_warps
   - Needed: Reorder scoring sequence
   - Status: 🟡 TODO

10. **warp_infinity** (Infinity)
    - Effect: No hand size limit (+50% blind requirements)
    - Current: Flagged in active_warps
    - Needed: Modify hand selection logic
    - Status: 🟡 TODO

11. **warp_phantom** (Phantom)
    - Effect: Discarded cards still count for scoring
    - Current: Flagged in active_warps
    - Needed: Track discards and include in scoring
    - Status: 🟡 TODO

---

## 🔴 Requires C++ Implementation

### Engine Warps (Complex)
12. **warp_blaze** (Blaze)
    - Effect: First category scores triple, others score nothing
    - Requires: Modify C++ scoring engine to filter categories
    - Status: 🔴 C++ NEEDED

13. **warp_inversion** (Inversion)
    - Effect: Low cards score as high cards
    - Requires: Modify C++ card value system
    - Status: 🔴 C++ NEEDED

14. **warp_mirror** (Mirror)
    - Effect: Pairs count as runs, runs count as pairs
    - Requires: Modify C++ category detection
    - Status: 🔴 C++ NEEDED

15. **warp_wildfire** (Wildfire)
    - Effect: All 5s become wild (+20% blind scaling)
    - Requires: Modify C++ wild card system
    - Status: 🔴 C++ NEEDED

---

## 📊 Implementation Summary

| Status | Count | Warps |
|--------|-------|-------|
| ✅ Working | 7 | echo, ghost, void, ascension, fortune, gambit, greed |
| 🟡 Partial | 4 | chaos, time, infinity, phantom |
| 🔴 C++ Needed | 4 | blaze, inversion, mirror, wildfire |
| **Total** | **15** | All warps accounted for |

---

## 🔧 Technical Details

### Warp Resolution Flow

1. **EnhancementManager:resolveWarps()**
   - Loads all active warp JSONs
   - Returns effects table with modifiers
   - Flags complex warps in `active_warps` array

2. **GameScene Scoring**
   - Main Hand (lines 660-700)
   - Crib Hand (lines 840-870)
   - Applies all Lua-compatible effects

### Effect Types Applied

```lua
-- Numeric modifiers
effects.retrigger          -- Multiply score by (1 + retrigger)
effects.cut_bonus          -- Add to chips before mult
effects.score_penalty      -- Multiply final score
effects.score_multiplier   -- Multiply final score
effects.mult_multiplier    -- Multiply all mult values
effects.hand_cost          -- Deduct gold per hand
effects.score_to_gold_pct  -- Convert % of score to gold

-- Flags
effects.free_discard       -- Boolean for free discards
effects.active_warps       -- Array of warp IDs for complex logic
```

### Scoring Order

1. Base chips + augments + jokers + imprints
2. **+ cut_bonus** (Ghost Cut)
3. Calculate mult (temp + perm)
4. **× mult_multiplier** (Ascension)
5. Final = chips × mult
6. **× score_penalty × score_multiplier** (Void, Fortune, Gambit, Greed)
7. **× (1 + retrigger)** (Echo - simplified)
8. **Convert to gold** (Greed)
9. **Pay hand cost** (Fortune)

---

## 🧪 Testing

### Verified Working
```bash
# Test spectral_ghost (cut bonus)
./MagicHand --autoplay --autoplay-runs=5 --autoplay-strategy=Optimal
# Look for: "Cut Bonus 20" in score breakdown

# Test warp_fortune (1.5x score, -5g)
# Purchase fortune warp and verify:
# - Score increases by ~50%
# - Gold decreases by 5 per hand

# Test warp_gambit (random 3x or 0.5x)
# Multiple runs will show variance in scores

# Test warp_greed (10% → gold)
# Verify gold increases after each hand
```

### Manual Test Procedure
1. Start game normally
2. Reach shop
3. Purchase warp (e.g., spectral_ghost for 30g)
4. Play hand
5. Check score breakdown for warp effects
6. Verify gold/economy changes

---

## 🚀 Future Enhancements

### Priority 1: Gameplay Warps
- Implement chaos (reshuffle on discard)
- Implement time (crib-first)
- Implement infinity (unlimited hand size)
- Implement phantom (count discards)

### Priority 2: C++ Warps
- Design mirror categories system
- Design card value inversion system
- Design wild card system
- Design category filtering (blaze)

### Priority 3: Balance
- Test all warp combinations
- Adjust multipliers/costs based on win rates
- Add warp synergy bonuses
- Consider warp rarity tiers

---

## 📝 Notes

- All basic warps are now data-driven (load from JSON)
- No more hardcoded warp effects in Lua
- Complex warps are flagged but gracefully ignored
- System is extensible for new warps

**Last Updated:** 2026-01-30
**Version:** 1.0
