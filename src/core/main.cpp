#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

#include "audio/AudioSystem.h"
#include "core/Engine.h"
#include "core/JsonUtils.h"
#include "core/Logger.h"
#include "events/EventSystem.h"
#include "graphics/Animation.h"
#include "graphics/FontRenderer.h"
#include "graphics/ParticleSystem.h"
#include "graphics/SpriteRenderer.h"
#include "input/InputManager.h"
#include "input/InputSystem.h"
#include "physics/NoiseGenerator.h"
#include "physics/PhysicsSystem.h"
#include "ui/UISystem.h"
#include <iostream>

#include "core/Profiler.h"
#include "graphics/DebugDraw.h"
#include "scripting/LuaBindings.h"

// ... after renderer init ...
// DebugDraw::Init(&g_Renderer);

// ... inside loop, after Flush ...
// DebugDraw::Render();
// DebugDraw::Clear(); // Clear per frame? Or persistent?
// Usually frame-based.

// Accessors for Engine subsystems (used by Lua bindings)
#define g_Renderer Engine::Instance().Renderer()
#define g_Physics Engine::Instance().Physics()
#define g_UISystem Engine::Instance().UI()
#define g_Particles Engine::Instance().Particles()

bool CheckLua(lua_State *L, int r) {
  if (r != LUA_OK) {
    LOG_ERROR("Lua Error: %s", lua_tostring(L, -1));
    return false;
  }
  return true;
}

int main(int argc, char *argv[]) {
  // 0. Parse command line arguments
  bool autoplayMode = false;
  int autoplayRuns = 100;                  // default
  const char *autoplayStrategy = "Random"; // default

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

  // 1. Initialize WindowManager (always use windowed mode)
  WindowConfig config;
  config.title = "Magic Hands";
  config.width = 1280;
  config.height = 720;
  config.mode = WindowMode::Windowed;
  config.vsync = true;

  if (!WindowManager::getInstance().initialize(config)) {
    LOG_ERROR("Failed to initialize WindowManager: %s",
              WindowManager::getInstance()
                  .getErrorString(WindowManager::getInstance().getLastError())
                  .c_str());
    return 1;
  }

  // 2. Initialize Engine (which creates GPU device using WindowManager)
  if (!Engine::Instance().Init())
    return 1;

  // 3. Initialize Lua
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  // Register all Graphics, UI, and Animation bindings
  LuaBindings::Register(L);

  // Register Physics & Input & Audio & Font
  Engine::Instance().Physics().RegisterLua(L);
  InputSystem::RegisterLua(L);
  InputManager::RegisterLua(L); // Gamepad & unified input
  AudioSystem::Instance().RegisterLua(L);
  FontRenderer::RegisterLua(L);
  // Register JSON utilities (Phase 5: now includes file I/O)
  RegisterJsonUtils(L);
  // Register Noise Generator (Phase 6: Procedural World Generation)
  NoiseGenerator::RegisterLua(L);

  // Register Particle System
  ParticleSystem::RegisterLua(L, &Engine::Instance().Particles());

  // Register Event System
  EventSystem::Instance().Init(L);
  EventSystem::RegisterLua(L);

  // Register WindowManager
  WindowManager::RegisterLua(L);

  // Pass AutoPlay flags to Lua as global variables
  lua_pushboolean(L, autoplayMode);
  lua_setglobal(L, "AUTOPLAY_MODE");
  lua_pushinteger(L, autoplayRuns);
  lua_setglobal(L, "AUTOPLAY_RUNS");
  lua_pushstring(L, autoplayStrategy);
  lua_setglobal(L, "AUTOPLAY_STRATEGY");

  // Run the main script
  if (CheckLua(L, luaL_dofile(L, "content/scripts/main.lua"))) {
    LOG_INFO("Lua script loaded.");
  }

  // 4. Main Loop
  LOG_INFO("Magic Hands Engine Starting");
  bool quit = false;

  Uint64 lastTime = SDL_GetTicks();

  while (!quit && !WindowManager::getInstance().shouldClose()) {
    PROFILE_FRAME(); // Tracy frame marker

    // Prepare Input System for new frame (clear text input)
    Engine::Instance().Input().BeginFrame();

    // Process Window Events (Resize, Quit, etc.)
    WindowManager::getInstance().updateWindow();

    if (WindowManager::getInstance().shouldClose()) {
      quit = true;
      break;
    }

    // Hot reload shortcuts
    // Use the new InputSystem!
    if (Engine::Instance().Input().IsKeyPressed(SDL_SCANCODE_F11)) {
      LOG_INFO("Toggling fullscreen (F11)");
      WindowManager::getInstance().toggleFullscreen();
    }

    if (Engine::Instance().Input().IsKeyPressed(SDL_SCANCODE_F5)) {
      LOG_INFO("=== HOT RELOAD (F5) ===");

      // 1. Reload all shaders
      LOG_INFO("Reloading shaders...");
      lua_getglobal(L, "ReloadAllShaders");
      if (lua_isfunction(L, -1)) {
        lua_pcall(L, 0, 0, 0);
      } else {
        LOG_WARN("ReloadAllShaders function not found");
        lua_pop(L, 1);
      }

      // 2. Reload all Lua scripts
      LOG_INFO("Reloading scripts...");

      // Clear package.loaded to force require() to reload all modules
      lua_getglobal(L, "package");
      lua_getfield(L, -1, "loaded");
      lua_pushnil(L);
      while (lua_next(L, -2)) {
        lua_pop(L, 1);        // Pop value
        lua_pushvalue(L, -1); // Duplicate key
        lua_pushnil(L);       // Set to nil
        lua_settable(L, -4);  // package.loaded[key] = nil
      }
      lua_pop(L, 2); // Pop loaded and package

      // Reset state if needed before reload?
      // Main script reload typically re-initializes things.

      // Now reload main.lua (will reload all require'd modules)
      int result = luaL_dofile(L, "content/scripts/main.lua");
      if (result != LUA_OK) {
        LOG_ERROR("Script reload error: %s", lua_tostring(L, -1));
        lua_pop(L, 1);
      } else {
        LOG_INFO("Hot reload complete!");
      }
    }

    Uint64 now = SDL_GetTicks();
    float dt = (now - lastTime) / 1000.0f;
    lastTime = now;

    // Fixed timestep physics update (60 Hz)
    static const float FIXED_DT = 1.0f / 60.0f;
    static const float MAX_FRAME_TIME = 0.25f;
    static float physicsAccumulator = 0.0f;

    // Reset accumulator on long frames (scene loading) to prevent catch-up
    // stutter
    if (dt > MAX_FRAME_TIME) {
      LOG_DEBUG("Long frame (%.3fs) - resetting physics accumulator", dt);
      physicsAccumulator = 0.0f;
      dt = FIXED_DT;
    }

    physicsAccumulator += dt;
    while (physicsAccumulator >= FIXED_DT) {
      Engine::Instance().Physics().Update(FIXED_DT);
      physicsAccumulator -= FIXED_DT;
    }

    // Update Engine (Audio, Input, etc)
    Engine::Instance().Update(dt);

    // Rendering
    // Skip rendering if window is minimized/occluded to prevent GPU blocking
    if (!WindowManager::getInstance().isMinimized()) {
      SDL_GPUDevice *gpu_device = Engine::Instance().GetGPUDevice();
      if (gpu_device) {
        SDL_GPUCommandBuffer *cmdBuf = SDL_AcquireGPUCommandBuffer(gpu_device);
        if (cmdBuf) {
          g_Renderer.BeginFrame(cmdBuf);

          // Call Lua Update(dt)
          lua_getglobal(L, "update");
          if (lua_isfunction(L, -1)) {
            lua_pushnumber(L, dt); // Pass DeltaTime
            if (!CheckLua(L, lua_pcall(L, 1, 0, 0))) {
              // Error already printed
            }
          } else {
            lua_pop(L, 1);
          }

          g_Renderer.EndFrame();
          SDL_SubmitGPUCommandBuffer(cmdBuf);
        }
      }
    } else {
      // Window is minimized, just update logic without rendering
      lua_getglobal(L, "update");
      if (lua_isfunction(L, -1)) {
        lua_pushnumber(L, dt);
        if (!CheckLua(L, lua_pcall(L, 1, 0, 0))) {
          // Error already printed
        }
      } else {
        lua_pop(L, 1);
      }

      // Sleep briefly to avoid spinning the CPU
      SDL_Delay(16); // ~60 FPS equivalent
    }

    // Check if AutoPlay wants to quit
    if (autoplayMode) {
      lua_getglobal(L, "AUTOPLAY_QUIT");
      if (lua_isboolean(L, -1) && lua_toboolean(L, -1)) {
        LOG_INFO("AutoPlay requested quit");
        quit = true;
      }
      lua_pop(L, 1);
    }
  }

  // Cleanup
  LOG_INFO("Shutting down Magic Hands Engine");
  EventSystem::Instance().Destroy();
  Engine::Instance().Destroy();
  WindowManager::getInstance().shutdown();
  lua_close(L);

  if (autoplayMode) {
    LOG_INFO("AutoPlay QA Bot Shutdown Complete");
  }

  return 0;
}
