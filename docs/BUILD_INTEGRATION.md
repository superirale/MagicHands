# Phase 1 Build Integration Guide

This guide explains how to integrate the Phase 1 UI improvements into the Magic Hands build system.

## Required Changes to CMakeLists.txt

Add the new InputManager files to the source list.

**File:** `CMakeLists.txt`

Find the section where source files are listed and add:

```cmake
# Input sources
src/input/InputSystem.cpp
src/input/InputSystem.h
src/input/InputManager.cpp      # ← ADD THIS
src/input/InputManager.h        # ← ADD THIS
```

## Required Changes to Engine

The InputManager needs to be initialized, updated, and shutdown by the Engine.

**File:** `src/core/Engine.cpp` (or wherever Engine is implemented)

### 1. Add Include
```cpp
#include "input/InputManager.h"
```

### 2. Initialize InputManager
In `Engine::Init()`, after InputSystem is initialized:

```cpp
bool Engine::Init() {
    // ... existing initialization ...
    
    // Initialize InputSystem
    if (!m_InputSystem.Init()) {
        LOG_ERROR("Failed to initialize InputSystem");
        return false;
    }
    
    // Initialize InputManager (ADD THIS)
    InputManager::Instance().Init();
    LOG_INFO("InputManager initialized");
    
    // ... rest of initialization ...
    return true;
}
```

### 3. Update InputManager
In `Engine::Update(float dt)`, after InputSystem update:

```cpp
void Engine::Update(float dt) {
    // Update InputSystem
    m_InputSystem.Update();
    
    // Update InputManager (ADD THIS)
    InputManager::Instance().Update(dt);
    
    // ... rest of update ...
}
```

### 4. Shutdown InputManager
In `Engine::Shutdown()`:

```cpp
void Engine::Shutdown() {
    // ... existing shutdown ...
    
    // Shutdown InputManager (ADD THIS)
    InputManager::Instance().Shutdown();
    LOG_INFO("InputManager shut down");
    
    // ... rest of shutdown ...
}
```

### 5. Register Lua Bindings
In the Lua state initialization (usually in Engine or LuaBindings):

```cpp
// In RegisterLua() or Engine::InitLua()
InputManager::RegisterLua(L);
```

## Build Instructions

Once the above changes are made:

```bash
# Configure CMake
mkdir -p build && cd build
cmake ..

# Build
cmake --build . --config Release

# Run
./MagicHand
```

## Verify Integration

After building, verify these features work:

### 1. Theme System
```lua
-- In Lua console or game script
local Theme = require("UI.Theme")
print(Theme.get("colors.primary").r)  -- Should print a number
```

### 2. UI Scaling
```lua
local UIScale = require("UI.UIScale")
UIScale.init()
print(UIScale.get())  -- Should print scale factor (probably 1.0)
```

### 3. Input Manager
```lua
-- Connect a controller and test
if inputmgr.isGamepadConnected() then
    print("Gamepad: " .. inputmgr.getGamepadName())
end

-- Test cursor
local x, y = inputmgr.getCursor()
print("Cursor: " .. x .. ", " .. y)
```

### 4. UI Components
```lua
-- Test styled button
local UIButton = require("UI.elements.UIButton")
local button = UIButton(nil, "Test", font, function() print("Clicked!") end, "danger")
```

## Troubleshooting

### Linker Errors
If you get undefined reference errors for InputManager:
- Make sure `src/input/InputManager.cpp` is in CMakeLists.txt
- Rebuild CMake cache: `rm -rf build && mkdir build && cd build && cmake ..`

### Lua Errors
If Lua can't find Theme or UIScale:
- Verify the files are in `content/scripts/UI/`
- Check that `content/` directory is being copied to build directory

### Controller Not Detected
- Make sure SDL3 gamepad support is enabled
- Test with `SDL_NumJoysticks()` to verify SDL sees the controller
- Some controllers need firmware updates or specific drivers

### UI Scaling Not Working
- Call `UIScale.init()` in UI.lua initialization (already done)
- Verify `ui.setScaleFactor()` and `ui.getScaleFactor()` are registered

## Optional: Enable Tracy Profiler

If you want to profile the new InputManager:

```bash
cmake .. -DHELHEIM_ENABLE_TRACY=ON
cmake --build .
```

Then add profiling markers:
```cpp
// In InputManager::Update()
PROFILE_SCOPE();  // If Tracy is integrated
```

## Next Steps

Once integrated and tested, you're ready for Phase 2: Essential Components!

See `docs/Phase1_Implementation_Summary.md` for detailed documentation.
