# Magic Hands - Complete Project Outline

**Last Updated**: January 30, 2026  
**Recent Changes**: Fixed crib scoring to apply full effect pipeline (jokers, augments, imprints, warps)

---

## Table of Contents
1. [Codebase Understanding](#codebase-understanding)
2. [Gameplay Explanation](#gameplay-explanation)
3. [Technical Implementation](#technical-implementation)
4. [Recent Fixes & Changes](#recent-fixes--changes)

---

# 📚 Codebase Understanding

## 🎮 **Game Overview**
**Magic Hands** is a **Cribbage-based roguelike card game** (similar to Balatro) built with a custom C++20 game engine. The game combines traditional Cribbage scoring mechanics with roguelike deck-building, featuring:
- Card collection and scoring system based on Cribbage rules (15s, pairs, runs, flushes, nobs)
- 40 Jokers with tiered stacking mechanics (5 tiers: Base → Amplified → Synergy → Rule Bend → Ascension)
- Campaign progression through Acts and Blinds (Small/Big/Boss)
- Shop system with enhancements, planets, rule warps, imprints, and deck sculptors
- Meta-progression with 40 achievements and unlock system
- Boss battles with unique mechanics

## 🏗️ **Architecture**

**Technology Stack:**
- **Language**: C++20 with Lua 5.4 scripting
- **Rendering**: SDL3 (GPU-accelerated)
- **Physics**: Box2D v3.0.0
- **Audio**: Orpheus audio middleware
- **Data**: nlohmann/json for configuration
- **Testing**: Catch2 v3.5.2

**Design Philosophy:**
> **"Game logic in Lua. Engine primitives in C++."**
- C++ provides low-level systems (rendering, physics, input, audio)
- Lua handles all gameplay logic, UI, and game state
- Hot-reloadable scripts (press F6)
- Data-driven design with JSON definitions

## 📁 **Project Structure**

```
MagicHands/
├── src/                      # C++ Engine (~15,700 lines)
│   ├── core/                # Engine, Logger, WindowManager, Base64
│   ├── graphics/            # SpriteRenderer, FontRenderer, Animation, ParticleSystem
│   ├── physics/             # PhysicsSystem, NoiseGenerator (Box2D wrapper)
│   ├── audio/               # AudioSystem (Orpheus wrapper)
│   ├── input/               # InputSystem
│   ├── scripting/           # Lua bindings (*Bindings.cpp)
│   ├── ui/                  # UISystem, UILayout
│   ├── events/              # EventSystem (pub/sub)
│   ├── asset/               # AssetManager, AssetConfig
│   ├── tilemap/             # TileMap, TileSet, TileLayer, ObjectLayer
│   ├── pathfinding/         # Pathfinder
│   └── gameplay/            # Game-specific C++ systems
│       ├── card/            # Card, Deck
│       ├── cribbage/        # HandEvaluator, ScoringEngine
│       ├── joker/           # Joker, JokerEffectSystem
│       ├── blind/           # Blind
│       └── boss/            # Boss
├── content/
│   ├── scripts/             # Lua game logic
│   │   ├── main.lua         # Entry point
│   │   ├── scenes/          # GameScene, TitleScene, SplashScene
│   │   ├── UI/              # HUD, ShopUI, CollectionUI, etc.
│   │   ├── criblage/        # CampaignState, JokerManager, Economy, Shop
│   │   ├── Systems/         # Achievements, Unlocks, Undo
│   │   └── visuals/         # CardView, EffectManager
│   ├── data/                # JSON definitions
│   │   ├── achievements.json
│   │   ├── jokers/          # 40 joker definitions
│   │   ├── enhancements/    # Planet cards (21 total)
│   │   ├── imprints/        # Card imprints (25 total)
│   │   ├── warps/           # Rule warps (15 total)
│   │   ├── spectrals/       # Deck sculptors (8 total)
│   │   └── bosses/          # Boss definitions (12 total)
│   ├── images/              # Sprites, UI textures, card atlas
│   ├── audio/               # Sound effects and music
│   └── fonts/               # TTF fonts
├── tests/                   # Catch2 unit tests
├── docs/                    # Comprehensive documentation
└── build/                   # CMake output
```

## 🎯 **Core Systems**

### **1. Card System (C++)**
- `Card` class: Rank (1-13), Suit (Hearts/Diamonds/Clubs/Spades)
- `Deck` class: 52-card deck with shuffle, draw, discard
- Cribbage scoring: 15s, pairs, runs, flushes, nobs
- `HandEvaluator`: Detects all scoring patterns
- `ScoringEngine`: Calculates final score with modifiers

### **2. Joker System (C++ + Lua)**
- **Data-driven**: JSON definitions with triggers, conditions, effects
- **Stackable Jokers**: ~25% support tier progression (×1 to ×5)
- **Effect Types**: `add_chips`, `add_multiplier`, `add_permanent_multiplier`
- **JokerEffectSystem**: Processes effects in resolution order
- **JokerManager** (Lua): 5-slot inventory, stacking logic

### **3. Campaign & Blinds**
- **3 Acts** with increasing difficulty multipliers (1.0x, 2.5x, 6.0x)
- **3 Blind Types**: Small, Big, Boss
- **Boss System**: 12 unique bosses with special rules
- **CampaignState** (Lua): Tracks act, gold, hands, discards

### **4. Shop & Economy**
- Purchase jokers, planets, warps, imprints, sculptors
- Rarity-based pricing: Common/Uncommon/Rare/Legendary
- Reroll system (costs gold)
- **UnlockSystem**: Progressive content gating (start with 20%, unlock through achievements)

### **5. Enhancement System**
- **Planets** (Hand Augments): Stackable, no downside
- **Rule Warps**: Max 3 active, powerful but risky
- **Imprints**: Bind to specific cards, max 2 per card
- **Sculptors** (Deck Shapers): Rare, modify deck composition

### **6. Meta-Progression (Phase 3)**
- **40 Achievements** across 10 categories
- **Collection UI**: 6 tabs (Achievements, Jokers, Planets, Warps, Imprints, Sculptors)
- **Tier Indicators**: Visual badges for joker tiers
- **Score Preview**: Real-time calculation when selecting cards
- **Undo System**: Press Z to undo mistakes
- **Run Statistics**: Track 9 metrics per run
- **Achievement Notifications**: Animated popups

### **7. Rendering System**
- **SpriteRenderer**: Batch rendering for performance
- **FontRenderer**: Text rendering with TTF fonts
- **ParticleSystem**: Object-pooled particles
- **Animation**: Frame-based sprite animation
- **Post-processing**: Shader support (CRT shader included)
- Camera system with zoom and viewport control

### **8. Event System**
- Publish/subscribe pattern
- Events: `hand_scored`, `blind_won`, `run_complete`, `joker_added`, `gold_changed`, etc.
- Priority-based handlers
- Event queuing for deferred processing

## 🔧 **Code Style & Conventions**

```cpp
// Classes: PascalCase
class SpriteRenderer { };

// Member variables: m_ prefix + PascalCase
SDL_GPUDevice* m_GPUDevice;

// Static variables: s_ prefix + PascalCase  
static LogLevel s_MinLevel;

// Functions/Methods: PascalCase
void Update(float dt);

// Parameters/locals: camelCase
void SetCamera(float x, float y);

// Constants/Enums: PascalCase
enum class LogLevel { Trace, Debug, Info, Warn, Error };

// Lua bindings: Lua_ prefix + PascalCase
static int Lua_CreateBody(lua_State* L);
```

## 📊 **Current Status**

**✅ Phase 1 Complete**: Core systems (Imprints, Sculptors, Tiers)  
**✅ Phase 2 Complete**: Content creation (121 cards total)  
**✅ Phase 3 Complete**: Meta-progression & Polish

**Content Breakdown:**
- 40 Jokers (10 stackable)
- 21 Planets (Hand Augments)
- 15 Rule Warps
- 25 Imprints
- 8 Sculptors (Deck Shapers)
- 12 Bosses
- 40 Achievements

**Build Status**: ✅ Successful (Release)  
**Game Status**: 🎮 Fully Playable

## ⌨️ **Controls**

| Key | Action |
|-----|--------|
| **C** | Open/Close Collection |
| **TAB** | Show/Hide Run Statistics |
| **Z** | Undo |
| **Enter** | Play hand |
| **Backspace** | Discard cards |
| **1/2** | Sort by rank/suit |
| **F6** | Hot-reload Lua scripts |

## 📚 **Key Documentation**

- `AGENTS.md` - AI coding agent development guide
- `API.md` - Complete Lua API reference
- `README.md` - Project overview
- `GDD.MD` - Master game design document
- `PHASE3_COMPLETE.md` - Latest feature completion status
- `ROADMAP.MD` - Implementation roadmap

## 🔍 **Notable Technical Details**

1. **Singleton Pattern**: Used for managers (Engine, WindowManager, AssetManager)
2. **Result<T>**: Error handling pattern (no exceptions)
3. **Logger**: All logging via `LOG_*` macros (Trace/Debug/Info/Warn/Error)
4. **Precompiled Headers**: `src/core/pch.h` includes common headers
5. **Content Directory**: Copied to build directory post-build
6. **Thread Safety**: Most systems NOT thread-safe (main thread only)
7. **Tracy Profiler**: Optional integration (cmake -DMAGIC_HANDS_ENABLE_TRACY=ON)

## 🚀 **Build Commands**

```bash
# Configure
mkdir -p build && cd build
cmake ..

# Build
cmake --build . --config Release

# Run
./MagicHand

# Test
ctest --output-on-failure
./magic_hands_tests
```

---

# 🃏 Gameplay Explanation

## 🎯 **Core Concept**

Magic Hands is a **Cribbage-based roguelike deck-builder** (think Balatro meets traditional Cribbage). You're trying to score points by making poker-like combinations, but using **Cribbage scoring rules** instead. Your goal is to build a powerful engine of Jokers and enhancements to reach increasingly higher score targets.

---

## 🎮 **How a Run Works**

### **Campaign Structure**
- **3 Acts** with escalating difficulty
- Each Act has **3 Blinds** (challenges):
  - **Small Blind** - Warm-up (easier target)
  - **Big Blind** - Main challenge (harder target)
  - **Boss Blind** - Unique boss with special rules

### **Score Targets (Examples)**
- **Act 1**: Small (100), Big (250), Boss (600)
- **Act 2**: Small (600), Big (1400), Boss (3000)
- **Act 3**: Even higher...

Each Blind gives you **multiple hands** (usually 3-4) to reach the target score. If you don't reach it, you lose the run!

---

## 🎴 **Playing a Hand** (Core Loop)

### **1. DEAL Phase**
- You're dealt **6 cards** from a standard 52-card deck
- You must choose **2 cards to put in the "Crib"**
  - The Crib is a special 2-card collection
  - Cards you put in the Crib are **immediately replaced** from the deck
  - The Crib persists across multiple hands within the same Blind
  - The Crib **only scores on the final hand** of the Blind (bonus points!)
- You now have **4 cards** in your hand to play

### **2. PLAY Phase**
- Select which cards you want to score (usually all 4)
- A **Cut Card** is revealed (5th card drawn randomly)
- Press **Enter** to lock in your selection

### **3. SCORE Phase**
This is where the magic happens! The game evaluates your hand using **Cribbage scoring rules**:

#### **Cribbage Scoring Categories:**

1. **Fifteens** (2 points each)
   - Any combination of cards that adds to 15
   - Face cards (J/Q/K) = 10, Aces = 1
   - Example: 5 + 10 = 15 (2 points), 7 + 8 = 15 (2 points)

2. **Pairs** (2 points each)
   - Two cards of the same rank
   - Three of a kind = 3 pairs = 6 points
   - Four of a kind = 6 pairs = 12 points

3. **Runs** (length points)
   - 3+ sequential cards (regardless of suit)
   - Example: 4-5-6 = 3 points, J-Q-K = 3 points
   - 4-card run = 4 points, 5-card run = 5 points

4. **Flush** (4 or 5 points)
   - All 4 cards in hand same suit = 4 points
   - All 5 cards (including cut card) same suit = 5 points

5. **Nobs** (1 point)
   - Jack in your hand matches the suit of the cut card

#### **Score Calculation:**
```
Base Chips = Sum of all category points
Multiplier = 1.0 + (Temporary Multipliers) + (Permanent Multipliers)
Final Score = Base Chips × Multiplier
```

Your score is added to your **running total** for the Blind. Reach the target to win!

### **4. SHOP Phase**
After clearing a Blind, you visit the shop where you can:
- **Buy Jokers** (permanent modifiers, 5 slots max)
- **Buy Enhancements** (Planets, Warps, Imprints, Sculptors)
- **Sell Items** (get gold back)
- **Reroll** the shop (costs gold)

---

## 🃏 **The Joker System** (Your Power Scaling)

Jokers are **permanent modifiers** that make you stronger:

### **Joker Examples:**
- **"Fifteen Fever"**: +3 multiplier per fifteen scored
- **"Pair Power"**: +20 chips per pair
- **"Runner's High"**: +2 multiplier per run

### **Joker Slots:**
- You have **5 Joker slots** maximum
- Jokers trigger automatically when their conditions are met
- Some Jokers are **stackable**...

### **Stackable Jokers & Tiers** (The Key Progression!)
About 25% of Jokers can be **stacked** (bought multiple times):

| Stack | Tier | Effect |
|-------|------|--------|
| ×1 | **Base** | Standard effect (e.g., +3 mult per Ace) |
| ×2 | **Amplified** | Numeric boost (e.g., +5 mult per Ace) |
| ×3 | **Synergy** | New effect added (e.g., +5 mult + 30 chips per Ace) |
| ×4 | **Rule Bend** | Game-changing (e.g., +12 mult + 60 chips + 0.3x permanent mult) |
| ×5 | **Ascension** | Build-defining (e.g., +25 mult + 150 chips + 1.0x permanent mult) |

**Example:** "Ace Power" Joker
- Stack 1: +3 mult per Ace
- Stack 2: +5 mult per Ace
- Stack 3: +8 mult + 30 chips per Ace
- Stack 4: +12 mult + 60 chips + 0.3x permanent mult
- Stack 5: +25 mult + 150 chips + 1.0x permanent mult (**BUILD AROUND THIS!**)

---

## 🌟 **Enhancement System**

### **1. Planets (Hand Augments)** - Stable Power
- Boost specific scoring categories
- **Unlimited stacking**, no downside
- Examples:
  - "The Fifteen": +4 chips to all 15s
  - "The Run": Runs gain +1 mult
  - "The Pair": Pairs gain +10 chips

### **2. Rule Warps (Spectral Cards)** - High Risk/Reward
- **Max 3 active** at once
- Powerful but often have drawbacks
- Often **irreversible**
- Examples:
  - "Ghost Cut": Cut card always scores (+15% blind scaling penalty)
  - "Poltergeist": All 5s are wild (bosses stronger)

### **3. Imprints** - Card Modification
- Bind effects to **specific cards**
- **Max 2 imprints per card**
- Persist through reshuffles
- Examples:
  - "Gold Inlay": This card gives +0.1x mult when scored
  - "Echo": Retrigger this card's effects
  - "Lucky Pips": 5% chance to retrigger

### **4. Sculptors (Deck Shapers)** - Deck Manipulation
- **Rare/Mythic only**
- Permanently modify your deck
- Examples:
  - Remove all 2s from deck
  - Duplicate all Aces
  - Add wild cards

---

## 👑 **Boss Battles**

Boss Blinds have **special rules** that counter dominant strategies:

- **The Counter**: 15s count as 14 (no points!)
- **The Skunk**: Multipliers disabled
- **The Dealer**: Your discards score for the enemy
- **The Auditor**: Stack bonuses don't work
- **The Purist**: Can't use Rule Warps
- **The Breaker**: Imprinted cards may shatter
- **The Collapser**: Ascension tier jokers increase blind scaling

Bosses force you to **adapt your strategy**!

---

## 🏆 **Meta-Progression**

### **Achievements** (40 total)
- 10 categories: First Steps, Collection, Joker Mastery, Economic, Score Hunter, Strategic, Milestones, Boss Slayer, Spectral, Prestige
- Examples:
  - "First Steps": Play your first hand
  - "Perfect Score": Score 29 points (perfect cribbage hand)
  - "Completionist": Unlock all 121 cards

### **Unlock System**
- Start with **20% of content** (24/121 items)
- Unlock more by **completing achievements**
- Unlockable content:
  - New Jokers
  - New Planets
  - New Rule Warps
  - New Imprints
  - New Sculptors

### **Collection UI** (Press C)
- View all unlocked/locked content
- 6 tabs: Achievements, Jokers, Planets, Warps, Imprints, Sculptors
- Track your progress

---

## 🎯 **Win/Loss Conditions**

### **Victory**
- Complete **Act 3 Boss Blind** (reach the target score)

### **Defeat**
- Fail any Blind (run out of hands before reaching target)
- You can always retry with new strategies!

---

## 🧠 **Strategic Depth**

### **Key Decisions:**
1. **What to put in the Crib?** (builds for final hand bonus)
2. **Which Jokers to buy?** (synergies matter!)
3. **When to stack vs diversify?** (focus on a few strong jokers or spread out?)
4. **Which cards to Imprint?** (5s and Aces are valuable!)
5. **Risk Rule Warps?** (big power, but penalties...)
6. **Deck sculpting?** (remove low cards, add more 5s?)

### **Sample Build Paths:**
- **"Fifteen Engine"**: Stack "Fifteen Fever" joker + "The Fifteen" planet + Imprint 5s with Gold Inlay
- **"Pair Explosion"**: Duplicate high-value ranks + "Pair Power" joker + "The Pair" planet
- **"Run Master"**: Keep sequential cards + "Runner's High" joker + "The Run" planet
- **"Wild Chaos"**: Use Rule Warps to make cards wild + high-tier jokers

---

## 🎮 **Example Turn**

1. **Dealt**: 5♠, 7♥, 8♣, 10♦, J♠, Q♥
2. **Discard to Crib**: 10♦, Q♥ (replaced with 3♠, 9♦)
3. **Hand**: 5♠, 7♥, 8♣, 3♠, 9♦ (choose 4 to play)
4. **Select**: 5♠, 7♥, 8♣, 9♦
5. **Cut Card**: K♠
6. **Scoring**:
   - Fifteens: 7+8 = 15 (2 pts), none other
   - Pairs: None
   - Runs: 7-8-9 = 3 pts (run of 3)
   - Flush: None
   - Nobs: None
   - **Base Chips: 5 points**
7. **Jokers Apply**:
   - "Fifteen Fever" (×2): +6 multiplier (1 fifteen × 2 stacks × +3 mult)
   - "Runner's High": +2 multiplier (1 run)
   - **Total Multiplier: 1.0 + 6 + 2 = 9.0x**
8. **Final Score**: 5 × 9.0 = **45 points**!

---

## 🎊 **The Core Loop**

```
Play Hand → Score Points → (Repeat 3-4 times) → Clear Blind
    ↓
Visit Shop → Buy Jokers/Enhancements → Get Stronger
    ↓
Face Next Blind (Higher Target) → Repeat
    ↓
Reach Boss → Adapt to Boss Rules → Win or Lose
    ↓
(If Win) → Next Act (Even Harder!)
```

---

# 🛠️ Technical Implementation

## **Global Resolution Order** (CRITICAL for Scoring)

When a hand is scored, effects are applied in this exact order:

1. **Card Imprints** - Individual card bonuses
2. **Hand Augments** (Planets) - Category boosts
3. **Rule Warps** - Game rule modifications
4. **Jokers** - Permanent modifier effects
5. **Joker Set Bonuses** - Stack tier effects
6. **Boss Modifiers** - Boss penalties/rules
7. **Final Clamps** - Apply caps (temp mult ≤10x, perm mult ≤5x)

## **Scoring Formula**

```
Base Chips = Sum of all category points (15s, pairs, runs, flush, nobs)
             + Flat chip additions from effects

Multiplier = 1.0 
             + Σ(temporary multipliers)    [capped at 10x]
             + Σ(permanent multipliers)     [capped at 5x]

Final Score = Base Chips × Multiplier
```

## **Data-Driven Architecture**

All game content is defined in JSON files:

```json
{
  "id": "ace_power_tiered",
  "name": "Ace Power",
  "rarity": "common",
  "type": "utility",
  "stackable": true,
  "triggers": ["on_score"],
  "conditions": ["contains_rank:A"],
  "tiers": [
    {
      "level": 1,
      "name": "Base",
      "effects": [{"type": "add_multiplier", "value": 3, "per": "each_A"}]
    },
    {
      "level": 2,
      "name": "Amplified",
      "effects": [{"type": "add_multiplier", "value": 5, "per": "each_A"}]
    }
    // ... up to tier 5
  ]
}
```

## **Game State Machine** (Lua)

```
DEAL → PLAY → SCORE → SHOP → BLIND_PREVIEW → (loop)
```

Each state is managed in `GameScene.lua` with transitions based on player actions and game events.

## **Event-Driven Architecture**

The game uses a pub/sub event system for loose coupling:

```lua
-- Subscribe
events.on("hand_scored", function(data)
    MagicHandsAchievements:onHandScored(data)
end)

-- Emit
events.emit("hand_scored", {
    score = totalScore,
    categories = {...},
    jokers_used = {...}
})
```

---

## 📝 **Summary**

**Magic Hands** is a feature-complete Cribbage roguelike with:
- Deep strategic deck-building mechanics
- Tiered progression system encouraging focused builds
- Rich meta-progression with achievements and unlocks
- Data-driven content architecture for easy expansion
- Clean separation between engine (C++) and game logic (Lua)

The game is currently in **Phase 3 Complete** status and is fully playable!

---

# 🔧 Recent Fixes & Changes

## Fix: Crib Scoring Now Applies Full Effect Pipeline (January 30, 2026)

### **Problem**
The crib was only inheriting the numeric multipliers from the main hand, but NOT re-evaluating jokers, augments, imprints, and warps against the crib's own patterns.

**Example Issue:**
- Main hand has 4 fifteens with "Fifteen Fever" joker → gets +24 mult
- Crib hand has 2 fifteens → should get +12 mult from same joker
- **OLD**: Crib only used the 24 mult from main hand (ignored crib's fifteens)
- **NEW**: Crib now evaluates its own patterns and gets +12 mult

### **Solution**
Modified `GameScene.lua:676-780` to apply the complete scoring pipeline to crib:

1. ✅ **Evaluate crib patterns** - Call `cribbage.evaluate()` for crib hand
2. ✅ **Apply Card Imprints** - Resolve imprints on crib cards
3. ✅ **Apply Hand Augments** - Re-evaluate planets against crib patterns
4. ✅ **Apply Rule Warps** - Reuse global warp effects (cut bonus, retrigger, penalties)
5. ✅ **Apply Jokers** - Re-evaluate all joker effects against crib patterns
6. ✅ **Calculate final score** - Use same formula as main hand

### **Code Changes**

**File**: `content/scripts/scenes/GameScene.lua`  
**Lines**: 676-780

**Key Changes:**
- Maintain both `cribCards` (C++ objects) and `cribCardsLua` (Lua tables) for imprint resolution
- Call full effect pipeline: imprints → augments → warps → jokers
- Apply same score aggregation formula as main hand
- Track separate gold earned from crib card imprints

### **Impact**

**Before:**
```lua
-- Crib only got inherited multipliers
cribScore = baseChips × (1 + mainHandMult)
```

**After:**
```lua
-- Crib gets full effect evaluation
cribChips = baseChips + augmentChips + jokerChips + imprintChips
cribMult = 1 + (baseMult + augmentMult + jokerMult + imprintMult) × imprintXMult
cribScore = cribChips × cribMult × warpEffects
```

### **Benefits**

1. ✅ **Consistent gameplay** - Crib scoring now matches main hand scoring
2. ✅ **Joker synergies work** - Building around specific patterns (fifteens, pairs, runs) now benefits crib
3. ✅ **Imprints matter** - The 2 player-selected crib cards with imprints are now valuable
4. ✅ **Strategic depth** - Players can optimize crib card selection for their build
5. ✅ **"The Crib" planet** - Future crib-specific augments will work correctly

### **Testing**

To test the fix:
1. Build a deck with "Fifteen Fever" joker or similar pattern-based joker
2. Add cards to crib that form the same pattern (e.g., 5s for fifteens)
3. On final hand, check crib score breakdown
4. Verify joker effects apply to crib's patterns, not just inherited multipliers

Expected console output:
```
--- CRIB SCORING PIPELINE ---
Crib Base: 10 x 1.0
Crib Augments: +8 Chips, +2 Mult
Crib Jokers: +0 Chips, +12 Mult
Crib Imprints: +0 Chips, +0 Mult, x1.0
Crib Final Score: 234
-----------------------------
```

### **Future Work**

- Consider creating "The Crib" planet enhancement (mentioned in GDD but not implemented)
- Add UI indicator showing crib scoring is different/enhanced
- Consider separate achievement for high crib scores
