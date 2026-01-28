#include "graphics/FontRenderer.h"
#include "core/Color.h"
#include "core/Logger.h"
#include <fstream>

// Define implementation only here
#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"

SpriteRenderer *FontRenderer::s_Renderer = nullptr;
std::vector<FontRenderer::FontData> FontRenderer::s_Fonts;

bool FontRenderer::Init(SpriteRenderer *renderer) {
  s_Renderer = renderer;
  return true;
}

void FontRenderer::Destroy() { s_Fonts.clear(); }

int FontRenderer::LoadFont(const char *path, float size) {
  std::ifstream file(path, std::ios::binary | std::ios::ate);
  if (!file.is_open()) {
    LOG_ERROR("Failed to open font: %s", path);
    return -1;
  }

  std::streamsize ttf_size = file.tellg();
  file.seekg(0, std::ios::beg);

  std::vector<unsigned char> ttf_buffer(ttf_size);
  if (!file.read((char *)ttf_buffer.data(), ttf_size)) {
    LOG_ERROR("Failed to read font file!");
    return -1;
  }
  LOG_DEBUG("Read Font File: %s Size: %td bytes.", path, ttf_size);

  // Bake Bitmap
  const int BMP_W = 1024;
  const int BMP_H = 1024;
  std::vector<unsigned char> temp_bitmap(BMP_W * BMP_H);

  FontData fontData;
  fontData.size = size;
  fontData.width = BMP_W;
  fontData.height = BMP_H;

  // Bake standard ASCII
  int res = stbtt_BakeFontBitmap(ttf_buffer.data(), 0, size, temp_bitmap.data(),
                                 BMP_W, BMP_H, 32, 96, fontData.cdata);
  if (res <= 0) {
    LOG_ERROR("Failed to bake font bitmap! Return: %d", res);
    return -1;
  }
  LOG_DEBUG("Font baked successfully. Rows used: %d", -res);

  // Convert 1-channel bitmap to 4-channel RGBA for our Renderer
  std::vector<unsigned char> rgba_bitmap(BMP_W * BMP_H * 4);
  for (int i = 0; i < BMP_W * BMP_H; i++) {
    unsigned char val = temp_bitmap[i];
    rgba_bitmap[i * 4 + 0] = 255;
    rgba_bitmap[i * 4 + 1] = 255;
    rgba_bitmap[i * 4 + 2] = 255;
    // Text alpha comes from the bake
    // But if val > 0 it is visible.
    // We want White Text with transparency.
    rgba_bitmap[i * 4 + 3] = val;
  }

  int textureId =
      s_Renderer->LoadTextureFromMemory(rgba_bitmap.data(), BMP_W, BMP_H);
  fontData.textureId = textureId;
  LOG_INFO("Font Loaded. Path: %s Size: %.1f TextureID: %d", path, size,
           textureId);

  s_Fonts.push_back(fontData);
  return (int)s_Fonts.size() - 1;
}

void FontRenderer::DrawText(int fontId, const char *text, float x, float y,
                            const Color &color) {
  if (fontId < 0 || fontId >= s_Fonts.size()) {
    // std::cerr << "Invalid Font ID: " << fontId << std::endl;
    return;
  }

  FontData &font = s_Fonts[fontId];

  // Iterate string
  while (*text) {
    unsigned char c = (unsigned char)*text;
    if (c >= 32 && c < 128) {
      stbtt_aligned_quad q;
      // Use 0 for 'opengl_fillrule' to assume Y increases downwards (Top-Left
      // origin)
      stbtt_GetBakedQuad(font.cdata, font.width, font.height, c - 32, &x, &y,
                         &q, 0);

      // Draw Quad
      float w = q.x1 - q.x0;
      float h = q.y1 - q.y0;

      s_Renderer->DrawSpriteRect(font.textureId, q.x0, q.y0, w, h, q.s0, q.t0,
                                 q.s1 - q.s0, q.t1 - q.t0, 0.0f, false, false,
                                 color, true);
    }
    text++;
  }
}

void FontRenderer::GetTextSize(int fontId, const char *text, float *width,
                               float *height, float *baselineOffset) {
  if (fontId < 0 || fontId >= s_Fonts.size()) {
    if (width)
      *width = 0.0f;
    if (height)
      *height = 0.0f;
    if (baselineOffset)
      *baselineOffset = 0.0f;
    return;
  }

  FontData &font = s_Fonts[fontId];

  float x = 0.0f;
  float y = 0.0f;
  float minY = 0.0f;
  float maxY = 0.0f;

  // Iterate string to measure bounds
  while (*text) {
    unsigned char c = (unsigned char)*text;
    if (c >= 32 && c < 128) {
      stbtt_aligned_quad q;
      stbtt_GetBakedQuad(font.cdata, font.width, font.height, c - 32, &x, &y,
                         &q, 0);

      // Track vertical bounds
      if (q.y0 < minY)
        minY = q.y0;
      if (q.y1 > maxY)
        maxY = q.y1;
    }
    text++;
  }

  if (width)
    *width = x;
  if (height)
    *height = maxY - minY;
  // Baseline offset is the distance from top of bounding box to baseline (y=0)
  // Since minY is typically negative, -minY gives us the offset from top to baseline
  if (baselineOffset)
    *baselineOffset = -minY;
}

int FontRenderer::Lua_LoadFont(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  float size = (float)luaL_checknumber(L, 2);
  int id = LoadFont(path, size);
  lua_pushinteger(L, id);
  return 1;
}

int FontRenderer::Lua_DrawText(lua_State *L) {
  int id = (int)luaL_checkinteger(L, 1);
  const char *text = luaL_checkstring(L, 2);
  float x = (float)luaL_checknumber(L, 3);
  float y = (float)luaL_checknumber(L, 4);

  Color color = Color::White;
  if (lua_gettop(L) >= 5 && lua_istable(L, 5)) {
    lua_getfield(L, 5, "r");
    color.r = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, 5, "g");
    color.g = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, 5, "b");
    color.b = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, 5, "a");
    if (!lua_isnil(L, -1)) {
      color.a = (float)lua_tonumber(L, -1);
    }
    lua_pop(L, 1);
  }

  DrawText(id, text, x, y, color);
  return 0;
}

int FontRenderer::Lua_GetTextSize(lua_State *L) {
  int id = (int)luaL_checkinteger(L, 1);
  const char *text = luaL_checkstring(L, 2);

  float width = 0.0f;
  float height = 0.0f;
  float baselineOffset = 0.0f;
  GetTextSize(id, text, &width, &height, &baselineOffset);

  lua_pushnumber(L, width);
  lua_pushnumber(L, height);
  lua_pushnumber(L, baselineOffset);
  return 3;
}

void FontRenderer::RegisterLua(lua_State *L) {
  // We can add to existing graphics table or new font table?
  // Let's add 'loadFont' and 'print' to 'graphics' table in main.cpp logic or
  // here? The previous pattern was main.cpp does the registration block. But
  // here we have a RegisterLua function. Let's attach to global "graphics".

  lua_getglobal(L, "graphics");
  if (lua_istable(L, -1)) {
    lua_pushcfunction(L, Lua_LoadFont);
    lua_setfield(L, -2, "loadFont");
    lua_pushcfunction(L, Lua_DrawText);
    lua_setfield(L, -2, "print");
    lua_pushcfunction(L, Lua_GetTextSize);
    lua_setfield(L, -2, "getTextSize");
  }
  lua_pop(L, 1);
}
