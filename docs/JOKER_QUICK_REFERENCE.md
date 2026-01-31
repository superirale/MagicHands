# Joker System Quick Reference

## Condition Types

| String | Description | Example |
|--------|-------------|---------|
| `contains_rank:<rank>` | Has specific rank | `contains_rank:7` |
| `contains_suit:<suit>` | Has specific suit | `contains_suit:H` |
| `count_15s <op> <n>` | Compare fifteens | `count_15s > 0` |
| `count_pairs <op> <n>` | Compare pairs | `count_pairs >= 2` |
| `count_runs <op> <n>` | Compare runs | `count_runs > 0` |
| `has_nobs` | Has nobs (boolean) | `has_nobs` |
| `hand_total_21` | Totals 21 (boolean) | `hand_total_21` |

**Operators:** `>`, `>=`, `<`, `<=`, `==`, `!=`

## Counter Types

| String | Description |
|--------|-------------|
| `each_15` | Count of 15 combinations |
| `each_pair` | Count of pair combinations |
| `each_run` | Count of run sequences |
| `cards_in_runs` | Total cards in runs |
| `card_count` | Total cards in hand |
| `each_even` | Even-ranked cards |
| `each_odd` | Odd-ranked cards |
| `each_face` | Face cards (J, Q, K) |
| `each_<rank>` | Specific rank (e.g., `each_7`, `each_K`) |
| `each_<suit>` | Specific suit (e.g., `each_H`, `each_S`) |

## Effect Types

| String | Description |
|--------|-------------|
| `add_chips` | Add chips to score |
| `add_multiplier` | Add temporary multiplier |
| `add_temp_mult` | Alias for `add_multiplier` |
| `add_permanent_multiplier` | Add permanent multiplier |

## JSON Template

### Simple Joker
```json
{
    "id": "my_joker",
    "name": "My Joker",
    "rarity": "common",
    "triggers": ["on_score"],
    "conditions": ["count_15s > 0"],
    "effects": [{
        "type": "add_chips",
        "value": 50,
        "per": "each_15"
    }]
}
```

### Tiered Joker
```json
{
    "id": "my_joker_tiered",
    "stackable": true,
    "triggers": ["on_score"],
    "conditions": ["count_pairs > 0"],
    "tiers": [
        {
            "level": 1,
            "effects": [{ "type": "add_chips", "value": 20, "per": "each_pair" }]
        },
        {
            "level": 2,
            "effects": [{ "type": "add_chips", "value": 40, "per": "each_pair" }]
        }
    ]
}
```

## Adding New Types

### New Condition
```cpp
// 1. Create class
class MyCondition : public Condition {
    bool evaluate(const HandResult& hand) const override {
        // Logic here
    }
    std::string getDescription() const override { return "my_condition"; }
};

// 2. Register in ConditionFactory.cpp
if (conditionStr == "my_condition") {
    return std::make_unique<MyCondition>();
}
```

### New Counter
```cpp
// 1. Add to appropriate class (Pattern or CardProperty)
// 2. Register in CounterFactory.cpp
if (perString == "my_counter") {
    return std::make_unique<MyCounter>();
}
```

### New Effect
```cpp
// 1. Create class
class MyEffect : public Effect {
    EffectResult apply(const HandResult& hand, int count) const override {
        EffectResult result;
        result.addedChips = /* logic */;
        return result;
    }
    float getValue() const override { return m_Value; }
};

// 2. Register in EffectFactory.cpp
if (type == "my_effect") {
    return std::make_unique<MyEffect>(value);
}
```

## Testing

```bash
# All tests
./magic_hands_tests

# Specific system
./magic_hands_tests "[condition]"
./magic_hands_tests "[counter]"
./magic_hands_tests "[effect]"

# Specific test
./magic_hands_tests "HasNobsCondition"
```

## Common Patterns

**Add bonus when condition met:**
```json
{ "conditions": ["count_15s > 0"], "effects": [{ "type": "add_chips", "value": 50 }] }
```

**Scale by count:**
```json
{ "effects": [{ "type": "add_chips", "value": 20, "per": "each_15" }] }
```

**Multiple effects:**
```json
{
    "effects": [
        { "type": "add_chips", "value": 30 },
        { "type": "add_multiplier", "value": 2.0 }
    ]
}
```

## Files

- **Main System:** `src/gameplay/joker/JokerEffectSystem.cpp`
- **Conditions:** `src/gameplay/joker/conditions/`
- **Counters:** `src/gameplay/joker/counters/`
- **Effects:** `src/gameplay/joker/effects/`
- **Tests:** `tests/TestJoker*.cpp`
- **Full Docs:** `docs/JOKER_SYSTEM.md`
