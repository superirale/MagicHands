# Phase 3 Architecture Overview

This document provides a visual overview of how Phase 3 systems integrate with the Magic Hands game engine.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GameScene (Main Loop)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Camera      │  │ CampaignState│  │EffectManager │          │
│  │  (Viewport)  │  │  (Game State)│  │  (Particles) │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              PHASE 3 SYSTEMS (NEW)                        │  │
│  ├───────────────────────────────────────────────────────────┤  │
│  │                                                             │  │
│  │  ┌─────────────────┐        ┌──────────────────┐         │  │
│  │  │ Achievement     │◄───────┤  Event System    │         │  │
│  │  │ System          │        │  (C++ Core)      │         │  │
│  │  └────────┬────────┘        └──────────────────┘         │  │
│  │           │                                                │  │
│  │           │ unlocks                                        │  │
│  │           ▼                                                │  │
│  │  ┌─────────────────┐                                      │  │
│  │  │ Unlock System   │                                      │  │
│  │  │ (Content Gate)  │                                      │  │
│  │  └────────┬────────┘                                      │  │
│  │           │                                                │  │
│  │           │ provides                                       │  │
│  │           ▼                                                │  │
│  │  ┌─────────────────┐    ┌────────────────┐              │  │
│  │  │ Collection UI   │    │ Undo System    │              │  │
│  │  │ (6 Tabs)        │    │ (State Stack)  │              │  │
│  │  └─────────────────┘    └────────────────┘              │  │
│  │                                                             │  │
│  │  ┌─────────────────┐    ┌────────────────┐              │  │
│  │  │ Score Preview   │    │ Tier Indicator │              │  │
│  │  │ (Real-time)     │    │ (Joker Stacks) │              │  │
│  │  └─────────────────┘    └────────────────┘              │  │
│  │                                                             │  │
│  │  ┌──────────────────┐   ┌────────────────┐              │  │
│  │  │ Achievement      │   │ Run Stats      │              │  │
│  │  │ Notification     │   │ Panel          │              │  │
│  │  └──────────────────┘   └────────────────┘              │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  HUD         │  │  ShopUI      │  │  DeckView    │          │
│  │  (Core UI)   │  │  (Shopping)  │  │  (Collection)│          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Event Flow

```
┌──────────────────┐
│  Player Action   │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│  Game Logic (JokerManager, Shop, CampaignState)  │
└────────┬─────────────────────────────────────────┘
         │
         │ emits event
         ▼
┌──────────────────┐
│  Event System    │◄───────── C++ Core (EventSystem::Instance())
│  (events.emit)   │
└────────┬─────────┘
         │
         │ broadcasts
         ├──────────────────────────────────────────────┐
         │                                              │
         ▼                                              ▼
┌─────────────────────┐                    ┌────────────────────┐
│ Achievement System  │                    │  Other Listeners   │
│ (checks conditions) │                    │  (Future Systems)  │
└────────┬────────────┘                    └────────────────────┘
         │
         │ on unlock
         ▼
┌─────────────────────┐
│  Unlock System      │
│  (gates content)    │
└────────┬────────────┘
         │
         │ shows notification
         ▼
┌──────────────────────┐
│ Achievement          │
│ Notification UI      │
└──────────────────────┘
```

## Event Types and Sources

| Event | Source File | Line | Triggers |
|-------|------------|------|----------|
| `hand_scored` | GameScene.lua | 511 | Player plays 4 cards |
| `blind_won` | GameScene.lua | 531 | Score exceeds blind requirement |
| `run_complete` | GameScene.lua | 545 | Player loses (game over) |
| `joker_added` | JokerManager.lua | ? | Joker purchased/added |
| `joker_slots_full` | JokerManager.lua | ? | All 5 joker slots filled |
| `gold_changed` | Economy.lua | ? | Gold earned/spent |
| `shop_purchase` | Shop.lua | ? | Item bought from shop |
| `shop_reroll` | Shop.lua | ? | Shop rerolled |
| `sculptor_used` | Shop.lua | ? | Deck sculptor applied |
| `discard_used` | CampaignState.lua | ? | Player discards cards |

## UI Layer Hierarchy (Z-Order)

```
┌─────────────────────────────────────────┐  TOP (Layer 9)
│   Achievement Notification              │  Always visible
├─────────────────────────────────────────┤
│   Collection UI (C key)                 │  Layer 8
├─────────────────────────────────────────┤
│   Run Stats Panel (TAB key)             │  Layer 7
├─────────────────────────────────────────┤
│   Tier Indicators (on jokers)           │  Layer 6
├─────────────────────────────────────────┤
│   Score Preview (PLAY state)            │  Layer 5
├─────────────────────────────────────────┤
│   State-specific UI                     │  Layer 4
│   - Shop UI                             │
│   - Blind Preview                       │
│   - Deck View                           │
├─────────────────────────────────────────┤
│   Cards & Crib                          │  Layer 3
├─────────────────────────────────────────┤
│   HUD & Helper Text                     │  Layer 2
├─────────────────────────────────────────┤
│   Background                            │  Layer 1 (Base)
└─────────────────────────────────────────┘
```

## Data Flow: Achievement Unlock

```
1. Player Action
   └─► Game Logic (e.g., JokerManager:addJoker())
       └─► Event Emission (events.emit("joker_added", {...}))
           └─► Achievement System Listener
               └─► Check Conditions (e.g., "collect 5 jokers")
                   └─► Achievement Unlocked!
                       ├─► UnlockSystem:unlockContent("joker_mystery_box")
                       │   └─► New content available in shop
                       └─► AchievementNotification:show(achievement)
                           └─► Animated popup appears
```

## Keyboard Input Routing

```
┌──────────────────┐
│ Input.isPressed  │
└────────┬─────────┘
         │
         ├─── [C] ──────► Toggle Collection UI
         │                (blocks other input when open)
         │
         ├─── [TAB] ────► Toggle Run Stats Panel
         │
         ├─── [Z] ──────► Undo System (PLAY state only)
         │
         ├─── [Enter] ──► Play Hand (PLAY state)
         │
         ├─── [Backspace]► Discard Cards (PLAY state)
         │
         ├─── [1] ──────► Sort by Rank
         │
         └─── [2] ──────► Sort by Suit
```

## Score Calculation with Phase 3 Integration

```
┌──────────────────────────────────────────────────────────┐
│ GameScene:playHand()                                      │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  1. Get selected cards (4 hand + 1 cut)                  │
│  2. Boss Rules                                            │
│  3. Base Score (cribbage.evaluate + cribbage.score)      │
│  4. Card Imprints (EnhancementManager:resolveImprints)   │
│  5. Hand Augments (EnhancementManager:resolveAugments)   │
│  6. Rule Warps (EnhancementManager:resolveWarps)         │
│  7. Jokers & Tiers (JokerManager:applyEffects)           │
│  8. Final Score = (Chips + Bonuses) × Multipliers        │
│                                                            │
│  9. ► events.emit("hand_scored", {...}) ◄─────────────┐  │
│                                                        │  │
│  10. Check Campaign Result                             │  │
│      ├─► WIN:  events.emit("blind_won", {...})        │  │
│      └─► LOSS: events.emit("run_complete", {...})     │  │
│                                                        │  │
└────────────────────────────────────────────────────────┼──┘
                                                         │
                                                         ▼
                                              ┌────────────────────┐
                                              │ Achievement System │
                                              │ (listens & tracks) │
                                              └────────────────────┘
```

## Update Loop Integration

```
GameScene:update(dt)
├─► EffectManager:update(dt)
├─► [PHASE 3] achievementNotification:update(dt)
├─► [PHASE 3] undoSystem:update(dt)
│
├─► Input: Check keyboard shortcuts
│   ├─► [C] → Toggle Collection
│   ├─► [TAB] → Toggle Run Stats
│   └─► [Z] → Undo action
│
├─► [PHASE 3] If Collection Open:
│   └─► collectionUI:update(dt, mx, my, clicked)
│       └─► return early (blocks other input)
│
├─► State-specific updates:
│   ├─► SHOP → shopUI:update()
│   ├─► DECK_VIEW → deckView:update()
│   ├─► BLIND_PREVIEW → blindPreview:update()
│   └─► PLAY:
│       ├─► [PHASE 3] Update Score Preview
│       ├─► Handle card dragging
│       ├─► Handle card selection
│       └─► [PHASE 3] Track undo state
│
└─► End of frame
```

## Memory Management

All Phase 3 systems follow these patterns:

1. **Singleton Pattern**: `MagicHandsAchievements`, `UnlockSystem`
   - Single instance per game session
   - Persistent state across scenes

2. **UI Components**: Instantiated in `GameScene:init()`
   - Lifecycle tied to GameScene
   - Cleaned up when scene destroyed

3. **Event Listeners**: Registered in `:init()` methods
   - Use weak references where possible
   - Cleaned up automatically by event system

4. **State Management**:
   - Achievement progress: Saved to disk
   - Unlock state: Saved to disk
   - Run stats: In-memory only (resets per run)
   - Undo stack: In-memory only (cleared on new hand)

## File Structure

```
content/
├── data/
│   └── achievements.json              (40 achievements)
├── scripts/
│   ├── Systems/
│   │   ├── MagicHandsAchievements.lua (Achievement tracking)
│   │   ├── UnlockSystem.lua           (Content gating)
│   │   └── UndoSystem.lua             (Undo stack)
│   ├── UI/
│   │   ├── CollectionUI.lua           (6-tab collection)
│   │   ├── TierIndicator.lua          (Joker tier badges)
│   │   ├── ScorePreview.lua           (Real-time preview)
│   │   ├── AchievementNotification.lua (Popup animation)
│   │   └── RunStatsPanel.lua          (9 stat tracking)
│   └── scenes/
│       └── GameScene.lua              (Main integration)
```

## Performance Profile

| System | Update Cost | Draw Cost | Notes |
|--------|------------|-----------|-------|
| Achievement System | O(1) per event | None | Event-driven, no polling |
| Unlock System | O(1) lookup | None | Hash table lookups |
| Collection UI | O(n) items | O(visible) | Only updates when open |
| Tier Indicators | None | O(jokers) | Max 5 jokers |
| Score Preview | O(cards) | O(1) | Only in PLAY state |
| Achievement Notification | O(1) | O(1) | Single animation |
| Run Stats Panel | O(1) | O(stats) | Max 9 stats |
| Undo System | O(1) | None | Fixed stack size |

**Total Overhead**: ~2-5% CPU when all systems active

## Testing Strategy

### Unit Tests
- Achievement condition evaluation
- Unlock system logic
- Undo stack operations

### Integration Tests
- Event emission → Achievement unlock
- Achievement unlock → Content available
- UI interaction → State changes

### Manual Tests
- Play through full run
- Verify all 40 achievements can unlock
- Test all keyboard shortcuts
- Verify UI layering and overlays
- Check save/load persistence

---

**Last Updated**: January 28, 2026  
**Architecture Version**: 3.0 (Phase 3 Complete)
