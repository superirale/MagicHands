# Magic Hands Engine Documentation

A 2D game engine built with SDL3, Box2D physics, and Lua scripting. Currently powering a **Don't Starve-style survival game**.

**Last Updated**: December 17, 2025

---

## 📚 Documentation Index

### Engine Documentation
- **[API Reference](./API_REFERENCE.md)** - Complete Lua API documentation
- **[Architecture](./ARCHITECTURE.md)** - System design and technical overview
- **[UI System](./UI_SYSTEM.md)** - Data-driven UI framework guide
- **[Tutorials](./TUTORIALS.md)** - Step-by-step development guides

### Game Documentation
- **[Game Systems](./GAME_SYSTEMS.md)** - Survival game mechanics
- **[ROADMAP](../content/ROADMAP.md)** - Feature progress and future plans

---

## 🎮 Quick Overview

### Engine Features
- **SDL3 Rendering**: Modern GPU-accelerated 2D rendering with sprite batching
- **Box2D Physics**: Full 2D physics simulation
- **Lua 5.4 Scripting**: Complete game logic in Lua with OOP support
- **Data-Driven Design**: JSON definitions for game content
- **Audio System**: SDL3 Audio for WAV playback
- **Tilemap Engine**: High-performance C++ Tiled map rendering (supports CSV, Base64, Zlib/Gzip)
- **Scene Management**: Formal lifecycle-based scene/state management

### Game Features (Implemented)
The engine currently powers a complete survival game with:
- ✅ Inventory & Item System (grid UI, drag & drop)
- ✅ Crafting System (recipes, categories)
- ✅ Resource Gathering (trees, rocks, tools)
- ✅ Survival Stats (hunger, sanity, health)
- ✅ Day/Night Cycle (lighting, darkness mechanics)
- ✅ Creature AI & Combat (state machines, aggression)
- ✅ Save/Load System (full world serialization)
- ✅ Procedural World Generation (biomes, noise-based)
- ✅ Building System (structures, chest storage with UI)
- ✅ **Large-scale World Rendering** (C++ Tilemap Engine)

---

## 🚀 Getting Started

### Prerequisites
- C++17 compiler
- CMake 3.15+
- SDL3 (auto-fetched)
- Lua 5.4 (auto-fetched)
- Box2D (auto-fetched)
- Zlib (auto-fetched)

### Build Instructions

```bash
# Clone repository
git clone <repository-url>
cd MagicHands

# Configure and build
mkdir -p build && cd build
cmake ..
cmake --build . --config Release

# Run
./MagicHand
```

### Game Controls

| Key | Action |
|-----|--------|
| **Arrow Keys** | Move player |
| **E** / **Left Click** | Harvest / Interact with structures |
| **I** | Toggle inventory |
| **C** | Toggle crafting menu |
| **B** | Enter build mode |
| **P** | Place campfire |
| **F** | Attack nearby creature |
| **S** | Save game |
| **L** | Load game |
| **ESC** | Close UI windows |
| **TAB** | Test Scene Transition (Title Scene) |

---

## 📖 Documentation Guide

### For Engine Developers
Start with:
1. [Architecture](./ARCHITECTURE.md) - Understand the system design
2. [API Reference](./API_REFERENCE.md) - Learn the Lua bindings
3. [Tutorials](./TUTORIALS.md) - Follow step-by-step guides

### For Game Developers
Start with:
1. [Game Systems](./GAME_SYSTEMS.md) - Understand implemented mechanics
2. [Tutorials](./TUTORIALS.md) - Learn how to add content
3. [API Reference](./API_REFERENCE.md) - Use the engine APIs

---

## 🏗️ Project Structure

```
MagicHands/
├── src/                    # C++ engine code
│   ├── main.cpp           # Entry point, game loop
│   ├── SpriteRenderer.*   # GPU rendering system
│   ├── PhysicsSystem.*    # Box2D wrapper
│   ├── AudioSystem.*      # Sound playback
│   ├── FontRenderer.*     # Text rendering
│   ├── UISystem.*         # UI management
│   ├── InputSystem.*      # Keyboard/mouse input
│   ├── tilemap/           # C++ Tilemap engine
│   └── scripting/         # Lua bindings
├── content/
│   ├── scripts/           # Lua game logic
│   │   ├── main.lua      # Game scenes & player
│   │   ├── Inventory.lua  # Systems...
│   │   └── ...
│   ├── data/              # JSON game data
│   │   ├── ItemDefinitions.json
│   │   ├── CraftingRecipes.json
│   │   └── ...
│   ├── images/            # Sprites & textures
│   ├── audio/             # Sound effects
│   └── ROADMAP.md         # Development roadmap
├── engine/lua/            # Lua engine utilities
│   ├── Core.lua          # OOP & coroutines
│   └── Scenes.lua        # Scene & transition management
├── docs/                  # Documentation (you are here)
└── build/                 # CMake output
```

---

## 🔧 Design Philosophy

> **Game logic in Lua. Engine primitives in C++.**

The Magic Hands engine is designed to keep all gameplay code in Lua for rapid iteration, while the C++ layer provides only low-level systems (rendering, physics, audio, input). This allows:
- Fast development (no recompilation for gameplay changes)
- Hot-reloadable scripts
- Data-driven design via JSON
- Clear separation of concerns

---

## 📊 Current Status

**Engine**: Stable and feature-complete for 2D survival games  
**Game**: Playable with ~80% of planned features implemented  
**Documentation**: Actively maintained

See [ROADMAP](../content/ROADMAP.md) for detailed progress and future plans.

---

## 🤝 Contributing

Documentation improvements are welcome! If you find errors or want to add examples:
1. Edit the relevant .md file
2. Follow existing formatting conventions
3. Keep examples concise and clear

---

## 📝 License

MIT License - See LICENSE file for details


## Features

### Core Systems
- **SDL3 GPU Rendering**: Modern Metal-based rendering pipeline with sprite batching
- **Box2D v3 Physics**: Robust 2D physics simulation
- **Lua 5.4 Scripting**: Full game logic in Lua with OOP and coroutines
- **Audio System**: SDL3 Audio for sound effects and music
- **Tilemap Engine**: High-performance C++ rendering of Tiled maps
- **Post-Processing Shaders**: Multi-pass shader pipeline
- **Data-Driven UI**: Hades-style declarative UI system with inheritance and animations

### Scripting Features
- Object-oriented programming with `class()` system
- Coroutines for async logic (`thread()` and `wait()`)
- **Advanced Scene Management** with transitions and data passing
- Animation components for sprite sheets
- Tiled map loading and interaction
- Physics and input bindings

## Quick Start

### Build
```bash
cmake --build build
```

### Run
```bash
./build/MagicHand
```

### Controls
- **Arrow Keys**: Move player
- **Space**: Jump (Title screen: advance to game)
- **Down Arrow**: Debug health drain

## Project Structure

```
Helheim/
├── src/                  # C++ engine code
│   ├── main.cpp         # Entry point
│   ├── SpriteRenderer.*  # GPU rendering
│   ├── PhysicsSystem.*   # Box2D wrapper
│   ├── tilemap/          # Tilemap engine
│   └── ...
├── content/
│   ├── scripts/         # Lua game scripts
│   │   ├── main.lua    # Game entry point
│   │   ├── Core.lua    # OOP & coroutines
│   │   ├── Scenes.lua  # Scene management
│   │   └── ...
│   ├── images/         # Textures
│   └── audio/          # Sound files
└── docs/               # Documentation
```

## Documentation

- [API Reference](./API_REFERENCE.md) - Lua API documentation
- [Architecture](./ARCHITECTURE.md) - System design overview
- [UI System](./UI_SYSTEM.md) - Data-driven UI guide
- [Tutorials](./TUTORIALS.md) - Step-by-step guides

## License

MIT License - See LICENSE file for details
