#pragma once
#include "core/Color.h"
#include "graphics/SpriteRenderer.h"
#include "stb_truetype.h"
#include <SDL3/SDL.h>
#include <lua.hpp>
#include <string>
#include <vector>

// We need stb_truetype.h available. Since using FetchContent, it should be in
// search path.

class FontRenderer {
public:
  static bool Init(SpriteRenderer *renderer);
  static void Destroy();

  // Loads a TTF from path, bakes a specific size (pixels)
  // Returns a "FontID" (index into internal list)
  static int LoadFont(const char *path, float size);

  static void DrawText(int fontId, const char *text, float x, float y,
                       const Color &color = Color::White);

  // Lua Bindings
  static int Lua_LoadFont(lua_State *L);
  static int Lua_DrawText(lua_State *L);
  static void RegisterLua(lua_State *L);

private:
  struct FontData {
    int textureId;
    stbtt_bakedchar cdata[96]; // ASCII 32..126
    float size;
    int width;
    int height;
  };

  static SpriteRenderer *s_Renderer;
  static std::vector<FontData> s_Fonts;
};
