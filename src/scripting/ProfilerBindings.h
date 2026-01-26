#pragma once

#include <lua.hpp>

// Registers the 'profiler' global table with Tracy integration
void RegisterProfilerBindings(lua_State *L);
