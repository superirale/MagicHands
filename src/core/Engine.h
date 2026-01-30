#pragma once

#include "WindowManager.h"
#include "graphics/ParticleSystem.h"
#include "graphics/SpriteRenderer.h"
#include "input/InputSystem.h"
#include "physics/PhysicsSystem.h"
#include "ui/UISystem.h"

class Engine {
public:
  // Singleton accessor
  static Engine &Instance();

  // Initialize all subsystems
  bool Init();
  
  // Initialize in headless mode (no window/GPU)
  bool InitHeadless();

  // Update subsystems
  void Update(float dt);
  
  // Check if running in headless mode
  bool IsHeadless() const { return m_Headless; }

  // Shutdown all subsystems in reverse order
  void Destroy();

  // Subsystem accessors
  SpriteRenderer &Renderer() { return m_Renderer; }
  PhysicsSystem &Physics() { return m_Physics; }
  UISystem &UI() { return m_UI; }
  ParticleSystem &Particles() { return m_Particles; }
  InputSystem &Input() { return m_Input; }

  // Const accessors
  const SpriteRenderer &Renderer() const { return m_Renderer; }
  const PhysicsSystem &Physics() const { return m_Physics; }
  const UISystem &UI() const { return m_UI; }
  const ParticleSystem &Particles() const { return m_Particles; }
  const InputSystem &Input() const { return m_Input; }

  SDL_GPUDevice *GetGPUDevice() const { return m_GPUDevice; }

private:
  Engine() = default;
  ~Engine() = default;

  // Non-copyable
  Engine(const Engine &) = delete;
  Engine &operator=(const Engine &) = delete;

  SDL_GPUDevice *m_GPUDevice = nullptr;
  bool m_Headless = false;

  SpriteRenderer m_Renderer;
  PhysicsSystem m_Physics;
  UISystem m_UI;
  ParticleSystem m_Particles;
  InputSystem m_Input;

  // WindowManager event callback handles
  CallbackHandle m_ResizeCallbackHandle = 0;
  CallbackHandle m_FocusCallbackHandle = 0;
};
