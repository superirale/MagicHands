#pragma once

#include <SDL3/SDL.h>
#include <string>
#include <unordered_map>
#include <vector>

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

/**
 * InputSystem - Manages keyboard/mouse state and action mappings.
 *
 * Features:
 * - State Caching: Detects "Just Pressed" and "Just Released" events.
 * - Action Mapping: Binds logical action names (e.g. "Jump") to physical keys.
 */
class InputSystem {
public:
  InputSystem() = default;
  ~InputSystem() = default;

  // Called by Engine at startup
  bool Init();

  // Called by Engine every frame *before* Game  // Lifecycle
  void Update();
  void BeginFrame(); // Clears per-frame buffers (text input)

  // Keyboard
  bool IsKeyDown(SDL_Scancode key) const;
  bool IsKeyPressed(SDL_Scancode key) const;  // Just pressed this frame
  bool IsKeyReleased(SDL_Scancode key) const; // Just released this frame

  // Mouse API
  bool IsMouseButtonDown(int button) const;
  bool IsMouseButtonPressed(int button) const;
  bool IsMouseButtonReleased(int button) const;
  void GetMousePosition(int *x, int *y) const;

  // Action Mapping API
  void BindAction(const std::string &actionName, const std::string &keyName);
  bool IsActionDown(const std::string &actionName) const;
  bool IsActionPressed(const std::string &actionName) const;
  bool IsActionReleased(const std::string &actionName) const;

  // Text Input API
  void StartTextInput();
  void StopTextInput();
  const std::string &GetTextInput() const;
  void ClearTextInput();
  void OnTextInput(
      const char *text); // Called by WindowManager on SDL_EVENT_TEXT_INPUT

  // Lua Registration
  static void RegisterLua(lua_State *L);

private:
  // Keyboard State
  // We store full snapshots of the keyboard state (512 keys is standard for
  // SDL)
  std::vector<Uint8> m_CurrentKeyState;
  std::vector<Uint8> m_PrevKeyState;

  // Mouse State
  Uint32 m_CurrentMouseButtons = 0;
  Uint32 m_PrevMouseButtons = 0;
  float m_MouseX = 0;
  float m_MouseY = 0;

  // Action Mappings
  std::unordered_map<std::string, SDL_Scancode> m_KeyBindings;

  // Text Input
  std::string m_TextInput;
  bool m_TextInputActive = false;

  // Helpers
  SDL_Scancode GetScancodeFromStr(const std::string &keyName);

  // Lua bindings
  static int Lua_IsDown(lua_State *L);
  static int Lua_IsPressed(lua_State *L);
  static int Lua_IsReleased(lua_State *L);
  static int Lua_GetMousePosition(lua_State *L);
  static int Lua_IsMouseButtonDown(lua_State *L);
  static int Lua_IsMouseButtonPressed(lua_State *L);  // New
  static int Lua_IsMouseButtonReleased(lua_State *L); // New

  // Action Lua bindings
  static int Lua_Bind(lua_State *L);
  static int Lua_IsActionDown(lua_State *L);
  static int Lua_IsActionPressed(lua_State *L);
  static int Lua_IsActionReleased(lua_State *L);
};
