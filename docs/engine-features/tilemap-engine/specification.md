# Feature Specification: C++ Tilemap Engine

## 1. Overview
The **C++ Tilemap Engine** is a high-performance rendering and data management system for Magic Hands. It replaces the current Lua-based tile rendering with a native C++ implementation optimized for large, complex worlds like those in *Stardew Valley*.

The engine supports two primary use cases:
- **Procedural Worlds**: Large, runtime-generated terrain with dynamic modification (farming, mining)
- **Hand-Crafted Maps**: Pre-designed areas (towns, interiors, dungeons) created in Tiled Map Editor

---

## 2. Integration: Tiled Map Editor
*   **Format Support**: Native support for Tiled JSON (.tmj) and Tileset (.tsj) exports.
*   **Workflow**: Maps are designed in Tiled, exported as JSON, and loaded via the Magic Hands C++ API.
*   **See Also**: [Tiled Integration Guidelines](tiled-integration.md) for detailed workflow and conventions.

---

## 3. Core Features

### A. Rendering Architecture
*   **Vertex Batching**: All tiles sharing a texture atlas are batched into a single vertex buffer transfer.
*   **Vertex Tinting**: Per-tile and per-layer color multiplication for static lighting (baking shadows) and day/night variations.
*   **Multi-Texture Support**: Automatically handles layers that span multiple tilesets by splitting draw calls or using texture arrays.
*   **Frustum Culling**: Tile rendering is automatically restricted to the current camera viewport.
*   **Animated Tiles**: Native support for Tiled's frame-based tile animations with optional Lua callbacks.
*   **Static Buffering**: Ground and stationary layers use persistent vertex buffers on the GPU, only updating when the map changes (or when a chunk is dynamically modified).
*   **Instanced Rendering**: Common repeated tiles (fields, water) use GPU instancing for optimal performance.
*   **Dynamic Tile Modification**: API to change tiles at runtime (e.g., tilling soil, watering). 
    *   Updates only affected vertex buffer regions (chunks) via dirty rectangle tracking.
    *   **Physics Sync**: Automatically rebuilds Box2D bodies for the chunk if the modified tile has collision data.

### B. Layer Management
*   **Multi-layered Support**: Handles unlimited layers exported from Tiled.
*   **Layer Categories** (determined by naming convention):
    *   `Ground_*`: Base terrain, static buffering, no sorting
    *   `Fringe_*`: Y-sorted with entities (trees, fences, buildings)
    *   `Overhang_*`: Always rendered on top (roofs, canopy)
    *   `Collision_*`: Invisible, used for Box2D static bodies
    *   `Objects_*`: Parsed as entity spawn data, not rendered as tiles
*   **Depth Integration**: 
    *   **Fringe Layers (Interleaved)**: Supports **Row-based Y-sorting**. Tiles in these layers are drawn individually interleaved with game entities (players/NPCs) based on Y-position to allow correct "behind/in-front" visual sorting.
*   **Layer Tinting**: Per-layer color overlay (e.g., fog on overhangs, warm tint for interiors).
*   **Layer Visibility**: Runtime toggle for debugging and editor tools.

### C. Data & Metadata
*   **Tile Properties**: Direct access to custom Tiled properties (e.g., `is_farmable`, `fish_type`, `step_sound`, `particle_emitter`).
*   **Map Properties**: Access to custom properties set on the map itself (e.g., `forced_time`, `music_track`, `ambient_light`).
*   **Object Layers**: Full support for Tiled Object Layers to define spawn points, triggers, NPCs, and POIs.
*   **Collision Polygons**: Parse and create Box2D chain shapes from Tiled polygon collision objects.
*   **Fast Queries**: O(1) tile data lookup for gameplay systems (AI, pathfinding).
*   **Data Encoding/Compression**: Support for `base64`, `zlib`, and `zstd` encoded layer data, common in Tiled JSON exports.
*   **Chunking (Large Maps)**: Automatically splits large maps into internal 16x16 or 32x32 chunks for efficient frustum culling and partial vertex updates.

### D. Tinting & Lighting System
*   **Global Tint**: Applied to all layers, controlled by day/night cycle manager.
*   **Layer Tint**: Per-layer color multiplication, stacks with global tint.
*   **Baked Lightmaps**: Optional support for pre-baked lighting from Tiled (via tile properties or separate overlay layer).

---

## 4. Technical Implementation Details

### C++ Components
*   `TileMap`: Primary class for managing map data and rendering.
*   `TileSet`: Handles texture loading (via AssetManager) and UV coordinate mapping for different atlases.
*   `TileLayer`: Manages vertex buffers and state for individual map layers.
*   `TiledParser`: Utility to deserialize `.tmj` files using `nlohmann::json`.
*   `ObjectLayer`: Container for parsed Tiled objects with property access.

### AssetManager Integration
*   Tileset textures are loaded through `AssetManager` to prevent duplicate loading across maps.
*   Shared tilesets (e.g., common terrain) are cached and reused.
*   Maps can specify an `assetGroup` for grouped loading/unloading.

---

## 5. Lua API

### Loading & Creation
```lua
-- Load from Tiled JSON file (towns, interiors)
local townMap = TileMap.load("content/maps/town.tmj")
local townMap = TileMap.load("content/maps/town.tmj", {
    assetGroup = "town"  -- Optional: group for AssetManager
})

-- Create empty map for procedural generation
local wilderness = TileMap.create(500, 500, 32)  -- width, height, tileSize
```

### Rendering
```lua
-- Standard draw (uses frustum culling)
townMap:draw()

-- Draw without culling (for minimaps)
townMap:draw({ ignoreCulling = true, scale = 0.1 })

-- Layer visibility control
townMap:setLayerVisible("Collision_Main", false)
```

### Tile Queries
```lua
-- Single tile queries
local canPlant = townMap:getProperty(x, y, "is_farmable")
local tileType = townMap:getTileId(x, y, "Ground_Base")
local emitter = townMap:getProperty(x, y, "particle_emitter")

-- Bulk queries
local tiles = townMap:getTilesInRect(x, y, w, h, "Ground_Base")
```

### Tile Modification
```lua
-- Single tile
townMap:setTileId(x, y, "Ground_Base", newTileId)

-- Bulk modification (better performance)
townMap:setTileIds({
    {x=1, y=2, layer="Ground_Base", id=5},
    {x=2, y=2, layer="Ground_Base", id=5},
    {x=3, y=2, layer="Ground_Base", id=6},
})

-- Save modifications as diff (not full map)
townMap:saveChanges("saves/farm_modifications.json")

-- Modification callback
townMap:onTileChanged(function(x, y, layerName, oldTile, newTile)
    -- Handle entity displacement, etc.
end)
```

### Tinting & Lighting
```lua
-- Global tint (day/night cycle)
townMap:setGlobalTint(Color.new(0.8, 0.7, 0.5, 1.0))

-- Per-layer tint (fog, atmosphere)
townMap:setLayerTint("Overhang_Fog", Color.new(1, 1, 1, 0.3))
```

### Object Layer Access
```lua
-- Get all objects from a layer
local npcs = townMap:getObjects("Objects_NPCs")
for _, obj in ipairs(npcs) do
    -- obj has: name, type, x, y, width, height, properties
    NPCManager.spawn(obj.name, obj.x, obj.y, obj.properties)
end

-- Get specific object by name
local spawnPoint = townMap:getObject("DefaultSpawn")
Player:setPosition(spawnPoint.x, spawnPoint.y)

-- Get objects by type
local doors = townMap:getObjectsByType("Door")
```

### Map Properties
```lua
-- Access map-level custom properties
local music = townMap:getMapProperty("music_track")
local forcedTime = townMap:getMapProperty("forced_time")
local ambientColor = townMap:getMapProperty("ambient_light")
```

### Collision
```lua
-- Create Box2D bodies from collision layer (simple tiles)
townMap:createCollisionBodies("Collision_Main")

-- Create Box2D chain shapes from polygon objects
townMap:createCollisionBodiesFromLayer("Objects_Collision")
```

### Animation Callbacks
```lua
-- Trigger on specific animation frames
townMap:onAnimationFrame("water_tile", 3, function(x, y)
    Audio.playEvent("water_splash", x, y)
end)
```

### Debugging
```lua
-- Memory usage inspection
local usage = TileMap.getMemoryUsage(townMap)
-- Returns: { vertices = 24MB, textures = 60MB, chunks = 8MB, total = 92MB }
```

---

## 6. Scene Integration

### Transition System
Tiled Object Layers define exit zones that trigger scene transitions:

```lua
-- Register map with scene system
Scenes.register("PelikanTown", function()
    local map = TileMap.load("content/maps/town.tmj")
    
    -- Spawn entities from object layers
    for _, obj in ipairs(map:getObjects("Objects_NPCs")) do
        NPCManager.spawn(obj)
    end
    
    -- Setup exit triggers
    for _, exit in ipairs(map:getObjects("Objects_Exits")) do
        TriggerSystem.create(exit.x, exit.y, exit.width, exit.height, function(entity)
            if entity == Player then
                Scenes.transition(exit.properties.destination, {
                    spawnPoint = exit.properties.spawn_id
                })
            end
        end)
    end
    
    return map
end)
```

### Spawn Points
When entering a map, spawn points determine player position:

```lua
function onEnterScene(map, params)
    local spawnPoint = map:getObject(params.spawnPoint or "DefaultSpawn")
    if spawnPoint then
        Player:setPosition(spawnPoint.x, spawnPoint.y)
    end
end
```

---

## 7. Performance Goals
*   **Memory**: Support maps up to 500x500 tiles with sub-100MB footprint.
*   **Frame Time**: Render a complete screen of 4 layers in < 0.5ms on targeted hardware.
*   **Loading**: Asynchronous loading support to prevent frame spikes during scene transitions.
*   **Chunk Updates**: Dirty rectangle tracking for minimal GPU buffer updates.
*   **Instancing**: Repeated tile patterns use instanced rendering where beneficial.

---

## 8. Future Considerations
*   **Infinite/Streaming Maps**: Chunk-based streaming for large exploration areas.
*   **Parallax Layers**: Background layers with different scroll rates for depth.
*   **Autotile Runtime Support**: Dynamic terrain transitions (though Tiled handles this at design time).
*   **Tile Animation Speed Control**: Per-tile animation speed modifiers.
