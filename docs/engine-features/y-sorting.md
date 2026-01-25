# Feature Specification: Y-Sorting (Depth)

> **Status: PROPOSED**

## Overview
Top-down 2D games (like RPGs) require sprites to be drawn in a specific order to create the illusion of depth. An object "lower" on the screen (higher Y coordinate) is "closer" to the camera and should obscure objects "higher" on the screen. This feature implements engine-level support for this sorting, commonly known as "Y-Sorting".

## Motivation
Currently, `SpriteRenderer` draws sprites in the order they are submitted (Submission Order). This places the burden on the user/scripter to manually order sorting calls. For dynamic entities (players moving around trees), this manual re-ordering is complex and error-prone. A native sorting system simplifies this significantly.

## Architecture: Deferred Rendering

To allow reordering of draw calls without losing the efficiency of texture batching, we will move `SpriteRenderer` from an **Immediate** submission model to a **Deferred** submission model.

### 1. Draw Commands
When `DrawSprite` is called, we will no longer immediately generate vertices. Instead, we create a lightweight `DrawCommand` and add it to a frame queue.

```cpp
struct DrawCommand {
    int textureId;
    float x, y, w, h;       // World position/size
    float sx, sy, sw, sh;   // UVs
    float rotation;
    bool flipX, flipY;
    bool screenSpace;       // If true, bypass Y-sorting
    Color tint;
    
    // Sorting keys
    int zIndex;             // Primary sort key (Layer)
    float sortY;            // Secondary sort key (Y-position for depth)
};
```

### 2. Sorting Strategy
In `SpriteRenderer::Flush()`, before generating vertices:

1. **Separate World and Screen-Space Draws**:
   - Screen-space draws (`screenSpace=true`) are queued separately and rendered last (always on top).
   - Only world-space draws participate in Y-sorting.

2. **Sort the World Draw Queue**:
   - **Primary Key**: `zIndex` (Ascending) - Allows broad layering (Background=-100, Ground=0, Foreground=100).
   - **Secondary Key**: `sortY` (Ascending) - Higher Y values (lower on screen) draw last (on top).
   - **Tertiary Key**: `textureId` (Ascending) - Minimize GPU state changes when Y values are equal.

**Sort Comparator**:
```cpp
auto sortComparator = [](const DrawCommand& a, const DrawCommand& b) {
    if (a.zIndex != b.zIndex) return a.zIndex < b.zIndex;
    if (std::abs(a.sortY - b.sortY) > 0.01f) return a.sortY < b.sortY;
    return a.textureId < b.textureId;  // Stability for equal Y
};
std::sort(worldDrawQueue.begin(), worldDrawQueue.end(), sortComparator);
```

### 3. Batch Generation
After sorting, we iterate through the ordered commands and generate vertices. We create a new GPU batch whenever the `textureId` changes between consecutive commands.

**Note**: Frequent texture switching due to interlaced Y-positions will increase draw calls. This is an acceptable trade-off for correctness. Future optimizations (Texture Arrays/Atlases) can mitigate this.

---

## API Changes

### C++ API
```cpp
// Added zIndex parameter (default 0)
void DrawSprite(int textureId, float x, float y, float w, float h,
                float rotation = 0.0f, bool flipX = false, bool flipY = false,
                Color tint = Color::White, bool screenSpace = false, 
                int zIndex = 0);
```

### Lua API
Update `graphics.draw` to accept an optional Z-index.

```lua
-- graphics.draw(tex, x, y, w, h, rotation, tint, screenSpace, zIndex)
graphics.draw(playerTex, x, y, 32, 32, 0, nil, false, 10) -- Layer 10

-- Backward compatible (zIndex defaults to 0)
graphics.draw(treeTex, x, y, 64, 64)
```

---

## Implementation Details

### Coordinate System
- **Engine uses Y-down**: Y=0 at top, increases downward.
- **Sort order**: Ascending `sortY` means higher Y (lower on screen) draws last (appears in front).

### Transparency
- Uses standard alpha blending (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA).
- Sorting (Painter's Algorithm) ensures correct blending order.

### Performance
- **Sorting overhead**: O(n log n) for n sprites.
  - 1,000 sprites: ~0.05ms
  - 10,000 sprites: ~0.5-1ms (on modern 3GHz CPU)
- **Worst case**: Pathological input with many equal zIndex values may approach 2ms for 10k sprites.
- **Mitigation**: Sort mode can be toggled per-layer or disabled for UI.

### Sort Mode Toggle
```cpp
enum class SortMode {
    None,      // Submission order (current behavior)
    YSort      // Z-index + Y-position sorting
};

void SetSortMode(SortMode mode);
```

---

## Integration

### TileMap Changes
- Add `int zIndex` field to `TileLayer` class.
- **Default values**:
  - Ground layers: `zIndex = -100`
  - Fringe layers: `zIndex = 0`
  - Overhang layers: `zIndex = 100`
- **Configurable via Tiled**: Custom property `z_index` on layers.
- **Modification**: `TileMap::draw()` passes layer's `zIndex` to `DrawSpriteRect()`.

### Entity Rendering
- Physics entities and NPCs submit with `zIndex = 0` (Fringe layer).
- Allows correct sorting against TileMap fringe objects and each other.
- **Tall sprites**: Use bottom Y-coordinate for `sortY` (e.g., `sortY = y + height`).

---

## Edge Cases

### 1. Identical Y and zIndex
**Scenario**: Two sprites at same position and layer.
**Behavior**: Tertiary sort by `textureId` provides deterministic order. If textures are also identical, order is undefined but stable within a frame.

### 2. Tall Sprites
**Scenario**: Sprite spans multiple Y-coordinates (e.g., tall tree).
**Solution**: Use **bottom Y** for `sortY`:
```cpp
cmd.sortY = y + h;  // Bottom of sprite
```
This ensures the sprite's "base" determines depth.

### 3. Screen-Space UI
**Scenario**: HUD elements should always render on top.
**Solution**: `screenSpace=true` draws bypass sorting and render last.

---

## Migration Path

### Breaking Changes
**None**. Default `zIndex=0` maintains relative submission order for sprites at the same Y-coordinate.

### Opt-In
- Existing games continue to work without modification.
- Enable Y-sorting by setting `SetSortMode(SortMode::YSort)` or passing explicit `zIndex` values.

---

## Future Optimizations

1. **Spatial Hashing**: Avoid sorting off-screen sprites (cull before sort).
2. **Texture Atlasing**: Reduce batch breaks by packing sprites into atlases.
3. **Instanced Rendering**: For identical sprites (grass, particles), use GPU instancing.
4. **Depth Buffer**: For 3D-style games, transition to Z-buffer instead of sorting.
