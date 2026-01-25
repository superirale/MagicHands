#pragma once

struct lua_State;

class LuaBindings {
public:
  static void Register(lua_State *L);
};
