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
  static bool Init();
  static void Destroy();
  static void Update(float dt);

  // Core API
  static void LoadBank(const std::string &path);
  static void PlayEvent(const std::string &name);

  // Volume control
  static void SetMasterVolume(float volume); // 0.0 to 1.0
  static float GetMasterVolume();

  // Legacy PlaySound removed as per user request. Use PlayEvent.

  // Lua Bindings
  static int Lua_LoadBank(lua_State *L);
  static int Lua_PlayEvent(lua_State *L);

  static void RegisterLua(lua_State *L);

private:
  static std::unique_ptr<Orpheus::AudioManager> s_Engine;
};
