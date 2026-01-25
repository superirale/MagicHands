#pragma once
#include <lua.hpp>
#include <nlohmann/json.hpp>

// Lua binding registration
void RegisterJsonUtils(lua_State* L);

// Lua bindings
int Lua_LoadJSON(lua_State* L);
int Lua_SaveFile(lua_State* L);  // Phase 5
int Lua_LoadFile(lua_State* L);  // Phase 5

// Helper for JSON parsing
void PushJSON(lua_State* L, const nlohmann::json& j);
