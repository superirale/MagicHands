# Phase 3: Polish & Meta-Progression

## Overview

Phase 3 focuses on transforming Magic Hands from a content-complete game into a polished, replayable roguelike with meta-progression systems that keep players engaged across multiple runs.

**Status**: 📋 Planning Phase  
**Prerequisites**: Phase 1 ✅ Complete | Phase 2 ✅ Complete

---

## 🎯 Phase 3 Goals

1. **Meta-Progression** - Unlock systems and persistent progression
2. **Visual Polish** - Animations, effects, and UI improvements
3. **Quality of Life** - Player convenience features
4. **Additional Content** - Extend beyond GDD minimums
5. **Balance & Tuning** - Playtesting-driven adjustments

---

## 📋 Phase 3 Tasks Breakdown

### 1. Meta-Progression System (High Priority)

#### Unlock System
- **Progressive Content Unlocking**
  - Start with 10 jokers, 5 planets, 3 warps unlocked
  - Unlock new content by achieving milestones
  - Track discovery progress (X/121 items discovered)
  
- **Unlock Conditions**
  - Win Act 1 → Unlock 5 random items
  - Win Act 2 → Unlock 10 random items
  - Win Act 3 → Unlock 15 random items
  - Score X points in single hand → Unlock tier-based joker
  - Use specific joker combo → Unlock synergy card
  - Beat specific boss → Unlock counter-card

#### Achievement System
- **Core Achievements** (30 total)
  - Score Milestones: "Score 10,000 in one hand"
  - Category Mastery: "Win with only 15s"
  - Tier Achievements: "Stack a joker to tier 5"
  - Boss Victories: "Defeat all 12 bosses"
  - Collection: "Unlock all jokers"
  - Economy: "Reach 500 gold in one run"
  
- **Secret Achievements** (10 total)
  - Hidden challenges for exploration
  - Easter eggs and special combos

#### Persistent Upgrades
- **Starting Bonuses** (unlock with achievements)
  - Start with +50 gold
  - Start with 1 random planet
  - Begin with extra hand/discard
  - Unlock better starting decks
  - Increase shop slots to 4
  
- **Meta Currency** (optional)
  - "Prestige Points" earned from runs
  - Spend on permanent upgrades
  - Unlock special game modes

#### Collection Browser
- **Card Compendium**
  - View all discovered cards
  - See full stats and tier progressions
  - Track usage statistics
  - Read lore/flavor text (if added)

**Files to Create/Modify:**
- `content/scripts/Systems/UnlockSystem.lua`
- `content/scripts/Systems/AchievementSystem.lua` (expand existing)
- `content/scripts/Systems/ProgressionManager.lua`
- `content/scripts/UI/CollectionUI.lua`
- `content/data/unlocks.json`
- `content/data/achievements.json`

---

### 2. Visual Polish (High Priority)

#### Tier Indicators
- **Joker Visual Upgrades**
  - Display current tier (1-5) on joker card
  - Visual effects at tier 3, 4, 5 (glow, particles)
  - "Ascension" aura for tier 5 jokers
  - Stack counter animation

#### Card Effects
- **Imprint Indicators**
  - Visual badge on imprinted cards
  - Glow effect during scoring
  - Show active imprint effects in tooltip

#### Animations
- **Purchase Animations**
  - Card flip when buying from shop
  - "New unlock!" banner with card reveal
  - Achievement popup with sound
  
- **Scoring Animations**
  - Number popup for chip/mult gains
  - Category highlight during evaluation
  - "Big Win" screen for high scores
  
- **Tier Up Animation**
  - Visual transformation when joker stacks
  - Particle burst for tier 5 ascension
  - Sound effect escalation

#### UI Improvements
- **Enhanced HUD**
  - Clearer blind progress bar
  - Minimap of unlocks
  - Run statistics panel
  
- **Better Tooltips**
  - Show exact effect calculations
  - Display tier progression preview
  - Boss modifier explanations

**Files to Modify:**
- `content/scripts/visuals/EffectManager.lua`
- `content/scripts/UI/HUD.lua`
- `content/scripts/visuals/CardView.lua`
- `src/graphics/ParticleSystem.cpp` (if needed)

---

### 3. Quality of Life Features (Medium Priority)

#### Gameplay QoL
- **Undo System**
  - Undo last discard (before committing)
  - Undo card selection in crib
  - "Are you sure?" for important decisions
  
- **Auto-Sort Options**
  - Sort hand by rank
  - Sort by suit
  - Sort by value
  - Smart sort (groups scoring combos)
  
- **Score Preview**
  - Show potential score before playing hand
  - Highlight scoring cards
  - Show effect breakdown (base + jokers + planets)
  
- **Quick Actions**
  - Keyboard shortcuts (1-5 for hand selection)
  - Right-click for quick actions
  - "Skip animation" toggle

#### Information Display
- **Run Statistics**
  - Hands played / discarded
  - Total score across run
  - Gold earned / spent
  - Highest single hand score
  - Cards imprinted
  
- **Build Summary**
  - Active jokers with effects
  - Active warps and tradeoffs
  - Planet collection
  - Boss modifiers
  
- **History Log**
  - Last 5 hands played with scores
  - Purchase history
  - Blind progression

**Files to Modify:**
- `content/scripts/scenes/GameScene.lua`
- `content/scripts/UI/HUD.lua`
- `content/scripts/UI/StatsUI.lua` (new)
- `content/scripts/Systems/HistoryTracker.lua` (new)

---

### 4. Additional Content (Medium Priority)

#### Extend Beyond GDD Minimums
- **10 More Jokers** (40 → 50)
  - Focus on niche strategies
  - Combo-enabler jokers
  - "Meme" jokers for fun builds
  
- **5 More Planets** (21 → 26)
  - Dwarf planets (Ceres, Eris, Makemake, etc.)
  - Constellation-themed
  
- **5 More Warps** (15 → 20)
  - More extreme tradeoffs
  - Synergy-focused warps
  
- **New Card Types** (optional)
  - "Vouchers" - Permanent shop upgrades
  - "Artifacts" - Passive effects (equipment-like)
  - "Curses" - Negative effects with rewards

#### Special Jokers
- **Legendary Tier Jokers**
  - Ultra-rare, build-defining
  - Unique mechanics not in GDD
  - Examples: "The Architect" (design your own combo), "Infinity Gauntlet" (breaks all rules)

**Files to Create:**
- `content/data/jokers/` (10 more files)
- `content/data/enhancements/` (5 more planets)
- `content/data/warps/` (5 more warps)
- `content/data/vouchers/` (new category)

---

### 5. Game Modes (Low Priority)

#### Daily Challenge
- **Seeded Runs**
  - Same seed for all players each day
  - Leaderboard for highest score
  - Fixed shop rolls and boss order
  - Special modifiers rotate daily

#### Custom Mode
- **Rule Editor**
  - Start with specific jokers
  - Modify blind scaling
  - Enable/disable content
  - Create challenge runs

#### Endless Mode
- **Infinite Progression**
  - Acts continue beyond Act 3
  - Blinds scale infinitely
  - Unlock "prestige" tiers
  - Leaderboard for highest act reached

**Files to Create:**
- `content/scripts/modes/DailyChallenge.lua`
- `content/scripts/modes/CustomMode.lua`
- `content/scripts/modes/EndlessMode.lua`
- `content/scripts/Systems/LeaderboardManager.lua`

---

### 6. Balance & Tuning (Ongoing)

#### Playtesting Goals
- **Balance Pass 1: Numbers**
  - Adjust chip/mult values
  - Tune blind requirements
  - Rebalance shop prices
  - Fix overpowered combos

- **Balance Pass 2: Progression**
  - Act difficulty curve
  - Unlock pacing
  - Achievement difficulty
  - Meta-progression speed

- **Balance Pass 3: Variety**
  - Ensure all builds are viable
  - No dominant strategies
  - Boss fairness
  - Warp tradeoff validation

#### Analytics (Optional)
- **Track Gameplay Data**
  - Win rate by act
  - Most/least used jokers
  - Average scores
  - Time to complete runs
  - Unlock progression speed

**Tools Needed:**
- Playtest spreadsheet
- Balance calculator
- Analytics dashboard (optional)

---

## 📊 Phase 3 Priority Matrix

### Must-Have (Launch Blockers)
1. ✅ Meta-progression unlock system
2. ✅ Achievement system expansion
3. ✅ Tier visual indicators
4. ✅ Collection browser
5. ✅ Basic balance pass

### Should-Have (Polish)
6. ⭐ Undo system
7. ⭐ Score preview
8. ⭐ Run statistics
9. ⭐ Purchase animations
10. ⭐ Auto-sort options

### Nice-to-Have (Post-Launch)
11. 🌟 Daily challenge mode
12. 🌟 10 more jokers
13. 🌟 Custom mode
14. 🌟 Endless mode
15. 🌟 Advanced analytics

---

## 🗓️ Estimated Timeline

**Assuming full-time development:**

| Task Category | Estimated Time | Priority |
|---------------|----------------|----------|
| Meta-Progression System | 5-7 days | High |
| Visual Polish | 4-6 days | High |
| Quality of Life | 3-5 days | Medium |
| Additional Content | 2-4 days | Medium |
| Game Modes | 5-7 days | Low |
| Balance & Tuning | Ongoing | Ongoing |
| **TOTAL** | **19-29 days** | **~4-6 weeks** |

---

## 🎮 Success Criteria

Phase 3 is complete when:

✅ **Unlock system works** - Players start with limited content and unlock more  
✅ **Achievements functional** - 30+ achievements trackable and rewarding  
✅ **Collection browser exists** - Players can view all discovered cards  
✅ **Visual polish complete** - Tier indicators, animations, effects visible  
✅ **QoL features implemented** - Undo, preview, auto-sort, statistics  
✅ **Balance pass done** - Playtested, tuned, no game-breaking combos  
✅ **Game feels complete** - Polish level matches content quality  

---

## 🚀 Beyond Phase 3

After Phase 3, the game would be ready for:
- **Beta Testing** - External playtesters
- **Marketing** - Trailers, screenshots, press kit
- **Steam Page** - Store page setup
- **Early Access / Launch** - Public release
- **Live Service** - Seasonal content, events
- **DLC / Expansions** - New mechanics, acts, cards

---

## 📝 Notes

**Philosophy**: Phase 3 transforms Magic Hands from "content-complete" to "launch-ready." Focus on:
- Player retention (meta-progression keeps them coming back)
- Juice (animations and effects make it feel good to play)
- Accessibility (QoL features reduce friction)
- Replayability (unlocks, achievements, modes)

**Scope Management**: Start with "Must-Have" features. "Should-Have" and "Nice-to-Have" can be post-launch updates.

---

**Ready to start Phase 3?** Let me know which subsystem to tackle first!
