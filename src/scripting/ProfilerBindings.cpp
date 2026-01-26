#include "scripting/ProfilerBindings.h"
#include "core/Profiler.h"
#include <lua.hpp>

void RegisterProfilerBindings(lua_State *L) {
  // Register Profiler bindings (Tracy integration)
  // Note: These are no-ops when TRACY_ENABLE is not defined
  lua_newtable(L);

  // profiler.beginZone(name) - Start a named profiling zone
  lua_pushcfunction(L, [](lua_State *L) -> int {
#ifdef TRACY_ENABLE
    const char *name = luaL_checkstring(L, 1);
    // Tracy requires static source location, use message instead for dynamic
    // names
    TracyMessageL(name);
#else
    (void)L;
#endif
    return 0;
  });
  lua_setfield(L, -2, "beginZone");

  // profiler.endZone() - End current zone (no-op for message-based profiling)
  lua_pushcfunction(L, [](lua_State *L) -> int {
    (void)L;
    return 0;
  });
  lua_setfield(L, -2, "endZone");

  // profiler.mark(name) - Place a single marker/message
  lua_pushcfunction(L, [](lua_State *L) -> int {
#ifdef TRACY_ENABLE
    const char *name = luaL_checkstring(L, 1);
    TracyMessageL(name);
#else
    (void)L;
#endif
    return 0;
  });
  lua_setfield(L, -2, "mark");

  // profiler.plot(name, value) - Plot a numeric value
  lua_pushcfunction(L, [](lua_State *L) -> int {
#ifdef TRACY_ENABLE
    const char *name = luaL_checkstring(L, 1);
    double value = luaL_checknumber(L, 2);
    TracyPlot(name, value);
#else
    (void)L;
#endif
    return 0;
  });
  lua_setfield(L, -2, "plot");

  lua_setglobal(L, "profiler");
}
