# Phase 3 Troubleshooting Guide

## Issue 1: "attempt to call a nil value (global 'loadJSON')"

**Status**: ✅ **FIXED**

### Problem
The error occurred because Phase 3 systems were trying to use `loadJSON()` as a global function, but the correct API is `files.loadJSON()`.

### Solution Applied
Updated all Phase 3 files to use the correct `files.loadJSON()` API:

1. **MagicHandsAchievements.lua** - Added checks for `files` module
2. **CollectionUI.lua** - Fixed JSON loading call
3. **Phase3IntegrationTest.lua** - Fixed test JSON loading

### How JSON Loading Works

The Magic Hands engine provides a `files` module with three functions:

```lua
-- Load and parse JSON file into Lua table
local data = files.loadJSON("content/data/achievements.json")

-- Load file as raw string
local text = files.loadFile("path/to/file.txt")

-- Save string to file
files.saveFile("path/to/file.txt", "content")
```

### Implementation Details

The `files` module is registered in C++ via `RegisterJsonUtils()`:

**File**: `src/core/JsonUtils.cpp`
```cpp
void RegisterJsonUtils(lua_State *L) {
  lua_newtable(L);
  lua_pushcfunction(L, Lua_LoadJSON);
  lua_setfield(L, -2, "loadJSON");
  lua_pushcfunction(L, Lua_SaveFile);
  lua_setfield(L, -2, "saveFile");
  lua_pushcfunction(L, Lua_LoadFile);
  lua_setfield(L, -2, "loadFile");
  lua_setglobal(L, "files");  // ← Global 'files' module
}
```

This is called during Lua initialization in:
- `src/scripting/LuaBindings.cpp`
- `src/core/main.cpp`

### Best Practices for JSON Loading

Always check if the module exists before using it:

```lua
-- Method 1: Early return with error message
if not files or not files.loadJSON then
    print("ERROR: files.loadJSON not available")
    return
end

local data = files.loadJSON("path/to/file.json")
if not data then
    print("ERROR: Failed to load JSON file")
    return
end

-- Method 2: Inline check
local data = files and files.loadJSON and files.loadJSON("path.json") or nil
if data then
    -- Use data
end
```

### Testing JSON Loading

Press **Y** in-game to run the JSON loading test:

```lua
-- Loads and displays:
-- 1. Check if files module exists
-- 2. Check if files.loadJSON function exists
-- 3. Load achievements.json (40 achievements)
-- 4. Load a sample joker JSON
```

### Common Issues

#### Issue 1: "files module not found"
**Cause**: `RegisterJsonUtils()` not called during Lua initialization  
**Fix**: Verify `RegisterJsonUtils(L)` is in `LuaBindings.cpp` and `main.cpp`

#### Issue 2: "Failed to load JSON file"
**Cause**: File path incorrect or file doesn't exist  
**Fix**: 
- Paths are relative to executable location
- Use `content/data/` prefix
- Check file exists: `ls content/data/achievements.json`

#### Issue 3: "JSON parse error"
**Cause**: Invalid JSON syntax  
**Fix**: Validate JSON with `jq` or online validator
```bash
jq . content/data/achievements.json
```

### Debug Commands

| Key | Action |
|-----|--------|
| **Y** | Run JSON loading test |
| **T** | Run joker tests |
| **C** | Open collection (requires JSON loading) |

### Files That Use JSON Loading

| File | Purpose | JSON Loaded |
|------|---------|-------------|
| `MagicHandsAchievements.lua` | Achievement system | `achievements.json` |
| `CollectionUI.lua` | Collection browser | All card JSON files |
| `ShopUI.lua` | Shop metadata | Joker/enhancement JSON |
| `EnhancementManager.lua` | Enhancement data | Enhancement JSON |
| `BossManager.lua` | Boss definitions | Boss JSON |

### Verification Checklist

Run these checks if JSON loading fails:

- [ ] Build succeeded without errors
- [ ] `files` global exists (press Y to test)
- [ ] `files.loadJSON` function exists
- [ ] JSON file exists at specified path
- [ ] JSON file has valid syntax
- [ ] Path uses `/` not `\` (even on Windows)
- [ ] Path is relative to executable, not script

### Related Files

**C++ (Engine)**:
- `src/core/JsonUtils.h/cpp` - JSON utilities
- `src/scripting/LuaBindings.cpp` - Lua bindings registration
- `src/core/main.cpp` - Main initialization

**Lua (Game Logic)**:
- `content/scripts/Systems/MagicHandsAchievements.lua`
- `content/scripts/UI/CollectionUI.lua`
- `content/scripts/UI/ShopUI.lua`
- `content/scripts/criblage/BossManager.lua`
- `content/scripts/criblage/EnhancementManager.lua`

**Test Scripts**:
- `content/scripts/tests/TestJSONLoading.lua` - JSON loading test
- `content/scripts/tests/Phase3IntegrationTest.lua` - Full Phase 3 test

### Fixed Commits

**Commit**: Phase 3 JSON Loading Fix
**Files Modified**:
- `content/scripts/Systems/MagicHandsAchievements.lua` - Added `files.` prefix and error checks
- `content/scripts/UI/CollectionUI.lua` - Fixed `loadJSON` → `files.loadJSON`
- `content/scripts/tests/Phase3IntegrationTest.lua` - Fixed test JSON loading
- `content/scripts/scenes/GameScene.lua` - Added Y key for JSON test

**Status**: ✅ Fixed and tested

---

## Issue 2: "attempt to call a table value (upvalue 'ScorePreview')"

**Status**: ✅ **FIXED**

### Problem
```
Thread Error: content/scripts/scenes/GameScene.lua:101: 
attempt to call a table value (upvalue 'ScorePreview')
```

Phase 3 systems were mixing up module types:
- **Static Function Modules** (`ScorePreview`, `TierIndicator`) - Can't be instantiated
- **Singleton Modules** (`UndoSystem`) - Should be initialized once globally
- **Instance Classes** (`CollectionUI`, `AchievementNotification`) - Need instantiation

### Solution Applied

#### GameScene:init() - Correct Pattern

**Before** (Wrong):
```lua
self.scorePreview = ScorePreview(self.font)  -- Error: calling table
self.undoSystem = UndoSystem()                -- Error: calling table
```

**After** (Correct):
```lua
-- Singleton modules (initialize once)
UndoSystem:init()

-- Instance classes (create instances)
self.collectionUI = CollectionUI(self.font, self.smallFont)

-- Static modules (no initialization needed)
self.scorePreviewData = nil  -- Just store calculated data
```

#### Usage Pattern

**Static Function Module** (ScorePreview):
```lua
-- Calculate score
local preview = ScorePreview.calculate(cards, cutCard)

-- Draw preview
ScorePreview.draw(x, y, preview, font)
```

**Singleton Module** (UndoSystem):
```lua
-- Initialize once in init()
UndoSystem:init()

-- Use anywhere
UndoSystem:saveState("action", data)
local success, action = UndoSystem:undo()
```

**Instance Class** (CollectionUI):
```lua
-- Create instance in init()
self.collectionUI = CollectionUI(self.font, self.smallFont)

-- Use instance methods
self.collectionUI:update(dt, mx, my, clicked)
self.collectionUI:draw()
```

### Module Type Reference

| Module | Type | Pattern |
|--------|------|---------|
| `ScorePreview` | Static Functions | `ScorePreview.calculate()` |
| `TierIndicator` | Static Functions | `TierIndicator.draw()` |
| `UndoSystem` | Singleton | `UndoSystem:init()` then `UndoSystem:undo()` |
| `MagicHandsAchievements` | Singleton | `MagicHandsAchievements:init()` |
| `UnlockSystem` | Singleton | `UnlockSystem:init()` |
| `CollectionUI` | Instance Class | `CollectionUI(font, smallFont)` |
| `AchievementNotification` | Instance Class | `AchievementNotification(font, smallFont)` |
| `RunStatsPanel` | Instance Class | `RunStatsPanel(font, smallFont)` |

See `docs/PHASE3_MODULE_ARCHITECTURE.md` for detailed explanation.

---

## Other Common Phase 3 Issues

### Issue: Collection UI not opening (press C)

**Possible Causes**:
1. JSON loading failed (check logs)
2. CollectionUI module not loaded
3. Input conflict with other systems

**Debug**:
```lua
-- Add to GameScene:update()
if input.isPressed("c") then
    print("C pressed, showCollection:", self.showCollection)
    print("CollectionUI:", self.collectionUI)
end
```

### Issue: Achievements not tracking

**Possible Causes**:
1. Achievement system failed to initialize
2. Events not being emitted
3. Event listeners not registered

**Debug**:
```lua
-- Test event emission
events.emit("hand_scored", { score = 50, handTotal = 15 })
print("Event emitted")
```

### Issue: Score preview not showing

**Possible Causes**:
1. Not in PLAY state
2. Less than 4 cards selected
3. ScorePreview module failed to load

**Debug**:
```lua
-- Check in GameScene:update() PLAY state
print("Selected cards:", #selectedCards)
print("ScorePreview:", self.scorePreview)
```

---

**Last Updated**: January 28, 2026  
**Build**: v0.3.0 (Phase 3 Complete)
