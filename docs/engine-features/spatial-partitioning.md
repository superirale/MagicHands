# Feature Specification: Spatial Partitioning (Quadtree)

> **Status: IMPLEMENTED**

## Overview
A high-performance, dynamic Quadtree implementation for efficient spatial queries of non-physics game objects. This system enables fast proximity searches, area queries, and render culling without requiring full physics simulation.

## Motivation
Currently, spatial queries require iterating through all objects ($O(N)$). For a game with 1,000+ entities (NPCs, items, particles), querying "all entities within 100 pixels" becomes a performance bottleneck. A Quadtree reduces localized queries to $O(\log N)$ average case.

## Use Cases

> **The key insight**: Anything that asks *"what objects are near point X?"* benefits from spatial partitioning. The Quadtree turns O(N) brute-force searches into O(log N + K) queries, where K is the number of results.

### 1. **AI Perception & Aggro**
Instead of checking distance to ALL enemies every frame (O(N)), query only nearby candidates:
```lua
-- Without spatial partitioning: 100 enemies × 100 targets = 10,000 checks/frame
-- With Quadtree: typically 5-20 candidates checked

local nearbyTargets = spatial.queryRadius(aiTree, enemy.x, enemy.y, 300)
for _, targetId in ipairs(nearbyTargets) do
    if canSee(enemy, entities[targetId]) then
        enemy:setTarget(targetId)
        break
    end
end
```

### 2. **Click-to-Interact / Pickup Systems**
Find what the player clicked on or can interact with:
```lua
-- Find nearest interactable object to cursor
local nearestId = spatial.queryNearest(worldTree, mouseWorldX, mouseWorldY, 50)
if nearestId ~= -1 then
    local obj = worldObjects[nearestId]
    obj:interact(player)
end

-- Auto-pickup items near player
local nearbyItems = spatial.queryRadius(itemTree, player.x, player.y, 32)
for _, itemId in ipairs(nearbyItems) do
    player:pickup(items[itemId])
end
```

### 3. **Render Culling for Entities**
Only draw entities visible on screen, skipping hundreds of offscreen objects:
```lua
local visibleIds = spatial.query(entityTree, camX, camY, screenW, screenH)
for _, id in ipairs(visibleIds) do
    entities[id]:draw()  -- Skip the other 500+ entities offscreen
end
```

### 4. **Area-of-Effect (AoE) Damage/Healing**
Efficiently find all entities affected by explosions, spells, or auras:
```lua
-- Fireball explosion
local affected = spatial.queryRadius(entityTree, explosion.x, explosion.y, blastRadius)
for _, id in ipairs(affected) do
    entities[id]:takeDamage(50)
end

-- Healing aura
local allies = spatial.queryRadius(allyTree, healer.x, healer.y, healRadius)
for _, id in ipairs(allies) do
    allies[id]:heal(10 * dt)
end
```

### 5. **Goat/Creature Herding (Magic Hands-specific)**
Your game has a goat herding system. Spatial queries are perfect for:
```lua
-- Find nearby goats to form herds
local nearbyGoats = spatial.queryRadius(goatTree, leader.x, leader.y, 200)
for _, goatId in ipairs(nearbyGoats) do
    goats[goatId]:followLeader(leader)
end

-- Check if goats are within grazing range of grass
local grassInRange = spatial.queryRadius(grassTree, goat.x, goat.y, 50)
if #grassInRange > 0 then
    goat:graze(grass[grassInRange[1]])
end

-- Detect predators within awareness radius
local threats = spatial.queryRadius(predatorTree, goat.x, goat.y, 150)
if #threats > 0 then
    goat:flee(predators[threats[1]])
end
```

### 6. **Trigger Zones / Event Areas**
Detect when player enters specific regions:
```lua
-- Check if player entered any trigger zone
local triggersHit = spatial.query(triggerTree, player.x, player.y, 1, 1)
for _, triggerId in ipairs(triggersHit) do
    triggers[triggerId]:activate(player)
end
```


---

## Architecture

### Quadtree Algorithm

A Quadtree recursively subdivides 2D space into four quadrants (NW, NE, SW, SE). Objects are stored in the smallest node that fully contains them.

#### Node Structure
```cpp
struct QuadtreeNode {
    Rect bounds;                              // Spatial region this node covers
    std::vector<int> objectIds;               // Objects in THIS node
    std::array<std::unique_ptr<QuadtreeNode>, 4> children;  // NW, NE, SW, SE
    int level;                                // Depth in tree (root = 0)
};
```

#### Subdivision Rules
- **Trigger**: Node splits when `objectIds.size() > maxObjects` AND `level < maxLevels`
- **Process**:
  1. Create 4 child nodes, each 1/4 the size of the parent
  2. Attempt to redistribute objects to children
  3. Objects that **cross child boundaries** remain in the parent node
  4. Clear parent's `objectIds` only if all objects moved to children

#### Why Objects Can Stay in Parent Nodes
Large objects (e.g., 100x100 sprite) may span multiple quadrants and cannot be cleanly assigned to a single child. These remain in the parent, ensuring:
- **Correctness**: Queries always find the object
- **Trade-off**: Parent-level objects are included in ALL queries to that region

---

## Algorithm Details

### Insertion
```cpp
void insert(int id, Rect bounds) {
    1. Start at root node
    2. If bounds fit entirely within a child quadrant:
       - Recurse into that child
    3. Else (crosses boundaries OR node is leaf):
       - Store id in current node's objectIds
    4. After insertion, check if node needs subdivision
}
```

**Complexity**: $O(\log N)$ average, $O(D)$ worst case (D = max depth)

### Removal
```cpp
void remove(int id) {
    1. Look up bounds from m_ObjectBounds map
    2. Traverse tree to find containing node
    3. Remove id from node's objectIds
    4. (Optional) Collapse empty parent nodes
}
```

**Complexity**: $O(\log N)$ average

### Update (Optimized Remove + Insert)
```cpp
void update(int id, Rect newBounds) {
    1. Look up old bounds from m_ObjectBounds map
    2. If old and new bounds are in same leaf node:
       - Just update m_ObjectBounds (no tree traversal)
    3. Else:
       - Remove from old location
       - Insert at new location
}
```

**Optimization**: Avoids tree rebuild for small movements.

### Query
```cpp
void query(Rect area, std::vector<int>& results) {
    1. Start at root
    2. If area intersects node bounds:
       - Add all objectIds in this node to results
       - Recurse into children whose bounds intersect area
    3. Return unique results
}
```

**Complexity**: $O(\log N + K)$ where K = number of results

---

## C++ API

### `Quadtree` Class
```cpp
class Quadtree {
public:
    /**
     * Construct a quadtree covering the specified world area.
     * @param bounds World space covered by root node
     * @param maxObjects Max objects per node before subdivision
     * @param maxLevels Max tree depth (root = 0)
     */
    Quadtree(Rect bounds, int maxObjects = 10, int maxLevels = 5);
    
    // --- Object Management ---
    
    /**
     * Insert an object into the tree.
     * @param id Unique object identifier
     * @param bounds Object's axis-aligned bounding box
     */
    void insert(int id, Rect bounds);
    
    /**
     * Insert a point object (e.g., particle, pickup).
     * Internally creates a zero-size Rect.
     */
    void insertPoint(int id, float x, float y);
    
    /**
     * Remove an object from the tree.
     * Looks up bounds internally via m_ObjectBounds.
     */
    void remove(int id);
    
    /**
     * Update an object's position/size.
     * Optimized to avoid removal if still in same node.
     */
    void update(int id, Rect newBounds);
    
    // --- Queries ---
    
    /**
     * Find all objects intersecting a rectangular area.
     * @param area Query rectangle
     * @param results Output vector (cleared before filling)
     */
    void query(Rect area, std::vector<int>& results);
    
    /**
     * Find all objects within radius of a point.
     */
    void queryRadius(float x, float y, float radius, std::vector<int>& results);
    
    /**
     * Find the single nearest object to a point (within maxRadius).
     * @return Object ID, or -1 if none found
     */
    int queryNearest(float x, float y, float maxRadius = 1000.0f);
    
    // --- Utilities ---
    
    /** Remove all objects from tree. */
    void clear();
    
    /** Get current object count. */
    int size() const { return m_ObjectBounds.size(); }
    
    // --- Debug ---
    
    struct Stats {
        int nodeCount;
        int maxDepth;
        int totalObjects;
        std::array<int, 10> objectsPerLevel;  // Distribution
    };
    Stats getStats() const;

private:
    std::unique_ptr<QuadtreeNode> m_Root;
    std::unordered_map<int, Rect> m_ObjectBounds;  // ID -> bounds cache
    int m_MaxObjects;
    int m_MaxLevels;
};
```

---

## Lua API

### Module: `spatial`

```lua
-- Create a quadtree
local tree = spatial.create(x, y, w, h, maxObjects, maxLevels)
-- tree: integer handle

-- Insert objects
spatial.insert(tree, entityId, x, y, w, h)
spatial.insertPoint(tree, itemId, x, y)  -- For point objects

-- Remove objects
spatial.remove(tree, entityId)

-- Update object position
spatial.update(tree, entityId, newX, newY, newW, newH)

-- Query
local ids = spatial.query(tree, x, y, w, h)  -- Returns table of IDs
local nearbyIds = spatial.queryRadius(tree, x, y, radius)
local closestId = spatial.queryNearest(tree, x, y, maxRadius)

-- Cleanup
spatial.clear(tree)       -- Clear all objects
spatial.destroy(tree)     -- Free memory (handle becomes invalid)

-- Debug
local stats = spatial.stats(tree)
-- stats = {nodeCount, maxDepth, totalObjects, objectsPerLevel}
spatial.drawDebug(tree)   -- Render quadtree boundaries (dev only)
```

### Example Usage
```lua
-- Setup (once per scene)
local worldTree = spatial.create(0, 0, 3200, 1280, 10, 5)

-- Insert all entities
for id, entity in pairs(entities) do
    spatial.insert(worldTree, id, entity.x, entity.y, entity.w, entity.h)
end

-- Update loop
function update(dt)
    -- Update entity positions
    for id, entity in pairs(entities) do
        entity:move(dt)
        spatial.update(worldTree, id, entity.x, entity.y, entity.w, entity.h)
    end
    
    -- AI perception query
    local nearbyEnemies = spatial.queryRadius(worldTree, player.x, player.y, 200)
    for _, enemyId in ipairs(nearbyEnemies) do
        -- React to nearby enemies
    end
end

-- Render culling
function draw()
    local visibleIds = spatial.query(worldTree, cameraX, cameraY, screenW, screenH)
    for _, id in ipairs(visibleIds) do
        entities[id]:draw()
    end
end
```

---

## Performance Characteristics

### Time Complexity
| Operation | Average | Worst Case | Notes |
|-----------|---------|------------|-------|
| Insert    | $O(\log N)$ | $O(D)$ | D = max depth |
| Remove    | $O(\log N)$ | $O(D)$ | Requires tree traversal |
| Update    | $O(1)$ - $O(\log N)$ | $O(D)$ | Fast if same node |
| Query (small area) | $O(\log N + K)$ | $O(N)$ | K = results |
| Query (large area) | $O(N)$ | $O(N)$ | Degrades for large queries |

### Space Complexity
- **Per Object**: `~32 bytes` (8 bytes ID + 16 bytes Rect + 8 bytes map overhead)
- **Node Overhead**: `~128 bytes per node` (bounds + vector + 4 pointers)
- **Total for 10k objects**: ~1MB (acceptable)

### Performance Targets
- **Insertion**: < 1μs per object (10,000 objects in ~10ms)
- **Query (viewport, ~10% of world)**: < 0.5ms for 10,000 objects
- **Update (small movement)**: < 0.1μs (cached same-node case)

---

## Design Decisions

### 1. **Why Quadtree?**
**Alternatives Considered**:
- **Spatial Hash**: Simpler but poor for non-uniform distributions and range queries
- **R-Tree**: Better for many overlapping AABBs, but complex and slower inserts
- **Loose Quadtree**: Reduces update cost but increases memory and query cost

**Chosen**: Standard Quadtree because:
- Balanced performance for both queries and updates
- Well-suited for 2D games with varied object sizes
- Simple to implement and debug

### 2. **Internal Bounds Tracking**
By storing `m_ObjectBounds`, we simplify the API:
- `remove(id)` doesn't require passing bounds
- `update(id, newBounds)` doesn't require old bounds
- Small memory cost (~16 bytes per object) for much cleaner API

### 3. **Point Objects**
Many game objects are effectively points (particles, pickups). Supporting `insertPoint(id, x, y)` avoids forcing users to create fake Rects.

### 4. **No Automatic Rebalancing**
Unlike self-balancing trees, Quadtrees don't rebalance after removals. If many objects are removed from one area, empty nodes persist.

**Mitigation**: Provide `clear()` and rebuild from scratch if needed (cheap for < 10k objects).

---

## Thread Safety

- **Read-Only Queries**: Thread-safe (multiple concurrent `query` calls allowed)
- **Writes (`insert/remove/update`)**: NOT thread-safe
- **Mixed Read/Write**: NOT thread-safe

**Use Case**: Query on worker threads, but all modifications on main thread only.

**Future**: Add `std::shared_mutex` for read/write locking if needed.

---

## Integration Points

### 1. **TileMap Render Culling** (Optional)
Currently, `TileMap::draw` uses simple grid culling (lines 123-126). Could use Quadtree for non-tile entities:
```cpp
// In Game scene update:
quadtree.clear();
for (auto& entity : entities) {
    quadtree.insert(entity.id, entity.bounds);
}

// In render:
auto visibleIds = quadtree.query(cameraRect);
for (int id : visibleIds) {
    drawEntity(id);
}
```

### 2. **Pathfinding Dynamic Obstacles**
The `Pathfinder` currently only uses static TileMap collision. Could query Quadtree for dynamic entities:
```cpp
// Before A* search:
auto dynamicObstacles = quadtree.query(pathBounds);
// Mark tiles occupied by dynamicObstacles as non-walkable
```

### 3. **Click-to-Interact**
```lua
function onMouseClick(x, y)
    local clickRadius = 10
    local id = spatial.queryNearest(worldTree, x, y, clickRadius)
    if id then
        interact(id)
    end
end
```

---

## Implementation Notes

### Memory Management
- Use `std::unique_ptr` for child nodes to avoid manual deletion
- Pre-allocate `m_ObjectBounds` hash map with expected capacity
- Node vector pre-allocation: `objectIds.reserve(maxObjects * 2)`

### Edge Cases
- **Empty tree**: Query returns empty vector
- **Object larger than world**: Stored in root, included in ALL queries
- **Duplicate insert**: Overwrite existing entry in `m_ObjectBounds`
- **Remove non-existent ID**: No-op (safe)

### Optimizations (Future)
- **Lazy subdivision**: Only split on 2nd overflow to reduce node count
- **Node pooling**: Reuse node memory instead of `new/delete`
- **SIMD bounds tests**: Vectorize rect intersection checks

---

## Verification Plan

### Automated Tests
1. **Correctness**: Insert 10,000 random rects, query all regions, compare vs brute-force $O(N)$ search
2. **Boundary crossing**: Insert object at quadrant boundaries, verify it's found
3. **Large objects**: Insert object larger than leaf size, verify parent storage
4. **Update optimization**: Move object by 1 pixel, verify no tree rebuild
5. **Performance**: Benchmark 10,000 inserts + 1,000 queries < 20ms total

### Manual Verification
1. **Debug visualization**: Render quadtree boundaries in-game
2. **AI test**: NPC perception queries (should only react to nearby entities)
3. **Render culling**: Verify only on-screen entities are drawn (FPS improvement)

---

## Migration Path

### Phase 1: Core Implementation
- Implement `Quadtree` class in `src/core/SpatialIndex.h/cpp`
- Unit tests for all operations

### Phase 2: Lua Bindings
- Create `src/scripting/SpatialBindings.cpp`
- Register `spatial` module
- Example scene demonstrating usage

### Phase 3: Integration
- Add debug visualization (`spatial.drawDebug`)
- Optional: Integrate with renderer for automatic entity culling
- Optional: Pathfinding dynamic obstacles

---

## Future Enhancements

1. **Loose Quadtree**: Store objects in nodes larger than their actual bounds (reduces updates)
2. **Raycast Queries**: `queryRay(start, end)` for line-of-sight checks
3. **Batch Operations**: `insertBatch(ids[], bounds[])` for initial population
4. **Persistent Trees**: Serialize/deserialize for save games
