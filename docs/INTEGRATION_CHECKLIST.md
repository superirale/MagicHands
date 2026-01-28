# Integration Checklist

## Systems That Need Integration

### ✅ Already Working
- [x] Joker tier system (C++ engine complete)
- [x] Card imprints tracking (CampaignState)
- [x] Deck sculptors (Shop integration)
- [x] Event emissions (GameScene, Shop, Economy, etc.)

### ⚠️ Need Initialization in GameScene

#### 1. Achievement System
**File**: `content/scripts/scenes/GameScene.lua`
**Add to init():**
```lua
-- Initialize achievement and unlock systems
self.achievements = require("Systems.MagicHandsAchievements")
self.unlocks = require("Systems.UnlockSystem")
self.achievements:init()
self.unlocks:init()
```

#### 2. Visual Polish Systems
**Add to init():**
```lua
-- UI systems
self.tierIndicator = require("UI.TierIndicator")
self.scorePreview = require("UI.ScorePreview")
self.achievementNotif = require("UI.AchievementNotification")(self.font)
self.runStats = require("UI.RunStatsPanel")(self.font, self.smallFont)
self.collection = require("UI.CollectionUI")(self.font, self.smallFont)
self.undoSystem = require("Systems.UndoSystem")
self.undoSystem:init()
```

#### 3. Event Listeners
**Add to init():**
```lua
-- Listen for achievement unlocks
events.on("achievement_unlocked", function(data)
    self.achievementNotif:notify(data)
end)
```

#### 4. Update & Draw Loops
**Add to update():**
```lua
-- Update notification system
if self.achievementNotif then
    self.achievementNotif:update(dt)
end
```

**Add to draw():**
```lua
-- Draw notifications on top
if self.achievementNotif then
    self.achievementNotif:draw()
end

-- Draw run stats if visible
if self.runStats then
    self.runStats:draw()
end

-- Draw collection if visible
if self.collection then
    self.collection:draw()
end
```

#### 5. Input Handling
**Add to update():**
```lua
-- Collection toggle (C key)
if input.isKeyJustPressed("c") then
    if self.collection then
        self.collection:toggle()
    end
end

-- Stats toggle (TAB key)
if input.isKeyJustPressed("tab") then
    if self.runStats then
        self.runStats:toggle()
    end
end

-- Undo (Z key)
if input.isKeyJustPressed("z") then
    if self.undoSystem and self.undoSystem:canUndo() then
        local success, action = self.undoSystem:undo()
        if success then
            -- Apply undo logic
            print("Undid: " .. action.type)
        end
    end
end
```

---

## Testing Priorities

### High Priority (Must Test)
1. [ ] Run game and verify systems initialize
2. [ ] Win a blind and check achievement unlock
3. [ ] Press 'C' to open collection UI
4. [ ] Stack a joker and verify tier indicator shows
5. [ ] Check event emissions with LOG_DEBUG

### Medium Priority (Should Test)
6. [ ] Score preview updates correctly
7. [ ] Undo system works for discards
8. [ ] Run stats track correctly
9. [ ] Achievement notifications appear

### Low Priority (Nice to Test)
10. [ ] All 40 achievements can unlock
11. [ ] Collection UI loads all card descriptions
12. [ ] Tier 5 ascension aura displays

---

## Known Integration Issues to Fix

### 1. Global events object
The Lua `events` object needs to be available globally.
**Check**: `content/scripts/main.lua` or scene initialization

### 2. Font objects
TierIndicator, ScorePreview, etc. need font references.
**Solution**: Pass fonts from GameScene when creating UI objects

### 3. Save/Load Integration
Achievement and unlock data needs to persist.
**Files to modify**: Save system (if it exists)

---

## Quick Integration Script

Run this to verify all Phase 3 files exist:
```bash
cd "content/scripts"
ls Systems/MagicHandsAchievements.lua
ls Systems/UnlockSystem.lua
ls Systems/UndoSystem.lua
ls UI/CollectionUI.lua
ls UI/TierIndicator.lua
ls UI/ScorePreview.lua
ls UI/AchievementNotification.lua
ls UI/RunStatsPanel.lua
```

---

## Minimal Viable Integration

If you want to test quickly, start with just:
1. Initialize MagicHandsAchievements
2. Initialize UnlockSystem
3. Add one event listener for "hand_scored"
4. Run game and verify no crashes

Then gradually add the rest.
