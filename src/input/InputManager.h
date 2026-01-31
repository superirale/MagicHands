#pragma once

#include <SDL3/SDL.h>
#include <functional>
#include <string>
#include <unordered_map>

extern "C" {
#include <lua.h>
}

/**
 * InputManager - High-level input abstraction for UI interactions
 * 
 * Features:
 * - Unified input handling (keyboard, mouse, gamepad)
 * - UI action system (Confirm, Cancel, Navigate, etc.)
 * - Automatic device switching
 * - Virtual cursor for gamepad
 * - Controller support (Xbox, PlayStation, Switch Pro)
 */

enum class InputDevice {
    KeyboardMouse,
    Gamepad
};

enum class UIAction {
    Confirm,        // A button / Enter / Left Click
    Cancel,         // B button / ESC / Right Click
    NavigateUp,     // D-pad up / Arrow up
    NavigateDown,   // D-pad down / Arrow down
    NavigateLeft,   // D-pad left / Arrow left
    NavigateRight,  // D-pad right / Arrow right
    TabNext,        // RB / Tab
    TabPrevious,    // LB / Shift+Tab
    OpenMenu,       // Start / ESC
    OpenSettings    // Select / F1
};

class InputManager {
public:
    static InputManager& Instance();
    
    void Init();
    void Update(float dt);
    void Shutdown();
    
    // Input queries
    bool IsActionPressed(UIAction action) const;
    bool IsActionJustPressed(UIAction action) const;
    bool IsActionJustReleased(UIAction action) const;
    
    // Mouse/Gamepad cursor
    void GetCursorPosition(float& x, float& y) const;
    void SetCursorPosition(float x, float y);
    void MoveCursor(float dx, float dy);  // For gamepad analog stick
    
    // Device detection
    InputDevice GetActiveDevice() const { return m_ActiveDevice; }
    bool IsGamepadConnected() const { return m_GamepadConnected; }
    const char* GetGamepadName() const;
    
    // Callbacks
    using ActionCallback = std::function<void(UIAction)>;
    void SetActionCallback(ActionCallback callback);
    
    // Lua Registration
    static void RegisterLua(lua_State* L);
    
private:
    InputManager() = default;
    ~InputManager() = default;
    
    // Singleton - prevent copy/assignment
    InputManager(const InputManager&) = delete;
    InputManager& operator=(const InputManager&) = delete;
    
    InputDevice m_ActiveDevice = InputDevice::KeyboardMouse;
    bool m_GamepadConnected = false;
    SDL_Gamepad* m_Gamepad = nullptr;
    
    // State tracking
    std::unordered_map<UIAction, bool> m_ActionState;
    std::unordered_map<UIAction, bool> m_ActionPrevState;
    
    // Virtual cursor (for gamepad)
    float m_CursorX = 640.0f;
    float m_CursorY = 360.0f;
    float m_CursorSpeed = 500.0f;  // pixels per second
    
    ActionCallback m_ActionCallback;
    
    void UpdateKeyboardMouse();
    void UpdateGamepad(float dt);
    void CheckDeviceSwitch();
    
    // Helper to convert UIAction to string for logging
    static const char* ActionToString(UIAction action);
    
    // Lua bindings
    static int Lua_IsActionPressed(lua_State* L);
    static int Lua_IsActionJustPressed(lua_State* L);
    static int Lua_GetCursor(lua_State* L);
    static int Lua_IsGamepad(lua_State* L);
    static int Lua_IsGamepadConnected(lua_State* L);
    static int Lua_GetGamepadName(lua_State* L);
};
