# CRIBLAGE (Cribbage Roguelike)

A Balatro‑style roguelike built on Cribbage math, arithmetic combos, and rule‑breaking Jokers.

---

## 1. CORE RULES

- Deck: Standard 52 cards
- Hand size: 4 cards (unlockable to 5)
- Discards: 1–2 per hand (difficulty‑scaled)
- Cut Card: 1 revealed after lock‑in
- Scoring uses **hand + cut**

---

## 2. BASE SCORING TABLE (CHIPS ONLY)

| Category | Formula |
|--------|---------|
| Fifteens | 10 × count(15‑combinations) |
| Pair | 12 × pairs |
| Three‑of‑a‑kind | 24 |
| Four‑of‑a‑kind | 48 |
| Run | 8 × run_length |
| Flush | 20 (4), +10 per extra card |
| Nobs | 15 |

### Diminishing Returns (per category per hand)
- 1st trigger: 100%
- 2nd: 75%
- 3rd: 50%
- 4th+: 25%

---

## 3. FINAL SCORE FORMULA

```
chips = sum(category_chips × diminishing_factor)
final_score = chips × (1 + temporary_multiplier + permanent_multiplier)
```

Caps:
- Temporary multiplier ≤ 10x
- Permanent multiplier ≤ 5x

---

## 4. PEGGING SYSTEM (OPTIONAL MODULE)

### Flow
1. Player plays card
2. AI responds (profile‑based)
3. Running count toward 31
4. Peg events trigger
5. Rewards apply **next hand**

### Peg Rewards
| Event | Effect |
|----|----|
| 15 | +5 chips |
| 31 | +10 chips |
| Pair | +6 chips |
| Run | +8 chips |
| Go | +1 gold |

### AI Profiles
- Aggressive (pairs)
- Arithmetic (15/31)
- Runner (runs)
- Chaos

AI does not hold a real hand; it selects weighted legal plays.

---

## 5. JOKER SYSTEM

- Slots: 5
- Types:
  - Category Amplifiers
  - Rule Benders
  - Risk/Reward
  - Economy
  - Chaos / God Tier

Jokers:
- Trigger **after base scoring**
- Can add chips, multipliers, or modify rules
- Some ignore caps (explicitly marked)

---

## 6. DECK MANIPULATION

### Shop Upgrades
- Remove ranks
- Duplicate specific cards
- Increase rank/suit weighting
- Add wild cards
- Allow duplicate identities

### Permanent Rules
- Face cards as numbers
- Aces high & low
- Multiple cut cards

---

## 7. BLINDS & BOSSES

### Blind Scaling

| Act | Small | Big | Boss |
|----|------|-----|------|
| 1 | 100 | 250 | 600 |
| 2 | 600 | 1400 | 3000 |
| 3 | 3000 | 8000 | 15000 |

### Boss Design Rule
Bosses **break assumptions**, not just numbers.

Examples:
- The Counter – 15s count as 14
- The Skunk – multipliers disabled
- Thirty‑One – pegging only
- The Dealer – discards score for enemy

---

## 8. META PROGRESSION

Unlocks:
- New Jokers
- New bosses
- Alternative scoring tables
- Pegging module
- Endless mode

Difficulty Modifiers:
- Fewer discards
- Faster blind scaling
- Joker caps
- Combined boss effects

---

## 9. UI / UX FLOW

1. Blind preview
2. Hand draw
3. Discard
4. Lock hand
5. Cut reveal (animated)
6. Scoring breakdown (stacked)
7. Pegging (toggle)
8. Score explosion
9. Shop / Event

Design principles:
- Every category animates separately
- Multipliers stack visually
- Jokers glow when triggered

---

## 10. TECH NOTES

- Deterministic RNG (seeded runs)
- Data‑driven joker definitions (JSON)
- ECS‑friendly scoring pipeline
- Immediate‑mode UI compatible

---

## 11. MVP SCOPE

- 50 Jokers
- No pegging
- 2 Acts
- 8 Bosses

Post‑launch: add pegging + chaos jokers.

---

## 12. DESIGN PHILOSOPHY

Cribbage provides:
- Arithmetic depth
- Overlapping scoring axes
- Small hands → fast clarity

Balatro provides:
- Multipliers
- Rule breaking
- Meta progression

Criblage is where they meet.


---

## 13. JOKER DATA FORMAT (IMPLEMENTATION‑READY)

All Jokers are data‑driven.

```json
{
  "id": "fifteen_fever",
  "name": "Fifteen Fever",
  "rarity": "common",
  "triggers": ["on_score"],
  "conditions": ["count_15s > 0"],
  "effects": [
    { "type": "add_multiplier", "value": 0.2, "per": "each_15" }
  ],
  "caps": { "per_hand": 2.0 }
}
```

### Effect Types
- add_chips
- add_multiplier
- add_permanent_multiplier
- convert_chips_to_multiplier
- modify_rule
- spawn_card
- copy_joker

---

## 14. SCORING PIPELINE (ECS‑FRIENDLY)

### Systems Order
1. HandEvaluationSystem
2. CategoryScoringSystem
3. DiminishingReturnsSystem
4. JokerTriggerSystem
5. MultiplierAggregationSystem
6. FinalScoreSystem

### Pseudocode
```
HandResult result;

for category in categories:
  triggers = evaluate(category, hand, cut)
  chips += base_score(category, triggers) * diminishing(triggers)

for joker in jokers:
  if joker.condition(result):
    apply(joker.effects)

final_score = chips * (1 + temp_mult + perm_mult)
```

---

## 15. PEGGING AI WEIGHT TABLES

Each AI has weighted priorities:

### Arithmetic AI
- Make 15 / 31: 60%
- Create pair: 20%
- Create run: 10%
- Random legal: 10%

### Aggressive AI
- Pair/triple: 50%
- Run disruption: 20%
- 15/31: 20%
- Random: 10%

### Chaos AI
- Random legal play: 70%
- Risky overpeg: 30%

---

## 16. DIFFICULTY & ENDLESS SCALING

Blind requirement formula:
```
required_score = base × act_multiplier × difficulty_modifier
```

Act multipliers:
- Act 1: 1.0
- Act 2: 2.5
- Act 3: 6.0
- Endless: +1.4× per blind

Difficulty modifiers:
- Easy: 0.8
- Normal: 1.0
- Hard: 1.3
- Stake+: +0.15 per stake

---

## 17. BALANCE RULES (NON‑NEGOTIABLE)

- No Joker multiplies final score directly unless marked God‑Tier
- Chips grow faster than multipliers
- Permanent multipliers are rare
- Rule‑breaking Jokers reduce economy or increase blind scaling

---

## 18. CONTENT TOTALS (FULL RELEASE)

- Jokers: 150
- Bosses: 18
- Events: 40
- Deck modifiers: 60
- Difficulty stakes: 10

---

## 19. STEAM PITCH CORE

"A roguelike built on the forbidden math of Cribbage.
Score hands, break rules, stack multipliers, and outplay the house.
Every run rewrites the deck."

---

## 20. JOKER SET BONUS SYSTEM

## Overview
The **Joker Set Bonus System** introduces a new layer of strategy by rewarding players for collecting **multiple copies of the same Joker**. Rather than scaling linearly, duplicate Jokers unlock **new effects, rules, and transformations**, allowing players to build powerful, focused strategies.

---

## Purpose
This system encourages:
- **Build identity** (specialized runs)
- **Risk vs reward decision making**
- **Shop investment and commitment**
- **High replay value**

It also creates a *natural power curve* without breaking the core scoring balance.

---

## Mechanics

### Stack Thresholds
Jokers can be stacked up to a maximum number, depending on rarity and design. Stacking thresholds are:

| Stack Count | Name | Effect Type |
|-----------|------|-------------|
| ×1 | Base | Normal Joker effect |
| ×2 | Amplified | Enhanced numeric effects |
| ×3 | Synergy | New triggers or secondary effects |
| ×4 | Rule Bend | Conversion mechanics or rule modifications |
| ×5 | Ascension | Build-defining transformations (rare) |

**Note:** Not all Jokers are stackable to ×5. Some may cap at ×3 or ×4.

---

### System Rules
- **Duplicates must not scale linearly.**
- Each stack tier must introduce *qualitative changes* (new triggers or rules).
- Stack bonuses apply **after base scoring** and after standard Joker effects.
- Ascension (×5) effects are applied **last** and may ignore caps.
- Stackable Jokers are limited to **~25% of total Jokers**.

---

## Data Representation

Jokers are data-driven and include a `stack_bonuses` section:

```json
{
  "id": "fifteen_fever",
  "stackable": true,
  "max_stack": 5,
  "base_effect": { "type": "add_multiplier", "value": 0.2, "per": "each_15" },
  "stack_bonuses": {
    "2": { "modify": { "value": 0.3 } },
    "3": { "add_effect": { "type": "add_chips", "value": 5, "per": "each_15" } },
    "4": { "convert": { "from": "chips", "to": "multiplier", "rate": 0.5, "per": "every_2_15s" } },
    "5": { "override": "merge_triggers", "ignore_caps": true, "final_multiplier_per": 0.6 }
  }
}
```

---

## Example: Fifteen Fever (Stack Bonuses)

| Stack | Effect |
|------|--------|
| ×1 | +0.2x per 15 |
| ×2 | +0.3x per 15 |
| ×3 | +5 chips per 15 |
| ×4 | Every 2nd 15 → +0.5x |
| ×5 | All 15s merge into one mega-trigger; ignores caps |

---

## Engine Flow (Resolution Order)

1. **Base scoring** (hand + cut)
2. **Diminishing returns** applied
3. **Non-stack Jokers** resolved
4. **Stackable Jokers** resolved by group
5. **Ascension (×5)** effects resolved
6. **Final multiplier clamped** (unless ignored)

---

## Balance & Guardrails

- Only a subset of Jokers can stack
- Stack builds reduce shop reroll frequency
- Bosses may disable stack bonuses or duplicate acquisition
- Ascension builds increase blind scaling to prevent runaway scores

---

## UI / UX

### Joker Card Display
- Stack badge: `×2`, `×3`, `×4`, `×5`
- Visual progression:
  - ×3: Gold edge
  - ×4: Animated glow
  - ×5: Pulsing unique animation + sound

### Tooltip Example
```
FIFTEEN FEVER ×4
────────────────
Each 15: +0.3x
Each 15: +5 chips
Every 2nd 15 → +0.5x
```

---

## Boss Interactions (Examples)

| Boss | Stack Interaction |
|------|-------------------|
| The Auditor | Disables stack bonuses |
| The Purist | Disallows duplicate Jokers |
| The Collapser | Ascension Jokers increase blind scaling |

---

## Design Rationale
This system adds:
- **Strategic depth** without extra complexity
- **Meaningful shop decisions**
- **Memorable runs and player stories**
- **A strong identity for the game** (specialized builds)



---

## 21. FINAL NOTE

This document is intentionally complete.
No system depends on vibes or future design decisions.

Criblage can be implemented directly from this spec.

