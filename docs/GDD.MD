# 🃏 MASTER GAME DESIGN DOCUMENT (GDD)
## Core Systems & Architecture

---

## 1. Vision Statement
This game is a **systemic roguelike card engine** inspired by Cribbage and casino mechanics.  
Its core fantasy is *intentional degeneracy*: players build focused, rule-breaking engines that are powerful, expressive, and always counterable.

---

## 1.1 Adaptation from Classic Cribbage
Magic Hands is a **roguelike score-attack** game, not a simulation of traditional Cribbage.

### ❌ Removed Mechanics
- **The Pegging Phase**: There is no alternating play sequence. The tactical depth comes from hand construction and economy management, not play sequencing.
- **The Opponent**: You play against a target score (Blind), not an AI opponent.
- **The Board**: Victory is not reaching 121 points; it is surviving the current Blind.

### ✅ Retained Mechanics
- **The Deal**: 6 cards per hand.
- **The Discard**: Choosing 2 cards for the Crib remains the central tactical decision.
- **The Show**: Hand and Crib are scored using standard Cribbage rules (15s, runs, pairs, flushes, nobs).

### 🃏 Crib Scoring Rules
The Crib is a persistent 2-card collection that accumulates throughout a Blind (multi-hand challenge).

#### Mechanics:
- **Building the Crib**: On each hand, you may add up to 2 cards from your 6-card hand to the Crib
- **Replacement**: Cards added to the Crib are immediately replaced from the deck, maintaining a 6-card hand
- **Persistence**: The Crib carries over between hands within the same Blind
- **Scoring Window**: The Crib is scored **only on the last hand of the Blind**, using the cut card from that final hand
- **Score Application**: Crib score is added to the final hand's score to determine if the Blind is cleared

#### Strategic Implications:
- Early hands: Build a strong Crib without sacrificing immediate scoring
- Final hand: Maximize both hand and Crib scores to clear the Blind
- Hand Augments like "The Crib" can amplify Crib scoring power

---

## 2. Core Progression Pillars

- Limited slots
- Always active
- Some Jokers are stackable

### Shop Generation Rules:
- **No Duplicate Slots**: The same Joker cannot appear twice in a single shop roll.
- **Max Stack Filter**: Jokers at max stack (default 5) are removed from the generation pool.
- **Rarity Weights**: Scale with Act progression.


---

### Pillar 2: Joker Set Bonuses (Duplicates)

Collecting duplicate Jokers unlocks **qualitative upgrades** instead of linear scaling.

| Stack | Tier | Effect |
|----|----|----|
| ×1 | Base | Standard effect |
| ×2 | Amplified | Numeric improvement |
| ×3 | Synergy | New trigger |
| ×4 | Rule Bend | Conversion / override |
| ×5 | Ascension | Build-defining transformation |

Rules:

- Only ~25% of Jokers are stackable

- Ascension effects resolve last

- Duplicates shown as a single stacked card

---

### Pillar 3: Enhancement Cards

Consumable or persistent upgrades that exist outside Joker slots.

#### Categories
1. **Hand Augments (Planet-like)** — stable, stackable
2. **Rule Warps (Spectral-like)** — powerful, risky
3. **Card Imprints** — bind effects to individual cards
4. **Deck Shapers** — modify deck composition

---

## 3. Enhancement Categories

### Hand Augments
- Unlimited stacking
- No downside
- Applied before Jokers

Examples:
- The Fifteen: +4 chips to all 15s
- The Run: Runs gain +1 mult
- The Crib: Crib hands gain +1.5x

---

### Rule Warps
- Max 3 active
- Often irreversible
- Introduce explicit costs

Examples:
- Ghost Cut: Cut card always scores (+15% blind scaling)
- Poltergeist: All 5s are wild (bosses stronger)

---

### Card Imprints
- Persist through reshuffles
- Max 2 per card
- Destroyed if card is removed

Examples:
- Gold Inlay: +0.1x when scored
- Lucky Pips: 5% retrigger chance

---

### Deck Shapers
- Rare / Mythic only
- Often one-time use
- Heavy balance cost

Examples:
- Deck Sculptor: Remove one rank
- Twin Forge: Duplicate a rank

---

## 4. Global Resolution Order (CRITICAL)

1. Card Imprints  
2. Hand Augments  
3. Rule Warps  
4. Jokers  
5. Joker Set Bonuses  
6. Boss Modifiers  
7. Final clamps

---

## 5. Data-Driven Schema (Unified)

All modifiers compile to a shared structure:

```json
{
  "id": "string",
  "type": "joker | augment | warp | imprint | boss",
  "triggers": [],
  "conditions": [],
  "effects": [],
  "order": 0,
  "caps": {}
}
```

---

## 6. Balance Model

### Scoring Formula
Final Score =
(Base Chips + Flat Adds)
× (1 + Σ additive mult)
× Π multiplicative effects

### Scaling Rules
- Chips scale early
- Mult scales late
- Soft mult cap at ×10
- Ascension can exceed caps but increases blind scaling

---

## 7. Boss Counterplay Layer

Bosses exist to attack dominant strategies.

| Boss | Counter |
|----|----|
| The Purist | Disables Rule Warps |
| The Auditor | Halves Hand Augments |
| The Breaker | Imprinted cards may shatter |
| The Collapser | Duplicate Jokers increase blind scaling |

---

## 8. UI Architecture (Text Wireframe)

Main Screen:

- Center: Hand + Crib

- Bottom: Jokers (stacked)

- Left: Enhancement Panel

- Top Right: Boss effects

Enhancement Panel:

- Category icons

- Hover highlights affected cards

- Rule Warps animated subtly

---

## 9. Content Budget (Launch Target)

- 40 Jokers (10 stackable)
- 20 Hand Augments
- 15 Rule Warps
- 25 Card Imprints
- 8 Deck Shapers
- 12 Bosses

---

## 10. Engine Integration Notes

ECS Components:

- CardComponent

- JokerComponent

- ModifierComponent

- StackComponent

- ImprintComponent

Scoring Pipeline:


```cpp

resolveCardImprints();

resolveHandAugments();

resolveRuleWarps();

resolveJokers();

resolveJokerStacks();

applyBossModifiers();

clampAndScore();

```

---

## 11. Design North Star

> Power should feel **earned**, **directed**, and **counterable**.

This document defines a foundation that supports expansions, mods, and future game modes.
