#include "audio/AudioSystem.h"
#include "AudioManager.h" // Orpheus header
#include "core/Logger.h"

AudioSystem &AudioSystem::Instance() {
  static AudioSystem instance;
  return instance;
}

bool AudioSystem::Init() {
  LOG_INFO("Initializing Orpheus Audio System...");
  m_Engine = std::make_unique<Orpheus::AudioManager>();

  // Status is Result<void>, check with !result or !result.IsOk()
  if (!m_Engine->Init()) {
    LOG_ERROR("Failed to initialize Orpheus Audio Engine");
    return false;
  }

  LOG_INFO("Orpheus Audio initialized successfully");
  return true;
}

void AudioSystem::Destroy() {
  if (m_Engine) {
    m_Engine->Shutdown();
    m_Engine.reset();
  }
}

void AudioSystem::Update(float dt) {
  if (m_Engine) {
    m_Engine->Update(dt);
  }
}

void AudioSystem::LoadBank(const std::string &path) {
  if (m_Engine) {
    auto result = m_Engine->LoadEventsFromFile(path);
    if (!result) {
      LOG_ERROR("Failed to load sound bank: %s (Error: %s)", path.c_str(),
                result.GetError().What().c_str());
    } else {
      LOG_INFO("Loaded sound bank: %s", path.c_str());
    }
  }
}

void AudioSystem::PlayEvent(const std::string &name) {
  if (!m_Engine)
    return;

  auto result = m_Engine->PlayEvent(name);
  if (!result) {
    LOG_WARN("Failed to play event '%s': %s", name.c_str(),
             result.GetError().Message().c_str());
  }
}

void AudioSystem::SetMasterVolume(float volume) {
  // Clamp volume to 0.0-1.0 range
  m_MasterVolume = std::max(0.0f, std::min(1.0f, volume));
  LOG_DEBUG("Master volume set to: %.2f", m_MasterVolume);

  // TODO: Apply volume to Orpheus AudioManager when API is available
  // For now, just store the value
}

float AudioSystem::GetMasterVolume() const { return m_MasterVolume; }

// --- Lua Bindings ---

int AudioSystem::Lua_LoadBank(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  Instance().LoadBank(path);
  return 0;
}

int AudioSystem::Lua_PlayEvent(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  Instance().PlayEvent(name);
  return 0;
}

void AudioSystem::RegisterLua(lua_State *L) {
  lua_newtable(L);

  lua_pushcfunction(L, Lua_PlayEvent);
  lua_setfield(L, -2, "playEvent");

  lua_pushcfunction(L, Lua_LoadBank);
  lua_setfield(L, -2, "loadBank");

  lua_setglobal(L, "audio");
}
