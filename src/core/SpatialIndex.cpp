#include "core/SpatialIndex.h"
#include "core/Logger.h"
#include <algorithm>
#include <cmath>

// =============================================================================
// Constructor / Destructor
// =============================================================================

Quadtree::Quadtree(Rect bounds, int maxObjects, int maxLevels)
    : m_Root(std::make_unique<QuadtreeNode>(bounds, 0)),
      m_MaxObjects(maxObjects), m_MaxLevels(maxLevels) {
  // Pre-allocate space for expected object count
  m_ObjectBounds.reserve(1024);
}

Quadtree::~Quadtree() {
  // Unique pointers handle cleanup automatically
}

// =============================================================================
// Public API: Insert
// =============================================================================

void Quadtree::insert(int id, Rect bounds) {
  // Update or insert into bounds cache
  m_ObjectBounds[id] = bounds;

  // Insert into tree starting at root
  insertIntoNode(m_Root.get(), id, bounds);
}

void Quadtree::insertPoint(int id, float x, float y) {
  insert(id, Rect(x, y, 0, 0));
}

// =============================================================================
// Public API: Remove
// =============================================================================

void Quadtree::remove(int id) {
  // Look up bounds from cache
  auto it = m_ObjectBounds.find(id);
  if (it == m_ObjectBounds.end()) {
    return; // Object doesn't exist, no-op
  }

  Rect bounds = it->second;
  m_ObjectBounds.erase(it);

  // Remove from tree
  removeFromNode(m_Root.get(), id, bounds);
}

// =============================================================================
// Public API: Update
// =============================================================================

void Quadtree::update(int id, Rect newBounds) {
  // Look up old bounds
  auto it = m_ObjectBounds.find(id);
  if (it == m_ObjectBounds.end()) {
    // Object doesn't exist, just insert
    insert(id, newBounds);
    return;
  }

  Rect oldBounds = it->second;

  // Optimization: If bounds are very close, might still be in same node
  // For simplicity, we'll just remove and re-insert
  // A more advanced implementation would check if getQuadrant returns the same
  // result
  m_ObjectBounds[id] = newBounds;
  removeFromNode(m_Root.get(), id, oldBounds);
  insertIntoNode(m_Root.get(), id, newBounds);
}

// =============================================================================
// Public API: Query
// =============================================================================

void Quadtree::query(Rect area, std::vector<int> &results) {
  results.clear();
  queryNode(m_Root.get(), area, results);
}

void Quadtree::queryRadius(float x, float y, float radius,
                           std::vector<int> &results) {
  // Convert circle to bounding rect
  Rect area(x - radius, y - radius, radius * 2, radius * 2);
  query(area, results);

  // Filter results to only those actually within radius
  float radiusSq = radius * radius;
  results.erase(
      std::remove_if(results.begin(), results.end(),
                     [&](int id) {
                       auto it = m_ObjectBounds.find(id);
                       if (it == m_ObjectBounds.end())
                         return true;

                       const Rect &bounds = it->second;
                       // Check distance to closest point on rect
                       float closestX =
                           std::max(bounds.x, std::min(x, bounds.x + bounds.w));
                       float closestY =
                           std::max(bounds.y, std::min(y, bounds.y + bounds.h));
                       float dx = x - closestX;
                       float dy = y - closestY;
                       return (dx * dx + dy * dy) > radiusSq;
                     }),
      results.end());
}

int Quadtree::queryNearest(float x, float y, float maxRadius) {
  std::vector<int> candidates;
  queryRadius(x, y, maxRadius, candidates);

  if (candidates.empty()) {
    return -1;
  }

  // Find closest
  int nearestId = -1;
  float nearestDistSq = maxRadius * maxRadius;

  for (int id : candidates) {
    auto it = m_ObjectBounds.find(id);
    if (it == m_ObjectBounds.end())
      continue;

    const Rect &bounds = it->second;
    // Distance to closest point on object
    float closestX = std::max(bounds.x, std::min(x, bounds.x + bounds.w));
    float closestY = std::max(bounds.y, std::min(y, bounds.y + bounds.h));
    float dx = x - closestX;
    float dy = y - closestY;
    float distSq = dx * dx + dy * dy;

    if (distSq < nearestDistSq) {
      nearestDistSq = distSq;
      nearestId = id;
    }
  }

  return nearestId;
}

// =============================================================================
// Public API: Utilities
// =============================================================================

void Quadtree::clear() {
  m_ObjectBounds.clear();
  clearNode(m_Root.get());
}

Quadtree::Stats Quadtree::getStats() const {
  Stats stats{};
  stats.objectsPerLevel.fill(0);
  collectStats(m_Root.get(), stats);
  stats.totalObjects = static_cast<int>(m_ObjectBounds.size());
  return stats;
}

// =============================================================================
// Private: Insert Implementation
// =============================================================================

void Quadtree::insertIntoNode(QuadtreeNode *node, int id, const Rect &bounds) {
  // If this node has children, try to insert into a child
  if (node->children[0] != nullptr) {
    int quadrant = getQuadrant(node, bounds);
    if (quadrant != -1) {
      insertIntoNode(node->children[quadrant].get(), id, bounds);
      return;
    }
    // Object crosses boundaries, store in this node
  }

  // Store in this node
  node->objectIds.push_back(id);

  // Check if we need to subdivide
  if (node->objectIds.size() > static_cast<size_t>(m_MaxObjects) &&
      node->level < m_MaxLevels && node->children[0] == nullptr) {
    subdivide(node);
  }
}

// =============================================================================
// Private: Remove Implementation
// =============================================================================

void Quadtree::removeFromNode(QuadtreeNode *node, int id, const Rect &bounds) {
  // Try to remove from children first
  if (node->children[0] != nullptr) {
    int quadrant = getQuadrant(node, bounds);
    if (quadrant != -1) {
      removeFromNode(node->children[quadrant].get(), id, bounds);
      return;
    }
  }

  // Remove from this node
  auto &ids = node->objectIds;
  ids.erase(std::remove(ids.begin(), ids.end(), id), ids.end());
}

// =============================================================================
// Private: Query Implementation
// =============================================================================

void Quadtree::queryNode(QuadtreeNode *node, const Rect &area,
                         std::vector<int> &results) {
  // Check if query area intersects this node
  if (!node->bounds.intersects(area)) {
    return;
  }

  // Add all objects in this node
  for (int id : node->objectIds) {
    // Optional: Filter by actual bounds intersection
    auto it = m_ObjectBounds.find(id);
    if (it != m_ObjectBounds.end() && it->second.intersects(area)) {
      results.push_back(id);
    }
  }

  // Recurse into children
  if (node->children[0] != nullptr) {
    for (int i = 0; i < 4; ++i) {
      queryNode(node->children[i].get(), area, results);
    }
  }
}

// =============================================================================
// Private: Subdivision
// =============================================================================

void Quadtree::subdivide(QuadtreeNode *node) {
  float halfW = node->bounds.w / 2.0f;
  float halfH = node->bounds.h / 2.0f;
  float x = node->bounds.x;
  float y = node->bounds.y;
  int childLevel = node->level + 1;

  // Create 4 children: NW, NE, SW, SE
  node->children[0] =
      std::make_unique<QuadtreeNode>(Rect(x, y, halfW, halfH), childLevel);
  node->children[1] = std::make_unique<QuadtreeNode>(
      Rect(x + halfW, y, halfW, halfH), childLevel);
  node->children[2] = std::make_unique<QuadtreeNode>(
      Rect(x, y + halfH, halfW, halfH), childLevel);
  node->children[3] = std::make_unique<QuadtreeNode>(
      Rect(x + halfW, y + halfH, halfW, halfH), childLevel);

  // Redistribute objects to children
  std::vector<int> remaining;
  for (int id : node->objectIds) {
    auto it = m_ObjectBounds.find(id);
    if (it == m_ObjectBounds.end())
      continue;

    const Rect &bounds = it->second;
    int quadrant = getQuadrant(node, bounds);

    if (quadrant != -1) {
      // Object fits in a child
      node->children[quadrant]->objectIds.push_back(id);
    } else {
      // Object crosses boundaries, keep in parent
      remaining.push_back(id);
    }
  }

  // Update this node to only keep boundary-crossing objects
  node->objectIds = std::move(remaining);
}

// =============================================================================
// Private: Quadrant Detection
// =============================================================================

int Quadtree::getQuadrant(const QuadtreeNode *node, const Rect &bounds) const {
  float midX = node->bounds.x + node->bounds.w / 2.0f;
  float midY = node->bounds.y + node->bounds.h / 2.0f;

  // Check if object fits entirely in one quadrant
  bool inLeft = (bounds.x + bounds.w < midX);
  bool inRight = (bounds.x >= midX);
  bool inTop = (bounds.y + bounds.h < midY);
  bool inBottom = (bounds.y >= midY);

  if (inTop && inLeft)
    return 0; // NW
  if (inTop && inRight)
    return 1; // NE
  if (inBottom && inLeft)
    return 2; // SW
  if (inBottom && inRight)
    return 3; // SE

  return -1; // Crosses boundaries
}

// =============================================================================
// Private: Clear
// =============================================================================

void Quadtree::clearNode(QuadtreeNode *node) {
  node->objectIds.clear();

  // Recursively clear and destroy children
  for (int i = 0; i < 4; ++i) {
    if (node->children[i]) {
      clearNode(node->children[i].get());
      node->children[i].reset();
    }
  }
}

// =============================================================================
// Private: Stats Collection
// =============================================================================

void Quadtree::collectStats(QuadtreeNode *node, Stats &stats) const {
  stats.nodeCount++;
  stats.maxDepth = std::max(stats.maxDepth, node->level);

  // Count objects at this level
  if (node->level < 10) {
    stats.objectsPerLevel[node->level] +=
        static_cast<int>(node->objectIds.size());
  }

  // Recurse into children
  for (int i = 0; i < 4; ++i) {
    if (node->children[i]) {
      collectStats(node->children[i].get(), stats);
    }
  }
}
