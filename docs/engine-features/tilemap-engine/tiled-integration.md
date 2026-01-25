# Tiled Integration Guidelines

This document describes the workflow and conventions for creating maps in Tiled Map Editor for use with the Magic Hands Engine tilemap system.

---

## 1. Project Setup

### Recommended Tiled Settings
- **Tile Size**: 32x32 for outdoor areas, 16x16 for detailed interiors
- **Map Format**: JSON (.tmj)
- **Tileset Format**: JSON (.tsj) — embed or external
- **Layer Data Encoding**: `zstd` (preferred) or `zlib` for compression

### File Organization
```
content/
├── maps/
│   ├── town.tmj           # Town map
│   ├── farm.tmj           # Farm area
│   ├── house_interior.tmj # Interior map
│   └── tilesets/
│       ├── terrain.tsj    # Shared terrain tileset
│       ├── buildings.tsj  # Town buildings
│       └── interior.tsj   # Indoor furniture/walls
├── images/
│   ├── terrain_atlas.png  # Tileset images
│   ├── buildings_atlas.png
│   └── interior_atlas.png
```

---

## 2. Layer Naming Conventions

The engine uses layer name prefixes to determine rendering behavior:

| Prefix | Behavior | Example |
|--------|----------|---------|
| `Ground_*` | Static, rendered first, no sorting | `Ground_Base`, `Ground_Water` |
| `Fringe_*` | Y-sorted with entities | `Fringe_Trees`, `Fringe_Fences` |
| `Overhang_*` | Always on top of everything | `Overhang_Roofs`, `Overhang_Canopy` |
| `Collision_*` | Invisible, creates Box2D bodies | `Collision_Main`, `Collision_Water` |
| `Objects_*` | Object layer, not rendered | `Objects_NPCs`, `Objects_Exits` |

### Standard Layer Stack (Bottom to Top)
1. `Ground_Base` — Grass, dirt, paths
2. `Ground_Water` — Water tiles
3. `Fringe_Props` — Small objects (flowers, signs)
4. `Fringe_Trees` — Trees, large plants
5. `Fringe_Buildings` — Building fronts
6. `Overhang_Roofs` — Rooftops, awnings
7. `Collision_Main` — Walkability collision
8. `Objects_NPCs` — NPC spawn points
9. `Objects_Exits` — Scene transition zones

---

## 3. Object Layer Guidelines

### Common Object Types

#### NPCs
```
Type: NPC
Properties:
  - dialogue_id (string): Key for dialogue system
  - schedule (string): "daily", "shop_hours", etc.
  - facing (string): "up", "down", "left", "right"
```

#### Exits / Scene Transitions
```
Type: Exit
Properties:
  - destination (string): Scene name (e.g., "Farm", "House_Interior")
  - spawn_id (string): Name of spawn point object in destination
```

#### Spawn Points
```
Type: SpawnPoint
Name: Used as unique identifier (e.g., "DefaultSpawn", "FromTown")
```

#### Doors
```
Type: Door
Properties:
  - locked (bool): Requires key
  - key_id (string): Which key unlocks it
  - destination (string): Where door leads
```

#### Chests / Containers
```
Type: Chest
Properties:
  - loot_table (string): ID for loot generation
  - respawns (bool): Whether contents regenerate
```

#### Triggers
```
Type: Trigger
Properties:
  - event (string): Event name to fire
  - once (bool): Only trigger once
```

---

## 4. Tile Properties

Set these on individual tiles in the tileset to define behavior:

### Terrain Properties
| Property | Type | Description |
|----------|------|-------------|
| `is_farmable` | bool | Can be tilled/planted |
| `is_water` | bool | Treated as water for fishing |
| `step_sound` | string | Footstep sound ID ("grass", "wood", "stone") |
| `movement_speed` | float | Movement modifier (1.0 = normal, 0.5 = slow) |

### Visual Properties
| Property | Type | Description |
|----------|------|-------------|
| `particle_emitter` | string | Spawn particle effect ("water_splash", "fireflies") |
| `animation_sound` | string | Sound to play during animation |
| `light_source` | bool | Emits light for lighting system |
| `light_radius` | int | Radius if light_source is true |
| `light_color` | string | Hex color (e.g., "#FFAA00") |

### Collision Properties
| Property | Type | Description |
|----------|------|-------------|
| `collision` | string | "solid", "trigger", "water" |

---

## 5. Map Properties

Set these on the map itself (Map → Map Properties in Tiled):

| Property | Type | Description |
|----------|------|-------------|
| `music_track` | string | Background music event ID |
| `ambient_sound` | string | Ambient sound loop |
| `forced_time` | string | Override time ("day", "night", "dawn") |
| `ambient_light` | string | Hex color for ambient lighting |
| `weather` | string | Weather type ("none", "rain", "snow") |
| `indoor` | bool | Is this an interior map? |
| `display_name` | string | Shown when entering area |

---

## 6. Collision Setup

### Simple Tile Collision
For grid-aligned collision, use a dedicated tile layer:
1. Create layer named `Collision_Main`
2. Paint collision areas with any tile (will be invisible)
3. Engine creates Box2D bodies from non-empty tiles

### Complex Polygon Collision
For irregular shapes (buildings, cliffs):
1. Create Object Layer named `Objects_Collision`
2. Draw polygons/rectangles around collision areas
3. Engine creates Box2D chain shapes from polygons

### Water Collision (Special)
Water may be walkable but triggers different behavior:
1. Use `Collision_Water` layer with `collision: "water"` property
2. Engine creates sensor bodies (detect but don't block)

---

## 7. Animation Setup

Tiled supports tile animations natively:
1. Select a tile in tileset
2. Open Tile Animation Editor
3. Add frames with duration (ms)

The engine will:
- Automatically animate these tiles
- Support optional Lua callbacks on specific frames
- Sync animations across all instances of a tile

---

## 8. Best Practices

### Performance
- **Limit fringe layers**: Y-sorted layers are slower than static
- **Combine ground layers**: If not animating, merge into single layer
- **Use tile animations sparingly**: Each animated tile is a separate update
- **Prefer external tilesets**: Shared across maps, better caching

### Organization
- **Consistent naming**: Use the same layer names across all maps
- **Document custom properties**: Keep a properties reference document
- **Use Tiled templates**: For common objects like NPCs, doors

### Debugging
- **Collision layer color**: Use distinct colors for easy visibility in Tiled
- **Object labels**: Enable object names in Tiled for clarity
- **Test spawn points**: Verify all exits have matching spawn points

---

## 9. Example Map Structure

### Town Map (town.tmj)
```
Layers:
├── Ground_Base         [Tile Layer]
├── Ground_Paths        [Tile Layer]
├── Ground_Water        [Tile Layer]
├── Fringe_Fences       [Tile Layer]
├── Fringe_Trees        [Tile Layer]
├── Fringe_Buildings    [Tile Layer]
├── Overhang_Roofs      [Tile Layer]
├── Collision_Main      [Tile Layer]
├── Objects_NPCs        [Object Layer]
│   ├── Mayor (NPC)
│   ├── Blacksmith (NPC)
│   └── Merchant (NPC)
├── Objects_Exits       [Object Layer]
│   ├── ToFarm (Exit) → destination: "Farm", spawn_id: "FromTown"
│   ├── ToBeach (Exit) → destination: "Beach", spawn_id: "FromTown"
│   └── BlacksmithDoor (Exit) → destination: "Blacksmith_Interior"
└── Objects_Spawns      [Object Layer]
    ├── DefaultSpawn (SpawnPoint)
    ├── FromFarm (SpawnPoint)
    └── FromBeach (SpawnPoint)

Map Properties:
├── music_track: "town_theme"
├── ambient_sound: "town_ambience"
├── display_name: "Pelikan Town"
└── weather: "none"
```

---

## 10. Lua Loading Example

```lua
-- Load town map
local townMap = TileMap.load("content/maps/town.tmj", {
    assetGroup = "town"
})

-- Play map music
local music = townMap:getMapProperty("music_track")
if music then
    Audio.playMusic(music)
end

-- Show area name
local areaName = townMap:getMapProperty("display_name")
if areaName then
    UI.showAreaTitle(areaName)
end

-- Spawn NPCs
for _, obj in ipairs(townMap:getObjects("Objects_NPCs")) do
    NPCManager.spawn({
        name = obj.name,
        x = obj.x,
        y = obj.y,
        dialogue = obj.properties.dialogue_id,
        schedule = obj.properties.schedule,
        facing = obj.properties.facing or "down"
    })
end

-- Setup exits
for _, obj in ipairs(townMap:getObjects("Objects_Exits")) do
    TriggerSystem.createZone(obj.x, obj.y, obj.width, obj.height, function(entity)
        if entity.isPlayer then
            Scenes.transition(obj.properties.destination, {
                spawnPoint = obj.properties.spawn_id
            })
        end
    end)
end

-- Create collision bodies
townMap:createCollisionBodies("Collision_Main")
```

---

## 11. Checklist: Before Export

- [ ] All layers use correct naming prefixes
- [ ] All exits have `destination` and `spawn_id` properties
- [ ] Destination maps have matching spawn point objects
- [ ] Collision layer covers all impassable areas
- [ ] Map properties set (music, ambient, display_name)
- [ ] NPCs have `dialogue_id` and `schedule` properties
- [ ] Tileset images are in `content/images/`
- [ ] Export format is JSON with zstd compression
