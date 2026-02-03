#include "core/Engine.h"
#include "asset/AssetManager.h"
#include "audio/AudioSystem.h"
#include "core/JsonUtils.h"
#include "core/Logger.h"
#include "core/Profiler.h"
#include "events/EventSystem.h"
#include "gameplay/cribbage/effects/EffectFactory.h"
#include "graphics/FontRenderer.h"
#include "input/InputManager.h"
#include "physics/NoiseGenerator.h"
#include "scripting/LuaBindings.h"

#include <SDL3/SDL.h>

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

Engine &Engine::Instance() {
  static Engine instance;
  return instance;
}

bool Engine::Init() {
  LOG_DEBUG("Engine initializing subsystems...");

  // 0. Register built-in warp effects (must be done before gameplay)
  gameplay::EffectFactory::registerBuiltInEffects();

  // 1. Get window from WindowManager
  SDL_Window *window = WindowManager::getInstance().getNativeWindowHandle();
  if (!window) {
    LOG_ERROR("WindowManager has no active window");
    return false;
  }

  // 2. Create Graphics Device if not already created
  m_GPUDevice = SDL_CreateGPUDevice(
      SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_MSL, true, NULL);

  if (!m_GPUDevice) {
    LOG_ERROR("SDL_CreateGPUDevice failed: %s", SDL_GetError());
    return false;
  }

  if (!SDL_ClaimWindowForGPUDevice(m_GPUDevice, window)) {
    LOG_ERROR("SDL_ClaimWindowForGPUDevice failed: %s", SDL_GetError());
    return false;
  }

  // Initialize AssetManager with GPU device (for texture uploading)
  AssetManager::getInstance().setGPUDevice(m_GPUDevice);
  LOG_INFO("AssetManager initialized with GPU device");

  // Initialize renderer first (required by others)
  if (!m_Renderer.Init(m_GPUDevice, window)) {
    LOG_ERROR("Failed to initialize SpriteRenderer");
    return false;
  }

  // Initialize physics
  m_Physics.Init();

  // Initialize audio (singleton)
  AudioSystem::Instance().Init();

  // Initialize input system
  if (!m_Input.Init()) {
    LOG_ERROR("Failed to initialize InputSystem");
    return false;
  }

  // Initialize InputManager (gamepad/unified input)
  InputManager::Instance().Init();
  LOG_INFO("InputManager initialized");

  // Initialize font renderer (depends on SpriteRenderer)
  FontRenderer::Init(&m_Renderer);

  // Initialize particle system (depends on SpriteRenderer)
  m_Particles.Init(&m_Renderer);

  // Subscribe to WindowManager events
  m_ResizeCallbackHandle = WindowManager::getInstance().subscribeToResizeEvents(
      [this](uint32_t newWidth, uint32_t newHeight) {
        LOG_INFO("Window resized to %dx%d", newWidth, newHeight);
        m_Renderer.OnWindowResize(newWidth, newHeight);
      });

  m_FocusCallbackHandle =
      WindowManager::getInstance().subscribeToFocusEvents([this](bool focused) {
        if (!focused) {
          LOG_DEBUG("Window lost focus - reducing audio volume");
          AudioSystem::Instance().SetMasterVolume(
              0.3f); // Reduce to 30% when unfocused
        } else {
          LOG_DEBUG("Window gained focus - restoring audio volume");
          AudioSystem::Instance().SetMasterVolume(1.0f); // Restore full volume
        }
      });

  LOG_INFO("Engine subsystems initialized successfully");
  return true;
}

bool Engine::InitHeadless() {
  LOG_DEBUG("Engine initializing in HEADLESS mode (no window/GPU)...");
  m_Headless = true;

  // Initialize only non-graphical systems

  // Initialize physics (works without GPU)
  m_Physics.Init();

  // Initialize audio (works without GPU)
  AudioSystem::Instance().Init();

  // Initialize input system (works without window events)
  if (!m_Input.Init()) {
    LOG_ERROR("Failed to initialize InputSystem");
    return false;
  }

  LOG_INFO("Engine headless subsystems initialized successfully");
  return true;
}

void Engine::Update(float dt) {
  PROFILE_SCOPE();

  // Update Input State (captures SDL events/keyboard state)
  // This MUST happen before game logic uses input
  m_Input.Update();

  // Update InputManager (gamepad + unified input)
  InputManager::Instance().Update(dt);

  // Update audio system
  AudioSystem::Instance().Update(dt);
}

void Engine::Run(lua_State *L) {
  LOG_INFO("Magic Hands Engine Starting");
  bool quit = false;

  Uint64 lastTime = SDL_GetPerformanceCounter();
  Uint64 freq = SDL_GetPerformanceFrequency();

  while (!quit && !WindowManager::getInstance().shouldClose()) {
    PROFILE_FRAME(); // Tracy frame marker

    // Prepare Input System for new frame (clear text input)
    m_Input.BeginFrame();

    // Process Window Events (Resize, Quit, etc.)
    WindowManager::getInstance().updateWindow();

    if (WindowManager::getInstance().shouldClose()) {
      quit = true;
      break;
    }

    // Hot reload shortcuts
    if (m_Input.IsKeyPressed(SDL_SCANCODE_F11)) {
      LOG_INFO("Toggling fullscreen (F11)");
      WindowManager::getInstance().toggleFullscreen();
    }

    if (m_Input.IsKeyPressed(SDL_SCANCODE_F5)) {
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

      int result = luaL_dofile(L, "content/scripts/main.lua");
      if (result != LUA_OK) {
        LOG_ERROR("Script reload error: %s", lua_tostring(L, -1));
        lua_pop(L, 1);
      } else {
        LOG_INFO("Hot reload complete!");
      }
    }

    Uint64 now = SDL_GetPerformanceCounter();
    float dt = (float)((double)(now - lastTime) / freq);
    lastTime = now;

    // Fixed timestep physics update (60 Hz)
    static const float FIXED_DT = 1.0f / 60.0f;
    static const float MAX_FRAME_TIME = 0.25f;
    static float physicsAccumulator = 0.0f;

    if (dt > MAX_FRAME_TIME) {
      LOG_DEBUG("Long frame (%.3fs) - resetting physics accumulator", dt);
      physicsAccumulator = 0.0f;
      dt = FIXED_DT;
    }

    physicsAccumulator += dt;
    while (physicsAccumulator >= FIXED_DT) {
      m_Physics.Update(FIXED_DT);
      physicsAccumulator -= FIXED_DT;
    }

    // Update Engine (Audio, Input, etc)
    Update(dt);

    // Rendering
    if (!WindowManager::getInstance().isMinimized()) {
      if (m_GPUDevice) {
        SDL_GPUCommandBuffer *cmdBuf = SDL_AcquireGPUCommandBuffer(m_GPUDevice);
        if (cmdBuf) {
          m_Renderer.BeginFrame(cmdBuf);

          // Call Lua Update(dt)
          lua_getglobal(L, "update");
          if (lua_isfunction(L, -1)) {
            lua_pushnumber(L, dt);
            if (!CheckLua(L, lua_pcall(L, 1, 0, 0))) {
              // Error already printed
            }
          } else {
            lua_pop(L, 1);
          }

          m_Renderer.EndFrame();
          SDL_SubmitGPUCommandBuffer(cmdBuf);
        }
      }
    } else {
      lua_getglobal(L, "update");
      if (lua_isfunction(L, -1)) {
        lua_pushnumber(L, dt);
        if (!CheckLua(L, lua_pcall(L, 1, 0, 0))) {
          // Error already printed
        }
      } else {
        lua_pop(L, 1);
      }
      SDL_Delay(16);
    }

    // Check if AutoPlay wants to quit
    if (m_AutoplayMode) {
      lua_getglobal(L, "AUTOPLAY_QUIT");
      if (lua_isboolean(L, -1) && lua_toboolean(L, -1)) {
        LOG_INFO("AutoPlay requested quit");
        quit = true;
      }
      lua_pop(L, 1);
    }
  }
}

void Engine::RegisterLua(lua_State *L) {
  // Register all subsystem Lua bindings
  LuaBindings::Register(L);
  m_Physics.RegisterLua(L);
  m_Input.RegisterLua(L); // InputSystem
  InputManager::Instance().RegisterLua(L);
  AudioSystem::Instance().RegisterLua(L);
  FontRenderer::RegisterLua(L);
  RegisterJsonUtils(L);
  NoiseGenerator::RegisterLua(L);
  ParticleSystem::RegisterLua(L, &m_Particles);
  EventSystem::Instance().Init(L);
  EventSystem::RegisterLua(L);
  WindowManager::RegisterLua(L);
}

bool Engine::CheckLua(lua_State *L, int r) {
  if (r != LUA_OK) {
    LOG_ERROR("Lua Error: %s", lua_tostring(L, -1));
    return false;
  }
  return true;
}

void Engine::Destroy() {
  LOG_DEBUG("Engine destroying subsystems...");

  // Shutdown InputManager
  InputManager::Instance().Shutdown();
  LOG_INFO("InputManager shut down");

  // Unsubscribe from WindowManager events
  if (m_ResizeCallbackHandle != 0) {
    WindowManager::getInstance().unsubscribeFromResizeEvents(
        m_ResizeCallbackHandle);
    m_ResizeCallbackHandle = 0;
  }
  if (m_FocusCallbackHandle != 0) {
    WindowManager::getInstance().unsubscribeFromFocusEvents(
        m_FocusCallbackHandle);
    m_FocusCallbackHandle = 0;
  }

  // Destroy in reverse order of initialization
  m_Particles.Destroy();
  FontRenderer::Destroy();
  m_Renderer.Destroy();
  m_Physics.Destroy();
  AudioSystem::Instance().Destroy();

  if (m_GPUDevice) {
    SDL_DestroyGPUDevice(m_GPUDevice);
    m_GPUDevice = nullptr;
  }

  LOG_INFO("Engine subsystems destroyed");
}
