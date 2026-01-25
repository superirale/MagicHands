#pragma once

/**
 * Profiler.h - Tracy Profiler Integration
 *
 * These macros provide zero-cost abstraction when TRACY_ENABLE is not defined.
 * Use -DHELHEIM_ENABLE_TRACY=ON in CMake to enable profiling.
 */

#ifdef TRACY_ENABLE
#include <tracy/Tracy.hpp>

// Scope profiling (automatically uses function name)
#define PROFILE_SCOPE() ZoneScoped

// Scope profiling with custom name
#define PROFILE_SCOPE_N(name) ZoneScopedN(name)

// Frame marker (call once per frame in main loop)
#define PROFILE_FRAME() FrameMark

// Plot a value (useful for tracking metrics)
#define PROFILE_PLOT(name, value) TracyPlot(name, value)

// Memory allocation tracking
#define PROFILE_ALLOC(ptr, size) TracyAlloc(ptr, size)
#define PROFILE_FREE(ptr) TracyFree(ptr)

// Message logging in profiler
#define PROFILE_MESSAGE(text, len) TracyMessage(text, len)
#define PROFILE_MESSAGE_L(text) TracyMessageL(text)

#else
// No-op when profiling is disabled
#define PROFILE_SCOPE()
#define PROFILE_SCOPE_N(name)
#define PROFILE_FRAME()
#define PROFILE_PLOT(name, value)
#define PROFILE_ALLOC(ptr, size)
#define PROFILE_FREE(ptr)
#define PROFILE_MESSAGE(text, len)
#define PROFILE_MESSAGE_L(text)
#endif

// Convenience macro for Lua zone (stores name for dynamic zones)
#ifdef TRACY_ENABLE
#define PROFILE_LUA_ZONE(name)                                                 \
  static constexpr tracy::SourceLocationData TracyLuaLoc{                      \
      nullptr, name, __FILE__, __LINE__, 0};                                   \
  tracy::ScopedZone ___tracy_lua_zone(&TracyLuaLoc)
#else
#define PROFILE_LUA_ZONE(name)
#endif
