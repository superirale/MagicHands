#pragma once

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

// Forward declaration
class TileMap;

/**
 * High-performance A* pathfinding system for tile-based navigation.
 * Integrates with TileMap to read tile properties for traversal costs.
 */
class Pathfinder {
public:
  /**
   * Coordinate point on the tilemap grid.
   */
  struct Point {
    int x, y;

    bool operator==(const Point &other) const {
      return x == other.x && y == other.y;
    }

    bool operator!=(const Point &other) const { return !(*this == other); }
  };

  /**
   * Path represented as a sequence of points.
   */
  typedef std::vector<Point> Path;

  /**
   * Pathfinding request parameters.
   */
  struct PathRequest {
    Point start;
    Point end;
    std::string navigationLayer = "nav_ground";
    bool allowDiagonal = false;
    int maxSteps = 1000;
    float maxTimeMs = 5.0f;
    bool smoothPath = false;

    // Optional custom cost function (nullptr = use tile properties)
    // Returns cost multiplier, or negative for unwalkable
    std::function<float(int x, int y)> customCostFn = nullptr;
  };

  /**
   * Pathfinding result with metadata.
   */
  struct PathResult {
    Path path;            // Empty if no path found
    bool found = false;   // True if complete path found
    bool partial = false; // True if timeout/maxSteps hit
    int nodesExpanded = 0;
    float timeMs = 0.0f;
  };

  /**
   * Construct a pathfinder for a specific tilemap.
   */
  explicit Pathfinder(const TileMap &map);
  ~Pathfinder();

  // Disable copy and move (has const reference member)
  Pathfinder(const Pathfinder &) = delete;
  Pathfinder &operator=(const Pathfinder &) = delete;
  Pathfinder(Pathfinder &&) = delete;
  Pathfinder &operator=(Pathfinder &&) = delete;

  /**
   * Find a path from start to end.
   */
  PathResult findPath(const PathRequest &request);

  /**
   * Check if a specific tile is walkable.
   */
  bool isWalkable(int x, int y, const std::string &layer) const;

  /**
   * Get traversal cost for a tile.
   * @return Cost multiplier (>= 0), or -1.0 if unwalkable.
   */
  float getCost(int x, int y, const std::string &layer) const;

  /**
   * Invalidate cached paths in a rectangular region.
   */
  void invalidateRegion(int x, int y, int width, int height);

  /**
   * Clear all internal caches.
   */
  void clearCache();

public:
  /**
   * Internal node structure for A* algorithm.
   */
  struct Node {
    Point point;
    float gCost = 0.0f;
    float hCost = 0.0f;
    float fCost = 0.0f;
    Node *parent = nullptr;
    bool inClosedSet = false;

    void reset() {
      gCost = 0.0f;
      hCost = 0.0f;
      fCost = 0.0f;
      parent = nullptr;
      inClosedSet = false;
    }
  };

private:
  class NodePool;

  const TileMap &m_Map;

  // Layer name -> layer index cache
  mutable std::unordered_map<std::string, int> m_LayerCache;

  // Node pool for allocation reuse
  std::unique_ptr<NodePool> m_NodePool;

  // Internal A* implementation
  PathResult findPathInternal(const PathRequest &request);

  // Heuristic functions
  float heuristicManhattan(const Point &a, const Point &b) const;
  float heuristicOctile(const Point &a, const Point &b) const;

  // Path smoothing
  Path smoothPath(const Path &rawPath, const PathRequest &request) const;
  bool hasLineOfSight(const Point &a, const Point &b,
                      const PathRequest &request) const;

  // Tile queries
  int getLayerIndex(const std::string &layerName) const;
  bool isWalkableInternal(int x, int y, const PathRequest &request) const;
  float getCostInternal(int x, int y, const PathRequest &request) const;
};
