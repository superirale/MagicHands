# Feature Specification: Tracy Profiler Integration

**Status**: IMPLEMENTED  
**Priority**: Medium  
**Estimated Effort**: 2-3 days

## Overview

Integrate [Tracy Profiler](https://github.com/wolfpld/tracy) into the Magic Hands engine for real-time CPU/GPU performance analysis with minimal overhead.

## Goals

- Zero-cost when disabled (`TRACY_ENABLE` not defined)
- Automatic frame markers in main loop
- Zone profiling for engine subsystems
- Lua-accessible profiling zones
- GPU profiling support (SDL_GPU/Metal)

---

## Technical Design

### CMake Integration

```cmake
# CMakeLists.txt
option(HELHEIM_ENABLE_TRACY "Enable Tracy profiler" OFF)

if(HELHEIM_ENABLE_TRACY)
    FetchContent_Declare(
        tracy
        GIT_REPOSITORY https://github.com/wolfpld/tracy.git
        GIT_TAG v0.10
    )
    FetchContent_MakeAvailable(tracy)
    target_link_libraries(MagicHand PRIVATE TracyClient)
    target_compile_definitions(MagicHand PRIVATE TRACY_ENABLE)
endif()
```

### C++ Instrumentation

#### New Header: `src/core/Profiler.h`

```cpp
#pragma once

#ifdef TRACY_ENABLE
    #include <tracy/Tracy.hpp>
    #define PROFILE_SCOPE() ZoneScoped
    #define PROFILE_SCOPE_N(name) ZoneScopedN(name)
    #define PROFILE_FRAME() FrameMark
    #define PROFILE_GPU_ZONE(name) TracyGpuZone(name)
    #define PROFILE_GPU_COLLECT() TracyGpuCollect
#else
    #define PROFILE_SCOPE()
    #define PROFILE_SCOPE_N(name)
    #define PROFILE_FRAME()
    #define PROFILE_GPU_ZONE(name)
    #define PROFILE_GPU_COLLECT()
#endif
```

#### Usage in Engine

```cpp
// Engine.cpp
void Engine::Update(float dt) {
    PROFILE_SCOPE();
    m_Input.Update();
    // ...
}

// SpriteRenderer.cpp
void SpriteRenderer::Flush() {
    PROFILE_SCOPE_N("Renderer::Flush");
    // ...
}

// Main loop
while (running) {
    PROFILE_FRAME();
    // ...
}
```

### Lua Bindings

#### API Design

| Function | Description |
|----------|-------------|
| `profiler.beginZone(name)` | Start a named profiling zone |
| `profiler.endZone()` | End the current zone |
| `profiler.mark(name)` | Place a single marker |

#### Implementation

```cpp
static int Lua_ProfilerBeginZone(lua_State *L) {
#ifdef TRACY_ENABLE
    const char *name = luaL_checkstring(L, 1);
    tracy::ScopedZone zone;
    // Store zone in registry for endZone
#endif
    return 0;
}
```

#### Lua Usage

```lua
function GameScene:update(dt)
    profiler.beginZone("GameScene::update")
    -- game logic
    profiler.endZone()
end
```

### GPU Profiling (SDL_GPU)

Tracy supports Metal via `TracyMetal.hpp`. For SDL_GPU:

```cpp
void SpriteRenderer::BeginFrame() {
    PROFILE_GPU_ZONE("BeginFrame");
    // ...
}

void SpriteRenderer::EndFrame() {
    PROFILE_GPU_ZONE("EndFrame");
    PROFILE_GPU_COLLECT();
}
```

> [!NOTE]
> GPU profiling requires Metal context setup. See [Tracy GPU docs](https://github.com/wolfpld/tracy#gpu-profiling).

---

## Build Modes

| Mode | `TRACY_ENABLE` | Overhead |
|------|----------------|----------|
| Release | OFF | Zero |
| Development | ON | ~1-2% |
| Profile | ON + optimizations | ~0.5% |

---

## Verification Plan

1. Build with `-DHELHEIM_ENABLE_TRACY=ON`
2. Run game alongside Tracy GUI
3. Verify frame markers appear
4. Verify zone hierarchy matches engine structure
5. Test Lua zones in `SpatialDemoScene`

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `CMakeLists.txt` | Add Tracy FetchContent |
| `src/core/Profiler.h` | NEW - Macro definitions |
| `src/core/Engine.cpp` | Add frame/zone markers |
| `src/graphics/SpriteRenderer.cpp` | Add GPU zones |
| `src/scripting/LuaBindings.cpp` | Add `profiler` table |

---

## References

- [Tracy GitHub](https://github.com/wolfpld/tracy)
- [Tracy Manual (PDF)](https://github.com/wolfpld/tracy/releases)
