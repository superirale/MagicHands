# Feature Specification: Lua Debugger Integration

**Status**: IMPLEMENTED  
**Priority**: High  
**Completed**: 2026-01-10

## Overview

Interactive Lua debugging with MobDebug and ZeroBrane Studio, enabling breakpoints, stepping, and variable inspection during game development.

## Features

- ✅ Set breakpoints in Lua scripts
- ✅ Step through code (step over, step into, step out)
- ✅ Inspect variables and call stacks
- ✅ Remote debugging via socket (localhost:8172)
- ✅ On-demand activation via console command

---

## Implementation Summary

### LuaSocket Integration (C++)

The engine integrates **LuaSocket** to enable socket-based debugging:

- **Dependency**: `luasocket` (fetched via CMake FetchContent from `master` branch)
- **Manual CMake Configuration**: Manually defined `luasocket_core` and `luasocket_mime` static library targets
- **C Language Support**: Enabled C in project definition (`LANGUAGES C CXX`)
- **Lua Bindings**: Exposed `socket.core` and `mime.core` via `package.preload` in `LuaBindings.cpp`

```cpp
// src/scripting/LuaBindings.cpp
extern "C" {
    int luaopen_socket_core(lua_State* L);
    int luaopen_mime_core(lua_State* L);
}

void LuaBindings::Register(lua_State* L) {
    // Register socket modules
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    
    lua_pushcfunction(L, luaopen_socket_core);
    lua_setfield(L, -2, "socket.core");
    
    lua_pushcfunction(L, luaopen_mime_core);
    lua_setfield(L, -2, "mime.core");
    
    lua_pop(L, 2);
}
```

### MobDebug Integration (Lua)

- **Location**: `engine/lua/mobdebug.lua`
- **Source**: https://github.com/pkulchenko/MobDebug (v0.805)
- **Dependencies**: 
  - `engine/lua/socket.lua`
  - `engine/lua/mime.lua`
  - `engine/lua/ltn12.lua`
  - `engine/lua/socket/*.lua` (http, url, tp, smtp, ftp, headers, mbox)

### Console Command

Added `debug_start` command in `engine/lua/DebugCommands.lua`:

```lua
Console.register("debug_start", function()
    local status, mobdebug = pcall(require, "mobdebug")
    if status then
        Console.print("Attempting to connect to debugger (localhost:8172)...", {1, 1, 0, 1})
        mobdebug.start()
        Console.print("Debugger connected!", {0, 1, 0, 1})
    else
        Console.print("Failed to load mobdebug: " .. tostring(mobdebug), {1, 0, 0, 1})
    end
end, "Start Lua debugger (connects to IDE)")
```

---

## Usage Guide

### Quick Start

1. **Start ZeroBrane Studio**
   - Download from https://studio.zerobrane.com/
   - Go to **Project** → **Start Debugger Server**
   - Verify "Debugger server started at localhost:8172" appears in Output panel

2. **Connect from Game**
   - Run game: `./build/MagicHand`
   - Press `F1` to open console
   - Type `debug_start` and press Enter
   - Game will pause - this is expected!

3. **Debug Your Code**
   - Open any Lua file in ZeroBrane
   - Click line numbers to set breakpoints
   - Use debugger controls:
     - **F5** - Continue execution
     - **F10** - Step Over
     - **F11** - Step Into
     - **Shift+F11** - Step Out
     - **Shift+F5** - Stop debugging

### Setting Breakpoints

1. Open a Lua file in ZeroBrane (e.g., `content/scripts/main.lua`)
2. Click in the left margin next to any line number
3. A red dot appears - this is your breakpoint
4. Press **F5** to continue game execution
5. Game will pause when that line is reached

### Inspecting Variables

While paused at a breakpoint:
- **Hover** over variables to see their values
- Use the **Watch** window to monitor specific variables
- Use the **Stack** window to see the call stack
- Use the **Local Console** to execute Lua commands

---

## VS Code Support

**Note**: Most VS Code Lua debuggers (including Tom Blind's Local Lua Debugger) do **not** support the MobDebug socket protocol. They use the Debug Adapter Protocol (DAP) instead.

**Recommendation**: Use ZeroBrane Studio for the best MobDebug experience.

---

## Files Modified

| File | Changes |
|------|---------|
| `CMakeLists.txt` | Added LuaSocket FetchContent, manual target definitions, enabled C language |
| `src/scripting/LuaBindings.cpp` | Added `extern "C"` declarations and `package.preload` registration |
| `engine/lua/DebugCommands.lua` | Added `debug_start` console command |
| `engine/lua/mobdebug.lua` | NEW - MobDebug script |
| `engine/lua/socket.lua` | NEW - LuaSocket core module |
| `engine/lua/mime.lua` | NEW - LuaSocket MIME module |
| `engine/lua/ltn12.lua` | NEW - LuaSocket LTN12 module |
| `engine/lua/socket/*.lua` | NEW - LuaSocket protocol modules |

---

## Technical Notes

### Why Manual CMake Targets?

The `luasocket` repository doesn't provide a CMakeLists.txt in the root of the `v3.1.0` tag that FetchContent can use automatically. We switched to `master` branch and manually defined:

```cmake
# Manually define LuaSocket targets
set(LUASOCKET_SRC_DIR ${luasocket_SOURCE_DIR}/src)

add_library(luasocket_core STATIC
    ${LUASOCKET_SRC_DIR}/luasocket.c
    ${LUASOCKET_SRC_DIR}/timeout.c
    ${LUASOCKET_SRC_DIR}/buffer.c
    ${LUASOCKET_SRC_DIR}/io.c
    ${LUASOCKET_SRC_DIR}/auxiliar.c
    ${LUASOCKET_SRC_DIR}/options.c
    ${LUASOCKET_SRC_DIR}/inet.c
    ${LUASOCKET_SRC_DIR}/tcp.c
    ${LUASOCKET_SRC_DIR}/udp.c
    ${LUASOCKET_SRC_DIR}/except.c
    ${LUASOCKET_SRC_DIR}/select.c
    # Platform-specific
    $<IF:$<PLATFORM_ID:Windows>,${LUASOCKET_SRC_DIR}/wsocket.c,${LUASOCKET_SRC_DIR}/usocket.c>
)
target_include_directories(luasocket_core PRIVATE ${LUASOCKET_SRC_DIR} ${lua_SOURCE_DIR}/lua-5.4.6/include)
target_compile_definitions(luasocket_core PRIVATE LUASOCKET_DEBUG)
```

### On-Demand Activation

Unlike the original proposal, we use a console command (`debug_start`) rather than automatic initialization. This avoids:
- Connection timeout on startup if IDE isn't running
- Need for CMake build flags
- Unnecessary overhead when debugging isn't needed

---

## Troubleshooting

### "Connection refused" Error

**Cause**: ZeroBrane's debugger server isn't running.

**Solution**:
1. Open ZeroBrane Studio
2. **Project** → **Start Debugger Server**
3. Look for "Debugger server started at localhost:8172" in Output panel
4. Try `debug_start` again

### Game "Freezes" After `debug_start`

**This is normal!** The debugger pauses execution immediately. Press **F5** in ZeroBrane to continue.

### "Can't start debugging without an opened file"

**Cause**: ZeroBrane needs a file open to establish debugging context.

**Solution**: Open any Lua file from your project in ZeroBrane, then try again.

---

## References

- [MobDebug GitHub](https://github.com/pkulchenko/MobDebug)
- [ZeroBrane Studio](https://studio.zerobrane.com/)
- [LuaSocket](https://lunarmodules.github.io/luasocket/)
