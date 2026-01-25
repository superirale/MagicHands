# Feature Specification: Scene/State Management

## Overview
A robust, formal system for managing game scenes and global engine states. This system replaces the basic stack-based management with a lifecycle-oriented, transition-aware architecture.

## Requirements
1.  **Structured Lifecycle**: Clear hooks for initialization (`onInit`), activation (`enter`), deactivation (`exit`), and backgrounding (`pause`/`resume`).
2.  **Transition Support**: Built-in support for visual transitions (Fade, Slide, etc.) between scenes.
3.  **Data Hierarchy**: Support for scene-local state, transition data, and global persistent state.
4.  **Scene Stack**: Maintain a stack of scenes for overlays (menus, inventory).
5.  **Simplified API**: Easy-to-use API for switching and pushing scenes.

## Architecture

### Scene Lifecycle
- `onInit(data)`: Called once when the scene is instantiated. Receives data from the previous scene.
- `enter()`: Called when the scene becomes the active (top) scene.
- `exit()`: Called when the scene is removed from the stack or switched out.
- `pause()`: Called when a new scene is pushed on top of this one.
- `resume()`: Called when the scene on top is popped.
- `update(dt)`: Called every frame.
- `draw()`: Called every frame.

### Transitions
Transitions are specialized objects that manage the "between" state.
- `FadeTransition(duration, color)`: Classic fade through a color.
- `CrossfadeTransition(duration)`: Blends the outgoing and incoming scenes.

### State Management
- **Local State**: Variables stored in the scene instance.
- **Global State**: Managed by `SceneManager.sharedState`.

## User Interface (Lua API)
```lua
SceneManager.switch("GameScene", { type = "fade", duration = 0.5 }, { spawnPoint = "intro" })
SceneManager.push("PauseMenu", { type = "pop" })
SceneManager.pop({ type = "fade" })
```
