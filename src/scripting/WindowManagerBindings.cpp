#include "core/Logger.h"
#include "core/WindowManager.h"

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

void WindowManager::RegisterLua(lua_State *L) {
  lua_newtable(L);

  // Window dimensions
  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushinteger(L, WindowManager::getInstance().getWidth());
    return 1;
  });
  lua_setfield(L, -2, "getWidth");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushinteger(L, WindowManager::getInstance().getHeight());
    return 1;
  });
  lua_setfield(L, -2, "getHeight");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushnumber(L, WindowManager::getInstance().getAspectRatio());
    return 1;
  });
  lua_setfield(L, -2, "getAspectRatio");

  // DPI scaling
  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushnumber(L, WindowManager::getInstance().getDPIScale());
    return 1;
  });
  lua_setfield(L, -2, "getDPIScale");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushinteger(L, WindowManager::getInstance().getScaledWidth());
    return 1;
  });
  lua_setfield(L, -2, "getScaledWidth");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushinteger(L, WindowManager::getInstance().getScaledHeight());
    return 1;
  });
  lua_setfield(L, -2, "getScaledHeight");

  // Window mode
  lua_pushcfunction(L, [](lua_State *L) -> int {
    WindowMode mode = WindowManager::getInstance().getWindowMode();
    const char *modeStr = "Windowed";
    switch (mode) {
    case WindowMode::Windowed:
      modeStr = "Windowed";
      break;
    case WindowMode::Fullscreen:
      modeStr = "Fullscreen";
      break;
    case WindowMode::BorderlessFullscreen:
      modeStr = "BorderlessFullscreen";
      break;
    }
    lua_pushstring(L, modeStr);
    return 1;
  });
  lua_setfield(L, -2, "getWindowMode");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    const char *modeStr = luaL_checkstring(L, 1);
    WindowMode mode = WindowMode::Windowed;
    if (strcmp(modeStr, "Fullscreen") == 0) {
      mode = WindowMode::Fullscreen;
    } else if (strcmp(modeStr, "BorderlessFullscreen") == 0) {
      mode = WindowMode::BorderlessFullscreen;
    } else if (strcmp(modeStr, "Windowed") == 0) {
      mode = WindowMode::Windowed;
    } else {
      return luaL_error(L, "Invalid window mode: %s", modeStr);
    }
    WindowManager::getInstance().setWindowMode(mode);
    return 0;
  });
  lua_setfield(L, -2, "setWindowMode");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    WindowManager::getInstance().toggleFullscreen();
    return 0;
  });
  lua_setfield(L, -2, "toggleFullscreen");

  // Cursor management
  lua_pushcfunction(L, [](lua_State *L) -> int {
    bool visible = lua_toboolean(L, 1);
    WindowManager::getInstance().setCursorVisible(visible);
    return 0;
  });
  lua_setfield(L, -2, "setCursorVisible");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushboolean(L, WindowManager::getInstance().isCursorVisible());
    return 1;
  });
  lua_setfield(L, -2, "isCursorVisible");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    const char *cursorName = luaL_checkstring(L, 1);
    CursorType type = CursorType::Arrow;

    if (strcmp(cursorName, "Arrow") == 0)
      type = CursorType::Arrow;
    else if (strcmp(cursorName, "Hand") == 0)
      type = CursorType::Hand;
    else if (strcmp(cursorName, "Crosshair") == 0)
      type = CursorType::Crosshair;
    else if (strcmp(cursorName, "TextInput") == 0)
      type = CursorType::TextInput;
    else if (strcmp(cursorName, "Wait") == 0)
      type = CursorType::Wait;
    else if (strcmp(cursorName, "SizeNS") == 0)
      type = CursorType::SizeNS;
    else if (strcmp(cursorName, "SizeEW") == 0)
      type = CursorType::SizeEW;
    else if (strcmp(cursorName, "SizeNWSE") == 0)
      type = CursorType::SizeNWSE;
    else if (strcmp(cursorName, "SizeSWNE") == 0)
      type = CursorType::SizeSWNE;
    else if (strcmp(cursorName, "Move") == 0)
      type = CursorType::Move;
    else if (strcmp(cursorName, "NotAllowed") == 0)
      type = CursorType::NotAllowed;
    else
      return luaL_error(L, "Invalid cursor type: %s", cursorName);

    WindowManager::getInstance().setCursorType(type);
    return 0;
  });
  lua_setfield(L, -2, "setCursorType");

  // Performance metrics
  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushnumber(L, WindowManager::getInstance().getCurrentFPS());
    return 1;
  });
  lua_setfield(L, -2, "getFPS");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushnumber(L, WindowManager::getInstance().getCurrentFrameTime());
    return 1;
  });
  lua_setfield(L, -2, "getFrameTime");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushinteger(L, WindowManager::getInstance().getFrameCount());
    return 1;
  });
  lua_setfield(L, -2, "getFrameCount");

  // Window state
  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushboolean(L, WindowManager::getInstance().isFocused());
    return 1;
  });
  lua_setfield(L, -2, "isFocused");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushboolean(L, WindowManager::getInstance().isMinimized());
    return 1;
  });
  lua_setfield(L, -2, "isMinimized");

  // Multi-monitor support
  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushinteger(L, WindowManager::getInstance().getMonitorCount());
    return 1;
  });
  lua_setfield(L, -2, "getMonitorCount");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    std::vector<Monitor> monitors = WindowManager::getInstance().getMonitors();
    lua_createtable(L, monitors.size(), 0);

    for (size_t i = 0; i < monitors.size(); ++i) {
      const Monitor &m = monitors[i];
      lua_createtable(L, 0, 10);

      lua_pushstring(L, m.name.c_str());
      lua_setfield(L, -2, "name");

      lua_pushinteger(L, m.width);
      lua_setfield(L, -2, "width");

      lua_pushinteger(L, m.height);
      lua_setfield(L, -2, "height");

      lua_pushinteger(L, m.x);
      lua_setfield(L, -2, "x");

      lua_pushinteger(L, m.y);
      lua_setfield(L, -2, "y");

      lua_pushnumber(L, m.dpiScale);
      lua_setfield(L, -2, "dpiScale");

      lua_pushnumber(L, m.refreshRate);
      lua_setfield(L, -2, "refreshRate");

      lua_pushboolean(L, m.isPrimary);
      lua_setfield(L, -2, "isPrimary");

      lua_rawseti(L, -2, i + 1);
    }

    return 1;
  });
  lua_setfield(L, -2, "getMonitors");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    size_t monitorIndex = luaL_checkinteger(L, 1) - 1; // Lua is 1-indexed
    bool success = WindowManager::getInstance().setMonitor(monitorIndex);
    lua_pushboolean(L, success);
    return 1;
  });
  lua_setfield(L, -2, "setMonitor");

  // VSync control
  lua_pushcfunction(L, [](lua_State *L) -> int {
    bool enabled = lua_toboolean(L, 1);
    WindowManager::getInstance().setVSync(enabled);
    return 0;
  });
  lua_setfield(L, -2, "setVSync");

  lua_pushcfunction(L, [](lua_State *L) -> int {
    lua_pushboolean(L, WindowManager::getInstance().isVSyncEnabled());
    return 1;
  });
  lua_setfield(L, -2, "isVSyncEnabled");

  // Set as global "Window" table
  lua_setglobal(L, "Window");

  LOG_INFO("WindowManager Lua bindings registered");
}
