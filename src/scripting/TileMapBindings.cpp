#include "asset/AssetManager.h"
#include "core/Engine.h"
#include "core/Logger.h"
#include "scripting/LuaBindings.h"
#include "tilemap/TileMap.h"
#include <memory>
#include <unordered_map>

// Global reference to AssetManager
#define g_Assets AssetManager::getInstance()

// Storage for loaded tilemaps (Lua owns these via unique_ptr semantics)
static std::unordered_map<int, std::unique_ptr<TileMap>> s_Tilemaps;
static int s_NextTilemapId = 1;

#define g_Renderer Engine::Instance().Renderer()
#define g_Physics Engine::Instance().Physics()
#define g_WindowMgr WindowManager::getInstance()

// --- Tilemap Metatable ---
static const char *TILEMAP_MT = "MagicHands.TileMap";

struct TileMapUD {
  int id; // Index into s_Tilemaps
};

TileMap *getTileMap(lua_State *L, int idx = 1) {
  TileMapUD *ud = static_cast<TileMapUD *>(luaL_checkudata(L, idx, TILEMAP_MT));
  auto it = s_Tilemaps.find(ud->id);
  if (it == s_Tilemaps.end() || !it->second) {
    luaL_error(L, "Invalid TileMap handle");
    return nullptr;
  }
  return it->second.get();
}

// --- TileMap.load(path) ---
static int Lua_TileMapLoad(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);

  auto map = TileMap::load(path);
  if (!map) {
    lua_pushnil(L);
    return 1;
  }

  int id = s_NextTilemapId++;
  s_Tilemaps[id] = std::move(map);

  TileMapUD *ud =
      static_cast<TileMapUD *>(lua_newuserdata(L, sizeof(TileMapUD)));
  ud->id = id;

  luaL_getmetatable(L, TILEMAP_MT);
  lua_setmetatable(L, -2);

  return 1;
}

// --- TileMap.create(width, height, tileWidth, tileHeight) ---
static int Lua_TileMapCreate(lua_State *L) {
  int width = static_cast<int>(luaL_checkinteger(L, 1));
  int height = static_cast<int>(luaL_checkinteger(L, 2));
  int tileWidth = static_cast<int>(luaL_optinteger(L, 3, 32));
  int tileHeight = static_cast<int>(luaL_optinteger(L, 4, tileWidth));

  auto map = TileMap::create(width, height, tileWidth, tileHeight);
  int id = s_NextTilemapId++;
  s_Tilemaps[id] = std::move(map);

  TileMapUD *ud =
      static_cast<TileMapUD *>(lua_newuserdata(L, sizeof(TileMapUD)));
  ud->id = id;

  luaL_getmetatable(L, TILEMAP_MT);
  lua_setmetatable(L, -2);

  return 1;
}

// --- TileMap.getByName(name) - get from AssetManager ---
static int Lua_TileMapGetByName(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);

  auto asset = g_Assets.getTileMapByName(name);
  if (!asset || !asset->isValid()) {
    lua_pushnil(L);
    return 1;
  }

  // Get the shared TileMap from the asset and store a reference
  // We need to clone it or use wrapper to keep asset manager ownership
  // For simplicity, we'll use the shared_ptr approach with a different ID
  // scheme
  int id = s_NextTilemapId++;

  // Create a unique_ptr that wraps a copy of the shared_ptr's map
  // Note: This creates ownership in both places - asset manager and Lua
  // Alternatively, we could just reference the asset's map directly
  // For now, let's just load fresh from path (asset manager will cache the load
  // internally)
  auto freshMap = TileMap::load(asset->getPath());
  if (!freshMap) {
    lua_pushnil(L);
    return 1;
  }
  s_Tilemaps[id] = std::move(freshMap);

  TileMapUD *ud =
      static_cast<TileMapUD *>(lua_newuserdata(L, sizeof(TileMapUD)));
  ud->id = id;

  luaL_getmetatable(L, TILEMAP_MT);
  lua_setmetatable(L, -2);

  return 1;
}

// --- map:draw() ---
static int Lua_TileMapDraw(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  // Get camera position from renderer by default
  float cameraX = 0.0f;
  float cameraY = 0.0f;
  g_Renderer.GetCamera(&cameraX, &cameraY);

  // Get viewport from Renderer (physical pixels) and apply zoom
  float zoom = g_Renderer.GetZoom();
  int w, h;
  g_Renderer.GetWindowSize(&w, &h);
  int viewportWidth = static_cast<int>(w / zoom);
  int viewportHeight = static_cast<int>(h / zoom);

  // Optional: draw options table
  bool ignoreCulling = false;
  float scale = 1.0f;

  if (lua_istable(L, 2)) {
    lua_getfield(L, 2, "ignoreCulling");
    if (!lua_isnil(L, -1)) {
      ignoreCulling = lua_toboolean(L, -1);
    }
    lua_pop(L, 1);

    lua_getfield(L, 2, "scale");
    if (!lua_isnil(L, -1)) {
      scale = static_cast<float>(lua_tonumber(L, -1));
    }
    lua_pop(L, 1);

    lua_getfield(L, 2, "cameraX");
    if (!lua_isnil(L, -1)) {
      cameraX = static_cast<float>(lua_tonumber(L, -1));
    }
    lua_pop(L, 1);

    lua_getfield(L, 2, "cameraY");
    if (!lua_isnil(L, -1)) {
      cameraY = static_cast<float>(lua_tonumber(L, -1));
    }
    lua_pop(L, 1);
  }

  map->draw(g_Renderer, cameraX, cameraY, viewportWidth, viewportHeight,
            ignoreCulling, scale);
  return 0;
}

// --- map:getTileId(x, y, layerName) ---
static int Lua_TileMapGetTileId(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  int x = static_cast<int>(luaL_checkinteger(L, 2));
  int y = static_cast<int>(luaL_checkinteger(L, 3));
  const char *layerName = luaL_checkstring(L, 4);

  lua_pushinteger(L, map->getTileId(x, y, layerName));
  return 1;
}

// --- map:setTileId(x, y, layerName, tileId) ---
static int Lua_TileMapSetTileId(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  int x = static_cast<int>(luaL_checkinteger(L, 2));
  int y = static_cast<int>(luaL_checkinteger(L, 3));
  const char *layerName = luaL_checkstring(L, 4);
  int tileId = static_cast<int>(luaL_checkinteger(L, 5));

  map->setTileId(x, y, layerName, tileId);
  return 0;
}

// --- map:getProperty(x, y, propertyName) ---
static int Lua_TileMapGetProperty(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  int x = static_cast<int>(luaL_checkinteger(L, 2));
  int y = static_cast<int>(luaL_checkinteger(L, 3));
  const char *propName = luaL_checkstring(L, 4);

  std::string value = map->getProperty(x, y, propName);
  if (value.empty()) {
    lua_pushnil(L);
  } else {
    lua_pushstring(L, value.c_str());
  }
  return 1;
}

// --- map:getMapProperty(propertyName) ---
static int Lua_TileMapGetMapProperty(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  const char *propName = luaL_checkstring(L, 2);
  std::string value = map->getMapProperty(propName);

  if (value.empty()) {
    lua_pushnil(L);
  } else {
    lua_pushstring(L, value.c_str());
  }
  return 1;
}

// Helper to push TiledObject as Lua table
static void pushTiledObject(lua_State *L, const TiledObject *obj) {
  lua_newtable(L);

  lua_pushstring(L, obj->name.c_str());
  lua_setfield(L, -2, "name");

  lua_pushstring(L, obj->type.c_str());
  lua_setfield(L, -2, "type");

  lua_pushstring(L, obj->className.c_str());
  lua_setfield(L, -2, "class");

  lua_pushnumber(L, obj->x);
  lua_setfield(L, -2, "x");

  lua_pushnumber(L, obj->y);
  lua_setfield(L, -2, "y");

  lua_pushnumber(L, obj->width);
  lua_setfield(L, -2, "width");

  lua_pushnumber(L, obj->height);
  lua_setfield(L, -2, "height");

  lua_pushnumber(L, obj->rotation);
  lua_setfield(L, -2, "rotation");

  lua_pushboolean(L, obj->visible);
  lua_setfield(L, -2, "visible");

  // Properties subtable
  lua_newtable(L);
  for (const auto &[key, value] : obj->properties) {
    lua_pushstring(L, value.c_str());
    lua_setfield(L, -2, key.c_str());
  }
  lua_setfield(L, -2, "properties");
}

// --- map:getObjects(layerName) ---
static int Lua_TileMapGetObjects(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  const char *layerName = luaL_checkstring(L, 2);
  auto objects = map->getObjects(layerName);

  lua_createtable(L, static_cast<int>(objects.size()), 0);
  for (size_t i = 0; i < objects.size(); ++i) {
    pushTiledObject(L, objects[i]);
    lua_rawseti(L, -2, static_cast<int>(i + 1));
  }
  return 1;
}

// --- map:getObject(name) ---
static int Lua_TileMapGetObject(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  const char *name = luaL_checkstring(L, 2);
  const TiledObject *obj = map->getObject(name);

  if (!obj) {
    lua_pushnil(L);
  } else {
    pushTiledObject(L, obj);
  }
  return 1;
}

// --- map:getObjectsByType(type) ---
static int Lua_TileMapGetObjectsByType(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  const char *type = luaL_checkstring(L, 2);
  auto objects = map->getObjectsByType(type);

  lua_createtable(L, static_cast<int>(objects.size()), 0);
  for (size_t i = 0; i < objects.size(); ++i) {
    pushTiledObject(L, objects[i]);
    lua_rawseti(L, -2, static_cast<int>(i + 1));
  }
  return 1;
}

// --- map:getWidth(), map:getHeight(), etc ---
static int Lua_TileMapGetWidth(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;
  lua_pushinteger(L, map->getWidth());
  return 1;
}

static int Lua_TileMapGetHeight(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;
  lua_pushinteger(L, map->getHeight());
  return 1;
}

static int Lua_TileMapGetTileWidth(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;
  lua_pushinteger(L, map->getTileWidth());
  return 1;
}

static int Lua_TileMapGetTileHeight(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;
  lua_pushinteger(L, map->getTileHeight());
  return 1;
}

// --- map:setGlobalTint(r, g, b, a) ---
static int Lua_TileMapSetGlobalTint(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  float r = static_cast<float>(luaL_checknumber(L, 2));
  float g = static_cast<float>(luaL_checknumber(L, 3));
  float b = static_cast<float>(luaL_checknumber(L, 4));
  float a = static_cast<float>(luaL_optnumber(L, 5, 1.0));

  map->setGlobalTint(Color(r, g, b, a));
  return 0;
}

// --- map:setLayerTint(layerName, r, g, b, a) ---
static int Lua_TileMapSetLayerTint(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  const char *layerName = luaL_checkstring(L, 2);
  float r = static_cast<float>(luaL_checknumber(L, 3));
  float g = static_cast<float>(luaL_checknumber(L, 4));
  float b = static_cast<float>(luaL_checknumber(L, 5));
  float a = static_cast<float>(luaL_optnumber(L, 6, 1.0));

  map->setLayerTint(layerName, Color(r, g, b, a));
  return 0;
}

// --- map:setLayerVisible(layerName, visible) ---
static int Lua_TileMapSetLayerVisible(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  const char *layerName = luaL_checkstring(L, 2);
  bool visible = lua_toboolean(L, 3);

  map->setLayerVisible(layerName, visible);
  return 0;
}

// --- map:update(dt) ---
static int Lua_TileMapUpdate(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  float dt = static_cast<float>(luaL_checknumber(L, 2));
  map->update(dt);
  return 0;
}

// --- map:createCollisionBodies(layerName) ---
static int Lua_TileMapCreateCollisionBodies(lua_State *L) {
  TileMap *map = getTileMap(L, 1);
  if (!map)
    return 0;

  const char *layerName = luaL_checkstring(L, 2);
  map->createCollisionBodies(g_Physics, layerName);
  return 0;
}

// --- Garbage collection ---
static int Lua_TileMapGC(lua_State *L) {
  TileMapUD *ud = static_cast<TileMapUD *>(luaL_checkudata(L, 1, TILEMAP_MT));
  s_Tilemaps.erase(ud->id);
  return 0;
}

// --- Registration ---
void RegisterTileMapBindings(lua_State *L) {
  // Create metatable
  luaL_newmetatable(L, TILEMAP_MT);

  // __index = metatable
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");

  // __gc
  lua_pushcfunction(L, Lua_TileMapGC);
  lua_setfield(L, -2, "__gc");

  // Methods
  lua_pushcfunction(L, Lua_TileMapDraw);
  lua_setfield(L, -2, "draw");

  lua_pushcfunction(L, Lua_TileMapGetTileId);
  lua_setfield(L, -2, "getTileId");

  lua_pushcfunction(L, Lua_TileMapSetTileId);
  lua_setfield(L, -2, "setTileId");

  lua_pushcfunction(L, Lua_TileMapGetProperty);
  lua_setfield(L, -2, "getProperty");

  lua_pushcfunction(L, Lua_TileMapGetMapProperty);
  lua_setfield(L, -2, "getMapProperty");

  lua_pushcfunction(L, Lua_TileMapGetObjects);
  lua_setfield(L, -2, "getObjects");

  lua_pushcfunction(L, Lua_TileMapGetObject);
  lua_setfield(L, -2, "getObject");

  lua_pushcfunction(L, Lua_TileMapGetObjectsByType);
  lua_setfield(L, -2, "getObjectsByType");

  lua_pushcfunction(L, Lua_TileMapGetWidth);
  lua_setfield(L, -2, "getWidth");

  lua_pushcfunction(L, Lua_TileMapGetHeight);
  lua_setfield(L, -2, "getHeight");

  lua_pushcfunction(L, Lua_TileMapGetTileWidth);
  lua_setfield(L, -2, "getTileWidth");

  lua_pushcfunction(L, Lua_TileMapGetTileHeight);
  lua_setfield(L, -2, "getTileHeight");

  lua_pushcfunction(L, Lua_TileMapSetGlobalTint);
  lua_setfield(L, -2, "setGlobalTint");

  lua_pushcfunction(L, Lua_TileMapSetLayerTint);
  lua_setfield(L, -2, "setLayerTint");

  lua_pushcfunction(L, Lua_TileMapSetLayerVisible);
  lua_setfield(L, -2, "setLayerVisible");

  lua_pushcfunction(L, Lua_TileMapUpdate);
  lua_setfield(L, -2, "update");

  lua_pushcfunction(L, Lua_TileMapCreateCollisionBodies);
  lua_setfield(L, -2, "createCollisionBodies");

  lua_pop(L, 1); // Pop metatable

  // Create TileMap table
  lua_newtable(L);

  lua_pushcfunction(L, Lua_TileMapLoad);
  lua_setfield(L, -2, "load");

  lua_pushcfunction(L, Lua_TileMapCreate);
  lua_setfield(L, -2, "create");

  lua_pushcfunction(L, Lua_TileMapGetByName);
  lua_setfield(L, -2, "getByName");

  lua_setglobal(L, "TileMap");
}
