#include "core/Engine.h"
#include "asset/AssetManager.h"
#include "audio/AudioSystem.h"
#include "core/Logger.h"
#include "core/Profiler.h"
#include "gameplay/cribbage/effects/EffectFactory.h"
#include "graphics/FontRenderer.h"
#include "input/InputManager.h"

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

  // Make sure WindowManager updates its state (e.g. tracking size changes if
  // needed via events) But WindowManager::updateWindow() is called in main loop
  // for events? Actually main loop calls SDL_PollEvent,
  // WindowManager::updateWindowImpl processes it? Engine::Update doesn't need
  // to call WindowManager update if main loop does.
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
