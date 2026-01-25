# Architecture Overview

High-level design of the Magic Hands game engine.

---

## System Layers

```
┌─────────────────────────────────────┐
│      Lua Game Scripts               │
│  (main.lua, Player, Scenes, etc.)   │
└──────────────┬──────────────────────┘
               │ Lua C API
┌──────────────▼──────────────────────┐
│      C++ Engine Core                │
│  - SpriteRenderer                   │
│  - PhysicsSystem                    │
│  - AudioSystem                      │
│  - FontRenderer                     │
│  - UIManager                        │
│  - TileMapEngine                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      External Libraries             │
│  - SDL3 (GPU, Audio, Input)         │
│  - Box2D v3 (Physics)               │
│  - Lua 5.4 (Scripting)              │
│  - stb_truetype (Text)              │
│  - nlohmann_json (Data)             │
└─────────────────────────────────────┘
```

---

## Core Systems

### SpriteRenderer
**Purpose**: GPU-accelerated 2D rendering

**Key Features**:
- Metal shader pipeline (MSL)
- Sprite batching for performance
- Camera system (world → screen)
- Texture management with ID mapping

**Flow**:
1. `BeginFrame()` - Start render pass
2. `DrawSprite()` - Queue sprites in batches
3. `EndFrame()` - Upload to GPU, issue draw calls

**Files**: `SpriteRenderer.h/cpp`

---

### PhysicsSystem
**Purpose**: 2D physics simulation wrapper for Box2D

**Key Features**:
- ID-based API (not pointers)
- Pixel-based coordinates (64x64 = default body)
- Gravity: 2000 px/s² downward

**Design**:
- Static singleton (`g_Physics`)
- Lua bindings export userdata handles

**Files**: `PhysicsSystem.h/cpp`

---

### AudioSystem
**Purpose**: Sound effect playback

**Key Features**:
- 8 concurrent audio channels
- WAV file support via SDL3 Audio
- Simple `playSound()` API

**Limitations**: 
- No music streaming yet
- No 3D audio

**Files**: `AudioSystem.h/cpp`

---

### FontRenderer
**Purpose**: Text rendering using `stb_truetype`

**Key Features**:
- TrueType font rasterization
- Font atlas texture (1024x1024)
- Multiple font sizes cached separately

**Rendering**:
1. Bake font atlas on `LoadFont()`
2. `DrawText()` → quad per character
3. Uses `SpriteRenderer::DrawSpriteRect()` for UV mapping

**Files**: `FontRenderer.h/cpp`

---

### TileMapEngine
**Purpose**: High-performance Tiled map rendering

**Key Features**:
- Optimized C++ rendering of large tilemaps
- Support for multiple tile and object layers
- Integration with Box2D for automatic collision generation
- Per-layer and global tinting

**Files**: `TileMap.h/cpp`, `TileLayer.h/cpp`, `ObjectLayer.h/cpp`

---

## Lua Integration

### Binding Pattern
C++ functions are exposed via `lua_pushcfunction`:

```cpp
int Lua_LoadTexture(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    int id = g_Renderer.LoadTexture(path);
    lua_pushinteger(L, id);
    return 1;
}
```

### Module Registration
```cpp
lua_newtable(L);
lua_pushcfunction(L, Lua_LoadTexture);
lua_setfield(L, -2, "loadTexture");
lua_setglobal(L, "graphics");
```

Lua side:
```lua
local tex = graphics.loadTexture(...)
```

---

## Data Flow

### Rendering Pipeline
```
Lua: graphics.draw(tex, x, y, w, h)
  ↓
C++: SpriteRenderer::DrawSprite()
  ↓
Batch vertices → m_BatchedVertices
  ↓
EndFrame() → Upload to GPU transfer buffer
  ↓
GPU: Draw batched quads with Metal shader
```

### Physics Simulation
```
Lua: physics.applyForce(bodyId, fx, fy)
  ↓
C++: PhysicsSystem::ApplyForce()
  ↓
Box2D: b2Body_ApplyForceToCenter()
  ↓
main.cpp: g_Physics.Update(dt)
  ↓
Box2D: b2World_Step()
  ↓
Lua: x, y = physics.getPosition(bodyId)
```

---

---

## Scene Management Architecture

### Lifecycle-Oriented Transitions

**Scenes.lua**:
- `Scene` base class with `onInit`, `enter`, `exit`, etc.
- `SceneManager` handles the stack and active transitions.
- `Transition` objects (e.g., `FadeTransition`) manage visual overlays.

**Workflow**:
1. `SceneManager.switch(newScene, transition, data)`
2. `onInit(data)` called for new scene
3. Current scene `exit()`
4. Transition starts
5. New scene `enter()`
6. Transition finishes

---

## Memory Management

### GPU Resources
- **Textures**: Released in `SpriteRenderer::Destroy()`
- **Shaders/Pipeline**: Released on shutdown
- **Buffers**: Transfer buffer reused per frame

### Lua Ownership
- Physics body IDs: Userdata (GC-safe)
- Texture IDs: Plain integers (manual tracking)

### Critical: Destructor Order
`~SpriteRenderer()` does NOT call `Destroy()` to prevent crash during `exit()`. Cleanup is explicit in `main()` before SDL shutdown.

---

## Threading Model

**Single-threaded**: All systems run on main thread.

- Physics: Stepped once per frame
- Rendering: Immediate mode (batched)
- Audio: Fire-and-forget (SDL handles threads)

Lua coroutines provide cooperative multitasking via `thread()` and `wait()`.
