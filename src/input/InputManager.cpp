#include "input/InputManager.h"
#include "core/Logger.h"
#include "input/InputSystem.h"
#include "core/WindowManager.h"
#include "core/Engine.h"
#include <cmath>

extern "C" {
#include <lauxlib.h>
}

InputManager& InputManager::Instance() {
    static InputManager instance;
    return instance;
}

void InputManager::Init() {
    LOG_INFO("Initializing InputManager");
    
    // Check for gamepad (SDL3 API)
    int numGamepads = 0;
    SDL_JoystickID* gamepads = SDL_GetGamepads(&numGamepads);
    
    if (gamepads && numGamepads > 0) {
        LOG_DEBUG("Found %d gamepad(s)", numGamepads);
        
        // Open first gamepad
        m_Gamepad = SDL_OpenGamepad(gamepads[0]);
        if (m_Gamepad) {
            m_GamepadConnected = true;
            LOG_INFO("Gamepad connected: %s", SDL_GetGamepadName(m_Gamepad));
        } else {
            LOG_WARN("Failed to open gamepad");
        }
        
        SDL_free(gamepads);
    } else {
        LOG_INFO("No gamepads detected");
    }
    
    // Initialize action states
    for (int i = 0; i <= static_cast<int>(UIAction::OpenSettings); ++i) {
        UIAction action = static_cast<UIAction>(i);
        m_ActionState[action] = false;
        m_ActionPrevState[action] = false;
    }
    
    // Initialize virtual cursor to screen center
    auto& windowMgr = WindowManager::getInstance();
    m_CursorX = windowMgr.getWidth() / 2.0f;
    m_CursorY = windowMgr.getHeight() / 2.0f;
}

void InputManager::Update(float dt) {
    // Save previous state
    m_ActionPrevState = m_ActionState;
    
    CheckDeviceSwitch();
    
    if (m_ActiveDevice == InputDevice::KeyboardMouse) {
        UpdateKeyboardMouse();
    } else {
        UpdateGamepad(dt);
    }
}

void InputManager::UpdateKeyboardMouse() {
    auto& input = Engine::Instance().Input();
    
    // Map keyboard/mouse to UIActions using existing InputSystem
    m_ActionState[UIAction::Confirm] = 
        input.IsActionDown("mouse_left") || 
        input.IsActionDown("return");
    
    m_ActionState[UIAction::Cancel] = 
        input.IsActionDown("escape") || 
        input.IsActionDown("mouse_right");
    
    m_ActionState[UIAction::NavigateUp] = input.IsActionDown("up");
    m_ActionState[UIAction::NavigateDown] = input.IsActionDown("down");
    m_ActionState[UIAction::NavigateLeft] = input.IsActionDown("left");
    m_ActionState[UIAction::NavigateRight] = input.IsActionDown("right");
    
    // Tab navigation
    bool tabDown = input.IsActionDown("tab");
    bool shiftDown = input.IsActionDown("lshift") || input.IsActionDown("rshift");
    m_ActionState[UIAction::TabNext] = tabDown && !shiftDown;
    m_ActionState[UIAction::TabPrevious] = tabDown && shiftDown;
    
    m_ActionState[UIAction::OpenMenu] = input.IsActionDown("escape");
    m_ActionState[UIAction::OpenSettings] = input.IsActionDown("f1");
    
    // Update cursor from mouse
    int mouseX, mouseY;
    input.GetMousePosition(&mouseX, &mouseY);
    m_CursorX = static_cast<float>(mouseX);
    m_CursorY = static_cast<float>(mouseY);
}

void InputManager::UpdateGamepad(float dt) {
    if (!m_Gamepad) return;
    
    // Map gamepad buttons to UIActions
    m_ActionState[UIAction::Confirm] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_SOUTH) != 0;  // A
    
    m_ActionState[UIAction::Cancel] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_EAST) != 0;   // B
    
    m_ActionState[UIAction::NavigateUp] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_DPAD_UP) != 0;
    
    m_ActionState[UIAction::NavigateDown] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_DPAD_DOWN) != 0;
    
    m_ActionState[UIAction::NavigateLeft] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_DPAD_LEFT) != 0;
    
    m_ActionState[UIAction::NavigateRight] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_DPAD_RIGHT) != 0;
    
    m_ActionState[UIAction::TabNext] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER) != 0;  // RB
    
    m_ActionState[UIAction::TabPrevious] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER) != 0;   // LB
    
    m_ActionState[UIAction::OpenMenu] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_START) != 0;
    
    m_ActionState[UIAction::OpenSettings] = 
        SDL_GetGamepadButton(m_Gamepad, SDL_GAMEPAD_BUTTON_BACK) != 0;  // Select
    
    // Update virtual cursor from left analog stick
    Sint16 axisX = SDL_GetGamepadAxis(m_Gamepad, SDL_GAMEPAD_AXIS_LEFTX);
    Sint16 axisY = SDL_GetGamepadAxis(m_Gamepad, SDL_GAMEPAD_AXIS_LEFTY);
    
    float normalizedX = axisX / 32767.0f;
    float normalizedY = axisY / 32767.0f;
    
    // Apply deadzone
    const float deadzone = 0.15f;
    if (std::abs(normalizedX) < deadzone) normalizedX = 0.0f;
    if (std::abs(normalizedY) < deadzone) normalizedY = 0.0f;
    
    // Move cursor
    if (normalizedX != 0.0f || normalizedY != 0.0f) {
        m_CursorX += normalizedX * m_CursorSpeed * dt;
        m_CursorY += normalizedY * m_CursorSpeed * dt;
        
        // Clamp to screen bounds
        auto& windowMgr = WindowManager::getInstance();
        int winW = windowMgr.getWidth();
        int winH = windowMgr.getHeight();
        
        m_CursorX = std::max(0.0f, std::min(m_CursorX, static_cast<float>(winW)));
        m_CursorY = std::max(0.0f, std::min(m_CursorY, static_cast<float>(winH)));
    }
}

void InputManager::CheckDeviceSwitch() {
    auto& input = Engine::Instance().Input();
    
    // Check for mouse movement (switch to keyboard/mouse)
    int currentMouseX, currentMouseY;
    input.GetMousePosition(&currentMouseX, &currentMouseY);
    
    static int lastMouseX = currentMouseX;
    static int lastMouseY = currentMouseY;
    
    if (currentMouseX != lastMouseX || currentMouseY != lastMouseY) {
        if (m_ActiveDevice != InputDevice::KeyboardMouse) {
            m_ActiveDevice = InputDevice::KeyboardMouse;
            LOG_DEBUG("Switched to Keyboard/Mouse input");
        }
        lastMouseX = currentMouseX;
        lastMouseY = currentMouseY;
    }
    
    // Check for gamepad input (switch to gamepad)
    if (m_GamepadConnected && m_Gamepad) {
        // Check if any button is pressed
        for (int i = 0; i < SDL_GAMEPAD_BUTTON_COUNT; ++i) {
            if (SDL_GetGamepadButton(m_Gamepad, static_cast<SDL_GamepadButton>(i))) {
                if (m_ActiveDevice != InputDevice::Gamepad) {
                    m_ActiveDevice = InputDevice::Gamepad;
                    LOG_DEBUG("Switched to Gamepad input");
                }
                break;
            }
        }
    }
}

bool InputManager::IsActionPressed(UIAction action) const {
    auto it = m_ActionState.find(action);
    return it != m_ActionState.end() && it->second;
}

bool InputManager::IsActionJustPressed(UIAction action) const {
    auto it = m_ActionState.find(action);
    auto prevIt = m_ActionPrevState.find(action);
    
    bool current = it != m_ActionState.end() && it->second;
    bool previous = prevIt != m_ActionPrevState.end() && prevIt->second;
    
    return current && !previous;
}

bool InputManager::IsActionJustReleased(UIAction action) const {
    auto it = m_ActionState.find(action);
    auto prevIt = m_ActionPrevState.find(action);
    
    bool current = it != m_ActionState.end() && it->second;
    bool previous = prevIt != m_ActionPrevState.end() && prevIt->second;
    
    return !current && previous;
}

void InputManager::GetCursorPosition(float& x, float& y) const {
    x = m_CursorX;
    y = m_CursorY;
}

void InputManager::SetCursorPosition(float x, float y) {
    m_CursorX = x;
    m_CursorY = y;
}

void InputManager::MoveCursor(float dx, float dy) {
    m_CursorX += dx;
    m_CursorY += dy;
    
    // Clamp to screen bounds
    auto& windowMgr = WindowManager::getInstance();
    int winW = windowMgr.getWidth();
    int winH = windowMgr.getHeight();
    
    m_CursorX = std::max(0.0f, std::min(m_CursorX, static_cast<float>(winW)));
    m_CursorY = std::max(0.0f, std::min(m_CursorY, static_cast<float>(winH)));
}

const char* InputManager::GetGamepadName() const {
    if (m_Gamepad) {
        return SDL_GetGamepadName(m_Gamepad);
    }
    return "No Gamepad";
}

void InputManager::SetActionCallback(ActionCallback callback) {
    m_ActionCallback = callback;
}

void InputManager::Shutdown() {
    if (m_Gamepad) {
        SDL_CloseGamepad(m_Gamepad);
        m_Gamepad = nullptr;
        m_GamepadConnected = false;
        LOG_INFO("InputManager: Gamepad closed");
    }
}

const char* InputManager::ActionToString(UIAction action) {
    switch (action) {
        case UIAction::Confirm: return "Confirm";
        case UIAction::Cancel: return "Cancel";
        case UIAction::NavigateUp: return "NavigateUp";
        case UIAction::NavigateDown: return "NavigateDown";
        case UIAction::NavigateLeft: return "NavigateLeft";
        case UIAction::NavigateRight: return "NavigateRight";
        case UIAction::TabNext: return "TabNext";
        case UIAction::TabPrevious: return "TabPrevious";
        case UIAction::OpenMenu: return "OpenMenu";
        case UIAction::OpenSettings: return "OpenSettings";
        default: return "Unknown";
    }
}

// Lua Bindings
int InputManager::Lua_IsActionPressed(lua_State* L) {
    const char* actionStr = luaL_checkstring(L, 1);
    
    // Map string to UIAction
    UIAction action;
    if (strcmp(actionStr, "confirm") == 0) action = UIAction::Confirm;
    else if (strcmp(actionStr, "cancel") == 0) action = UIAction::Cancel;
    else if (strcmp(actionStr, "navigate_up") == 0) action = UIAction::NavigateUp;
    else if (strcmp(actionStr, "navigate_down") == 0) action = UIAction::NavigateDown;
    else if (strcmp(actionStr, "navigate_left") == 0) action = UIAction::NavigateLeft;
    else if (strcmp(actionStr, "navigate_right") == 0) action = UIAction::NavigateRight;
    else if (strcmp(actionStr, "tab_next") == 0) action = UIAction::TabNext;
    else if (strcmp(actionStr, "tab_previous") == 0) action = UIAction::TabPrevious;
    else if (strcmp(actionStr, "open_menu") == 0) action = UIAction::OpenMenu;
    else if (strcmp(actionStr, "open_settings") == 0) action = UIAction::OpenSettings;
    else {
        lua_pushboolean(L, false);
        return 1;
    }
    
    bool pressed = InputManager::Instance().IsActionPressed(action);
    lua_pushboolean(L, pressed);
    return 1;
}

int InputManager::Lua_IsActionJustPressed(lua_State* L) {
    const char* actionStr = luaL_checkstring(L, 1);
    
    // Map string to UIAction
    UIAction action;
    if (strcmp(actionStr, "confirm") == 0) action = UIAction::Confirm;
    else if (strcmp(actionStr, "cancel") == 0) action = UIAction::Cancel;
    else if (strcmp(actionStr, "navigate_up") == 0) action = UIAction::NavigateUp;
    else if (strcmp(actionStr, "navigate_down") == 0) action = UIAction::NavigateDown;
    else if (strcmp(actionStr, "navigate_left") == 0) action = UIAction::NavigateLeft;
    else if (strcmp(actionStr, "navigate_right") == 0) action = UIAction::NavigateRight;
    else if (strcmp(actionStr, "tab_next") == 0) action = UIAction::TabNext;
    else if (strcmp(actionStr, "tab_previous") == 0) action = UIAction::TabPrevious;
    else if (strcmp(actionStr, "open_menu") == 0) action = UIAction::OpenMenu;
    else if (strcmp(actionStr, "open_settings") == 0) action = UIAction::OpenSettings;
    else {
        lua_pushboolean(L, false);
        return 1;
    }
    
    bool pressed = InputManager::Instance().IsActionJustPressed(action);
    lua_pushboolean(L, pressed);
    return 1;
}

int InputManager::Lua_GetCursor(lua_State* L) {
    float x, y;
    InputManager::Instance().GetCursorPosition(x, y);
    lua_pushnumber(L, x);
    lua_pushnumber(L, y);
    return 2;
}

int InputManager::Lua_IsGamepad(lua_State* L) {
    bool isGamepad = InputManager::Instance().GetActiveDevice() == InputDevice::Gamepad;
    lua_pushboolean(L, isGamepad);
    return 1;
}

int InputManager::Lua_IsGamepadConnected(lua_State* L) {
    bool connected = InputManager::Instance().IsGamepadConnected();
    lua_pushboolean(L, connected);
    return 1;
}

int InputManager::Lua_GetGamepadName(lua_State* L) {
    const char* name = InputManager::Instance().GetGamepadName();
    lua_pushstring(L, name);
    return 1;
}

void InputManager::RegisterLua(lua_State* L) {
    // Register as "inputmgr" table
    lua_newtable(L);
    
    lua_pushcfunction(L, Lua_IsActionPressed);
    lua_setfield(L, -2, "isActionPressed");
    
    lua_pushcfunction(L, Lua_IsActionJustPressed);
    lua_setfield(L, -2, "isActionJustPressed");
    
    lua_pushcfunction(L, Lua_GetCursor);
    lua_setfield(L, -2, "getCursor");
    
    lua_pushcfunction(L, Lua_IsGamepad);
    lua_setfield(L, -2, "isGamepad");
    
    lua_pushcfunction(L, Lua_IsGamepadConnected);
    lua_setfield(L, -2, "isGamepadConnected");
    
    lua_pushcfunction(L, Lua_GetGamepadName);
    lua_setfield(L, -2, "getGamepadName");
    
    lua_setglobal(L, "inputmgr");
    
    LOG_INFO("InputManager Lua bindings registered");
}
