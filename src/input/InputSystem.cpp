#include "input/InputSystem.h"
#include "core/Engine.h"
#include "core/Logger.h"
#include <algorithm>
#include <cstring>

// Static singleton helper
static InputSystem &GetInput() { return Engine::Instance().Input(); }

bool InputSystem::Init() {
  LOG_INFO("Initializing Input System...");

  // Initialize keyboard state buffers
  int numKeys;
  const bool *state = SDL_GetKeyboardState(&numKeys);

  m_CurrentKeyState.resize(numKeys);
  m_PrevKeyState.resize(numKeys);

  // Initial Copy
  for (int i = 0; i < numKeys; i++) {
    m_CurrentKeyState[i] = state[i] ? 1 : 0;
    m_PrevKeyState[i] = state[i] ? 1 : 0;
  }

  return true;
}

void InputSystem::BeginFrame() {
  // Clear text input from previous frame
  m_TextInput.clear();
}

void InputSystem::Update() {
  // 1. Snapshot previous state
  m_PrevKeyState = m_CurrentKeyState; // Vector copy
  m_PrevMouseButtons = m_CurrentMouseButtons;

  // 2. Poll new state
  int numKeys;
  const bool *state = SDL_GetKeyboardState(&numKeys);

  if (m_CurrentKeyState.size() != numKeys) {
    m_CurrentKeyState.resize(numKeys);
    m_PrevKeyState.resize(numKeys);
  }

  for (int i = 0; i < numKeys; i++) {
    m_CurrentKeyState[i] = state[i] ? 1 : 0;
  }

  // Mouse
  m_CurrentMouseButtons = SDL_GetMouseState(&m_MouseX, &m_MouseY);
}

// --- Keyboard Core ---

bool InputSystem::IsKeyDown(SDL_Scancode key) const {
  if (key < 0 || key >= m_CurrentKeyState.size())
    return false;
  return m_CurrentKeyState[key];
}

bool InputSystem::IsKeyPressed(SDL_Scancode key) const {
  if (key < 0 || key >= m_CurrentKeyState.size())
    return false;
  return m_CurrentKeyState[key] && !m_PrevKeyState[key];
}

bool InputSystem::IsKeyReleased(SDL_Scancode key) const {
  if (key < 0 || key >= m_CurrentKeyState.size())
    return false;
  return !m_CurrentKeyState[key] && m_PrevKeyState[key];
}

// --- Mouse Core ---

bool InputSystem::IsMouseButtonDown(int button) const {
  // Buttons are 1-indexed (SDL_BUTTON_LEFT = 1)
  Uint32 mask = SDL_BUTTON_MASK(button);
  return (m_CurrentMouseButtons & mask);
}

bool InputSystem::IsMouseButtonPressed(int button) const {
  Uint32 mask = SDL_BUTTON_MASK(button);
  return (m_CurrentMouseButtons & mask) && !(m_PrevMouseButtons & mask);
}

bool InputSystem::IsMouseButtonReleased(int button) const {
  Uint32 mask = SDL_BUTTON_MASK(button);
  return !(m_CurrentMouseButtons & mask) && (m_PrevMouseButtons & mask);
}

void InputSystem::GetMousePosition(int *x, int *y) const {
  if (x)
    *x = (int)m_MouseX;
  if (y)
    *y = (int)m_MouseY;
}

// --- Action Mapping ---

void InputSystem::BindAction(const std::string &actionName,
                             const std::string &keyName) {
  SDL_Scancode scancode = GetScancodeFromStr(keyName);
  if (scancode != SDL_SCANCODE_UNKNOWN) {
    m_KeyBindings[actionName] = scancode;
    LOG_INFO("Bound action '%s' to key '%s'", actionName.c_str(),
             keyName.c_str());
  } else {
    LOG_WARN("Failed to bind action '%s': Unknown key '%s'", actionName.c_str(),
             keyName.c_str());
  }
}

bool InputSystem::IsActionDown(const std::string &actionName) const {
  auto it = m_KeyBindings.find(actionName);
  if (it != m_KeyBindings.end()) {
    return IsKeyDown(it->second);
  }
  return false;
}

bool InputSystem::IsActionPressed(const std::string &actionName) const {
  auto it = m_KeyBindings.find(actionName);
  if (it != m_KeyBindings.end()) {
    return IsKeyPressed(it->second);
  }
  return false;
}

bool InputSystem::IsActionReleased(const std::string &actionName) const {
  auto it = m_KeyBindings.find(actionName);
  if (it != m_KeyBindings.end()) {
    return IsKeyReleased(it->second);
  }
  return false;
}

SDL_Scancode InputSystem::GetScancodeFromStr(const std::string &keyName) {
  return SDL_GetScancodeFromName(keyName.c_str());
}

// --- Lua Bindings ---

int InputSystem::Lua_IsDown(lua_State *L) {
  const char *keyName = luaL_checkstring(L, 1);
  SDL_Scancode key = SDL_GetScancodeFromName(keyName);
  lua_pushboolean(L, GetInput().IsKeyDown(key));
  return 1;
}

int InputSystem::Lua_IsPressed(lua_State *L) {
  const char *keyName = luaL_checkstring(L, 1);
  SDL_Scancode key = SDL_GetScancodeFromName(keyName);
  lua_pushboolean(L, GetInput().IsKeyPressed(key));
  return 1;
}

int InputSystem::Lua_IsReleased(lua_State *L) {
  const char *keyName = luaL_checkstring(L, 1);
  SDL_Scancode key = SDL_GetScancodeFromName(keyName);
  lua_pushboolean(L, GetInput().IsKeyReleased(key));
  return 1;
}

int InputSystem::Lua_GetMousePosition(lua_State *L) {
  int x, y;
  GetInput().GetMousePosition(&x, &y);
  lua_pushinteger(L, x);
  lua_pushinteger(L, y);
  return 2;
}

int InputSystem::Lua_IsMouseButtonDown(lua_State *L) {
  const char *btnName = luaL_checkstring(L, 1);
  int btn = SDL_BUTTON_LEFT;
  if (strcmp(btnName, "left") == 0)
    btn = SDL_BUTTON_LEFT;
  else if (strcmp(btnName, "right") == 0)
    btn = SDL_BUTTON_RIGHT;
  else if (strcmp(btnName, "middle") == 0)
    btn = SDL_BUTTON_MIDDLE;

  lua_pushboolean(L, GetInput().IsMouseButtonDown(btn));
  return 1;
}

int InputSystem::Lua_IsMouseButtonPressed(lua_State *L) {
  const char *btnName = luaL_checkstring(L, 1);
  int btn = SDL_BUTTON_LEFT;
  if (strcmp(btnName, "left") == 0)
    btn = SDL_BUTTON_LEFT;
  else if (strcmp(btnName, "right") == 0)
    btn = SDL_BUTTON_RIGHT;
  else if (strcmp(btnName, "middle") == 0)
    btn = SDL_BUTTON_MIDDLE;

  lua_pushboolean(L, GetInput().IsMouseButtonPressed(btn));
  return 1;
}

int InputSystem::Lua_IsMouseButtonReleased(lua_State *L) {
  const char *btnName = luaL_checkstring(L, 1);
  int btn = SDL_BUTTON_LEFT;
  if (strcmp(btnName, "left") == 0)
    btn = SDL_BUTTON_LEFT;
  else if (strcmp(btnName, "right") == 0)
    btn = SDL_BUTTON_RIGHT;
  else if (strcmp(btnName, "middle") == 0)
    btn = SDL_BUTTON_MIDDLE;

  lua_pushboolean(L, GetInput().IsMouseButtonReleased(btn));
  return 1;
}

int InputSystem::Lua_Bind(lua_State *L) {
  const char *action = luaL_checkstring(L, 1);
  const char *key = luaL_checkstring(L, 2);
  GetInput().BindAction(action, key);
  return 0;
}

int InputSystem::Lua_IsActionDown(lua_State *L) {
  const char *action = luaL_checkstring(L, 1);
  lua_pushboolean(L, GetInput().IsActionDown(action));
  return 1;
}

int InputSystem::Lua_IsActionPressed(lua_State *L) {
  const char *action = luaL_checkstring(L, 1);
  lua_pushboolean(L, GetInput().IsActionPressed(action));
  return 1;
}

int InputSystem::Lua_IsActionReleased(lua_State *L) {
  const char *action = luaL_checkstring(L, 1);
  lua_pushboolean(L, GetInput().IsActionReleased(action));
  return 1;
}

// Text Input Methods
void InputSystem::StartTextInput() {
  m_TextInputActive = true;
  SDL_Window *window = WindowManager::getInstance().getNativeWindowHandle();

  if (window) {
    SDL_StartTextInput(window);
  }
}

void InputSystem::StopTextInput() {
  m_TextInputActive = false;
  SDL_StopTextInput(WindowManager::getInstance().getNativeWindowHandle());
}

const std::string &InputSystem::GetTextInput() const { return m_TextInput; }

void InputSystem::ClearTextInput() { m_TextInput.clear(); }

void InputSystem::OnTextInput(const char *text) {
  if (m_TextInputActive && text) {
    m_TextInput += text;
  }
}

// Lua Text Input Bindings
static int Lua_GetTextInput(lua_State *L) {
  const std::string &text = GetInput().GetTextInput();
  lua_pushstring(L, text.c_str());
  return 1;
}

static int Lua_StartTextInput(lua_State *L) {
  GetInput().StartTextInput();
  return 0;
}

static int Lua_StopTextInput(lua_State *L) {
  GetInput().StopTextInput();
  return 0;
}

void InputSystem::RegisterLua(lua_State *L) {
  lua_newtable(L);

  lua_pushcfunction(L, Lua_IsDown);
  lua_setfield(L, -2, "isDown");

  lua_pushcfunction(L, Lua_IsPressed);
  lua_setfield(L, -2, "isPressed");

  lua_pushcfunction(L, Lua_IsReleased);
  lua_setfield(L, -2, "isReleased");

  lua_pushcfunction(L, Lua_GetMousePosition);
  lua_setfield(L, -2, "getMousePosition");

  lua_pushcfunction(L, Lua_IsMouseButtonDown);
  lua_setfield(L, -2, "isMouseButtonDown");

  lua_pushcfunction(L, Lua_IsMouseButtonPressed);
  lua_setfield(L, -2, "isMouseButtonPressed");

  lua_pushcfunction(L, Lua_IsMouseButtonReleased);
  lua_setfield(L, -2, "isMouseButtonReleased");

  // Action API
  lua_pushcfunction(L, Lua_Bind);
  lua_setfield(L, -2, "bind");

  lua_pushcfunction(L, Lua_IsActionDown);
  lua_setfield(L, -2, "isActionDown");

  lua_pushcfunction(L, Lua_IsActionPressed);
  lua_setfield(L, -2, "isActionPressed");

  lua_pushcfunction(L, Lua_IsActionReleased);
  lua_setfield(L, -2, "isActionReleased");

  // Text input
  lua_pushcfunction(L, Lua_GetTextInput);
  lua_setfield(L, -2, "getTextInput");

  lua_pushcfunction(L, Lua_StartTextInput);
  lua_setfield(L, -2, "startTextInput");

  lua_pushcfunction(L, Lua_StopTextInput);
  lua_setfield(L, -2, "stopTextInput");

  lua_setglobal(L, "input");
}
