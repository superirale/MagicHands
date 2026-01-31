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
│   ├── pathfinding/       # Pathfinding (Pathfinder)
│   └── gameplay/          # Game-specific systems
│       ├── card/          # Card & Deck classes
│       ├── cribbage/      # Cribbage hand evaluation & scoring
│       │   └── effects/   # Warp effects (Strategy Pattern)
│       ├── joker/         # Joker system (Strategy Pattern)
│       │   ├── conditions/ # Joker condition classes
│       │   ├── counters/   # Joker counter classes
│       │   └── effects/    # Joker effect classes
│       ├── blind/         # Blind system
│       └── boss/          # Boss system
├── tests/                 # Catch2 unit tests (93 assertions)
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

### Joker System (Strategy Pattern Architecture)

The Joker system uses **Strategy Pattern** and **Factory Pattern** for extensibility and testability.

#### Architecture Overview

```
JokerEffectSystem
├── Conditions    - Evaluate when joker triggers (e.g., "count_15s > 0")
├── Counters      - Calculate multipliers (e.g., "each_15" = count fifteens)
└── Effects       - Apply score changes (e.g., "add_chips")
```

#### Condition System

Conditions determine when a joker's effects should apply.

**Base Interface:**
```cpp
class Condition {
public:
    virtual bool evaluate(const HandEvaluator::HandResult& hand) const = 0;
    virtual std::string getDescription() const = 0;
    static std::unique_ptr<Condition> parse(const std::string& conditionStr);
};
```

**Supported Condition Types:**
- `ContainsRankCondition` - Check for specific rank (e.g., `contains_rank:7`)
- `ContainsSuitCondition` - Check for specific suit (e.g., `contains_suit:H`)
- `CountComparisonCondition` - Compare counts (e.g., `count_15s > 0`, `count_pairs >= 2`)
- `HasNobsCondition` - Check for nobs (boolean)
- `HandTotal21Condition` - Check if hand totals 21 (boolean)

**Usage:**
```cpp
// Parse and evaluate condition
auto condition = Condition::parse("count_15s > 0");
bool met = condition->evaluate(handResult);
```

#### Counter System

Counters calculate multipliers for joker effects (the "per" field).

**Base Interface:**
```cpp
class Counter {
public:
    virtual int count(const HandEvaluator::HandResult& handResult) const = 0;
    static std::unique_ptr<Counter> parse(const std::string& perString);
};
```

**Pattern Counters** (cribbage scoring patterns):
- `each_15` - Count of 15 combinations
- `each_pair` - Count of pair combinations
- `each_run` - Count of run sequences
- `cards_in_runs` - Total cards in runs
- `card_count` - Total cards in hand

**Property Counters** (card properties):
- `each_even` - Even-ranked cards
- `each_odd` - Odd-ranked cards
- `each_face` - Face cards (J, Q, K)
- `each_<rank>` - Specific rank (e.g., `each_7`, `each_K`)
- `each_<suit>` - Specific suit (e.g., `each_H`, `each_S`)

**Usage:**
```cpp
// Parse and count
auto counter = Counter::parse("each_15");
int multiplier = counter->count(handResult);
```

#### Effect System

Effects apply the actual score changes.

**Base Interface:**
```cpp
class Effect {
public:
    virtual JokerEffectSystem::EffectResult 
    apply(const HandEvaluator::HandResult& handResult, int count) const = 0;
    
    virtual float getValue() const = 0;
    static std::unique_ptr<Effect> create(const std::string& type, float value);
};
```

**Effect Types:**
- `AddChipsEffect` - Add chips to score
- `AddMultiplierEffect` - Add temporary multiplier
- `AddPermMultEffect` - Add permanent multiplier

**Usage:**
```cpp
// Create and apply effect
auto effect = Effect::create("add_chips", 10.0f);
auto result = effect->apply(handResult, multiplier);
```

#### Complete Example

```cpp
// From JokerEffectSystem::ApplyJokersWithStacks()

// 1. Evaluate conditions
for (const auto& conditionStr : joker.conditions) {
    auto condition = Condition::parse(conditionStr);
    if (!condition->evaluate(handResult)) {
        allConditionsMet = false;
        break;
    }
}

// 2. Calculate counter multiplier
int count = 1;
if (!effect.per.empty()) {
    auto counter = Counter::parse(effect.per);
    count = counter->count(handResult);
}

// 3. Apply effect
auto effectObj = Effect::create(effect.type, effect.value);
auto result = effectObj->apply(handResult, count);
```

#### JSON Format (backward compatible)

```json
{
    "id": "fifteen_fever",
    "triggers": ["on_score"],
    "conditions": ["count_15s > 0"],
    "effects": [{
        "type": "add_chips",
        "value": 15,
        "per": "each_15"
    }]
}
```

#### Adding New Types

**New Condition:**
```cpp
class CustomCondition : public Condition {
public:
    bool evaluate(const HandEvaluator::HandResult& hand) const override {
        // Custom logic
    }
    std::string getDescription() const override { return "custom"; }
};

// Register in ConditionFactory.cpp
if (conditionStr == "custom") {
    return std::make_unique<CustomCondition>();
}
```

**New Counter:**
```cpp
class CustomCounter : public Counter {
public:
    int count(const HandEvaluator::HandResult& hand) const override {
        // Custom counting logic
    }
};

// Register in CounterFactory.cpp
if (perString == "custom_count") {
    return std::make_unique<CustomCounter>();
}
```

**New Effect:**
```cpp
class CustomEffect : public Effect {
public:
    JokerEffectSystem::EffectResult 
    apply(const HandEvaluator::HandResult& hand, int count) const override {
        // Custom effect logic
    }
    float getValue() const override { return m_Value; }
};

// Register in EffectFactory.cpp
if (type == "custom_effect") {
    return std::make_unique<CustomEffect>(value);
}
```

#### Testing

Unit tests cover all Strategy Pattern classes:

```bash
# Run joker system tests
./magic_hands_tests "[joker]"

# Run specific subsystem
./magic_hands_tests "[condition]"
./magic_hands_tests "[counter]"
./magic_hands_tests "[effect]"
```

**Test Coverage:** 93 assertions across 9 test cases

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
