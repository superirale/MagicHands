#pragma once

#include <array>
#include <functional>
#include <memory>
#include <unordered_map>
#include <vector>

/**
 * Simple axis-aligned bounding box.
 */
struct Rect {
  float x, y; // Top-left corner
  float w, h; // Width and height

  Rect() : x(0), y(0), w(0), h(0) {}
  Rect(float x_, float y_, float w_, float h_) : x(x_), y(y_), w(w_), h(h_) {}

  /**
   * Check if this rect intersects another.
   */
  bool intersects(const Rect &other) const {
    return x < other.x + other.w && x + w > other.x && y < other.y + other.h &&
           y + h > other.y;
  }

  /**
   * Check if this rect fully contains another.
   */
  bool contains(const Rect &other) const {
    return other.x >= x && other.y >= y && other.x + other.w <= x + w &&
           other.y + other.h <= y + h;
  }

  /**
   * Check if a point is inside this rect.
   */
  bool containsPoint(float px, float py) const {
    return px >= x && px < x + w && py >= y && py < y + h;
  }
};

/**
 * Quadtree-based spatial index for fast 2D range queries.
 *
 * This implementation uses a standard quadtree with objects stored in the
 * smallest node that fully contains them. Objects that cross quadrant
 * boundaries remain in parent nodes.
 *
 * Thread Safety: NOT thread-safe. All operations must be called from the same
 * thread (typically the main game thread).
 */
class Quadtree {
public:
  /**
   * Statistics about the quadtree structure.
   */
  struct Stats {
    int nodeCount;                       // Total number of nodes in tree
    int maxDepth;                        // Deepest level reached
    int totalObjects;                    // Total objects stored
    std::array<int, 10> objectsPerLevel; // Object distribution by level
  };

  /**
   * Construct a quadtree covering the specified world area.
   *
   * @param bounds World space covered by root node
   * @param maxObjects Max objects per node before subdivision (default: 10)
   * @param maxLevels Max tree depth, root = 0 (default: 5)
   */
  Quadtree(Rect bounds, int maxObjects = 10, int maxLevels = 5);

  /**
   * Destructor - cleans up all nodes.
   */
  ~Quadtree();

  // --- Object Management ---

  /**
   * Insert an object into the tree.
   * If an object with this ID already exists, its bounds are updated.
   *
   * @param id Unique object identifier
   * @param bounds Object's axis-aligned bounding box
   */
  void insert(int id, Rect bounds);

  /**
   * Insert a point object (e.g., particle, pickup).
   * Internally creates a zero-size Rect at the point.
   *
   * @param id Unique object identifier
   * @param x Point X coordinate
   * @param y Point Y coordinate
   */
  void insertPoint(int id, float x, float y);

  /**
   * Remove an object from the tree.
   * Looks up bounds internally via m_ObjectBounds.
   * No-op if the object doesn't exist.
   *
   * @param id Object identifier to remove
   */
  void remove(int id);

  /**
   * Update an object's position/size.
   * Optimized to avoid removal if still in same node.
   *
   * @param id Object identifier to update
   * @param newBounds New bounding box
   */
  void update(int id, Rect newBounds);

  // --- Queries ---

  /**
   * Find all objects intersecting a rectangular area.
   *
   * @param area Query rectangle
   * @param results Output vector (cleared before filling)
   */
  void query(Rect area, std::vector<int> &results);

  /**
   * Find all objects within radius of a point.
   *
   * @param x Center X coordinate
   * @param y Center Y coordinate
   * @param radius Search radius
   * @param results Output vector (cleared before filling)
   */
  void queryRadius(float x, float y, float radius, std::vector<int> &results);

  /**
   * Find the single nearest object to a point (within maxRadius).
   *
   * @param x Point X coordinate
   * @param y Point Y coordinate
   * @param maxRadius Maximum search distance (default: 1000.0f)
   * @return Object ID, or -1 if none found
   */
  int queryNearest(float x, float y, float maxRadius = 1000.0f);

  // --- Utilities ---

  /**
   * Remove all objects from tree.
   * Maintains tree structure.
   */
  void clear();

  /**
   * Get current object count.
   */
  int size() const { return static_cast<int>(m_ObjectBounds.size()); }

  /**
   * Get statistics about tree structure.
   * Useful for debugging and performance analysis.
   */
  Stats getStats() const;

private:
  /**
   * Internal node structure for the quadtree.
   */
  struct QuadtreeNode {
    Rect bounds;                // Spatial region this node covers
    std::vector<int> objectIds; // Objects stored in THIS node
    std::array<std::unique_ptr<QuadtreeNode>, 4>
        children; // NW, NE, SW, SE (nullptr if not subdivided)
    int level;    // Depth in tree (root = 0)

    QuadtreeNode(Rect bounds_, int level_)
        : bounds(bounds_), level(level_),
          children{nullptr, nullptr, nullptr, nullptr} {}
  };

  // Tree structure
  std::unique_ptr<QuadtreeNode> m_Root;
  std::unordered_map<int, Rect> m_ObjectBounds;          // ID -> bounds cache
  std::unordered_map<int, QuadtreeNode *> m_ObjectNodes; // ID -> current node

  // Configuration
  int m_MaxObjects; // Max objects before split
  int m_MaxLevels;  // Max depth

  // Internal methods
  void insertIntoNode(QuadtreeNode *node, int id, const Rect &bounds);
  void removeFromNode(QuadtreeNode *node, int id, const Rect &bounds);
  void queryNode(QuadtreeNode *node, const Rect &area,
                 std::vector<int> &results);
  void subdivide(QuadtreeNode *node);
  void tryMerge(QuadtreeNode *node);
  int countSubtreeObjects(QuadtreeNode *node) const;
  int getQuadrant(const QuadtreeNode *node, const Rect &bounds) const;
  void clearNode(QuadtreeNode *node);
  void collectStats(QuadtreeNode *node, Stats &stats) const;
};
