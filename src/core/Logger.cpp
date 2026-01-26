#include "core/Logger.h"
#include <cstring>
#include <ctime>
#include <lua.hpp>

// Static member initialization
LogLevel Logger::s_MinLevel = LogLevel::Info;

void Logger::Init(LogLevel minLevel) {
  s_MinLevel = minLevel;
  LOG_INFO("Logger initialized (min level: %s)", LevelToString(minLevel));
}

void Logger::SetMinLevel(LogLevel level) { s_MinLevel = level; }

LogLevel Logger::GetMinLevel() { return s_MinLevel; }

const char *Logger::LevelToString(LogLevel level) {
  switch (level) {
  case LogLevel::Trace:
    return "TRACE";
  case LogLevel::Debug:
    return "DEBUG";
  case LogLevel::Info:
    return "INFO";
  case LogLevel::Warn:
    return "WARN";
  case LogLevel::Error:
    return "ERROR";
  default:
    return "UNKNOWN";
  }
}

const char *Logger::LevelToColor(LogLevel level) {
  // ANSI color codes for terminal
  switch (level) {
  case LogLevel::Trace:
    return "\033[90m"; // Gray
  case LogLevel::Debug:
    return "\033[36m"; // Cyan
  case LogLevel::Info:
    return "\033[32m"; // Green
  case LogLevel::Warn:
    return "\033[33m"; // Yellow
  case LogLevel::Error:
    return "\033[31m"; // Red
  default:
    return "\033[0m";
  }
}

void Logger::Log(LogLevel level, const char *file, int line, const char *fmt,
                 ...) {
  // Skip if below minimum level
  if (static_cast<int>(level) < static_cast<int>(s_MinLevel)) {
    return;
  }

  // Get current time
  time_t now = time(nullptr);
  tm *localTime = localtime(&now);

  // Format timestamp
  char timestamp[32];
  strftime(timestamp, sizeof(timestamp), "%H:%M:%S", localTime);

  // Extract just the filename from the full path
  const char *filename = file;
  for (const char *p = file; *p; ++p) {
    if (*p == '/' || *p == '\\') {
      filename = p + 1;
    }
  }

  // Print prefix with color
  const char *color = LevelToColor(level);
  const char *reset = "\033[0m";

  fprintf(stderr, "%s[%s][%s]%s %s:%d: ", color, timestamp,
          LevelToString(level), reset, filename, line);

  // Print the actual message
  va_list args;
  va_start(args, fmt);
  vfprintf(stderr, fmt, args);
  va_end(args);

  fprintf(stderr, "\n");
  fflush(stderr);
}

// --- Lua Bindings ---

static int Lua_LogTrace(lua_State *L) {
  const char *msg = luaL_checkstring(L, 1);
  Logger::Log(LogLevel::Trace, "Lua", 0, "%s", msg);
  return 0;
}

static int Lua_LogDebug(lua_State *L) {
  const char *msg = luaL_checkstring(L, 1);
  Logger::Log(LogLevel::Debug, "Lua", 0, "%s", msg);
  return 0;
}

static int Lua_LogInfo(lua_State *L) {
  const char *msg = luaL_checkstring(L, 1);
  Logger::Log(LogLevel::Info, "Lua", 0, "%s", msg);
  return 0;
}

static int Lua_LogWarn(lua_State *L) {
  const char *msg = luaL_checkstring(L, 1);
  Logger::Log(LogLevel::Warn, "Lua", 0, "%s", msg);
  return 0;
}

static int Lua_LogError(lua_State *L) {
  const char *msg = luaL_checkstring(L, 1);
  Logger::Log(LogLevel::Error, "Lua", 0, "%s", msg);
  return 0;
}

static int Lua_LogSetLevel(lua_State *L) {
  const char *levelStr = luaL_checkstring(L, 1);
  LogLevel level = LogLevel::Info;
  if (strcmp(levelStr, "trace") == 0)
    level = LogLevel::Trace;
  else if (strcmp(levelStr, "debug") == 0)
    level = LogLevel::Debug;
  else if (strcmp(levelStr, "info") == 0)
    level = LogLevel::Info;
  else if (strcmp(levelStr, "warn") == 0)
    level = LogLevel::Warn;
  else if (strcmp(levelStr, "error") == 0)
    level = LogLevel::Error;
  Logger::SetMinLevel(level);
  return 0;
}

void Logger::RegisterLuaBindings(lua_State *L) {
  lua_newtable(L);
  lua_pushcfunction(L, Lua_LogTrace);
  lua_setfield(L, -2, "trace");
  lua_pushcfunction(L, Lua_LogDebug);
  lua_setfield(L, -2, "debug");
  lua_pushcfunction(L, Lua_LogInfo);
  lua_setfield(L, -2, "info");
  lua_pushcfunction(L, Lua_LogWarn);
  lua_setfield(L, -2, "warn");
  lua_pushcfunction(L, Lua_LogError);
  lua_setfield(L, -2, "error");
  lua_pushcfunction(L, Lua_LogSetLevel);
  lua_setfield(L, -2, "setLevel");
  lua_setglobal(L, "log");
}
