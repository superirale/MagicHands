# Lua API Reference

Complete reference for all Lua APIs available in the Magic Hands engine.

---

## Graphics API

### `graphics.loadTexture(path)`
Load a texture from disk.
- **Parameters**: `path` (string) - Path to image file
- **Returns**: `textureId` (number) - Texture handle
```lua
local tex = graphics.loadTexture("content/images/player.png")
```

### `graphics.getTextureSize(textureId)`
Get texture dimensions.
- **Parameters**: `textureId` (number)
- **Returns**: `width, height` (number, number)
```lua
local w, h = graphics.getTextureSize(tex)
```

### `graphics.draw(textureId, x, y, w, h, rotation, tint, screenSpace)`
Draw a sprite.
- **Parameters**: 
  - `textureId` (number)
  - `x, y` (number) - Position
  - `w, h` (number) - Size in pixels
  - `rotation` (number, optional) - Rotation in degrees (default: 0)
  - `tint` (table, optional) - Color table `{r, g, b, a}` (default: white)
  - `screenSpace` (boolean, optional) - Draw in screen space if true (default: false)
```lua
graphics.draw(tex, 100, 200, 64, 64, 45, {r=1, g=0.5, b=0.5, a=1}, false)
```

### `graphics.drawRect(x, y, w, h, color, screenSpace)`
Draw a solid color rectangle.
- **Parameters**:
  - `x, y, w, h` (number) - Position and size
  - `color` (table) - Color table `{r, g, b, a}`
  - `screenSpace` (boolean, optional) - Screen space if true (default: false)
```lua
graphics.drawRect(0, 0, Window.getWidth(), Window.getHeight(), {r=0, g=0, b=0, a=0.5}, true)
```

### `graphics.drawUI(textureId, x, y, w, h, rotation, tint)`
Draw in screen space (HUD).
- **Parameters**: Same as `draw` but always in screen space and no `screenSpace` parameter.
```lua
graphics.drawUI(heartTex, 20, 20, 32, 32, 0, {r=1, g=1, b=1, a=1})
```

### `graphics.setCamera(x, y)`
Set camera position for world-space rendering.
- **Parameters**: `x, y` (number) - Camera top-left
```lua
graphics.setCamera(playerX - 640, playerY - 360)
```

### `graphics.loadFont(path, size)`
Load a TrueType font.
- **Parameters**:
  - `path` (string) - Path to .ttf file
  - `size` (number) - Font size in pixels
- **Returns**: `fontId` (number)
```lua
local font = graphics.loadFont("content/fonts/font.ttf", 24)
```

### `graphics.print(fontId, text, x, y)`
Draw text.
- **Parameters**:
  - `fontId` (number)
  - `text` (string)
  - `x, y` (number) - Screen position
```lua
graphics.print(font, "Health: 100", 20, 20)
```

### Post-Processing Shaders

#### `graphics.loadShader(name, path)` → `boolean`
Load a named post-processing shader from a Metal shader file.

**Parameters:**
- `name` (string): Unique identifier for the shader
- `path` (string): Path to `.metal` shader file

**Returns:** `true` if successful, `false` otherwise

**Example:**
```lua
graphics.loadShader("darkness", "content/shaders/darkness.metal")
graphics.loadShader("bloom", "content/shaders/bloom.metal")
```

---

#### `graphics.unloadShader(name)`
Unload a shader and free GPU resources.

**Parameters:**
- `name` (string): Shader identifier

**Example:**
```lua
graphics.unloadShader("darkness")
```

---

#### `graphics.setShaderUniform(name, values)`
Set uniform parameters for a specific shader.

**Parameters:**
- `name` (string): Shader identifier
- `values` (table): Array of number values

**Example:**
```lua
graphics.setShaderUniform("darkness", { 0.75 })  -- 75% darkness
graphics.setShaderUniform("bloom", { 2.5, 0.8 })  -- intensity, threshold
```

---

#### `graphics.enableShader(name, enabled)`
Toggle a shader on/off without unloading (performance optimization).

**Parameters:**
- `name` (string): Shader identifier
- `enabled` (boolean): Enable or disable

**Example:**
```lua
-- Disable darkness during day
graphics.enableShader("darkness", false)

-- Enable at night
graphics.enableShader("darkness", true)
```

**Performance:** Skips entire render pass when disabled (~0.1-0.5ms saved per shader)

---

#### `graphics.reloadShader(name)` → `boolean`
Hot reload a shader from disk without restarting game.

**Parameters:**
- `name` (string): Shader identifier

**Returns:** `true` if successful, `false` otherwise

**Example:**
```lua
local success = graphics.reloadShader("darkness")
if success then print("Shader reloaded!") end
```

---

### Hot Reload (Development)

**F5 Key** - Reload all shaders AND all Lua scripts

This is the primary development hot reload shortcut:
1. Reloads all loaded shaders from disk
2. Clears Lua `package.loaded` cache
3. Reloads `main.lua` and all required modules
4. Resets game state (fresh reload)

**Usage:**
1. Edit shader file (`.metal`) or Lua script
2. Press **F5** in game
3. Changes appear instantly

**Console Output:**
```
=== HOT RELOAD (F5) ===
Reloading shaders...
✓ Reloaded shader: darkness
Reloading scripts...
✅ Hot reload complete!
```

---

## Physics API

### `physics.createBody(x, y, dynamic)`
Create a physics body.
- **Parameters**:
  - `x, y` (number) - Position
  - `dynamic` (boolean) - True for dynamic, false for static
- **Returns**: `bodyId` (userdata)
```lua
local bodyId = physics.createBody(300, 300, true)
```

### `physics.getPosition(bodyId)`
Get body position.
- **Returns**: `x, y` (number, number)
```lua
local x, y = physics.getPosition(bodyId)
```

### `physics.applyForce(bodyId, fx, fy)`
Apply force to body.
- **Parameters**:
  - `bodyId` (userdata)
  - `fx, fy` (number) - Force in Newtons
```lua
physics.applyForce(bodyId, 50000, 0)
```

### `physics.setVelocity(bodyId, vx, vy)`
Set body velocity directly.
- **Parameters**:
  - `bodyId` (userdata)
  - `vx, vy` (number) - Velocity in pixels/second
```lua
physics.setVelocity(bodyId, 200, 0)
```

---

## Input API

### `input.isDown(key)`
Check if key is pressed.
- **Parameters**: `key` (string) - Key name
- **Returns**: `pressed` (boolean)

**Supported Keys**:
- `"left"`, `"right"`, `"up"`, `"down"` - Arrow keys
- `"space"` - Space bar
- `"escape"` - Escape key
- `"a"`, `"b"`, `"c"`, ... - Letter keys (a-z)
- `"0"`, `"1"`, ... - Number keys (0-9)

```lua
if input.isDown("space") then
    -- Space held down
end
```

### `input.isPressed(key)`
Check if key was **just pressed** this frame.
- **Parameters**: `key` (string)
- **Returns**: `pressed` (boolean)
```lua
if input.isPressed("space") then
    jump()  -- Triggers only once per press
end
```

### `input.isReleased(key)`
Check if key was **just released** this frame.
- **Parameters**: `key` (string)
- **Returns**: `released` (boolean)

### `input.bind(action, key)`
Bind a key to a named action.
- **Parameters**: 
  - `action` (string) - Logical action name (e.g., "Jump")
  - `key` (string) - Physical key name (e.g., "space")
```lua
input.bind("Jump", "space")
input.bind("Attack", "z")
```

### `input.isActionDown(action)` / `isActionPressed(action)` / `isActionReleased(action)`
Check input state by action name.
- **Parameters**: `action` (string)
- **Returns**: `state` (boolean)
```lua
if input.isActionPressed("Jump") then
    hero:jump()
end
```

> [!NOTE]
> **Migration Note**: The Lua `InputHelper` module has been removed. Use the native `input` API instead:
> - `InputHelper.wasPressed(key)` → `input.isPressed(key)`
> - `InputHelper.wasReleased(key)` → `input.isReleased(key)`
> - `InputHelper.isHeld(key)` → `input.isDown(key)`
> - `InputHelper.wasMousePressed(btn)` → `input.isMouseButtonPressed(btn)`

### `input.isMouseButtonDown(button)`
Check if mouse button is held down.
- **Parameters**: `button` (string) - `"left"`, `"right"`, `"middle"`
- **Returns**: `held` (boolean)

### `input.isMouseButtonPressed(button)`
Check if mouse button was **just clicked**.
- **Parameters**: `button` (string)
- **Returns**: `pressed` (boolean)

### `input.isMouseButtonReleased(button)`
Check if mouse button was **just released**.
- **Parameters**: `button` (string)
- **Returns**: `released` (boolean)
```lua
if input.isMouseButtonPressed("left") then
    shoot()
end
```

### `input.getMousePosition()`
Get current mouse cursor position.
- **Returns**: `x, y` (number, number) - Screen coordinates

```lua
local mx, my = input.getMousePosition()
print("Mouse at:", mx, my)
```

---

## Audio API

### `audio.loadBank(path)`
Load an audio event bank (JSON).
- **Parameters**: `path` (string) - Path to .json file
```lua
audio.loadBank("content/audio/events.json")
```

### `audio.playEvent(name)`
Play a named audio event.
- **Parameters**: `name` (string) - Event name defined in bank
```lua
audio.playEvent("jump")
```

---

## Assets API

The Assets API provides manifest-based asset loading with caching.

### `assets.loadManifest(path)` → `loaded, total`
Load all assets defined in a JSON manifest file.
- **Parameters**: `path` (string) - Path to manifest JSON
- **Returns**: `loaded, total` (number, number) - Count of loaded and total assets
```lua
local loaded, total = assets.loadManifest("content/assets.json")
print(string.format("Loaded %d/%d assets", loaded, total))
```

**Manifest Format:**
```json
{
  "assets": {
    "textures": ["content/images/*.png"],
    "fonts": [{"path": "content/fonts/font.ttf", "sizes": [16, 18, 24]}]
  },
  "locales": {
    "es": {"title": "content/images/title_es.png"}
  }
}
```

### `assets.loadFont(path, size)` → `fontId`
Load a font with caching. Returns cached ID if already loaded.
- **Parameters**:
  - `path` (string) - Path to .ttf file
  - `size` (number) - Font size in pixels
- **Returns**: `fontId` (number)
```lua
-- First call loads font
local font = assets.loadFont("content/fonts/font.ttf", 24)
-- Subsequent calls return cached ID (fast)
local sameFont = assets.loadFont("content/fonts/font.ttf", 24)
```

### `assets.getTexture(name)` → `textureId`
Get a texture by its manifest name (derived from filename).
- **Parameters**: `name` (string) - Texture name (without extension)
- **Returns**: `textureId` (number)
```lua
local tex = assets.getTexture("player")  -- Gets content/images/player.png
```

### `assets.hasAsset(name)` → `boolean`
Check if a named asset exists in the manifest.
- **Parameters**: `name` (string)
- **Returns**: `exists` (boolean)
```lua
if assets.hasAsset("player") then
    local tex = assets.getTexture("player")
end
```

### `assets.setLocale(locale)`
Set the active locale for internationalized assets.
- **Parameters**: `locale` (string) - Locale code (e.g., "en", "es", "ja")
```lua
assets.setLocale("es")  -- Switch to Spanish assets
```

---

## Logger API

Structured logging with log levels and colored output.

### `log.trace(message)` / `log.debug(message)` / `log.info(message)` / `log.warn(message)` / `log.error(message)`
Log a message at the specified level.
- **Parameters**: `message` (string)
```lua
log.info("Player spawned at position " .. x .. ", " .. y)
log.warn("Health is low!")
log.error("Failed to load asset")
```

### `log.setLevel(level)`
Set minimum log level (messages below this are ignored).
- **Parameters**: `level` (string) - `"trace"`, `"debug"`, `"info"`, `"warn"`, or `"error"`
```lua
log.setLevel("debug")  -- Show debug and above
log.setLevel("warn")   -- Only show warnings and errors
```

**Output format**: `[HH:MM:SS][LEVEL] Lua:0: message`

---

## Profiler API

Tracy-based performance profiling (no-op when `TRACY_ENABLE` is not defined).

### `profiler.mark(name)`
Place a marker/message in the profiler timeline.
```lua
profiler.mark("Player::update started")
```

### `profiler.plot(name, value)`
Plot a numeric value for visualization in Tracy.
```lua
profiler.plot("FPS", 1.0 / dt)
profiler.plot("Active Entities", #entities)
```

### `profiler.beginZone(name)` / `profiler.endZone()`
Mark code sections (uses Tracy messages).
```lua
profiler.beginZone("AI Update")
-- expensive AI logic
profiler.endZone()
```

> [!NOTE]
> To enable profiling, build with `-DHELHEIM_ENABLE_TRACY=ON` and run the Tracy GUI.

---

### `loadJSON(path)`
Load and parse JSON file.
- **Parameters**: `path` (string)
- **Returns**: Lua table
```lua
local data = loadJSON("content/level.json")
print(data.title) -- "Dungeon Level 1"
```

---

## Core Lua Functions

### `class()`
Create a new class.
```lua
Player = class()
function Player:init(x, y)
    self.x = x
    self.y = y
end
```

### `thread(func)`
Start a coroutine.
```lua
thread(function()
    print("Start")
    wait(2.0)
    print("After 2 seconds")
end)
```

### `wait(seconds)`
Pause coroutine (must be inside `thread`).
```lua
wait(1.5) -- Wait 1.5 seconds
```

---

## ObjectPool API

Generic object pooling system to reduce garbage collection pressure by reusing Lua tables.

### `ObjectPool.new(constructor, reset, initialSize)` → `pool`
Create a new object pool.
- **Parameters**:
  - `constructor` (function): Returns a new object table
  - `reset` (function, optional): Resets an object for reuse `function(obj)`
  - `initialSize` (number, optional): Pre-allocate this many objects
- **Returns**: Pool instance
```lua
local bulletPool = ObjectPool.new(
    function() return { x = 0, y = 0, active = false } end,
    function(b) b.x = 0; b.y = 0; b.active = false end,
    50  -- Pre-allocate 50 bullets
)
```

### `pool:acquire(...)` → `object`
Get an object from the pool (reuses if available, creates if empty).
- **Parameters**: `...` - Arguments passed to object's `init` method if present
- **Returns**: Object table
```lua
local bullet = bulletPool:acquire()
bullet.x, bullet.y = player.x, player.y
```

### `pool:release(object)`
Return an object to the pool for reuse.
- **Parameters**: `object` (table) - Object to release
```lua
bulletPool:release(bullet)
```

### `pool:releaseAll()`
Release all active objects back to the pool.

### `pool:getStats()` → `table`
Get pool statistics for monitoring.
- **Returns**: Table with `available`, `active`, `totalCreated`, `totalReused`, `reuseRate`
```lua
local stats = bulletPool:getStats()
print(string.format("Reuse rate: %.0f%%", stats.reuseRate * 100))
```

### `pool:prewarm(count)`
Pre-allocate additional objects.
```lua
bulletPool:prewarm(100)  -- Add 100 more objects to pool
```

### `pool:shrink(maxSize)`
Remove excess available objects from pool.

### `pool:clear()`
Clear the entire pool (for cleanup/destruction).

## Window Manager API

### Window Dimensions

#### `Window.getWidth()` → `number`
Get current window width in logical pixels.
```lua
local width = Window.getWidth()  -- e.g., 1280
```

#### `Window.getHeight()` → `number`
Get current window height in logical pixels.
```lua
local height = Window.getHeight()  -- e.g., 720
```

#### `Window.getAspectRatio()` → `number`
Get current window aspect ratio.
```lua
local ratio = Window.getAspectRatio()  -- e.g., 1.777 (16:9)
```

### DPI Scaling

#### `Window.getDPIScale()` → `number`
Get DPI scale factor (1.0 = 96 DPI, 2.0 = Retina/192 DPI).
```lua
local scale = Window.getDPIScale()  -- e.g., 2.0 on Retina displays
```

#### `Window.getScaledWidth()` → `number`
Get physical pixel width (logical width × DPI scale).
```lua
local physicalWidth = Window.getScaledWidth()  -- e.g., 2560 on Retina
```

#### `Window.getScaledHeight()` → `number`
Get physical pixel height (logical height × DPI scale).
```lua
local physicalHeight = Window.getScaledHeight()  -- e.g., 1440 on Retina
```

### Window Modes

#### `Window.getWindowMode()` → `string`
Get current window mode.
- **Returns**: `"Windowed"`, `"Fullscreen"`, or `"BorderlessFullscreen"`
```lua
local mode = Window.getWindowMode()
if mode == "Windowed" then
    print("Running in windowed mode")
end
```

#### `Window.setWindowMode(mode)`
Set window mode.
- **Parameters**: `mode` (string) - `"Windowed"`, `"Fullscreen"`, or `"BorderlessFullscreen"`
```lua
Window.setWindowMode("Fullscreen")
```

#### `Window.toggleFullscreen()`
Toggle between windowed and fullscreen modes.
```lua
Window.toggleFullscreen()  -- Also bound to F11 key
```

### Cursor Management

#### `Window.setCursorVisible(visible)`
Show or hide the mouse cursor.
- **Parameters**: `visible` (boolean)
```lua
Window.setCursorVisible(false)  -- Hide cursor during gameplay
Window.setCursorVisible(true)   -- Show cursor in menus
```

#### `Window.isCursorVisible()` → `boolean`
Check if cursor is visible.
```lua
if Window.isCursorVisible() then
    print("Cursor is visible")
end
```

#### `Window.setCursorType(type)`
Change cursor appearance.
- **Parameters**: `type` (string)
- **Available Types**:
  - `"Arrow"` - Default cursor
  - `"Hand"` - Pointing hand (for buttons)
  - `"Crosshair"` - Crosshair (for targeting)
  - `"TextInput"` - I-beam (for text fields)
  - `"Wait"` - Hourglass/spinner
  - `"SizeNS"` - Vertical resize
  - `"SizeEW"` - Horizontal resize
  - `"SizeNWSE"` - Diagonal resize (↖↘)
  - `"SizeSWNE"` - Diagonal resize (↙↗)
  - `"Move"` - Four-way arrows
  - `"NotAllowed"` - Prohibited sign

```lua
-- Context-sensitive cursors
function OnButtonHover()
    Window.setCursorType("Hand")
end

function OnButtonLeave()
    Window.setCursorType("Arrow")
end

function OnTextFieldFocus()
    Window.setCursorType("TextInput")
end
```

### Performance Metrics

#### `Window.getFPS()` → `number`
Get current frames per second.
```lua
local fps = Window.getFPS()
print(string.format("FPS: %.1f", fps))
```

#### `Window.getFrameTime()` → `number`
Get frame time in seconds.
```lua
local frameTime = Window.getFrameTime()
print(string.format("Frame time: %.2fms", frameTime * 1000))
```

#### `Window.getFrameCount()` → `number`
Get total number of frames rendered since startup.
```lua
local frames = Window.getFrameCount()
```

### Window State

#### `Window.isFocused()` → `boolean`
Check if window has input focus.
```lua
if not Window.isFocused() then
    -- Pause game when window loses focus
    pauseGame()
end
```

#### `Window.isMinimized()` → `boolean`
Check if window is minimized.
```lua
if Window.isMinimized() then
    -- Reduce CPU usage
end
```

### Multi-Monitor Support

#### `Window.getMonitorCount()` → `number`
Get number of connected monitors.
```lua
local count = Window.getMonitorCount()
print(count .. " monitors detected")
```

#### `Window.getMonitors()` → `table`
Get array of monitor information.
- **Returns**: Array of monitor tables with fields:
  - `name` (string) - Monitor name
  - `width` (number) - Width in pixels
  - `height` (number) - Height in pixels
  - `x` (number) - X position
  - `y` (number) - Y position
  - `dpiScale` (number) - DPI scale factor
  - `refreshRate` (number) - Refresh rate in Hz
  - `isPrimary` (boolean) - True if primary monitor

```lua
local monitors = Window.getMonitors()
for i, monitor in ipairs(monitors) do
    print(string.format("Monitor %d: %s (%dx%d @ %.1fHz) %s",
        i,
        monitor.name,
        monitor.width,
        monitor.height,
        monitor.refreshRate,
        monitor.isPrimary and "[Primary]" or ""))
end
```

#### `Window.setMonitor(index)` → `boolean`
Move window to specific monitor.
- **Parameters**: `index` (number) - Monitor index (1-based)
- **Returns**: `true` if successful
```lua
if Window.getMonitorCount() > 1 then
    Window.setMonitor(2)  -- Move to second monitor
end
```

### VSync Control

#### `Window.setVSync(enabled)`
Enable or disable vertical sync.
- **Parameters**: `enabled` (boolean)
```lua
Window.setVSync(true)   -- Enable VSync (limit to monitor refresh rate)
Window.setVSync(false)  -- Disable VSync (uncapped framerate)
```

#### `Window.isVSyncEnabled()` → `boolean`
Check if VSync is enabled.
```lua
if Window.isVSyncEnabled() then
    print("VSync is ON")
end
```

---

## UI Manager API

### `UIManager.build()`
Build UI from `UIDefinitions`.
```lua
UIManager.build()
```

### `UIManager.get(name)`
Get UI element by name.
- **Returns**: UIElement or nil
```lua
local healthBar = UIManager.get("HealthBarFill")
healthBar.Width = 150
```

### `UIManager.show(name, immediate)`
Fade in UI element.
```lua
UIManager.show("SubtitlesBacking")
```

### `UIManager.hide(name, immediate)`
Fade out UI element.
```lua
UIManager.hide("SubtitlesBacking", true) -- Immediate
```

---

## Scene Management API

### `SceneManager.switch(sceneName, transition, data)`
Switch to a new scene, clearing the stack.
- **Parameters**:
    - `sceneName` (string): Global name of the scene class.
    - `transition` (table, optional): `{ type = "fade", duration = 0.5, color = {r,g,b,a} }`.
    - `data` (table, optional): Data passed to the new scene's `onInit`.

### `SceneManager.push(sceneName, transition, data)`
Push a new scene onto the stack, pausing the current one.

### `SceneManager.pop(transition)`
Pop the current scene and resume the previous one.

### `SceneManager.sharedState`
A global table for data that persists between scenes.

### `Scene:onInit(data)`
Lifecycle hook called when a scene is first created.

---

## TileMap API

### `TileMap.load(path)` → `tilemap`
Load a Tiled `.tmj` file. 
**Supported Formats:**
- Layer Data: CSV, Base64 (zlib compressed), Base64 (gzip compressed)
- Tile Animations: Yes (requires calling `map:update(dt)`)

### `TileMap.getByName(name)` → `tilemap`
Get a preloaded tilemap from the Asset Manager.

### `tilemap:update(dt)`
Update map animations. Must be called every frame with delta time.
- **Parameters**: `dt` (number) - Delta time in seconds.

### `tilemap:draw(options)`
Draw the tilemap.
- **Options**: `{ cameraX, cameraY, scale, ignoreCulling }`

### `tilemap:getTileId(x, y, layerName)` → `number`
### `tilemap:setTileId(x, y, layerName, tileId)`
### `tilemap:getProperty(x, y, propertyName)` → `string`
### `tilemap:getMapProperty(propertyName)` → `string`
### `tilemap:getObjects(layerName)` → `table[]`
### `tilemap:getObject(name)` → `table`
### `tilemap:createCollisionBodies(layerName)`
Generate Box2D static bodies for the specified layer.

---

## Pathfinding API

High-performance A* pathfinding for tile-based NPC navigation.

### `Pathfinding.createForTileMap(tilemap)` → `number`
Create a pathfinder for a specific tilemap.
- **Parameters**: `tilemap` (userdata) - TileMap instance
- **Returns**: `pathfinderId` (number) - Pathfinder handle
```lua
local map = TileMap.load("content/maps/world.tmj")
local pfId = Pathfinding.createForTileMap(map)
```

### `Pathfinding.setActive(id)`
Set the active pathfinder by ID.
- **Parameters**: `id` (number) - Pathfinder ID from `createForTileMap`
```lua
Pathfinding.setActive(myPathfinderId)
```

### `Pathfinding.find(request)` → `table`
Find a path between two points.
- **Parameters**: `request` (table) with fields:
  - `start` (table, required): `{x, y}` - Start tile coordinates
  - `target` (table, required): `{x, y}` - Target tile coordinates
  - `diagonal` (boolean, optional): Allow 8-way movement (default: false)
  - `layer` (string, optional): Navigation layer name (default: `"nav_ground"`)
  - `maxSteps` (number, optional): Max nodes to expand (default: 1000)
  - `maxTime` (number, optional): Max time in ms (default: 5.0)
  - `smooth` (boolean, optional): Apply path smoothing (default: false)
  - `costFunction` (function, optional): Custom `function(x, y) → cost` callback
- **Returns**: Result table with fields:
  - `path` (array): Array of `{x, y}` waypoints
  - `found` (boolean): True if complete path found
  - `partial` (boolean): True if search hit limits
  - `nodesExpanded` (number): Nodes explored (for profiling)
  - `timeMs` (number): Time taken in milliseconds

```lua
local result = Pathfinding.find({
    start = {x = npc.x, y = npc.y},
    target = {x = targetX, y = targetY},
    diagonal = true,
    layer = "nav_ground",
    smooth = true,
    maxSteps = 500
})

if result.found then
    for i, point in ipairs(result.path) do
        print(string.format("Step %d: (%d, %d)", i, point.x, point.y))
    end
elseif result.partial then
    print("Partial path (hit search limit)")
else
    print("No path found")
end
```

### `Pathfinding.isWalkable(x, y, layer)` → `boolean`
Check if a tile is walkable.
- **Parameters**:
  - `x, y` (number) - Tile coordinates
  - `layer` (string, optional) - Navigation layer (default: `"nav_ground"`)
- **Returns**: `walkable` (boolean)
```lua
if Pathfinding.isWalkable(spawnX, spawnY, "nav_ground") then
    spawnNPC(spawnX, spawnY)
end
```

### `Pathfinding.getCost(x, y, layer)` → `number`
Get traversal cost for a tile.
- **Parameters**:
  - `x, y` (number) - Tile coordinates
  - `layer` (string, optional) - Navigation layer
- **Returns**: `cost` (number) - Cost multiplier, or -1 if unwalkable
```lua
local cost = Pathfinding.getCost(x, y, "nav_ground")
if cost > 2.0 then
    print("Difficult terrain!")
end
```

### `Pathfinding.invalidateRegion(x, y, width, height)`
Invalidate cached pathfinding data for a region (call when tiles change).
- **Parameters**:
  - `x, y` (number) - Top-left tile coordinates
  - `width, height` (number) - Region size in tiles
```lua
function onDoorOpened(doorX, doorY)
    Pathfinding.invalidateRegion(doorX - 2, doorY - 2, 5, 5)
end
```

### Custom Cost Functions
```lua
local result = Pathfinding.find({
    start = {x = 0, y = 0},
    target = {x = 50, y = 50},
    costFunction = function(x, y)
        -- Avoid areas near enemies
        if isNearEnemy(x, y) then return 10.0 end
        -- Prefer roads
        if isRoad(x, y) then return 0.5 end
        return 1.0
    end
})
```

---

## Spatial Partitioning API

High-performance Quadtree for fast non-physics spatial queries.

### `spatial.create(x, y, w, h, maxObjects, maxLevels)` → `number`
Create a new spatial index (Quadtree).
- **Parameters**:
  - `x, y` (number) - Top-left corner of the world bounds
  - `w, h` (number) - Width and height of the world
  - `maxObjects` (number, optional) - Max objects per node before subdividing (default: 10)
  - `maxLevels` (number, optional) - Maximum tree depth (default: 5)
- **Returns**: `handle` (number) - Quadtree handle
```lua
local tree = spatial.create(0, 0, 3200, 1280, 10, 5)
```

### `spatial.destroy(handle)`
Free a spatial index and all its memory.
- **Parameters**: `handle` (number) - Quadtree handle
```lua
spatial.destroy(tree)
```

### `spatial.insert(handle, id, x, y, w, h)`
Insert an object with an axis-aligned bounding box.
- **Parameters**:
  - `handle` (number) - Quadtree handle
  - `id` (number) - Unique object ID
  - `x, y, w, h` (number) - Bounding box
```lua
spatial.insert(tree, entity.id, entity.x, entity.y, 32, 32)
```

### `spatial.insertPoint(handle, id, x, y)`
Insert a point object (zero-size).
- **Parameters**:
  - `handle` (number) - Quadtree handle
  - `id` (number) - Unique object ID
  - `x, y` (number) - Point position
```lua
spatial.insertPoint(tree, pickup.id, pickup.x, pickup.y)
```

### `spatial.remove(handle, id)`
Remove an object by ID.
- **Parameters**:
  - `handle` (number) - Quadtree handle
  - `id` (number) - Object ID to remove
```lua
spatial.remove(tree, destroyedEntity.id)
```

### `spatial.update(handle, id, x, y, w, h)`
Update an object's position/bounds.
- **Parameters**:
  - `handle` (number) - Quadtree handle
  - `id` (number) - Object ID
  - `x, y, w, h` (number) - New bounding box
```lua
spatial.update(tree, entity.id, entity.x, entity.y, entity.w, entity.h)
```

### `spatial.query(handle, x, y, w, h)` → `table`
Find all objects intersecting a rectangle.
- **Parameters**:
  - `handle` (number) - Quadtree handle
  - `x, y, w, h` (number) - Query rectangle
- **Returns**: Array of object IDs
```lua
local visibleIds = spatial.query(tree, cameraX, cameraY, screenW, screenH)
for _, id in ipairs(visibleIds) do
    entities[id]:draw()
end
```

### `spatial.queryRadius(handle, x, y, radius)` → `table`
Find all objects within a circular radius.
- **Parameters**:
  - `handle` (number) - Quadtree handle
  - `x, y` (number) - Center point
  - `radius` (number) - Search radius
- **Returns**: Array of object IDs
```lua
local nearbyEnemies = spatial.queryRadius(tree, player.x, player.y, 200)
```

### `spatial.queryNearest(handle, x, y, maxRadius)` → `number`
Find the nearest object to a point.
- **Parameters**:
  - `handle` (number) - Quadtree handle
  - `x, y` (number) - Search center
  - `maxRadius` (number, optional) - Maximum search radius (default: 1000)
- **Returns**: Object ID, or -1 if none found
```lua
local nearestPickup = spatial.queryNearest(tree, player.x, player.y, 100)
if nearestPickup ~= -1 then
    showInteractPrompt(nearestPickup)
end
```

### `spatial.clear(handle)`
Remove all objects from the tree.
```lua
spatial.clear(tree)
```

### `spatial.size(handle)` → `number`
Get the total object count.
```lua
local count = spatial.size(tree)
print("Objects in tree: " .. count)
```

### `spatial.stats(handle)` → `table`
Get tree statistics for debugging.
- **Returns**: Table with fields:
  - `nodeCount` (number) - Total nodes in tree
  - `maxDepth` (number) - Current max depth
  - `totalObjects` (number) - Object count
  - `objectsPerLevel` (array) - Objects at each depth level
```lua
local stats = spatial.stats(tree)
print(string.format("Nodes: %d, Depth: %d", stats.nodeCount, stats.maxDepth))
```

