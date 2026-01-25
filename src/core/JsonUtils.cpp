#include "core/JsonUtils.h"
#include "core/Logger.h"
#include <fstream>
#include <sstream>
#include <sys/stat.h>
#include <vector>

void RegisterJsonUtils(lua_State *L) {
  lua_register(L, "loadJSON", Lua_LoadJSON);
  lua_register(L, "saveFile", Lua_SaveFile); // Phase 5: File I/O
  lua_register(L, "loadFile", Lua_LoadFile); // Phase 5: File I/O
}

int Lua_LoadJSON(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  std::ifstream file(path);
  if (!file.is_open()) {
    LOG_ERROR("Failed to open JSON file: %s", path);
    lua_pushnil(L);
    return 1;
  }

  std::string content((std::istreambuf_iterator<char>(file)),
                      std::istreambuf_iterator<char>());
  file.close();

  // Parse JSON using nlohmann::json
  try {
    nlohmann::json j = nlohmann::json::parse(content);
    PushJSON(L, j);
    return 1;
  } catch (const nlohmann::json::parse_error &e) {
    LOG_ERROR("JSON parse error in %s: %s", path, e.what());
    lua_pushnil(L);
    return 1;
  }
}

// Phase 5: Save string to file
int Lua_SaveFile(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  const char *content = luaL_checkstring(L, 2);

  // Create directory if needed
  std::string pathStr(path);
  size_t lastSlash = pathStr.find_last_of("/");
  if (lastSlash != std::string::npos) {
    std::string dir = pathStr.substr(0, lastSlash);
    mkdir(dir.c_str(), 0755); // Create directory
  }

  std::ofstream file(path);
  if (file.is_open()) {
    file << content;
    file.close();
    lua_pushboolean(L, true);
    LOG_DEBUG("Saved file: %s", path);
  } else {
    lua_pushboolean(L, false);
    LOG_ERROR("Failed to save file: %s", path);
  }
  return 1;
}

// Phase 5: Load file as string
int Lua_LoadFile(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);

  std::ifstream file(path);
  if (file.is_open()) {
    std::string content((std::istreambuf_iterator<char>(file)),
                        std::istreambuf_iterator<char>());
    file.close();
    lua_pushstring(L, content.c_str());
  } else {
    lua_pushnil(L);
  }
  return 1;
}

// Helper to push JSON to Lua table (kept for loadJSON compatibility)
void PushJSON(lua_State *L, const nlohmann::json &j) {
  if (j.is_null()) {
    lua_pushnil(L);
  } else if (j.is_boolean()) {
    lua_pushboolean(L, j.get<bool>());
  } else if (j.is_number_integer()) {
    lua_pushinteger(L, j.get<int>());
  } else if (j.is_number_float()) {
    lua_pushnumber(L, j.get<double>());
  } else if (j.is_string()) {
    lua_pushstring(L, j.get<std::string>().c_str());
  } else if (j.is_array()) {
    lua_newtable(L);
    for (size_t i = 0; i < j.size(); ++i) {
      PushJSON(L, j[i]);
      lua_rawseti(L, -2, i + 1); // Lua is 1-indexed
    }
  } else if (j.is_object()) {
    lua_newtable(L);
    for (auto &el : j.items()) {
      lua_pushstring(L, el.key().c_str());
      PushJSON(L, el.value());
      lua_settable(L, -3);
    }
  }
}
