#include "pathfinding/Pathfinder.h"
#include "core/Logger.h"
#include "tilemap/TileMap.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <queue>
#include <unordered_set>

// ============================================================================
// Node Pool for Zero-Allocation Searches
// ============================================================================

class Pathfinder::NodePool {
public:
  explicit NodePool(size_t initialSize = 4096) { m_Nodes.resize(initialSize); }

  Node *acquire(const Point &point) {
    if (m_Index >= m_Nodes.size()) {
      // Pool exhausted, expand it
      size_t oldSize = m_Nodes.size();
      m_Nodes.resize(oldSize * 2);
      LOG_WARN("Pathfinding node pool expanded from %zu to %zu", oldSize,
               m_Nodes.size());
    }

    Node *node = &m_Nodes[m_Index++];
    node->reset();
    node->point = point;
    return node;
  }

  void reset() { m_Index = 0; }

  size_t getUsage() const { return m_Index; }

private:
  std::vector<Node> m_Nodes;
  size_t m_Index = 0;
};

// ============================================================================
// Priority Queue Comparator
// ============================================================================

struct NodeComparator {
  bool operator()(const Pathfinder::Node *a, const Pathfinder::Node *b) const {
    // Min-heap: lower f-cost has higher priority
    if (std::abs(a->fCost - b->fCost) < 0.001f) {
      // Tie-breaking: prefer nodes closer to goal (lower h-cost)
      return a->hCost > b->hCost;
    }
    return a->fCost > b->fCost;
  }
};

// ============================================================================
// Hash Function for Point
// ============================================================================

namespace std {
template <> struct hash<Pathfinder::Point> {
  size_t operator()(const Pathfinder::Point &p) const {
    // Use prime multipliers for better collision resistance on grid patterns
    return static_cast<size_t>(p.x * 73856093) ^
           static_cast<size_t>(p.y * 19349663);
  }
};
} // namespace std

// ============================================================================
// Constructor / Destructor
// ============================================================================

Pathfinder::Pathfinder(const TileMap &map)
    : m_Map(map), m_NodePool(std::make_unique<NodePool>()) {}

Pathfinder::~Pathfinder() = default;

// ============================================================================
// Public API
// ============================================================================

Pathfinder::PathResult Pathfinder::findPath(const PathRequest &request) {
  return findPathInternal(request);
}

bool Pathfinder::isWalkable(int x, int y, const std::string &layer) const {
  // Check bounds
  if (x < 0 || y < 0 || x >= m_Map.getWidth() || y >= m_Map.getHeight()) {
    return false;
  }

  int layerIdx = getLayerIndex(layer);
  if (layerIdx < 0) {
    return false;
  }

  // Get tile ID
  int tileId = m_Map.getTileId(x, y, layer);
  if (tileId == 0) {
    // Empty tile is walkable by default
    return true;
  }

  // Check "walkable" property (if not set, assume walkable)
  std::string walkableProp = m_Map.getProperty(x, y, "walkable");
  if (!walkableProp.empty() && walkableProp == "false") {
    return false;
  }

  return true;
}

float Pathfinder::getCost(int x, int y, const std::string &layer) const {
  if (!isWalkable(x, y, layer)) {
    return -1.0f;
  }

  // Check for custom cost property
  std::string costProp = m_Map.getProperty(x, y, "cost");
  if (!costProp.empty()) {
    try {
      return std::stof(costProp);
    } catch (...) {
      // Invalid cost, use default
    }
  }

  return 1.0f; // Default cost
}

void Pathfinder::invalidateRegion(int x, int y, int width, int height) {
  // Future: invalidate cached paths in this region
  // For now, just clear the entire cache
  clearCache();
}

void Pathfinder::clearCache() {
  m_LayerCache.clear();
  m_NodePool->reset();
}

// ============================================================================
// Internal A* Implementation
// ============================================================================

Pathfinder::PathResult
Pathfinder::findPathInternal(const PathRequest &request) {
  auto startTime = std::chrono::high_resolution_clock::now();

  PathResult result;

  // Validate inputs
  if (request.start == request.end) {
    result.path = {request.start};
    result.found = true;
    return result;
  }

  if (!isWalkableInternal(request.start.x, request.start.y, request)) {
    LOG_WARN("Pathfinding: Start position (%d, %d) is not walkable",
             request.start.x, request.start.y);
    return result;
  }

  if (!isWalkableInternal(request.end.x, request.end.y, request)) {
    LOG_WARN("Pathfinding: End position (%d, %d) is not walkable",
             request.end.x, request.end.y);
    return result;
  }

  // Reset node pool
  m_NodePool->reset();

  // Open set (priority queue) and closed set
  std::priority_queue<Node *, std::vector<Node *>, NodeComparator> openSet;
  std::unordered_set<Point> closedSet;
  std::unordered_map<Point, Node *> nodeMap;

  // Create start node
  Node *startNode = m_NodePool->acquire(request.start);
  startNode->gCost = 0.0f;
  startNode->hCost = request.allowDiagonal
                         ? heuristicOctile(request.start, request.end)
                         : heuristicManhattan(request.start, request.end);
  startNode->fCost = startNode->gCost + startNode->hCost;

  openSet.push(startNode);
  nodeMap[request.start] = startNode;

  Node *closestNode = startNode; // For partial paths
  float closestDistance = startNode->hCost;

  // Neighbor offsets (4-way or 8-way)
  const Point neighbors4[] = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}};
  const Point neighbors8[] = {{0, -1},  {1, 0},  {0, 1},  {-1, 0},
                              {-1, -1}, {1, -1}, {-1, 1}, {1, 1}};
  const Point *neighbors = request.allowDiagonal ? neighbors8 : neighbors4;
  const int neighborCount = request.allowDiagonal ? 8 : 4;

  // A* main loop
  while (!openSet.empty()) {
    // Check limits
    result.nodesExpanded++;
    if (result.nodesExpanded > request.maxSteps) {
      result.partial = true;
      break;
    }

    auto elapsed = std::chrono::high_resolution_clock::now() - startTime;
    float elapsedMs = std::chrono::duration<float, std::milli>(elapsed).count();
    if (elapsedMs > request.maxTimeMs) {
      result.partial = true;
      break;
    }

    // Get node with lowest f-cost
    Node *current = openSet.top();
    openSet.pop();

    // Skip if already in closed set (can happen due to priority queue)
    if (closedSet.count(current->point)) {
      continue;
    }

    closedSet.insert(current->point);
    current->inClosedSet = true;

    // Check if we reached the goal
    if (current->point == request.end) {
      // Reconstruct path
      result.found = true;
      Node *node = current;
      while (node != nullptr) {
        result.path.push_back(node->point);
        node = node->parent;
      }
      std::reverse(result.path.begin(), result.path.end());

      // Apply path smoothing if requested
      if (request.smoothPath && result.path.size() > 2) {
        result.path = smoothPath(result.path, request);
      }

      auto endTime = std::chrono::high_resolution_clock::now();
      result.timeMs =
          std::chrono::duration<float, std::milli>(endTime - startTime).count();
      return result;
    }

    // Track closest node for partial paths
    if (current->hCost < closestDistance) {
      closestNode = current;
      closestDistance = current->hCost;
    }

    // Explore neighbors
    for (int i = 0; i < neighborCount; i++) {
      Point neighborPoint = {current->point.x + neighbors[i].x,
                             current->point.y + neighbors[i].y};

      // Check bounds
      if (neighborPoint.x < 0 || neighborPoint.y < 0 ||
          neighborPoint.x >= m_Map.getWidth() ||
          neighborPoint.y >= m_Map.getHeight()) {
        continue;
      }

      // Check if in closed set
      if (closedSet.count(neighborPoint)) {
        continue;
      }

      // Check walkability
      if (!isWalkableInternal(neighborPoint.x, neighborPoint.y, request)) {
        continue;
      }

      // Calculate movement cost
      float moveCost = 1.0f;
      if (request.allowDiagonal && (i >= 4)) {
        // Diagonal movement
        moveCost = 1.414f; // sqrt(2)
      }

      // Get tile cost
      float tileCost =
          getCostInternal(neighborPoint.x, neighborPoint.y, request);
      if (tileCost < 0.0f) {
        continue; // Unwalkable
      }

      moveCost *= tileCost;

      float tentativeGCost = current->gCost + moveCost;

      // Get or create neighbor node
      Node *neighborNode = nullptr;
      auto it = nodeMap.find(neighborPoint);
      if (it != nodeMap.end()) {
        neighborNode = it->second;
      } else {
        neighborNode = m_NodePool->acquire(neighborPoint);
        nodeMap[neighborPoint] = neighborNode;
      }

      // Check if this is a better path
      if (neighborNode->parent == nullptr ||
          tentativeGCost < neighborNode->gCost) {
        neighborNode->parent = current;
        neighborNode->gCost = tentativeGCost;
        neighborNode->hCost =
            request.allowDiagonal
                ? heuristicOctile(neighborPoint, request.end)
                : heuristicManhattan(neighborPoint, request.end);
        neighborNode->fCost = neighborNode->gCost + neighborNode->hCost;

        openSet.push(neighborNode);
      }
    }
  }

  // No path found, but return partial path if requested
  if (result.partial && closestNode != startNode) {
    result.found = false;
    result.partial = true;

    // Reconstruct partial path to closest node
    Node *node = closestNode;
    while (node != nullptr) {
      result.path.push_back(node->point);
      node = node->parent;
    }
    std::reverse(result.path.begin(), result.path.end());
  }

  auto endTime = std::chrono::high_resolution_clock::now();
  result.timeMs =
      std::chrono::duration<float, std::milli>(endTime - startTime).count();

  return result;
}

// ============================================================================
// Heuristic Functions
// ============================================================================

float Pathfinder::heuristicManhattan(const Point &a, const Point &b) const {
  return static_cast<float>(std::abs(a.x - b.x) + std::abs(a.y - b.y));
}

float Pathfinder::heuristicOctile(const Point &a, const Point &b) const {
  int dx = std::abs(a.x - b.x);
  int dy = std::abs(a.y - b.y);
  return static_cast<float>(std::max(dx, dy) + 0.414f * std::min(dx, dy));
}

// ============================================================================
// Path Smoothing (String-Pulling Algorithm)
// ============================================================================

Pathfinder::Path Pathfinder::smoothPath(const Path &rawPath,
                                        const PathRequest &request) const {
  if (rawPath.size() < 3) {
    return rawPath;
  }

  Path smoothed;
  smoothed.push_back(rawPath[0]);

  size_t current = 0;
  while (current < rawPath.size() - 1) {
    size_t farthest = current + 1;

    // Find farthest visible point (check all remaining points)
    for (size_t i = current + 2; i < rawPath.size(); i++) {
      if (hasLineOfSight(rawPath[current], rawPath[i], request)) {
        farthest = i;
        // Don't break - keep checking for an even farther visible point
      }
    }

    smoothed.push_back(rawPath[farthest]);
    current = farthest;
  }

  return smoothed;
}

bool Pathfinder::hasLineOfSight(const Point &a, const Point &b,
                                const PathRequest &request) const {
  // Bresenham's line algorithm
  int dx = std::abs(b.x - a.x);
  int dy = std::abs(b.y - a.y);
  int sx = (a.x < b.x) ? 1 : -1;
  int sy = (a.y < b.y) ? 1 : -1;
  int err = dx - dy;

  Point current = a;

  while (true) {
    // Check if current tile is walkable
    if (current != a && current != b) {
      if (!isWalkableInternal(current.x, current.y, request)) {
        return false;
      }
    }

    if (current == b) {
      break;
    }

    int e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      current.x += sx;
    }
    if (e2 < dx) {
      err += dx;
      current.y += sy;
    }
  }

  return true;
}

// ============================================================================
// Internal Helper Functions
// ============================================================================

int Pathfinder::getLayerIndex(const std::string &layerName) const {
  // Check cache
  auto it = m_LayerCache.find(layerName);
  if (it != m_LayerCache.end()) {
    return it->second;
  }

  // Validate layer exists by checking if we can get any tile from it
  // TileMap returns 0 for non-existent layers, but also for empty tiles
  // For now, we'll assume the layer exists if the name is non-empty
  // TODO: Add TileMap::hasLayer() method for proper validation
  if (layerName.empty()) {
    return -1;
  }

  m_LayerCache[layerName] = 0;
  return 0;
}

bool Pathfinder::isWalkableInternal(int x, int y,
                                    const PathRequest &request) const {
  // Check bounds
  if (x < 0 || y < 0 || x >= m_Map.getWidth() || y >= m_Map.getHeight()) {
    return false;
  }

  // Use custom cost function if provided
  if (request.customCostFn) {
    float cost = request.customCostFn(x, y);
    return cost >= 0.0f;
  }

  return isWalkable(x, y, request.navigationLayer);
}

float Pathfinder::getCostInternal(int x, int y,
                                  const PathRequest &request) const {
  // Use custom cost function if provided
  if (request.customCostFn) {
    return request.customCostFn(x, y);
  }

  return getCost(x, y, request.navigationLayer);
}
