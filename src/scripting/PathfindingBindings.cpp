#include "core/Engine.h"
#include "core/Logger.h"
#include "pathfinding/Pathfinder.h"
#include "scripting/LuaBindings.h"
#include "tilemap/TileMap.h"
#include <memory>
#include <unordered_map>
#include <vector>

// Storage for pathfinders (one per scene/tilemap typically)
static std::unordered_map<int, std::unique_ptr<Pathfinder>> s_Pathfinders;
static int s_NextPathfinderId = 1;
static int s_CurrentPathfinderId = -1; // Active pathfinder for current scene

// Storage for Lua function references that need cleanup
static std::vector<int> s_PendingFuncRefs;

// ============================================================================
// Helper: Get Current Pathfinder
// ============================================================================

static Pathfinder *getCurrentPathfinder(lua_State *L) {
  if (s_CurrentPathfinderId < 0) {
    luaL_error(L, "No active pathfinder. Create a pathfinder first.");
    return nullptr;
  }

  auto it = s_Pathfinders.find(s_CurrentPathfinderId);
  if (it == s_Pathfinders.end()) {
    luaL_error(L, "Invalid pathfinder handle");
    return nullptr;
  }

  return it->second.get();
}

// ============================================================================
// Pathfinding.create(tilemap) - Create pathfinder for a tilemap
// ============================================================================

// External declaration - we need access to the tilemap from userdata
extern TileMap *getTileMap(lua_State *L, int idx);

// ============================================================================
// Pathfinding.createForTileMap(tilemap) - Create pathfinder for a tilemap
// ============================================================================

static int Lua_PathfindingCreateForTileMap(lua_State *L) {
  // Get tilemap from argument (userdata)
  TileMap *tilemap = getTileMap(L, 1);
  if (!tilemap) {
    luaL_error(L, "Pathfinding.createForTileMap: Invalid TileMap argument");
    return 0;
  }

  int id = s_NextPathfinderId++;
  s_Pathfinders[id] = std::make_unique<Pathfinder>(*tilemap);
  s_CurrentPathfinderId = id;

  lua_pushinteger(L, id);
  return 1;
}

// ============================================================================
// Pathfinding.setActive(id) - Set active pathfinder by ID
// ============================================================================

static int Lua_PathfindingSetActive(lua_State *L) {
  int id = static_cast<int>(luaL_checkinteger(L, 1));

  auto it = s_Pathfinders.find(id);
  if (it == s_Pathfinders.end()) {
    luaL_error(L, "Pathfinding.setActive: Invalid pathfinder ID %d", id);
    return 0;
  }

  s_CurrentPathfinderId = id;
  return 0;
}

// ============================================================================
// Pathfinding.find(request) - Find a path
// ============================================================================

static int Lua_PathfindingFind(lua_State *L) {
  Pathfinder *pathfinder = getCurrentPathfinder(L);
  if (!pathfinder)
    return 0;

  // Parse request table
  luaL_checktype(L, 1, LUA_TTABLE);

  Pathfinder::PathRequest request;

  // Get start point
  lua_getfield(L, 1, "start");
  if (lua_istable(L, -1)) {
    lua_getfield(L, -1, "x");
    request.start.x = static_cast<int>(luaL_checkinteger(L, -1));
    lua_pop(L, 1);

    lua_getfield(L, -1, "y");
    request.start.y = static_cast<int>(luaL_checkinteger(L, -1));
    lua_pop(L, 1);
  } else {
    luaL_error(L, "Pathfinding.find: 'start' must be a table with x and y");
  }
  lua_pop(L, 1);

  // Get target point
  lua_getfield(L, 1, "target");
  if (lua_istable(L, -1)) {
    lua_getfield(L, -1, "x");
    request.end.x = static_cast<int>(luaL_checkinteger(L, -1));
    lua_pop(L, 1);

    lua_getfield(L, -1, "y");
    request.end.y = static_cast<int>(luaL_checkinteger(L, -1));
    lua_pop(L, 1);
  } else {
    luaL_error(L, "Pathfinding.find: 'target' must be a table with x and y");
  }
  lua_pop(L, 1);

  // Optional: diagonal
  lua_getfield(L, 1, "diagonal");
  if (!lua_isnil(L, -1)) {
    request.allowDiagonal = lua_toboolean(L, -1);
  }
  lua_pop(L, 1);

  // Optional: layer
  lua_getfield(L, 1, "layer");
  if (lua_isstring(L, -1)) {
    request.navigationLayer = lua_tostring(L, -1);
  }
  lua_pop(L, 1);

  // Optional: maxSteps
  lua_getfield(L, 1, "maxSteps");
  if (lua_isnumber(L, -1)) {
    request.maxSteps = static_cast<int>(lua_tointeger(L, -1));
  }
  lua_pop(L, 1);

  // Optional: maxTime
  lua_getfield(L, 1, "maxTime");
  if (lua_isnumber(L, -1)) {
    request.maxTimeMs = static_cast<float>(lua_tonumber(L, -1));
  }
  lua_pop(L, 1);

  // Optional: smooth
  lua_getfield(L, 1, "smooth");
  if (!lua_isnil(L, -1)) {
    request.smoothPath = lua_toboolean(L, -1);
  }
  lua_pop(L, 1);

  // Optional: costFunction (Lua callback)
  int costFuncRef = LUA_NOREF;
  lua_getfield(L, 1, "costFunction");
  if (lua_isfunction(L, -1)) {
    // Store the function reference
    costFuncRef = luaL_ref(L, LUA_REGISTRYINDEX);

    // Create a C++ lambda that calls the Lua function
    request.customCostFn = [L, costFuncRef](int x, int y) -> float {
      lua_rawgeti(L, LUA_REGISTRYINDEX, costFuncRef);
      lua_pushinteger(L, x);
      lua_pushinteger(L, y);
      if (lua_pcall(L, 2, 1, 0) != LUA_OK) {
        LOG_ERROR("Error in cost function: %s", lua_tostring(L, -1));
        lua_pop(L, 1);
        return 1.0f;
      }
      float cost = static_cast<float>(lua_tonumber(L, -1));
      lua_pop(L, 1);
      return cost;
    };
  } else {
    lua_pop(L, 1);
  }

  // Execute pathfinding
  auto result = pathfinder->findPath(request);

  // Release the Lua function reference now that pathfinding is complete
  if (costFuncRef != LUA_NOREF) {
    luaL_unref(L, LUA_REGISTRYINDEX, costFuncRef);
  }

  // Build result table
  lua_newtable(L);

  // path array
  lua_createtable(L, static_cast<int>(result.path.size()), 0);
  for (size_t i = 0; i < result.path.size(); i++) {
    lua_newtable(L);

    lua_pushinteger(L, result.path[i].x);
    lua_setfield(L, -2, "x");

    lua_pushinteger(L, result.path[i].y);
    lua_setfield(L, -2, "y");

    lua_rawseti(L, -2, static_cast<int>(i + 1));
  }
  lua_setfield(L, -2, "path");

  // found
  lua_pushboolean(L, result.found);
  lua_setfield(L, -2, "found");

  // partial
  lua_pushboolean(L, result.partial);
  lua_setfield(L, -2, "partial");

  // nodesExpanded
  lua_pushinteger(L, result.nodesExpanded);
  lua_setfield(L, -2, "nodesExpanded");

  // timeMs
  lua_pushnumber(L, result.timeMs);
  lua_setfield(L, -2, "timeMs");

  return 1;
}

// ============================================================================
// Pathfinding.isWalkable(x, y, layer) - Check if tile is walkable
// ============================================================================

static int Lua_PathfindingIsWalkable(lua_State *L) {
  Pathfinder *pathfinder = getCurrentPathfinder(L);
  if (!pathfinder)
    return 0;

  int x = static_cast<int>(luaL_checkinteger(L, 1));
  int y = static_cast<int>(luaL_checkinteger(L, 2));
  const char *layer = luaL_optstring(L, 3, "nav_ground");

  bool walkable = pathfinder->isWalkable(x, y, layer);
  lua_pushboolean(L, walkable);
  return 1;
}

// ============================================================================
// Pathfinding.getCost(x, y, layer) - Get tile cost
// ============================================================================

static int Lua_PathfindingGetCost(lua_State *L) {
  Pathfinder *pathfinder = getCurrentPathfinder(L);
  if (!pathfinder)
    return 0;

  int x = static_cast<int>(luaL_checkinteger(L, 1));
  int y = static_cast<int>(luaL_checkinteger(L, 2));
  const char *layer = luaL_optstring(L, 3, "nav_ground");

  float cost = pathfinder->getCost(x, y, layer);
  lua_pushnumber(L, cost);
  return 1;
}

// ============================================================================
// Pathfinding.invalidateRegion(x, y, width, height) - Invalidate cache
// ============================================================================

static int Lua_PathfindingInvalidateRegion(lua_State *L) {
  Pathfinder *pathfinder = getCurrentPathfinder(L);
  if (!pathfinder)
    return 0;

  int x = static_cast<int>(luaL_checkinteger(L, 1));
  int y = static_cast<int>(luaL_checkinteger(L, 2));
  int width = static_cast<int>(luaL_checkinteger(L, 3));
  int height = static_cast<int>(luaL_checkinteger(L, 4));

  pathfinder->invalidateRegion(x, y, width, height);
  return 0;
}

// ============================================================================
// Internal: Set active pathfinder for current scene
// ============================================================================

void SetActivePathfinder(Pathfinder *pathfinder) {
  // This would be called when a scene is activated
  // For now, we'll create and store pathfinders by ID
  // In production, integrate with scene system
}

// Create pathfinder for a tilemap (called internally)
int CreatePathfinderForTileMap(const TileMap &tilemap) {
  int id = s_NextPathfinderId++;
  s_Pathfinders[id] = std::make_unique<Pathfinder>(tilemap);
  s_CurrentPathfinderId = id;
  return id;
}

// ============================================================================
// Registration
// ============================================================================

void RegisterPathfindingBindings(lua_State *L) {
  lua_newtable(L);

  lua_pushcfunction(L, Lua_PathfindingCreateForTileMap);
  lua_setfield(L, -2, "createForTileMap");

  lua_pushcfunction(L, Lua_PathfindingSetActive);
  lua_setfield(L, -2, "setActive");

  lua_pushcfunction(L, Lua_PathfindingFind);
  lua_setfield(L, -2, "find");

  lua_pushcfunction(L, Lua_PathfindingIsWalkable);
  lua_setfield(L, -2, "isWalkable");

  lua_pushcfunction(L, Lua_PathfindingGetCost);
  lua_setfield(L, -2, "getCost");

  lua_pushcfunction(L, Lua_PathfindingInvalidateRegion);
  lua_setfield(L, -2, "invalidateRegion");

  lua_setglobal(L, "Pathfinding");

  LOG_INFO("Pathfinding bindings registered");
}
