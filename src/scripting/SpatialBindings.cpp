#include "core/Engine.h"
#include "core/Logger.h"
#include "core/SpatialIndex.h"
#include "scripting/LuaBindings.h"
#include <memory>
#include <unordered_map>

// =============================================================================
// Storage for Quadtrees
// =============================================================================

static std::unordered_map<int, std::unique_ptr<Quadtree>> s_SpatialTrees;
static int s_NextSpatialHandle = 1;

// =============================================================================
// Helper: Get Quadtree by Handle
// =============================================================================

static Quadtree *getSpatialTree(lua_State *L, int handle) {
  auto it = s_SpatialTrees.find(handle);
  if (it == s_SpatialTrees.end()) {
    luaL_error(L, "Invalid spatial tree handle: %d", handle);
    return nullptr;
  }
  return it->second.get();
}

// =============================================================================
// spatial.create(x, y, w, h, maxObjects, maxLevels) -> handle
// =============================================================================

static int Lua_SpatialCreate(lua_State *L) {
  float x = static_cast<float>(luaL_checknumber(L, 1));
  float y = static_cast<float>(luaL_checknumber(L, 2));
  float w = static_cast<float>(luaL_checknumber(L, 3));
  float h = static_cast<float>(luaL_checknumber(L, 4));
  int maxObjects = static_cast<int>(luaL_optinteger(L, 5, 10));
  int maxLevels = static_cast<int>(luaL_optinteger(L, 6, 5));

  int handle = s_NextSpatialHandle++;
  s_SpatialTrees[handle] =
      std::make_unique<Quadtree>(Rect(x, y, w, h), maxObjects, maxLevels);

  lua_pushinteger(L, handle);
  return 1;
}

// =============================================================================
// spatial.insert(handle, id, x, y, w, h)
// =============================================================================

static int Lua_SpatialInsert(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));
  int id = static_cast<int>(luaL_checkinteger(L, 2));
  float x = static_cast<float>(luaL_checknumber(L, 3));
  float y = static_cast<float>(luaL_checknumber(L, 4));
  float w = static_cast<float>(luaL_checknumber(L, 5));
  float h = static_cast<float>(luaL_checknumber(L, 6));

  Quadtree *tree = getSpatialTree(L, handle);
  if (tree) {
    tree->insert(id, Rect(x, y, w, h));
  }

  return 0;
}

// =============================================================================
// spatial.insertPoint(handle, id, x, y)
// =============================================================================

static int Lua_SpatialInsertPoint(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));
  int id = static_cast<int>(luaL_checkinteger(L, 2));
  float x = static_cast<float>(luaL_checknumber(L, 3));
  float y = static_cast<float>(luaL_checknumber(L, 4));

  Quadtree *tree = getSpatialTree(L, handle);
  if (tree) {
    tree->insertPoint(id, x, y);
  }

  return 0;
}

// =============================================================================
// spatial.remove(handle, id)
// =============================================================================

static int Lua_SpatialRemove(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));
  int id = static_cast<int>(luaL_checkinteger(L, 2));

  Quadtree *tree = getSpatialTree(L, handle);
  if (tree) {
    tree->remove(id);
  }

  return 0;
}

// =============================================================================
// spatial.update(handle, id, x, y, w, h)
// =============================================================================

static int Lua_SpatialUpdate(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));
  int id = static_cast<int>(luaL_checkinteger(L, 2));
  float x = static_cast<float>(luaL_checknumber(L, 3));
  float y = static_cast<float>(luaL_checknumber(L, 4));
  float w = static_cast<float>(luaL_checknumber(L, 5));
  float h = static_cast<float>(luaL_checknumber(L, 6));

  Quadtree *tree = getSpatialTree(L, handle);
  if (tree) {
    tree->update(id, Rect(x, y, w, h));
  }

  return 0;
}

// =============================================================================
// spatial.query(handle, x, y, w, h) -> table of IDs
// =============================================================================

static int Lua_SpatialQuery(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));
  float x = static_cast<float>(luaL_checknumber(L, 2));
  float y = static_cast<float>(luaL_checknumber(L, 3));
  float w = static_cast<float>(luaL_checknumber(L, 4));
  float h = static_cast<float>(luaL_checknumber(L, 5));

  Quadtree *tree = getSpatialTree(L, handle);
  if (!tree) {
    lua_newtable(L);
    return 1;
  }

  std::vector<int> results;
  tree->query(Rect(x, y, w, h), results);

  // Create Lua table
  lua_createtable(L, static_cast<int>(results.size()), 0);
  for (size_t i = 0; i < results.size(); ++i) {
    lua_pushinteger(L, results[i]);
    lua_rawseti(L, -2, static_cast<int>(i + 1));
  }

  return 1;
}

// =============================================================================
// spatial.queryRadius(handle, x, y, radius) -> table of IDs
// =============================================================================

static int Lua_SpatialQueryRadius(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));
  float x = static_cast<float>(luaL_checknumber(L, 2));
  float y = static_cast<float>(luaL_checknumber(L, 3));
  float radius = static_cast<float>(luaL_checknumber(L, 4));

  Quadtree *tree = getSpatialTree(L, handle);
  if (!tree) {
    lua_newtable(L);
    return 1;
  }

  std::vector<int> results;
  tree->queryRadius(x, y, radius, results);

  // Create Lua table
  lua_createtable(L, static_cast<int>(results.size()), 0);
  for (size_t i = 0; i < results.size(); ++i) {
    lua_pushinteger(L, results[i]);
    lua_rawseti(L, -2, static_cast<int>(i + 1));
  }

  return 1;
}

// =============================================================================
// spatial.queryNearest(handle, x, y, maxRadius) -> id or -1
// =============================================================================

static int Lua_SpatialQueryNearest(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));
  float x = static_cast<float>(luaL_checknumber(L, 2));
  float y = static_cast<float>(luaL_checknumber(L, 3));
  float maxRadius = static_cast<float>(luaL_optnumber(L, 4, 1000.0f));

  Quadtree *tree = getSpatialTree(L, handle);
  if (!tree) {
    lua_pushinteger(L, -1);
    return 1;
  }

  int nearestId = tree->queryNearest(x, y, maxRadius);
  lua_pushinteger(L, nearestId);
  return 1;
}

// =============================================================================
// spatial.clear(handle)
// =============================================================================

static int Lua_SpatialClear(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));

  Quadtree *tree = getSpatialTree(L, handle);
  if (tree) {
    tree->clear();
  }

  return 0;
}

// =============================================================================
// spatial.destroy(handle)
// =============================================================================

static int Lua_SpatialDestroy(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));

  auto it = s_SpatialTrees.find(handle);
  if (it != s_SpatialTrees.end()) {
    s_SpatialTrees.erase(it);
  }

  return 0;
}

// =============================================================================
// spatial.size(handle) -> count
// =============================================================================

static int Lua_SpatialSize(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));

  Quadtree *tree = getSpatialTree(L, handle);
  if (!tree) {
    lua_pushinteger(L, 0);
    return 1;
  }

  lua_pushinteger(L, tree->size());
  return 1;
}

// =============================================================================
// spatial.stats(handle) -> table
// =============================================================================

static int Lua_SpatialStats(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));

  Quadtree *tree = getSpatialTree(L, handle);
  if (!tree) {
    lua_newtable(L);
    return 1;
  }

  Quadtree::Stats stats = tree->getStats();

  // Create stats table
  lua_createtable(L, 0, 4);

  lua_pushinteger(L, stats.nodeCount);
  lua_setfield(L, -2, "nodeCount");

  lua_pushinteger(L, stats.maxDepth);
  lua_setfield(L, -2, "maxDepth");

  lua_pushinteger(L, stats.totalObjects);
  lua_setfield(L, -2, "totalObjects");

  // objectsPerLevel as array
  lua_createtable(L, 10, 0);
  for (int i = 0; i < 10; ++i) {
    lua_pushinteger(L, stats.objectsPerLevel[i]);
    lua_rawseti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "objectsPerLevel");

  return 1;
}

// =============================================================================
// spatial.drawDebug(handle) - Render tree boundaries
// =============================================================================

static int Lua_SpatialDrawDebug(lua_State *L) {
  int handle = static_cast<int>(luaL_checkinteger(L, 1));

  Quadtree *tree = getSpatialTree(L, handle);
  if (!tree) {
    return 0;
  }

  // TODO: Implement debug rendering
  // This would require access to the renderer and recursively drawing node
  // bounds For now, just log that debug rendering was requested
  LOG_WARN("spatial.drawDebug: Debug rendering not yet implemented");

  return 0;
}

// =============================================================================
// Registration
// =============================================================================

void RegisterSpatialBindings(lua_State *L) {
  // Create spatial table
  lua_newtable(L);

  // Register functions
  lua_pushcfunction(L, Lua_SpatialCreate);
  lua_setfield(L, -2, "create");

  lua_pushcfunction(L, Lua_SpatialInsert);
  lua_setfield(L, -2, "insert");

  lua_pushcfunction(L, Lua_SpatialInsertPoint);
  lua_setfield(L, -2, "insertPoint");

  lua_pushcfunction(L, Lua_SpatialRemove);
  lua_setfield(L, -2, "remove");

  lua_pushcfunction(L, Lua_SpatialUpdate);
  lua_setfield(L, -2, "update");

  lua_pushcfunction(L, Lua_SpatialQuery);
  lua_setfield(L, -2, "query");

  lua_pushcfunction(L, Lua_SpatialQueryRadius);
  lua_setfield(L, -2, "queryRadius");

  lua_pushcfunction(L, Lua_SpatialQueryNearest);
  lua_setfield(L, -2, "queryNearest");

  lua_pushcfunction(L, Lua_SpatialClear);
  lua_setfield(L, -2, "clear");

  lua_pushcfunction(L, Lua_SpatialDestroy);
  lua_setfield(L, -2, "destroy");

  lua_pushcfunction(L, Lua_SpatialSize);
  lua_setfield(L, -2, "size");

  lua_pushcfunction(L, Lua_SpatialStats);
  lua_setfield(L, -2, "stats");

  lua_pushcfunction(L, Lua_SpatialDrawDebug);
  lua_setfield(L, -2, "drawDebug");

  // Register as global "spatial"
  lua_setglobal(L, "spatial");

  LOG_INFO("Registered Lua module: spatial");
}
