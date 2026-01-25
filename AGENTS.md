# Magic Hands - Agent Development Guide

This document provides guidelines for AI coding agents working on the Magic Hands game.

## Build System

### Building the Project

```bash
# Configure CMake (from project root)
mkdir -p build && cd build
cmake ..

# Build (all targets)
cmake --build . --config Release

# Build specific target
cmake --build . --target MagicHands --config Release
cmake --build . --target magic_hands_tests --config Release
```

### Running the Game

```bash
# From build directory
./MagicHand
```

### Testing

```bash
# Run all tests
cd build
ctest --output-on-failure

# Run test executable directly
./magic_hands_tests

# Run specific test by name (using Catch2 filters)
./magic_hands_tests "[base64]"
./magic_hands_tests "Base64 Decoding"

# List all available tests
./helheim_tests --list-tests
```

**Test Framework**: Catch2 v3.5.2

### Optional Features

```bash
# Enable Tracy profiler
cmake .. -DHELHEIM_ENABLE_TRACY=ON
cmake --build .
```

## Project Structure

```
MagicHands/
├── src/                    # C++ engine code
│   ├── core/              # Engine core (Engine, Logger, WindowManager, etc.)
│   ├── graphics/          # Rendering (SpriteRenderer, Animation, ParticleSystem)
│   ├── physics/           # Box2D integration (PhysicsSystem, NoiseGenerator)
│   ├── audio/             # Orpheus audio wrapper (AudioSystem)
│   ├── input/             # Input handling (InputSystem)
│   ├── scripting/         # Lua bindings (*Bindings.cpp files)
│   ├── ui/                # UI system (UISystem, UILayout)
│   ├── events/            # Event system (EventSystem)
│   ├── asset/             # Asset management (AssetManager, AssetConfig)
│   ├── tilemap/           # Tilemap system (TileMap, TileSet, TileLayer)
│   └── pathfinding/       # Pathfinding (Pathfinder)
├── tests/                 # Catch2 unit tests
├── content/               # Game assets (Lua scripts, JSON data, images, audio)
│   ├── scripts/          # Lua game logic
│   └── data/             # JSON definitions
├── docs/                  # Documentation
└── external/             # Dependencies (fetched by CMake)
```

## Code Style Guidelines

### C++ Standards

- **C++ Version**: C++20 (set in CMakeLists.txt)
- **Compiler Requirements**: GCC, Clang, or MSVC with C++20 support

### Naming Conventions

```cpp
// Classes: PascalCase
class SpriteRenderer { };
class PhysicsSystem { };

// Member variables: m_ prefix + PascalCase
class Engine {
  SDL_GPUDevice* m_GPUDevice;
  SpriteRenderer m_Renderer;
  CallbackHandle m_ResizeCallbackHandle;
};

// Static variables: s_ prefix + PascalCase
static LogLevel s_MinLevel;
static std::unique_ptr<Orpheus::AudioManager> s_Engine;

// Functions/Methods: PascalCase
bool Init();
void Update(float dt);
void DrawSprite(int textureId, float x, float y);

// Parameters/Local variables: camelCase
void SetCamera(float x, float y);
int LoadTexture(const char* path);
void ApplyForce(b2BodyId bodyId, float fx, float fy);

// Constants/Enums: PascalCase
enum class LogLevel { Trace, Debug, Info, Warn, Error };
enum class WindowMode { Windowed, Fullscreen, BorderlessFullscreen };

// Macros: UPPER_CASE
#define LOG_INFO(...) Logger::Log(LogLevel::Info, __FILE__, __LINE__, __VA_ARGS__)
#define PROFILE_SCOPE()
```

### Header Guards

Use `#pragma once` consistently (not `#ifndef` guards).

### Include Order

```cpp
// 1. Corresponding header (for .cpp files)
#include "core/Engine.h"

// 2. Project headers
#include "asset/AssetManager.h"
#include "audio/AudioSystem.h"
#include "core/Logger.h"

// 3. External library headers
#include <SDL3/SDL.h>
#include <box2d/box2d.h>

// 4. Standard library headers
#include <string>
#include <vector>
#include <memory>
```

### Precompiled Headers

The project uses precompiled headers (`src/core/pch.h`). Common includes:
- Standard library: `<algorithm>`, `<vector>`, `<string>`, `<memory>`, etc.
- SDL3: `<SDL3/SDL.h>`, `<SDL3/SDL_gpu.h>`
- Lua: `<lua.h>`, `<lauxlib.h>`, `<lualib.h>`
- Core: `"core/Logger.h"`, `"core/Result.h"`

### Types and Smart Pointers

```cpp
// Prefer smart pointers over raw pointers
std::unique_ptr<SDLManager> g_sdlManager;
std::shared_ptr<Texture> texture;

// Use Result<T> for fallible operations
Result<int> LoadTexture(const char* path);
Result<void> Init();

// Check results explicitly
auto result = LoadTexture("image.png");
if (result.IsOk()) {
    int id = result.GetValue();
} else {
    LOG_ERROR("%s", result.GetError().message.c_str());
}

// Return errors explicitly
return Error{"File not found"};
return Err<int>("Invalid texture format");
```

### Error Handling and Logging

```cpp
// Use Logger macros for all logging
LOG_TRACE("Detailed debug info: %d", value);
LOG_DEBUG("Engine initializing subsystems...");
LOG_INFO("AssetManager initialized with GPU device");
LOG_WARN("Texture size exceeds recommended limit");
LOG_ERROR("Failed to initialize SpriteRenderer");

// Always log errors before returning failure
if (!m_Renderer.Init(m_GPUDevice, window)) {
    LOG_ERROR("Failed to initialize SpriteRenderer");
    return false;
}

// Use Result<T> for operations that can fail
Result<int> LoadFont(const std::string& path) {
    if (!fileExists(path)) {
        return Error{"Font file not found"};
    }
    return fontId;
}
```

### Singleton Pattern

```cpp
// Standard singleton pattern used throughout
class WindowManager {
public:
    static WindowManager& getInstance();
    
    WindowManager(const WindowManager&) = delete;
    WindowManager& operator=(const WindowManager&) = delete;

private:
    WindowManager() = default;
    ~WindowManager() = default;
};

// Thread-safe singleton implementation
static std::mutex g_singletonMutex;
static std::unique_ptr<WindowManager> g_instance;

WindowManager& WindowManager::getInstance() {
    std::lock_guard<std::mutex> lock(g_singletonMutex);
    if (!g_instance) {
        g_instance.reset(new WindowManager());
    }
    return *g_instance;
}
```

### Lua Bindings

```cpp
// Lua binding functions: Lua_ prefix + PascalCase
static int Lua_CreateBody(lua_State* L);
static int Lua_LoadBank(lua_State* L);

// Register functions in RegisterLua() method
void PhysicsSystem::RegisterLua(lua_State* L) {
    lua_register(L, "createBody", Lua_CreateBody);
    lua_register(L, "getPosition", Lua_GetPosition);
}
```

## Architecture Patterns

### Engine Subsystems

- Use singleton pattern for managers: `Engine::Instance()`, `WindowManager::getInstance()`
- Init/Update/Destroy lifecycle for all systems
- Prefer composition over inheritance
- Subsystems should be independent and loosely coupled

### Lua Integration

- **Philosophy**: Game logic in Lua, engine primitives in C++
- All gameplay code lives in `content/scripts/`
- C++ provides low-level systems (rendering, physics, input)
- Lua bindings in `src/scripting/*Bindings.cpp`

### Event System

```cpp
// C++ event subscription
EventSystem::Instance().Subscribe("player_death", [](const EventData& event) {
    LOG_INFO("Player died: %s", event.stringData.at("reason").c_str());
});

// Emit events
EventData event("item_collected");
event.SetString("itemId", "gold_coin").SetInt("quantity", 10);
EventSystem::Instance().Emit(event);
```

### Asset Management

- Assets are cached and reference-counted
- Load via `AssetManager::getInstance().load<T>(path)`
- Support for: textures, shaders, tilemaps, fonts
- Audio handled by Orpheus library, not AssetManager

## Common Pitfalls

1. **Don't bypass the Logger**: Always use `LOG_*` macros, not `std::cout` or `printf`
2. **Check initialization order**: Systems depend on each other (e.g., FontRenderer needs SpriteRenderer)
3. **Content directory**: Game assets must be in `content/`, which is copied to build directory post-build
4. **SDL3 ownership**: WindowManager owns the SDL_Window, Engine owns SDL_GPUDevice
5. **Thread safety**: Most systems are not thread-safe; use from main thread only
6. **Lua state lifecycle**: Pass `lua_State*` explicitly; don't store it globally

## Dependencies

- **SDL3**: Window, input, GPU rendering (preview-3.1.3)
- **Box2D**: 2D physics (v3.0.0)
- **Lua**: Scripting (v5.4.6)
- **nlohmann/json**: JSON parsing (v3.11.3)
- **Orpheus**: Audio middleware (custom library)
- **Catch2**: Unit testing (v3.5.2)
- **stb**: Image loading (stb_image.h)

All dependencies are fetched automatically via CMake FetchContent.

## Development Workflow

1. **Make changes** to C++ code in `src/`
2. **Build** with `cmake --build build/`
3. **Test** with `ctest` or `./build/helheim_tests`
4. **Run** with `./build/MagicHand`
5. **Iterate**: Lua scripts can be hot-reloaded in-game (F6)

## Platform Notes

- **macOS**: Primary development platform (Apple Silicon tested)
- **Linux**: Should work with minimal adjustments
- **Windows**: MSVC support (untested, may need tweaks)

---

**Last Updated**: January 2026  
**Engine Version**: 0.1.0
