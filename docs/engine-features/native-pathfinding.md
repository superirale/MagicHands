# Feature Specification: Native Pathfinding (A*)

> **Status: ✅ IMPLEMENTED** - Core A* algorithm with node pooling, path smoothing, and Lua bindings.

## Overview
A high-performance C++ implementation of the A* (A-Star) pathfinding algorithm, designed specifically for tile-based NPC navigation. This system integrates directly with the `TileMap` engine to provide efficient path calculation for entities within the game world.

## Requirements
1.  **High Performance**: Path calculation must be fast enough to run multiple queries per frame for various NPCs without significantly impacting frame rate.
    - Target: <1ms for typical paths (20-50 tiles) on target hardware.
    - Support for 10+ concurrent pathfinding requests per frame.
2.  **TileMap Integration**: The system must use the existing `TileMap` data and tile properties to determine traversal costs and obstacles.
    - Read tile properties (e.g., `"walkable"`, `"cost"`, `"terrain_type"`) from designated navigation layers.
    - Support multiple navigation layers for different entity types (e.g., ground units vs. flying units).
3.  **Lua Accessibility**: Full exposure to Lua, allowing scripts to request paths for NPCs and handle navigation logic.
    - Simple API for common use cases.
    - Advanced options for custom cost functions and constraints.
4.  **Path Smoothing**: Optional path smoothing to avoid "jagged" diagonal movements.
    - String-pulling algorithm for removing unnecessary waypoints.
    - Configurable smoothing level.
5.  **Dynamic Updates**: Ability to handle changes in the environment by invalidating affected paths.
    - Efficient dirty region tracking when tiles change.
    - Optional path repair for minor changes vs. full recalculation.

## Architecture

### Grid Navigation
The pathfinder operates on a grid derived from the `TileMap`. Each cell in the grid corresponds to a tile.

- **Traversability**: Determined by checking tile properties in a designated navigation layer.
    - Default: Tiles without a `"walkable"` property or with `"walkable" = false` are obstacles.
    - Support for custom traversability predicates via Lua callbacks.
- **Cost System**: Tile-based cost system where different terrain types have different traversal weights.
    - Default cost: 1.0 for all walkable tiles.
    - Custom costs: Read from tile property `"cost"` (e.g., `"cost" = 2.0` for mud, `"cost" = 0.5` for roads).
    - Diagonal movement cost: 1.414 (√2) when diagonal movement is enabled.
- **Multi-Layer Support**: Different navigation layers for different entity types.
    - Example: `"nav_ground"` for walking NPCs, `"nav_water"` for boats, `"nav_air"` for flying creatures.

### A* Algorithm Details
- **Open/Closed Sets**: 
    - Open set: Binary min-heap (priority queue) for $O(\log n)$ insertion and extraction.
    - Closed set: Hash set for $O(1)$ membership testing.
- **Heuristic Functions**: 
    - **Manhattan distance** for 4-way movement: `h(n) = |dx| + |dy|`
    - **Octile distance** for 8-way movement: `h(n) = max(|dx|, |dy|) + (√2 - 1) * min(|dx|, |dy|)`
    - Heuristic weight: Configurable multiplier (default 1.0) for trading optimality vs. speed.
- **Node Pooling**: Pre-allocated node pool to eliminate per-search allocations.
    - Pool size: Configurable, default 4096 nodes.
    - Automatic pool expansion if needed (with warning).
- **Search Limits**: 
    - **Max steps**: Default 1000 nodes expanded, configurable per request.
    - **Timeout**: Optional time limit (e.g., 5ms) to prevent frame stalls.
    - Early termination returns partial path or empty result based on configuration.
- **Tie-Breaking**: When f-scores are equal, prefer nodes closer to the goal to reduce exploration.

## C++ API

### `Pathfinder` Class
```cpp
class Pathfinder {
public:
    struct Point { 
        int x, y; 
        
        bool operator==(const Point& other) const {
            return x == other.x && y == other.y;
        }
    };
    
    typedef std::vector<Point> Path;

    /**
     * Construct a pathfinder for a specific tilemap.
     * Caches layer indices for performance.
     */
    explicit Pathfinder(const TileMap& map);

    struct PathRequest {
        Point start;
        Point end;
        std::string navigationLayer = "nav_ground";
        bool allowDiagonal = false;
        int maxSteps = 1000;
        float maxTimeMs = 5.0f;  // Max time before early termination
        bool smoothPath = false;  // Apply string-pulling smoothing
        
        // Optional: Custom cost function (nullptr = use tile properties)
        std::function<float(int x, int y)> customCostFn = nullptr;
    };
    
    struct PathResult {
        Path path;              // Empty if no path found
        bool found = false;     // True if complete path found
        bool partial = false;   // True if timeout/maxSteps hit
        int nodesExpanded = 0;  // For debugging/profiling
        float timeMs = 0.0f;    // Time taken
    };

    /**
     * Finds a path from start to end.
     * @return PathResult with path and metadata.
     */
    PathResult findPath(const PathRequest& request);

    /**
     * Checks if a specific tile is walkable.
     * Caches layer index for repeated calls.
     */
    bool isWalkable(int x, int y, const std::string& layer) const;
    
    /**
     * Get traversal cost for a tile.
     * @return Cost multiplier, or -1.0 if unwalkable.
     */
    float getCost(int x, int y, const std::string& layer) const;
    
    /**
     * Invalidate cached paths in a rectangular region.
     * Call when tiles are modified.
     */
    void invalidateRegion(int x, int y, int width, int height);
    
    /**
     * Clear all internal caches.
     */
    void clearCache();

private:
    const TileMap& m_Map;
    
    // Cached layer indices for performance
    mutable std::unordered_map<std::string, int> m_LayerCache;
    
    // Node pool for allocation reuse
    struct Node;
    std::vector<Node> m_NodePool;
    size_t m_PoolIndex = 0;
    
    // Path smoothing implementation
    Path smoothPath(const Path& rawPath) const;
    
    // A* internals
    PathResult findPathInternal(const PathRequest& request);
};
```

## Lua API

### Basic Usage
```lua
-- Simple pathfinding request
-- Returns: { path = {{x=1, y=2}, ...}, found = true, nodesExpanded = 42 }
local result = Pathfinding.find({
    start = {x = playerX, y = playerY}, 
    target = {x = targetX, y = targetY},
    diagonal = true,
    layer = "nav_ground",
    smooth = true
})

if result.found then
    npc:followPath(result.path)
else
    print("No path found! Expanded " .. result.nodesExpanded .. " nodes")
end
```

### Advanced Options
```lua
-- Advanced pathfinding with custom costs
local result = Pathfinding.find({
    start = {x = startX, y = startY},
    target = {x = endX, y = endY},
    diagonal = false,
    layer = "nav_ground",
    maxSteps = 500,
    maxTime = 3.0,  -- milliseconds
    smooth = false,
    
    -- Optional: Custom cost function
    costFunction = function(x, y)
        -- Avoid areas near enemies
        if isNearEnemy(x, y) then
            return 10.0  -- High cost
        end
        return 1.0  -- Normal cost
    end
})
```

### Utility Functions
```lua
-- Check if a tile is walkable
if Pathfinding.isWalkable(x, y, "nav_ground") then
    spawnNPC(x, y)
end

-- Get traversal cost for a tile
local cost = Pathfinding.getCost(x, y, "nav_ground")
if cost > 0 then
    print("Tile cost: " .. cost)
else
    print("Tile is unwalkable")
end

-- Invalidate paths when environment changes
function onDoorOpened(x, y)
    Pathfinding.invalidateRegion(x - 5, y - 5, 10, 10)
end
```

### Integration Example
```lua
-- NPC behavior using pathfinding
function NPC:moveToTarget(targetX, targetY)
    local result = Pathfinding.find({
        start = {x = self.x, y = self.y},
        target = {x = targetX, y = targetY},
        diagonal = true,
        layer = "nav_ground",
        smooth = true,
        maxSteps = 200
    })
    
    if result.found then
        self.currentPath = result.path
        self.pathIndex = 1
    elseif result.partial then
        -- Got partial path, use it anyway
        self.currentPath = result.path
        self.pathIndex = 1
        print("Warning: Using partial path")
    else
        -- No path at all, try direct movement or give up
        self:onPathfindingFailed()
    end
end

function NPC:update(dt)
    if self.currentPath and self.pathIndex <= #self.currentPath then
        local waypoint = self.currentPath[self.pathIndex]
        
        -- Move toward waypoint
        if self:moveTo(waypoint.x, waypoint.y, dt) then
            self.pathIndex = self.pathIndex + 1
        end
    end
end
```

## Technical Implementation Details

### Memory Management
- **Node Pool**: Pre-allocated pool of A* nodes (default 4096) to eliminate per-search allocations.
- **Path Storage**: Paths stored as `std::vector<Point>` with small-vector optimization for short paths.
- **Layer Cache**: Hash map caching layer name → layer index lookups.

### Optimization Strategies
- **Early Termination**: 
    - Stop search if max steps or time limit exceeded.
    - Return partial path to closest node if configured.
- **Jump Point Search**: (Future) For uniform-cost grids, use JPS for significant speedup.
- **Hierarchical Pathfinding**: (Future) For very large maps (>1000x1000), use hierarchical A* with pre-computed clusters.
- **Path Caching**: (Future) Cache recent path results with invalidation on tile changes.
- **Spatial Hashing**: (Future) For dynamic obstacles (moving NPCs), use spatial hash for fast collision checks.

### Performance Profiling
- **Metrics Tracking**: Each `PathResult` includes:
    - `nodesExpanded`: Number of nodes explored.
    - `timeMs`: Time taken in milliseconds.
- **Debug Visualization**: (Future) Render explored nodes and final path for debugging.

---

## Performance Goals
- **Typical Path (20-50 tiles)**: < 1ms on target hardware.
- **Long Path (100-200 tiles)**: < 3ms on target hardware.
- **Worst Case (unreachable target)**: < 5ms with maxSteps limit.
- **Concurrent Requests**: Support 10+ pathfinding requests per frame without frame drops.
- **Memory Footprint**: < 1MB for pathfinder state + node pool.

---

## Edge Cases & Error Handling

### Invalid Inputs
- **Out-of-bounds coordinates**: Return empty path with `found = false`.
- **Start == End**: Return single-point path immediately.
- **Start or End unwalkable**: Return empty path with `found = false`.

### Unreachable Targets
- **No path exists**: Return empty path after exhausting search or hitting limits.
- **Partial paths**: If `maxSteps` or `maxTime` exceeded, optionally return path to closest explored node.

### Dynamic Environment
- **Tile changes during pathfinding**: Not detected mid-search (acceptable for performance).
- **Tile changes between searches**: Use `invalidateRegion()` to clear affected cached data.

### Large Maps
- **Maps > 1000x1000**: May require hierarchical pathfinding (future enhancement).
- **Current approach**: Rely on `maxSteps` limit to prevent excessive computation.

---

## Integration with Magic Hands

### Ownership & Lifecycle
- **Per-Scene Pathfinder**: Each `Scene` owns a `Pathfinder` instance tied to its `TileMap`.
- **Initialization**: Created when scene loads, destroyed when scene unloads.
- **Lua Binding**: Exposed as `Pathfinding` global in Lua (delegates to current scene's pathfinder).

### TileMap Integration
- **Tile Property Reading**: Pathfinder reads `"walkable"` and `"cost"` properties from tiles.
- **Layer Support**: Supports multiple navigation layers (e.g., `"nav_ground"`, `"nav_water"`, `"nav_air"`).
- **Change Notifications**: When `TileMap:setTileId()` is called, automatically invalidate affected pathfinding regions.

### Scene Integration Example
```lua
-- In a scene's onInit
function GameScene:onInit()
    self.map = TileMap.load("content/maps/world.tmj")
    
    -- Pathfinding automatically uses this scene's map
    -- No explicit setup needed
end

function GameScene:update(dt)
    -- NPCs can request paths
    for _, npc in ipairs(self.npcs) do
        if npc:needsNewPath() then
            local result = Pathfinding.find({
                start = {x = npc.x, y = npc.y},
                target = {x = npc.targetX, y = npc.targetY},
                diagonal = true,
                layer = "nav_ground"
            })
            
            if result.found then
                npc:setPath(result.path)
            end
        end
    end
end
```

### Physics Integration
- **Static Obstacles**: Read from TileMap collision layers.
- **Dynamic Obstacles**: (Future) Query `PhysicsSystem` for dynamic bodies to mark tiles as temporarily blocked.

---

## Future Enhancements

### Phase 2: Advanced Features
- **Jump Point Search (JPS)**: For uniform-cost grids, significant performance improvement.
- **Hierarchical Pathfinding**: For maps > 1000x1000, pre-compute navigation clusters.
- **Flow Fields**: For many agents moving to same target (e.g., RTS-style movement).
- **Path Caching**: Cache and reuse recent path results with smart invalidation.

### Phase 3: Dynamic Obstacles
- **Moving Entities**: Mark tiles occupied by NPCs/players as temporarily unwalkable.
- **Path Repair**: When path becomes blocked, attempt local repair before full recalculation.
- **Steering Behaviors**: Combine pathfinding with local steering for smooth navigation around dynamic obstacles.

### Phase 4: Advanced AI
- **Tactical Pathfinding**: Prefer cover, avoid danger zones, flank enemies.
- **Group Movement**: Coordinate paths for multiple units to avoid congestion.
- **Asynchronous Pathfinding**: Offload long-distance paths to background thread.

---

## Testing & Validation

### Unit Tests
- **Basic paths**: Straight lines, L-shapes, diagonal movement.
- **Obstacles**: Paths around walls, mazes.
- **Edge cases**: Unreachable targets, out-of-bounds, start == end.
- **Performance**: Benchmark typical and worst-case scenarios.

### Integration Tests
- **TileMap integration**: Verify correct reading of tile properties.
- **Multi-layer**: Test different navigation layers for different entity types.
- **Dynamic updates**: Verify `invalidateRegion()` works correctly.

### Visual Debugging
- **Path visualization**: Render computed paths in-game for debugging.
- **Explored nodes**: Show which tiles were examined during search.
- **Cost overlay**: Display traversal costs as a heatmap.
