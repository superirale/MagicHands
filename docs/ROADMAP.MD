# Criblage Implementation Roadmap

## Overview
A Balatro-style roguelike built on Cribbage scoring mechanics with 50 Jokers, deck manipulation, and boss battles.

**Tech Stack**: Magic Hands Engine (SDL3, Lua, C++, Box2D)

---

## Phase 1: Core Foundation (Weeks 1-3)

### 1.1 Card System
- [ ] **Card Data Structure** (C++)
  - Card entity with rank, suit, value
  - 52-card deck representation
  - Shuffle with seeded RNG
- [ ] **Card Rendering** (Lua + C++)
  - Card sprite system (front/back)
  - Card positioning and layout
  - Drag and drop mechanics
- [ ] **Hand Management**
  - Draw 4 cards (configurable to 5)
  - Discard system (1-2 per hand)
  - Lock-in mechanism
  - Cut card reveal animation

### 1.2 Cribbage Scoring Engine
- [ ] **HandEvaluationSystem** (C++)
  - Detect fifteens (all combinations)
  - Detect pairs/trips/quads
  - Detect runs (3+ sequential cards)
  - Detect flushes (4+ same suit)
  - Detect nobs (Jack matching cut suit)
- [ ] **Scoring Pipeline**
  - Base chip calculation per category
  - Diminishing returns (100%, 75%, 50%, 25%)
  - Multiplier aggregation (temp + permanent)
  - Final score formula: `chips × (1 + temp_mult + perm_mult)`
  - Cap enforcement (temp ≤10x, perm ≤5x)

### 1.3 Basic UI Framework
- [ ] **Game State Management** (Lua)
  - Blind preview screen
  - Hand phase
  - Scoring phase
  - Shop/event phase
- [ ] **HUD Elements**
  - Score display
  - Blind progress bar
  - Gold counter
  - Discard remaining
- [ ] **Card UI**  
  - Hand display (4-5 cards)
  - Selected state highlighting
  - Discard pile visualization

---

## Phase 2: Joker System (Weeks 4-5)

### 2.1 Joker Data Architecture
- [ ] **JSON Definitions** (`content/data/jokers.json`)
  - ID, name, rarity, triggers, conditions, effects
  - Effect types: add_chips, add_multiplier, modify_rule, etc.
  - Per-hand caps
- [ ] **JokerManager** (C++/Lua)
  - Load joker definitions
  - 5-slot joker inventory
  - Trigger evaluation system
  - Effect application pipeline

### 2.2 Core Joker Types
- [ ] **Category Amplifiers** (10 Jokers)
  - Boost fifteens, pairs, runs, flushes
  - Example: "Fifteen Fever" (+0.2x per 15)
- [ ] **Rule Benders** (10 Jokers)
  - Face cards as numbers
  - Aces high & low
  - Multiple cut cards
- [ ] **Economy Jokers** (10 Jokers)
  - Gold per category trigger
  - Discount shop items
  - Extra rerolls

### 2.3 Joker UI
- [ ] **Joker Display**
  - 5-slot horizontal bar
  - Hover tooltips
  - Glow effect when triggered
- [ ] **Shop Integration**
  - Joker purchase screen
  - Sell mechanism
  - Rarity-based pricing

---

## Phase 3: Blind & Boss System (Weeks 6-7)

### 3.1 Blind Progression
- [ ] **Blind Scaling Formula**
  - Small/Big/Boss targets per act
  - Act 1: 100/250/600
  - Act 2: 600/1400/3000
  - Difficulty modifiers
- [ ] **Blind Types**
  - Small blind (warming up)
  - Big blind (main challenge)
  - Boss blind (rule changes)

### 3.2 Boss Mechanics (8 Bosses MVP)
- [ ] **Boss Definitions** (JSON)
  - The Counter (15s count as 14)
  - The Skunk (multipliers disabled)
  - Thirty-One (pegging only)
  - The Dealer (discards score for enemy)
  - The Auditor (disables stack bonuses)
  - The Purist (no duplicate Jokers)
  - The Collapser (Ascension increases scaling)
  - +1 more boss
- [ ] **Boss UI**
  - Pre-fight warning screen
  - Boss rule display during fight
  - Victory/defeat animations

### 3.3 Run Structure  
- [ ] **Act System**
  - 2 Acts for MVP
  - 3 blinds per act
  - Shop after each blind
- [ ] **Win/Loss Conditions**
  - Win: Clear Act 2 Boss
  - Loss: Fail any blind
  - Scoring feedback screen

---

## Phase 4: Deck Manipulation & Shop (Week 8)

### 4.1 Shop System
- [ ] **Shop Screen** (Lua UI)
  - Joker slots (3-5 random)
  - Deck mod options
  - Reroll button (cost gold)
- [ ] **Deck Modifications**
  - Remove ranks (e.g., remove all 2s)
  - Duplicate specific cards
  - Increase rank/suit weighting
  - Add wild cards
  - Allow duplicate identities

### 4.2 Economy
- [ ] **Gold System**
  - Earn gold per blind
  - Bonus gold for overkill
  - Shop pricing tiers
- [ ] **Event System** (Starter)
  - 5 random events
  - Risk/reward mechanics
  - Examples: gamble, upgrade, curse

---

## Phase 5: Scoring Animations & Feedback (Weeks 9-10)

### 5.1 Scoring Breakdown UI
- [ ] **Category Animations**
  - Fifteens flash and stack
  - Pairs bounce
  - Runs animate sequentially
  - Flushes glow
- [ ] **Multiplier Visualization**
  - Temp multipliers stack visually
  - Permanent multipliers shown separately
  - Final score explosion effect
- [ ] **Joker Triggers**
  - Glow when activated
  - Pop-up tooltip showing effect
  - Sound effects per trigger

### 5.2 Polish
- [ ] **Particle Effects**
  - Score numbers float up
  - Gold coins sparkle
  - Card shuffle effects
- [ ] **Audio Integration**
  - Card play sounds
  - Scoring chimes
  - Joker activation sounds
  - Music tracks (menu, shop, battle)

---

## Phase 6: Meta Progression (Week 11)

### 6.1 Unlocks System
- [ ] **Unlock Tracker** (JSON persistence)
  - New Jokers (unlock by beating bosses)
  - New bosses
  - Alternative scoring tables
  - Endless mode
- [ ] **Difficulty Stakes**
  - Stake 1-3 for MVP
  - Each stake adds modifiers:
    - Fewer discards
    - Faster blind scaling
    - Joker caps
    - Combined boss effects

### 6.2 Player Profile
- [ ] **Save/Load System**
  - Persistent unlocks
  - Run history
  - High scores
  - Stats tracking

---

## Phase 7: MVP Content Creation (Week 12)

### 7.1 Joker Content (50 Total)
- [ ] Category Amplifiers: 15
- [ ] Rule Benders: 12
- [ ] Risk/Reward: 10
- [ ] Economy: 8
- [ ] Chaos/God Tier: 5

### 7.2 Balance Pass
- [ ] Blind scaling tuning
- [ ] Joker power levels
- [ ] Gold economy
- [ ] Boss difficulty

---

## Phase 8: Joker Set Bonus System (Week 13)

### 8.1 Stack Mechanic
- [ ] **Stack Detection**
  - Detect duplicate Jokers
  - Track stack count (1-5)
  - Apply tier bonuses
- [ ] **Stack Tiers**
  - ×2: Amplified (numeric boost)
  - ×3: Synergy (new trigger)
  - ×4: Rule Bend (conversion)
  - ×5: Ascension (transformation)

### 8.2 Stackable Jokers (12-15)
- [ ] Convert ~25% of Jokers to stackable
- [ ] Define stack_bonuses in JSON
- [ ] UI badge system (×2, ×3, ×4, ×5)
- [ ] Visual progression (gold edge, glow, pulse)

---

## Phase 9: Polish & Testing (Week 14)

### 9.1 Bug Fixes
- [ ] Edge case testing (all Joker combos)
- [ ] RNG determinism verification
- [ ] Save/load stability
- [ ] Performance optimization

### 9.2 Tutorial & Onboarding
- [ ] Interactive tutorial
  - How to score fifteens
  - Discarding strategy
  - Joker basics
  - Shop mechanics
- [ ] Tooltip system
  - Hover over categories
  - Joker descriptions
  - Boss warnings

### 9.3 Final UI/UX
- [ ] Menu screens (main, settings, credits)
- [ ] Keybindings config
- [ ] Resolution support
- [ ] Accessibility options

---

## Phase 10: Optional - Pegging System (Post-MVP)

### 10.1 Pegging Flow
- [ ] Player plays card → AI responds
- [ ] Running count toward 31
- [ ] Peg events (15, 31, pair, run, go)
- [ ] Rewards apply next hand

### 10.2 AI Profiles
- [ ] Aggressive (pairs)
- [ ] Arithmetic (15/31)
- [ ] Runner (runs)
- [ ] Chaos (random)

---

## Tech Implementation Notes

### Data-Driven Architecture
```
content/
  ├── data/
  │   ├── jokers.json         # All 50 Jokers
  │   ├── bosses.json         # 8 Boss definitions
  │   ├── events.json         # Random events
  │   └── deck_mods.json      # Shop upgrades
  └── scripts/
      ├── systems/
      │   ├── ScoringSystem.lua
      │   ├── JokerSystem.lua
      │   ├── ShopSystem.lua
      │   └── BlindSystem.lua
      └── ui/
          ├── GameUI.lua
          ├── ShopUI.lua
          └── ScoreUI.lua
```

### C++ Systems
- `HandEvaluator.cpp` - Core cribbage logic
- `JokerEngine.cpp` - Effect resolution
- `RNG.cpp` - Seeded random
- `SaveManager.cpp` - Persistence

### Lua Game Logic
- State machine (menu → blind → hand → score → shop)
- UI rendering and input
- Animation sequencing
- Game flow control

---

## Milestones

### M1: Playable Prototype (Week 3)
- Deal hand, score fifteens/pairs/runs, see total chips

### M2: Joker Integration (Week 5)
- 20 Jokers working, shop functional

### M3: Full Run (Week 7)
- 2 Acts, 8 Bosses, win condition

### M4: MVP Complete (Week 12)
- 50 Jokers, all systems, balanced

### M5: Polish (Week 14)
- Tutorial, sounds, effects, ready to ship

---

## Success Metrics
- Average run time: 15-25 minutes
- Player understands scoring after 2 runs
- At least 3 viable build archetypes
- Boss variety feels distinct
- Shop decisions feel meaningful

---

## Risk Mitigation
- **Scope creep**: Defer pegging to post-MVP
- **Balance nightmare**: Spreadsheet all Joker effects early
- **UI complexity**: Prototype animations in code first
- **Performance**: Profile scoring pipeline with 100 Jokers active

---

## Post-Release Content Plan
- Add 100 more Jokers (total 150)
- Add pegging system
- Add 10 more bosses (total 18)
- Add endless mode
- Add daily challenges
- Add leaderboards
