# Magic Hands Engine

A 2D game engine built in C++ with Lua scripting, designed for creating Don't Starve-style survival games.

![Feature Completion](https://img.shields.io/badge/Core_Gameplay-90%25-brightgreen)
![Status](https://img.shields.io/badge/Status-Playable-blue)
![Engine](https://img.shields.io/badge/Engine-C++17-orange)
![Scripting](https://img.shields.io/badge/Scripting-Lua_5.4-blue)

## 🎮 Current Game Status

**Magic Hands** is a fully playable survival game with complete core mechanics:

See [ROADMAP.md](content/ROADMAP.md) for detailed progress.

---

## 🏗️ Engine Architecture

### Core Technologies
- **Rendering**: SDL3 with custom sprite batching
- **Physics**: Box2D
- **Scripting**: Lua 5.4 with OOP support
- **Data**: JSON for definitions (items, creatures, recipes)
- **Audio**: Orpheus (Data-driven audio middleware)

### Design Philosophy

> **Game logic in Lua. Engine primitives in C++.**

The engine provides low-level systems (rendering, physics, input) while all gameplay code lives in Lua scripts. This enables rapid iteration without recompilation.

---

## 🚀 Features

### Engine Core
- **2D Rendering System**
  - Sprite batching for performance
  - Texture atlas support
  - Animation system (frame-based)
  - Screen-space UI rendering
  - Post-processing shaders with UI exclusion
  
- **Particle System**
  - Object pooling for performance
  - Configurable emitters (rain, snow, smoke, fire, etc.)
  - Physics simulation (velocity, gravity, fade)
  - Lua bindings for dynamic effects
  
- **Event System**
  - Publish/subscribe pattern
  - Priority-based handlers
  - Event queuing for deferred processing
  - Lua bindings for game events
  
- **Physics Integration**
  - Box2D bodies and collision
  - Dynamic and static bodies
  - Force-based movement
  
- **Lua Scripting**
  - Class system with inheritance (`class()`)
  - Coroutines for sequences
  - Hot-reloadable scripts (F6)
  
- **Data-Driven Design**
  - JSON definitions for items, creatures, biomes, recipes
  - Declarative UI system (Hades-style)
  
- **Input System**
  - Keyboard and mouse support
  - Extensible key mapping

### Game Systems (Lua)


---

## 📁 Project Structure

```
MagicHands/
├── src/                    # C++ engine code
│   ├── main.cpp            # Entry point, game loop
│   ├── SpriteRenderer.cpp  # Batch rendering
│   ├── InputSystem.cpp     # Input bindings
│   ├── UISystem.cpp        # UI rendering
│   └── ...
├── content/
│   ├── scripts/            # Lua game logic
│   │   ├── main.lua        # Game scenes, player
│   │   ├── Inventory.lua   # Systems...
│   │   └── ...
│   ├── data/               # JSON definitions
│   │   ├── ItemDefinitions.json
│   │   ├── CreatureDefinitions.json
│   │   └── ...
│   ├── images/             # Sprites, UI textures
│   └── audio/              # Sound effects
├── engine/lua/             # Lua engine libs (Core.lua)
└── build/                  # CMake build output
```

---

## 🛠️ Building

### Requirements
- C++17 compiler (GCC, Clang, MSVC)
- CMake 3.15+
- SDL3 (fetched automatically)
- Lua 5.4 (fetched automatically)
- Box2D (fetched automatically)

### Build Steps

```bash
# Clone repository
git clone <repository-url>
cd MagicHands

# Create build directory
mkdir -p build
cd build

# Configure and build
cmake ..
cmake --build . --config Release

# Run game
./MagicHand
```

### Platform Notes
- **macOS**: Tested on Apple Silicon (M1/M2)
- **Linux**: Should work with minor adjustments
- **Windows**: MSVC support (untested)

---

## 🎯 Quick Start (Playing the Game)

### Controls
| Key | Action |
|-----|--------|


### Getting Started


---

## 🧩 Extending the Engine

### Creating a Lua System

```lua
-- MySystem.lua
MySystem = {}

function MySystem.init()
    MySystem.data = {}
end

function MySystem.update(dt)
    -- Game logic here
end

return MySystem
```

Then require it in `main.lua`:
```lua
require "MySystem"
MySystem.init()
```

---

## 🔧 Engine C++ API (Lua Bindings)

### Graphics
```lua
graphics.loadTexture(path)
graphics.draw(textureId, x, y, w, h)
graphics.drawUI(textureId, x, y, w, h)  -- Screen space
graphics.setCamera(x, y)
```

### Physics
```lua
physics.createBody(x, y, dynamic)
physics.setPosition(bodyId, x, y)
physics.getPosition(bodyId)
physics.applyForce(bodyId, fx, fy)
```

### Input
```lua
input.isDown(key)  -- "w", "space", "escape", etc.
input.isPressed(key) -- Just pressed this frame
input.isActionPressed(action) -- "Jump", "Attack"
input.isMouseButtonPressed(button)  -- "left", "right"
input.getMousePosition()
```

### Audio
```lua
audio.loadBank("events.json")
audio.playEvent("event_name")
```

### Data
```lua
loadJSON(path)  -- Returns Lua table
```

### Animation
```lua
animation.new(textureId, frameWidth, frameHeight, frameDuration, frameCount)
animation.update(anim, dt)
animation.draw(anim, x, y, w, h)
```

### Window Manager
```lua
-- Window dimensions and DPI
Window.getWidth()  -- Logical pixels
Window.getHeight()
Window.getDPIScale()  -- 1.0 = normal, 2.0 = Retina

-- Window modes
Window.toggleFullscreen()  -- Also F11 hotkey
Window.setWindowMode("Fullscreen")  -- or "Windowed", "BorderlessFullscreen"

-- Cursor management
Window.setCursorType("Hand")  -- Arrow, Hand, Crosshair, TextInput, etc.
Window.setCursorVisible(false)

-- Performance metrics
Window.getFPS()
Window.getFrameTime()

-- Multi-monitor
Window.getMonitors()  -- Array of monitor info
Window.setMonitor(2)  -- Move to second monitor
```

See [API Reference](docs/API_REFERENCE.md#window-manager-api) for complete WindowManager documentation.

---

## 📊 Performance

The engine is designed for 2D pixel-art games with reasonable scale:
- **Sprite batching**: Reduces draw calls
- **Spatial queries**: Efficient nearby object checks
- **Lua coroutines**: Smooth gameplay sequences

**Target**: 60 FPS on modern hardware with hundreds of entities.

---

## 🗺️ Roadmap

See [content/ROADMAP.md](content/ROADMAP.md) for detailed feature list and progress.

### Next Planned Features
- Advanced building (walls, farms, workbenches)
- Seasonal system (winter, summer, weather)
- Polish (sound effects, particles, visual feedback)

---

## 📚 Documentation

Comprehensive documentation is available in the [`docs/`](docs/) folder:

- **[Documentation Index](docs/README.md)** - Start here for overview
- **[Game Systems](docs/GAME_SYSTEMS.md)** - Complete survival mechanics reference with APIs
- **[API Reference](docs/API_REFERENCE.md)** - Full Lua API documentation
- **[Architecture](docs/ARCHITECTURE.md)** - Engine design and technical details
- **[UI System](docs/UI_SYSTEM.md)** - Data-driven UI framework guide
- **[Tutorials](docs/TUTORIALS.md)** - Step-by-step development guides

---

## 🤝 Contributing

This is currently a personal project. If you'd like to contribute:
1. Check the roadmap for features
2. Follow existing code style
3. Keep game logic in Lua
4. Test thoroughly before submitting

---

## 📝 License

[Specify license here - MIT, GPL, proprietary, etc.]

---

## 🙏 Credits

### Libraries
- **SDL3**: Cross-platform multimedia library
- **Box2D**: 2D physics engine
- **Lua**: Scripting language
- **nlohmann/json**: C++ JSON parser
- **Orpheus**: Audio middleware

### Inspiration


---

## 📧 Contact

[Your contact information]

---

**Built with ❤️ using C++ and Lua**
