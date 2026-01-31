# Settings Menu Guide

## Overview

The Settings Menu is a complete, ready-to-use UI that showcases all Phase 1 features. It provides players with control over:

- **Visual Theme** (Default/Colorblind Mode)
- **UI Scale** (75%, 100%, 125%, 150%, Auto)
- **Controller Status** (detection and info display)

## Files Created

1. **`content/scripts/UI/SettingsUI.lua`** - Main settings menu implementation
2. **`content/scripts/examples/SettingsExample.lua`** - Integration example
3. **`content/scripts/tests/Phase1Test.lua`** - Feature verification tests

## Quick Start

### 1. Basic Integration

```lua
-- In your game initialization:
local SettingsUI = require("UI.SettingsUI")
local UILayout = require("UI.UILayout")

-- Create settings menu
local layout = UILayout()
layout:init()
local settingsMenu = SettingsUI("UI_FONT", layout)
```

### 2. Update Loop

```lua
function Game.update(dt)
    -- Open settings with F1 or Select button (controller)
    if inputmgr.isActionJustPressed("open_settings") then
        settingsMenu:open()
    end
    
    -- Update settings menu
    if settingsMenu.active then
        local mx, my = inputmgr.getCursor()
        local clicked = inputmgr.isActionJustPressed("confirm")
        settingsMenu:update(dt, mx, my, clicked)
        return  -- Don't update game while settings open
    end
    
    -- ... rest of game update ...
end
```

### 3. Draw Loop

```lua
function Game.draw()
    -- ... draw game ...
    
    -- Draw settings on top
    settingsMenu:draw()
end
```

## Features

### Theme Switcher

**Default Theme:**
- Standard color palette
- Optimized for normal vision

**Colorblind Mode (Deuteranopia):**
- Adjusted red/green colors for colorblind players
- Blue/yellow color scheme for success/danger
- Purple instead of green for uncommon rarity

**Usage:**
```lua
-- Switch theme programmatically
settingsMenu:setTheme("default")
settingsMenu:setTheme("deuteranopia")

-- Or use the UI buttons
```

### UI Scale Selector

**Presets:**
- **75%** - Smaller UI (SMALL preset)
- **100%** - Normal size (NORMAL preset)
- **125%** - Larger UI (LARGE preset)
- **150%** - Extra large (HUGE preset)
- **Auto** - Automatically scales based on window size

**Usage:**
```lua
-- Set scale programmatically
local UIScale = require("UI.UIScale")
UIScale.applyPreset("LARGE")  -- 125%
UIScale.set(1.5)  -- 150%
UIScale.auto()  -- Auto-detect

-- Or use the UI buttons
```

### Controller Info Display

Shows:
- Controller name (if connected)
- Connection status
- Active input device (gamepad vs keyboard/mouse)

**Updates automatically** - displays real-time controller status

## Keyboard/Mouse Controls

| Action | Key |
|--------|-----|
| Open Settings | F1 |
| Close Settings | ESC |
| Click Button | Left Mouse Button |
| Navigate | Mouse Movement |

## Controller Controls

| Action | Button |
|--------|--------|
| Open Settings | Select/Back Button |
| Close Settings | B Button |
| Confirm | A Button |
| Navigate | Left Stick (moves cursor) |

## API Reference

### SettingsUI Class

```lua
SettingsUI = class()
```

#### Constructor

```lua
function SettingsUI:init(font, layout)
```

**Parameters:**
- `font` - Font name (string, e.g., "UI_FONT")
- `layout` - UILayout instance

**Example:**
```lua
local layout = UILayout()
layout:init()
local settings = SettingsUI("UI_FONT", layout)
```

#### Methods

**`settingsMenu:open()`**
- Opens the settings menu
- Updates all displays to current values

**`settingsMenu:close()`**
- Closes the settings menu
- Logs close action

**`settingsMenu:update(dt, mx, my, clicked)`**
- Updates menu state
- Handles input
- Returns `{ action = "close" }` when menu is closed

**Parameters:**
- `dt` - Delta time (float)
- `mx, my` - Mouse/cursor position (float)
- `clicked` - Whether confirm action was pressed (boolean)

**`settingsMenu:draw()`**
- Renders the settings menu
- Draws overlay, panel, labels, and buttons

**`settingsMenu:setTheme(themeName)`**
- Changes the active theme
- Updates display label

**Parameters:**
- `themeName` - "default" or "deuteranopia"

**`settingsMenu:setScale(scale)`**
- Sets UI scale factor
- Updates display label

**Parameters:**
- `scale` - Scale factor (float, e.g., 1.0, 1.25, 1.5)

**`settingsMenu:getControllerStatus()`**
- Returns formatted controller status string
- Updates in real-time

#### Properties

**`settingsMenu.active`** (boolean)
- Whether the menu is currently open

**`settingsMenu.panel`** (UIPanel)
- Main container panel

**`settingsMenu.buttons`** (table)
- Array of UIButton instances

**`settingsMenu.labels`** (table)
- Array of UILabel instances

## Testing

### Run Phase 1 Tests

```lua
local Phase1Test = require("tests.Phase1Test")
Phase1Test.runAll()
```

**Tests:**
1. Theme system (colors, sizes, manipulation)
2. UI Scale (scaling, presets, window size)
3. Input Manager (controller detection, cursor, actions)

**Output:**
- Logs test results to console
- Verifies all Phase 1 features work correctly

### Run Settings Example

```lua
local SettingsExample = require("examples.SettingsExample")
SettingsExample.runTest()
```

## Customization

### Add Custom Theme

```lua
-- In Theme.lua, add new theme:
Theme.themes.myCustomTheme = {
    colors = {
        primary = { r = 1, g = 0.5, b = 0, a = 1 },
        -- ... rest of color definitions
    },
    -- ... sizes, fonts, animation
}

-- Then use it:
Theme.setTheme("myCustomTheme")
```

### Add Custom Scale Preset

```lua
-- In UIScale.lua:
UIScale.PRESETS.CUSTOM = 2.0  -- 200%

-- Then use it:
UIScale.applyPreset("CUSTOM")
```

### Modify Settings Layout

Edit `SettingsUI.lua` `createUI()` method to:
- Add/remove buttons
- Change layout/spacing
- Add new sections
- Customize styling

## Troubleshooting

### Settings Menu Not Opening

**Check:**
1. Is InputManager initialized? (`InputManager::Instance().Init()` in Engine)
2. Is InputManager Lua registered? (`InputManager::RegisterLua(L)` in main.cpp)
3. Are you checking the right action? (`inputmgr.isActionJustPressed("open_settings")`)

### Theme Not Changing

**Check:**
1. Is Theme.lua loaded? (`local Theme = require("UI.Theme")`)
2. Are components using `Theme.get()`?
3. Try logging: `log.info(Theme.current)`

### UI Scale Not Working

**Check:**
1. Is UIScale.init() called? (in UI.lua init)
2. Are components using scaled values?
3. Try: `UIScale.set(2.0)` and check if UI gets bigger

### Controller Not Detected

**Check:**
1. Is controller plugged in/connected?
2. Is SDL3 recognizing it? (check logs for "Gamepad connected")
3. Try unplugging and replugging controller
4. Some controllers need firmware updates

## Examples

### Opening Settings from Main Menu

```lua
-- In main menu:
local menuButton = UIButton(nil, "Settings", font, function()
    settingsMenu:open()
end, "info")
```

### Saving Settings to File

```lua
-- Save current settings
function SaveSettings()
    local settings = {
        theme = Theme.current,
        scale = UIScale.get()
    }
    files.saveJSON("content/data/user_settings.json", settings)
end

-- Load settings
function LoadSettings()
    local settings = files.loadJSON("content/data/user_settings.json")
    if settings then
        Theme.setTheme(settings.theme)
        UIScale.set(settings.scale)
    end
end
```

### Toggle Settings with Controller

```lua
-- In game update:
if inputmgr.isActionJustPressed("open_settings") then
    if settingsMenu.active then
        settingsMenu:close()
    else
        settingsMenu:open()
    end
end
```

## Next Steps

With the Settings Menu complete, you can:

1. **Add More Settings**
   - Audio volume sliders
   - Graphics quality options
   - Key rebinding
   - Fullscreen toggle

2. **Integrate into Existing Menus**
   - Add "Settings" button to main menu
   - Add "Options" to pause menu
   - Create separate tabs for different setting categories

3. **Save/Load User Preferences**
   - Create settings.json file
   - Load on startup
   - Save on change or menu close

4. **Move to Phase 2**
   - Add UIProgressBar for volume sliders
   - Add UISlider for continuous values
   - Add UIDropdown for selection options
   - Add UICheckbox for boolean settings

## Conclusion

The Settings Menu is a **complete, production-ready UI** that demonstrates all Phase 1 features:

✅ Theme System - Easy theme switching  
✅ UI Scaling - Multi-resolution support  
✅ Controller Support - Full gamepad integration  
✅ Styled Components - Professional appearance  

**You're ready to ship Phase 1!** 🚀
