#include "gameplay/blind/Blind.h"
#include "gameplay/boss/Boss.h"

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

using namespace gameplay;

// ===== Blind Bindings =====

static int Lua_BlindCreate(lua_State *L) {
  int act = luaL_checkinteger(L, 1);
  const char *typeStr = luaL_checkstring(L, 2);
  const char *bossId = luaL_optstring(L, 3, "");

  try {
    BlindType type = Blind::StringToType(typeStr);
    Blind blind = Blind::Create(act, type, bossId);

    // Return blind as table
    lua_newtable(L);

    lua_pushstring(L, Blind::TypeToString(blind.type).c_str());
    lua_setfield(L, -2, "type");

    lua_pushinteger(L, blind.act);
    lua_setfield(L, -2, "act");

    lua_pushinteger(L, blind.baseScore);
    lua_setfield(L, -2, "baseScore");

    lua_pushstring(L, blind.bossId.c_str());
    lua_setfield(L, -2, "bossId");

    return 1;
  } catch (const std::exception &e) {
    lua_pushnil(L);
    lua_pushstring(L, e.what());
    return 2;
  }
}

static int Lua_BlindGetRequiredScore(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  float difficultyMod = static_cast<float>(luaL_optnumber(L, 2, 1.0));

  // Extract blind from table
  lua_getfield(L, 1, "act");
  int act = lua_tointeger(L, -1);
  lua_pop(L, 1);

  lua_getfield(L, 1, "type");
  const char *typeStr = lua_tostring(L, -1);
  lua_pop(L, 1);

  lua_getfield(L, 1, "bossId");
  const char *bossId = lua_tostring(L, -1);
  lua_pop(L, 1);

  try {
    BlindType type = Blind::StringToType(typeStr);
    Blind blind = Blind::Create(act, type, bossId);
    int required = blind.GetRequiredScore(difficultyMod);

    lua_pushinteger(L, required);
    return 1;
  } catch (const std::exception &e) {
    lua_pushnil(L);
    lua_pushstring(L, e.what());
    return 2;
  }
}

// ===== Boss Bindings =====

static int Lua_BossLoad(lua_State *L) {
  const char *filePath = luaL_checkstring(L, 1);

  try {
    Boss boss = Boss::FromJSON(filePath);

    // Return boss as table
    lua_newtable(L);

    lua_pushstring(L, boss.id.c_str());
    lua_setfield(L, -2, "id");

    lua_pushstring(L, boss.name.c_str());
    lua_setfield(L, -2, "name");

    lua_pushstring(L, boss.description.c_str());
    lua_setfield(L, -2, "description");

    // Effects array
    lua_newtable(L);
    for (size_t i = 0; i < boss.effects.size(); ++i) {
      lua_pushstring(L, boss.effects[i].c_str());
      lua_rawseti(L, -2, i + 1);
    }
    lua_setfield(L, -2, "effects");

    return 1;
  } catch (const std::exception &e) {
    lua_pushnil(L);
    lua_pushstring(L, e.what());
    return 2;
  }
}

void RegisterBlindBindings(lua_State *L) {
  // Register blind global table
  lua_newtable(L);

  lua_pushcfunction(L, Lua_BlindCreate);
  lua_setfield(L, -2, "create");

  lua_pushcfunction(L, Lua_BlindGetRequiredScore);
  lua_setfield(L, -2, "getRequiredScore");

  lua_setglobal(L, "blind");
}

void RegisterBossBindings(lua_State *L) {
  // Register boss global table
  lua_newtable(L);

  lua_pushcfunction(L, Lua_BossLoad);
  lua_setfield(L, -2, "load");

  lua_setglobal(L, "boss");
}
