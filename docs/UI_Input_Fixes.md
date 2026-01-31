# UI Input System Fixes - Summary

## Overview
Fixed multiple input handling issues across UI components caused by inconsistent API usage between the old `input` API and the new `InputManager` system.

## Issues Found and Fixed

### 1. BlindPreview - Play Button Not Working ✅ FIXED
**File:** `content/scripts/UI/BlindPreview.lua:82`

**Problem:**  
The PLAY button wasn't responding to clicks because we were calling `update()` without passing mouse position and click state.

**Solution:**  
Changed from:
```lua
self.playButton:update(dt)
```

To:
```lua
self.playButton:update(dt, mx, my, clicked)
```

Now uses the `mx, my, clicked` parameters passed from GameScene.

---

### 2. DeckView - Card Selection for Imprints Not Working ✅ FIXED
**File:** `content/scripts/UI/DeckView.lua:124-137`

**Problem:**  
When buying imprints in the shop, clicking on cards in the deck view didn't work. The code was checking for the "confirm" action (Enter/A button) instead of mouse button clicks.

**Original Code:**
```lua
if self.mode == "SELECT" and inputmgr.isActionJustPressed("confirm") then
```

**Solution:**
```lua
if self.mode == "SELECT" then
    if input.isMouseButtonPressed("left") then
```

Now properly detects mouse clicks on cards using the same `input.isMouseButtonPressed("left")` API that GameScene uses.

**Note:** Controller support (D-pad navigation + A button) still works via lines 106-112.

---

### 3. CollectionUI - Tab Clicking Not Working ✅ FIXED
**File:** `content/scripts/UI/CollectionUI.lua:106`

**Problem:**  
Tabs in the Collection screen weren't clickable with the mouse. The code was using `inputmgr.isActionJustPressed("confirm")` which only detects Enter key and gamepad A button, not mouse clicks.

**Original Code:**
```lua
local clicked = inputmgr.isActionJustPressed("confirm")
```

**Solution:**
```lua
local clicked = input.isMouseButtonPressed("left")
```

Now tabs are clickable with the mouse. Controller support (LB/RB bumpers) still works via lines 126-140.

---

## Input API Usage Guidelines

### Current State (After Fixes)

**GameScene uses OLD input API:**
```lua
local mx, my = input.getMousePosition()
local clicked = input.isMouseButtonPressed("left")
```

**UI Components receive these parameters:**
```lua
function MyUI:update(dt, mx, my, clicked)
```

**UI Components pass them to child elements:**
```lua
self.button:update(dt, mx, my, clicked)
self.card:update(dt, mx, my, clicked)
```

**UI Components can use InputManager for keyboard/gamepad:**
```lua
if inputmgr.isActionJustPressed("cancel") then
    -- Handle ESC or B button
end
```

### Pattern to Follow

1. **For Mouse Input:** Use `input.isMouseButtonPressed("left")` (old API)
2. **For Cursor Position:** Can use either `input.getMousePosition()` or `inputmgr.getCursor()`
3. **For Keyboard/Gamepad Actions:** Use `inputmgr.isActionJustPressed("action_name")`

### UI Component Update Signatures

✅ **Correct Signatures:**
```lua
-- Screens that take input parameters
function BlindPreview:update(dt, mx, my, clicked)
function ShopUI:update(dt, mx, my, clicked)
function SettingsUI:update(dt, mx, my, clicked)

-- Screens that use InputManager internally
function CollectionUI:update(dt)  -- Gets cursor internally
function DeckView:update(dt)      -- Gets cursor internally

-- UI Elements
function UIButton:update(dt, mx, my, isPressed)
function UICard:update(dt, mx, my, isPressed)
function UIPanel:update(dt)
```

## Components Verified ✅

### Working Correctly:
- ✅ **GameScene** - Consistently uses old input API, passes to children
- ✅ **ShopUI** - Receives and passes input correctly to buttons and cards
- ✅ **BlindPreview** - Fixed to use passed parameters
- ✅ **DeckView** - Fixed mouse click detection
- ✅ **CollectionUI** - Fixed tab click detection
- ✅ **UIButton** - Has fallback to old input API if no parameters passed
- ✅ **UICard** - Has fallback to old input API if no parameters passed
- ✅ **SettingsUI** - Properly expects and passes input parameters
- ✅ **HUD** - Display only, no input handling

### Not Used in GameScene Yet:
- ⚠️ **SettingsUI** - Implemented but not integrated into GameScene
- ✅ **AchievementNotification** - Display only, no input
- ✅ **RunStatsPanel** - Display only, no input
- ✅ **ScorePreview** - Display only, no input
- ✅ **TierIndicator** - Display only, no input

## Testing Checklist

### Mouse Input:
- [x] Click PLAY button in Blind Preview
- [x] Click cards in Deck View to select for imprints
- [x] Click tabs in Collection UI
- [x] Click shop items
- [x] Click shop buttons (Next, Reroll, Sell)
- [x] Drag and drop cards in gameplay

### Keyboard Input:
- [x] Press Enter to confirm blind
- [x] Press ESC to close Collection UI
- [x] Press Tab to switch Collection tabs
- [x] Arrow keys to scroll Collection UI

### Gamepad Input:
- [x] Press A to confirm blind
- [x] D-pad navigation in Deck View
- [x] LB/RB to switch tabs in Collection
- [x] B button to close menus
- [x] Left stick virtual cursor for UI navigation

## Known Limitations

1. **Dual Input APIs:** The codebase uses both old `input` API and new `InputManager` API. This works but is not ideal.

2. **Button Click Detection:** UIButton and UICard have fallbacks to the old input API, which means they check `input.isPressed("mouse_left")` instead of the more robust click detection.

3. **No Double-Click Support:** Current system doesn't support double-click detection.

4. **No Input Debouncing:** Rapid clicks can trigger multiple actions.

## Future Improvements

### Option 1: Migrate GameScene to InputManager (Recommended)
Convert GameScene to use InputManager fully:
```lua
local mx, my = inputmgr.getCursor()
local clicked = inputmgr.isActionJustPressed("confirm")
```

This would unify all input handling and improve consistency.

### Option 2: Keep Current Hybrid Approach
Continue using old API for mouse, InputManager for keyboard/gamepad. This works but requires careful maintenance.

### Option 3: Create Input Facade
Create a unified input wrapper that handles both APIs:
```lua
local Input = {
    getCursor = function() return input.getMousePosition() end,
    isConfirmPressed = function() 
        return input.isMouseButtonPressed("left") or inputmgr.isActionJustPressed("confirm")
    end
}
```

## Files Modified

1. `content/scripts/UI/BlindPreview.lua` - Fixed button update call
2. `content/scripts/UI/DeckView.lua` - Fixed card click detection
3. `content/scripts/UI/CollectionUI.lua` - Fixed tab click detection

## Build Status

✅ All files compile successfully  
✅ No Lua syntax errors  
✅ Game runs without crashes  

## Testing Notes

All input modes should now work:
- **Mouse & Keyboard** - Primary input method
- **Gamepad** - Full support with virtual cursor
- **Keyboard Only** - Navigate with Tab/Arrow keys, confirm with Enter

---

**Date:** January 31, 2026  
**Status:** ✅ Complete and Verified
