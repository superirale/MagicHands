# Magic Hands Lua API Reference

**Engine**: Custom C++20 + Lua 5.4 + SDL3  
**Last Updated**: January 28, 2026

---

## Graphics API

All graphics functions are in the `graphics` global table.

### Drawing Functions

#### graphics.drawRect(x, y, width, height, color, filled)
Draws a rectangle (filled or outline).

**Parameters**:
- `x` (number) - X position
- `y` (number) - Y position  
- `width` (number) - Rectangle width
- `height` (number) - Rectangle height
- `color` (table) - Color table: `{r=1, g=1, b=1, a=1}` (values 0-1)
- `filled` (boolean) - `true` for filled, `false` for outline

**C++ Implementation**: `LuaBindings.cpp:159` (Lua_DrawRect)

**Example**:
```lua
-- Filled red rectangle
graphics.drawRect(100, 100, 200, 150, {r=1, g=0, b=0, a=1}, true)

-- White outline
graphics.drawRect(100, 100, 200, 150, {r=1, g=1, b=1, a=1}, false)
```

---

#### graphics.print(fontId, text, x, y, color)
Renders text at the specified position.

**Parameters**:
- `fontId` (number) - Font ID from `graphics.loadFont()`
- `text` (string) - Text to render
- `x` (number) - X position
- `y` (number) - Y position
- `color` (table) - Optional color: `{r=1, g=1, b=1, a=1}` (defaults to white)

**C++ Implementation**: `FontRenderer.cpp:118` (Lua_DrawText)

**Example**:
```lua
local font = graphics.loadFont("content/fonts/font.ttf", 24)
graphics.print(font, "Hello World", 100, 100, {r=1, g=1, b=1, a=1})
```

---

#### graphics.draw(textureId, x, y, width, height, rotation, flipX, flipY, color, screenSpace)
Draws a sprite/texture.

**Parameters**:
- `textureId` (number) - Texture ID from `graphics.loadTexture()`
- `x`, `y` (number) - Position
- `width`, `height` (number) - Size
- `rotation` (number) - Rotation in radians
- `flipX`, `flipY` (boolean) - Flip horizontally/vertically
- `color` (table) - Tint color
- `screenSpace` (boolean) - Screen space (true) or world space (false)

**C++ Implementation**: `LuaBindings.cpp:100` (Lua_DrawSprite)

---

#### graphics.drawSub(textureId, x, y, width, height, u, v, uWidth, vHeight, rotation, flipX, flipY, color, screenSpace)
Draws a sub-rectangle (sprite sheet).

**Parameters**: Similar to `draw()` with UV coordinates added

**C++ Implementation**: `LuaBindings.cpp:116` (Lua_DrawSpriteRect)

---

### Resource Loading

#### graphics.loadTexture(path)
Loads a texture file.

**Returns**: Texture ID (number)

**Example**:
```lua
local texture = graphics.loadTexture("content/images/sprite.png")
```

---

#### graphics.loadFont(path, size)
Loads a TrueType font.

**Parameters**:
- `path` (string) - Path to .ttf file
- `size` (number) - Font size in pixels

**Returns**: Font ID (number)

**C++ Implementation**: `FontRenderer.cpp:110` (Lua_LoadFont)

**Example**:
```lua
local font = graphics.loadFont("content/fonts/font.ttf", 24)
local smallFont = graphics.loadFont("content/fonts/font.ttf", 16)
```

---

### Utility Functions

#### graphics.getTextureSize(textureId)
Gets texture dimensions.

**Returns**: width, height (two numbers)

---

#### graphics.getWindowSize()
Gets window dimensions.

**Returns**: width, height (two numbers)

---

### Camera Functions

#### graphics.setCamera(x, y)
Sets camera position.

---

#### graphics.setViewport(width, height)
Sets viewport size.

---

#### graphics.setZoom(zoom)
Sets camera zoom level.

---

#### graphics.resetViewport()
Resets viewport to window size.

---

### Shader Functions

#### graphics.loadShader(name, path)
Loads a post-processing shader.

---

#### graphics.enableShader(name, enabled)
Enables/disables a shader.

---

#### graphics.setShaderUniform(name, values)
Sets shader uniform values.

---

## Functions That DO NOT Exist

These functions are commonly used in other engines but are **not available** in Magic Hands:

```lua
graphics.setColor(r, g, b, a)           -- ❌ Does not exist
graphics.rectangle("fill", x, y, w, h)  -- ❌ Does not exist
graphics.setFont(font)                  -- ❌ Does not exist
graphics.circle("fill", x, y, radius)   -- ❌ Does not exist
```

**Why**: Magic Hands uses a different graphics architecture. Colors and fonts are passed per-draw call, not set globally.

---

## Input API

All input functions are in the `input` global table.

### Keyboard

#### input.isPressed(key)
Check if key was just pressed this frame (single frame detection).

**Parameters**: `key` (string) - Key name: "a"-"z", "return", "escape", "space", "tab", etc.

**Example**:
```lua
if input.isPressed("c") then
    -- Handle 'C' key press
end
```

---

### Mouse

#### input.getMousePosition()
Gets mouse position.

**Returns**: x, y (two numbers)

---

#### input.isMouseButtonPressed(button)
Checks if mouse button is held down.

**Parameters**: `button` (string) - "left", "right", or "middle"

**Example**:
```lua
local mx, my = input.getMousePosition()
local clicked = input.isMouseButtonPressed("left")
```

---

### Functions That DO NOT Exist

```lua
input.isMouseJustPressed(button)  -- ❌ Does not exist (wrong API)
input.isKeyJustPressed(key)       -- ❌ Does not exist (use isPressed)
```

---

## Files API

All file functions are in the `files` global table.

### JSON

#### files.loadJSON(path)
Loads and parses a JSON file.

**Returns**: Lua table or nil

**C++ Implementation**: `JsonUtils.cpp:19` (Lua_LoadJSON)

**Example**:
```lua
if files and files.loadJSON then
    local data = files.loadJSON("content/data/items.json")
    if data then
        print("Loaded: " .. data.name)
    end
end
```

---

#### files.saveFile(path, content)
Saves string to file.

**C++ Implementation**: `JsonUtils.cpp:45` (Lua_SaveFile)

---

#### files.loadFile(path)
Loads file as string.

**C++ Implementation**: `JsonUtils.cpp:71` (Lua_LoadFile)

---

## Events API

Global `events` table for event system.

### events.on(eventName, callback)
Subscribe to an event.

**Example**:
```lua
events.on("hand_scored", function(data)
    print("Score: " .. data.score)
end)
```

---

### events.emit(eventName, data)
Emit an event.

**Example**:
```lua
events.emit("gold_changed", { amount = 100, delta = 50 })
```

---

## Color Format

All colors in Magic Hands use table format with RGBA values from 0 to 1:

```lua
local color = {
    r = 1.0,  -- Red (0-1)
    g = 0.5,  -- Green (0-1)
    b = 0.0,  -- Blue (0-1)
    a = 1.0   -- Alpha/opacity (0-1, optional, defaults to 1)
}
```

**Common Colors**:
```lua
local white = {r=1, g=1, b=1, a=1}
local black = {r=0, g=0, b=0, a=1}
local red = {r=1, g=0, b=0, a=1}
local green = {r=0, g=1, b=0, a=1}
local blue = {r=0, g=0, b=1, a=1}
local transparent = {r=0, g=0, b=0, a=0}
```

---

## Best Practices

### 1. Always Check Module Availability
```lua
if files and files.loadJSON then
    local data = files.loadJSON(path)
end
```

### 2. Pass Font and Color Per-Draw
```lua
-- Don't try to "set" font or color globally
-- Pass them with each draw call
graphics.print(font, "text", x, y, color)
```

### 3. Use tonumber() for Event Data
```lua
events.on("score_changed", function(data)
    local score = tonumber(data.score) or 0  -- Type safety
end)
```

### 4. Check for nil Returns
```lua
local data = files.loadJSON(path)
if not data then
    print("Failed to load: " .. path)
    return
end
```

---

## Common Patterns

### Drawing a UI Panel
```lua
local x, y, w, h = 100, 100, 300, 200

-- Background
graphics.drawRect(x, y, w, h, {r=0.1, g=0.1, b=0.2, a=0.9}, true)

-- Border
graphics.drawRect(x, y, w, h, {r=0.5, g=0.7, b=0.9, a=1}, false)

-- Title
graphics.print(font, "Title", x+10, y+10, {r=1, g=1, b=1, a=1})
```

### Loading Game Data
```lua
local function loadItemData(itemId)
    local path = "content/data/items/" .. itemId .. ".json"
    
    if not files or not files.loadJSON then
        print("ERROR: files.loadJSON not available")
        return nil
    end
    
    local data = files.loadJSON(path)
    if not data then
        print("ERROR: Failed to load " .. path)
        return nil
    end
    
    return data
end
```

### Handling Input
```lua
function MyUI:update(dt, mx, my, clicked)
    -- Check if button is clicked
    if clicked and mx >= self.x and mx <= self.x + self.width and
       my >= self.y and my <= self.y + self.height then
        self:onClick()
    end
    
    -- Check for keyboard shortcut
    if input.isPressed("escape") then
        self:close()
    end
end
```

---

## Source Code References

**Graphics Bindings**: `src/scripting/LuaBindings.cpp`  
**Font Rendering**: `src/graphics/FontRenderer.cpp`  
**JSON Utilities**: `src/core/JsonUtils.cpp`  
**Input System**: (C++ input bindings)  
**Event System**: (C++ EventSystem)  

---

## Adding New API Functions

If you need to add new graphics functions to the Lua API:

1. Implement the C++ function in `LuaBindings.cpp`
2. Register it in the `graphics` table (around line 540-575)
3. Document it in this API.md file
4. Rebuild the project: `cd build && cmake --build . --config Release`

**Example** (adding a circle function):
```cpp
// In LuaBindings.cpp
int Lua_DrawCircle(lua_State *L) {
    float x = (float)luaL_checknumber(L, 1);
    float y = (float)luaL_checknumber(L, 2);
    float radius = (float)luaL_checknumber(L, 3);
    Color color = ParseColor(L, 4);
    bool filled = lua_toboolean(L, 5);
    
    // Implement circle drawing...
    return 0;
}

// In RegisterBindings() function (around line 560)
lua_pushcfunction(L, Lua_DrawCircle);
lua_setfield(L, -2, "drawCircle");
```

---

**This is the complete Magic Hands Lua API. Use only these functions - others do not exist!**
