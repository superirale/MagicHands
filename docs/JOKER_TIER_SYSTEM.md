# Joker Tier System

## Overview

The Joker Tier System implements the GDD's 5-tier stacking progression for Magic Hands jokers. Instead of linear scaling, stackable jokers gain **qualitative upgrades** at each tier level.

## GDD Specification

| Stack | Tier | Effect Type |
|-------|------|-------------|
| ×1 | Base | Standard effect |
| ×2 | Amplified | Numeric improvement |
| ×3 | Synergy | New trigger |
| ×4 | Rule Bend | Conversion / override |
| ×5 | Ascension | Build-defining transformation |

## Implementation

### JSON Schema

Stackable jokers now use a `tiers` array instead of a single `effects` array:

```json
{
    "id": "lucky_seven_tiered",
    "name": "Lucky Seven",
    "rarity": "common",
    "stackable": true,
    "triggers": ["on_score"],
    "conditions": [],
    "tiers": [
        {
            "level": 1,
            "name": "Base",
            "description": "+7 Mult per 7",
            "effects": [
                {
                    "type": "add_multiplier",
                    "value": 7,
                    "per": "each_7"
                }
            ]
        },
        {
            "level": 2,
            "name": "Amplified",
            "description": "+12 Mult per 7",
            "effects": [
                {
                    "type": "add_multiplier",
                    "value": 12,
                    "per": "each_7"
                }
            ]
        },
        {
            "level": 3,
            "name": "Synergy",
            "description": "+15 Mult per 7, +50 chips per 15",
            "effects": [
                {
                    "type": "add_multiplier",
                    "value": 15,
                    "per": "each_7"
                },
                {
                    "type": "add_chips",
                    "value": 50,
                    "per": "each_15"
                }
            ]
        },
        {
            "level": 4,
            "name": "Rule Bend",
            "description": "+20 Mult per 7, gains permanent mult",
            "effects": [
                {
                    "type": "add_multiplier",
                    "value": 20,
                    "per": "each_7"
                },
                {
                    "type": "add_permanent_multiplier",
                    "value": 0.5,
                    "per": "each_7"
                }
            ]
        },
        {
            "level": 5,
            "name": "Ascension",
            "description": "Massive bonuses, build-defining power",
            "effects": [
                {
                    "type": "add_multiplier",
                    "value": 50,
                    "per": "each_7"
                },
                {
                    "type": "add_permanent_multiplier",
                    "value": 2.0,
                    "per": "each_7"
                },
                {
                    "type": "add_chips",
                    "value": 100,
                    "per": "each_7"
                }
            ]
        }
    ]
}
```

### C++ Implementation

#### Joker.h
- Added `tieredEffects` map: `std::map<int, std::vector<JokerEffect>>`
- Added `stackable` flag
- Loads tier data from JSON `tiers` array

#### JokerEffectSystem.cpp
- New function: `ApplyJokersWithStacks()` accepts `std::vector<std::pair<Joker, int>>`
- Determines which effect set to use based on stack count
- For tiered jokers: uses tier effects directly (no multiplication)
- For legacy jokers: multiplies base effects by stack count

#### JokerBindings.cpp
- Updated `Lua_JokerApplyEffects()` to accept optional 4th parameter: `stackCounts` table
- Passes stack counts (1-5) to C++ for proper tier resolution

### Lua Integration

#### JokerManager.lua
```lua
function JokerManager:applyEffects(hand, trigger)
    local jokerPaths = {}
    local stackCounts = {}
    
    for _, jokerObj in ipairs(self.slots) do
        table.insert(jokerPaths, "content/data/jokers/" .. jokerObj.id .. ".json")
        table.insert(stackCounts, jokerObj.stack)  -- Pass actual stack count
    end

    return joker.applyEffects(jokerPaths, hand, trigger, stackCounts)
end
```

#### EnhancementManager.lua
- Updated `resolveAugments()` to pass stack counts for planet cards
- Planets can stack infinitely (GDD: "Unlimited stacking")

## Migration Guide

### Converting Existing Jokers to Tiered System

1. **Identify stackable jokers** (currently ~25% should be stackable per GDD)

2. **Design tier progression**:
   - Tier 1: Base effect (same as current)
   - Tier 2: 1.5-2x numeric boost
   - Tier 3: Add secondary effect or new trigger
   - Tier 4: Add conversion or permanent mult
   - Tier 5: Transformative, build-defining power

3. **Update JSON format**:
   - Remove `effects` array
   - Add `stackable: true`
   - Add `tiers` array with 5 levels

### Example: Converting "Fifteen Fever"

**Before (linear stacking):**
```json
{
    "id": "fifteen_fever",
    "effects": [{"type": "add_chips", "value": 15, "per": "each_15"}]
}
```

**After (tiered):**
```json
{
    "id": "fifteen_fever",
    "stackable": true,
    "tiers": [
        {"level": 1, "effects": [{"type": "add_chips", "value": 15, "per": "each_15"}]},
        {"level": 2, "effects": [{"type": "add_chips", "value": 25, "per": "each_15"}]},
        {"level": 3, "effects": [
            {"type": "add_chips", "value": 35, "per": "each_15"},
            {"type": "add_multiplier", "value": 1, "per": "each_15"}
        ]},
        {"level": 4, "effects": [
            {"type": "add_chips", "value": 50, "per": "each_15"},
            {"type": "add_multiplier", "value": 2, "per": "each_15"}
        ]},
        {"level": 5, "effects": [
            {"type": "add_chips", "value": 100, "per": "each_15"},
            {"type": "add_multiplier", "value": 5, "per": "each_15"},
            {"type": "add_permanent_multiplier", "value": 0.5}
        ]}
    ]
}
```

## Backward Compatibility

Non-stackable jokers continue to use the legacy `effects` array:
- No `tiers` field = use old system
- Stack count is ignored (always treated as 1)
- Multiple copies in inventory take separate slots

## Testing

Test files for tier system:
- `content/scripts/test_joker_tiers.lua` - Unit tests for tier progression
- `content/data/jokers/lucky_seven_tiered.json` - Example tiered joker

## Balance Considerations

1. **Tier 5 Power Level**: Ascension effects should be game-winning but not broken
2. **Blind Scaling**: GDD notes "Ascension can exceed caps but increases blind scaling"
3. **Rarity**: Higher rarity jokers should have more powerful tier 5 transformations
4. **Shop Pool**: Maxed jokers (stack 5) removed from shop generation

## Future Enhancements

- **Tier-specific conditions**: e.g., "Tier 3+ only triggers if..."
- **Ascension resolution order**: Implement GDD rule "Ascension effects resolve last"
- **Visual indicators**: UI showing current tier level and next tier preview
- **Tier-down mechanic**: Boss that reduces joker stacks?

---

**Last Updated**: January 2026  
**Status**: Fully Implemented (Phase 1 Complete)
