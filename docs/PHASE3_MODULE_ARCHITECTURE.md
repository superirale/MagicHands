# Phase 3 Module Architecture

## Module Types

Phase 3 introduces two types of Lua modules with different usage patterns:

### 1. Singleton Modules (Global State)

These modules maintain global state and are initialized once:

| Module | Purpose | Initialization | Usage |
|--------|---------|----------------|-------|
| `MagicHandsAchievements` | Achievement tracking | `MagicHandsAchievements:init()` | `MagicHandsAchievements:checkProgress()` |
| `UnlockSystem` | Content unlocking | `UnlockSystem:init()` | `UnlockSystem:isUnlocked("joker_id")` |
| `UndoSystem` | Undo stack | `UndoSystem:init()` | `UndoSystem:saveState()` |

**Pattern**:
```lua
-- In GameScene:init()
MagicHandsAchievements:init()

-- Anywhere in code
MagicHandsAchievements:unlock("achievement_id")
```

### 2. Static Function Modules

These modules provide utility functions without state:

| Module | Purpose | Usage |
|--------|---------|-------|
| `ScorePreview` | Score calculation | `ScorePreview.calculate(cards, cutCard)` |
| `TierIndicator` | Visual rendering | `TierIndicator.draw(x, y, tier, font)` |

**Pattern**:
```lua
-- No initialization needed
local preview = ScorePreview.calculate(selectedCards, cutCard)
ScorePreview.draw(x, y, preview, font)
```

### 3. Instance Classes

These classes create unique instances per object:

| Class | Purpose | Instantiation | Usage |
|-------|---------|---------------|-------|
| `CollectionUI` | Collection browser | `CollectionUI(font, smallFont)` | `self.collectionUI:update(dt)` |
| `AchievementNotification` | Popup notifications | `AchievementNotification(font, smallFont)` | `self.achievementNotification:notify(ach)` |
| `RunStatsPanel` | Stats display | `RunStatsPanel(font, smallFont)` | `self.runStatsPanel:draw()` |

**Pattern**:
```lua
-- In GameScene:init()
self.collectionUI = CollectionUI(self.font, self.smallFont)

-- In GameScene:update()
self.collectionUI:update(dt, mx, my, clicked)
```

---

## Implementation Details

### Singleton Module Pattern

```lua
-- MagicHandsAchievements.lua
local MagicHandsAchievements = {}

-- Module-level state (shared globally)
local achievements = {}
local achievementDefs = {}

function MagicHandsAchievements:init()
    -- Initialize global state
    self.initialized = true
end

function MagicHandsAchievements:unlock(id)
    -- Operate on global state
    achievements[id].unlocked = true
end

return MagicHandsAchievements
```

### Static Function Module Pattern

```lua
-- ScorePreview.lua
local ScorePreview = {}

-- No state, just pure functions
function ScorePreview.calculate(cards, cutCard)
    -- Calculate and return result
    return { total = score, chips = chips, mult = mult }
end

function ScorePreview.draw(x, y, preview, font)
    -- Draw using provided data
end

return ScorePreview
```

### Instance Class Pattern

```lua
-- CollectionUI.lua
local CollectionUI = class()

function CollectionUI:init(font, smallFont)
    -- Instance-specific state
    self.font = font
    self.visible = false
    self.scrollOffset = 0
end

function CollectionUI:update(dt, mx, my, clicked)
    -- Operate on instance state
    self.scrollOffset = self.scrollOffset + delta
end

return CollectionUI
```

---

## Common Mistakes & Fixes

### Mistake 1: Calling Module as Constructor

**Wrong**:
```lua
self.scorePreview = ScorePreview(self.font)  -- Error: attempt to call table
```

**Right**:
```lua
-- ScorePreview is a module, not a class
local preview = ScorePreview.calculate(cards, cutCard)
ScorePreview.draw(x, y, preview, font)
```

### Mistake 2: Trying to Create Multiple Singletons

**Wrong**:
```lua
self.achievements1 = MagicHandsAchievements()  -- Error: attempt to call table
self.achievements2 = MagicHandsAchievements()  -- Doesn't make sense
```

**Right**:
```lua
-- Initialize once globally
MagicHandsAchievements:init()

-- Use anywhere without instance
MagicHandsAchievements:checkProgress("hand_scored", data)
```

### Mistake 3: Storing Module as Instance Variable

**Wrong**:
```lua
self.undoSystem = UndoSystem()  -- Error if UndoSystem is module
self.undoSystem:update(dt)       -- Doesn't exist
```

**Right**:
```lua
-- Initialize once
UndoSystem:init()

-- Use directly
UndoSystem:saveState("action", data)
UndoSystem:undo()
```

---

## GameScene Integration Pattern

```lua
function GameScene:init()
    -- 1. Initialize singleton modules (global state)
    MagicHandsAchievements:init()
    UnlockSystem:init()
    UndoSystem:init()
    
    -- 2. Create instance classes
    self.collectionUI = CollectionUI(self.font, self.smallFont)
    self.achievementNotification = AchievementNotification(self.font, self.smallFont)
    self.runStatsPanel = RunStatsPanel(self.font, self.smallFont)
    
    -- 3. Initialize local state for modules
    self.scorePreviewData = nil  -- Stores result of ScorePreview.calculate()
end

function GameScene:update(dt)
    -- Update instance classes
    self.achievementNotification:update(dt)
    
    -- Use singleton modules
    if input.isPressed("z") then
        UndoSystem:undo()
    end
    
    -- Use static modules
    if #selectedCards == 4 then
        self.scorePreviewData = ScorePreview.calculate(selectedCards, cutCard)
    end
end

function GameScene:draw()
    -- Draw instance classes
    self.collectionUI:draw()
    
    -- Draw using static modules
    if self.scorePreviewData then
        ScorePreview.draw(x, y, self.scorePreviewData, font)
    end
    
    TierIndicator.draw(x, y, tier, font)
end
```

---

## Why This Design?

### Singleton Modules
- **Achievement System**: Global progress across all scenes
- **Unlock System**: Content availability is game-wide
- **Undo System**: One undo stack per gameplay session

### Static Function Modules
- **ScorePreview**: Pure calculation, no state needed
- **TierIndicator**: Pure rendering, no state needed

### Instance Classes
- **UI Components**: Each needs own scroll position, visibility state
- **Notifications**: Queue and animation state per instance

---

## Debugging Tips

### Check Module Type

```lua
print(type(ScorePreview))           -- "table"
print(type(ScorePreview.calculate)) -- "function"
print(type(CollectionUI))           -- "function" (constructor)
```

### Verify Initialization

```lua
-- Singleton modules
if not MagicHandsAchievements.initialized then
    print("ERROR: Achievement system not initialized")
end

-- Instance classes
if not self.collectionUI then
    print("ERROR: CollectionUI not instantiated")
end
```

### Test Module Functions

```lua
-- Test static function
local result = ScorePreview.calculate({}, {})
print("Result:", result)  -- nil (expected - invalid input)

-- Test singleton
local success = MagicHandsAchievements:unlock("test_ach")
print("Unlocked:", success)
```

---

## File Reference

### Singleton Modules
- `content/scripts/Systems/MagicHandsAchievements.lua`
- `content/scripts/Systems/UnlockSystem.lua`
- `content/scripts/Systems/UndoSystem.lua`

### Static Function Modules
- `content/scripts/UI/ScorePreview.lua`
- `content/scripts/UI/TierIndicator.lua`

### Instance Classes
- `content/scripts/UI/CollectionUI.lua`
- `content/scripts/UI/AchievementNotification.lua`
- `content/scripts/UI/RunStatsPanel.lua`

---

**Last Updated**: January 28, 2026  
**Phase 3 Version**: v0.3.1 (Module Architecture Clarified)
