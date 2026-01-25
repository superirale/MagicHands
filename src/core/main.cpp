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
  // 0. Initialize Logger first
  Logger::Init(LogLevel::Info);

  // 1. Initialize WindowManager (Handles SDL_Init and Window Creation)
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
  AudioSystem::RegisterLua(L);
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
    // We need the GPU device, which Engine now owns.
    // Ideally Engine or Renderer handles BeginFrame/EndFrame completely, but
    // main loop logic here does Lua Update inside. Let's get the device from
    // Engine? Or just trust Engine::Renderer() is initialized.

    // We need the GPU Device to AcquireCommandBuffer.
    // Engine owns it now (m_GPUDevice).
    // Accessor needed? Or Engine::BeginFrame()?
    // Current design: Engine::Instance().Renderer().BeginFrame(cmdBuf).
    // But we need cmdBuf from `SDL_AcquireGPUCommandBuffer`.
    // And that needs `gpu_device`.

    // Quick fix: Add GetGPUDevice() to Engine?
    // Or just make Engine::Update do rendering? But Lua update is in the
    // middle.

    // Let's add GetGPUDevice() to Engine.h?
    // Or make m_GPUDevice public (it's public in my previous edit? No, default
    // is private? I used `replace_file_content` targeting the block but checked
    // the structure... In `Engine.h`:
    //   SDL_GPUDevice *m_GPUDevice = nullptr;
    //   SpriteRenderer m_Renderer;
    // These are usually private in the provided file?
    // `private:` was at line 46.
    // My previous edit inserted `m_GPUDevice` around line 47, which is INSIDE
    // `private:`. So it's private. I need a getter.

    // OR: Move `SDL_AcquireGPUCommandBuffer` to Engine?
    // `Engine::BeginFrame()` -> returns cmdBuf?
    // Let's assume for now I added a getter or I will add one.
    // Actually, I should add a simple getter `SDL_GPUDevice* GetDevice() {
    // return m_GPUDevice; }` to `Engine.h`. I'll do that in a separate step or
    // right now via another replace.

    // Wait, I can access it if I make it public.
    // Let's change `main.cpp` to use `Engine::Instance().GetGPUDevice()`, and I
    // will add that method.

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
  }

  // Cleanup
  EventSystem::Instance().Destroy();
  Engine::Instance().Destroy();
  WindowManager::getInstance().shutdown();
  lua_close(L);
  // Handle destroyed in shutdown/destroy calls

  return 0;
}
