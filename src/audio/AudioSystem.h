#pragma once

#include <memory>
#include <string>

// Forward declare Orpheus types
namespace Orpheus {
class AudioManager;
}

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

class AudioSystem {
public:
  static AudioSystem &Instance();

  bool Init();
  void Destroy();
  void Update(float dt);

  // Core API
  void LoadBank(const std::string &path);
  void PlayEvent(const std::string &name);

  // Volume control
  void SetMasterVolume(float volume); // 0.0 to 1.0
  float GetMasterVolume() const;

  // Lua Bindings
  static int Lua_LoadBank(lua_State *L);
  static int Lua_PlayEvent(lua_State *L);

  void RegisterLua(lua_State *L);

private:
  AudioSystem() = default;
  ~AudioSystem() = default;

  // Non-copyable
  AudioSystem(const AudioSystem &) = delete;
  AudioSystem &operator=(const AudioSystem &) = delete;

  std::unique_ptr<Orpheus::AudioManager> m_Engine;
  float m_MasterVolume = 1.0f;
};
