#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

#include "core/Engine.h"
#include "core/Logger.h"
#include <iostream>

int main(int argc, char *argv[]) {
  // 0. Parse command line arguments
  bool autoplayMode = false;
  int autoplayRuns = 100;
  const char *autoplayStrategy = "Random";

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--autoplay") == 0) {
      autoplayMode = true;
    } else if (strncmp(argv[i], "--autoplay-runs=", 16) == 0) {
      autoplayRuns = atoi(argv[i] + 16);
    } else if (strncmp(argv[i], "--autoplay-strategy=", 20) == 0) {
      autoplayStrategy = argv[i] + 20;
    }
  }

  // Initialize Logger first
  Logger::Init(LogLevel::Info);

  if (autoplayMode) {
    LOG_INFO("=== AutoPlay QA Bot Mode Enabled ===");
    LOG_INFO("Runs: %d", autoplayRuns);
    LOG_INFO("Strategy: %s", autoplayStrategy);
  }

  // 1. Initialize WindowManager
  WindowConfig config;
  config.title = "Magic Hands";
  config.width = 1280;
  config.height = 720;
  config.mode = WindowMode::Windowed;
  config.vsync = true;

  if (!WindowManager::getInstance().initialize(config)) {
    LOG_ERROR("Failed to initialize WindowManager");
    return 1;
  }

  // 2. Initialize Engine
  Engine &engine = Engine::Instance();
  engine.SetAutoplayMode(autoplayMode);
  if (!engine.Init())
    return 1;

  // 3. Initialize Lua
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  // Register all bindings through Engine
  engine.RegisterLua(L);

  // Pass AutoPlay flags to Lua
  lua_pushboolean(L, autoplayMode);
  lua_setglobal(L, "AUTOPLAY_MODE");
  lua_pushinteger(L, autoplayRuns);
  lua_setglobal(L, "AUTOPLAY_RUNS");
  lua_pushstring(L, autoplayStrategy);
  lua_setglobal(L, "AUTOPLAY_STRATEGY");

  // Run the main script
  if (engine.CheckLua(L, luaL_dofile(L, "content/scripts/main.lua"))) {
    LOG_INFO("Lua script loaded.");
  }

  // 4. Main Loop (Delegated to Engine)
  engine.Run(L);

  // Cleanup
  LOG_INFO("Shutting down Magic Hands Engine");
  engine.Destroy();
  WindowManager::getInstance().shutdown();
  lua_close(L);

  if (autoplayMode) {
    LOG_INFO("AutoPlay QA Bot Shutdown Complete");
  }

  return 0;
}
