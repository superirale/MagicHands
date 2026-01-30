#include "scripting/LuaBindings.h"
#include "asset/AssetManager.h"
#include "audio/AudioSystem.h"
#include "core/Color.h"
#include "core/Engine.h"
#include "core/JsonUtils.h"
#include "core/Logger.h"
#include "core/ObjectPool.h"
#include "core/Profiler.h"
#include "core/pch.h"
#include "graphics/Animation.h"
#include "graphics/FontRenderer.h"
#include "graphics/ParticleSystem.h"
#include "scripting/ProfilerBindings.h"
#include "ui/UILayout.h"
#include <fstream>

// Forward declaration for TileMap bindings
extern void RegisterTileMapBindings(lua_State *L);

// Forward declaration for Pathfinding bindings
extern void RegisterPathfindingBindings(lua_State *L);

// Forward declaration for Spatial Partitioning bindings
extern void RegisterSpatialBindings(lua_State *L);

// Forward declaration for Card bindings
extern void RegisterCardBindings(lua_State *L);

// Forward declaration for Cribbage bindings
extern void RegisterCribbageBindings(lua_State *L);

// Forward declaration for Joker bindings
extern void RegisterJokerBindings(lua_State *L);

// Forward declarations for Blind/Boss bindings
extern void RegisterBlindBindings(lua_State *L);
extern void RegisterBossBindings(lua_State *L);

// LuaSocket C-API
extern "C" {
int luaopen_socket_core(lua_State *L);
int luaopen_mime_core(lua_State *L);
}

// Accessors for Engine subsystems
#define g_Renderer Engine::Instance().Renderer()
#define g_UISystem Engine::Instance().UI()
#define g_Assets AssetManager::getInstance()

static ObjectPool<Animation> s_AnimationPool;

// Helper to parse color from Lua table
static Color ParseColor(lua_State *L, int index) {
  if (!lua_istable(L, index))
    return Color::White;

  Color c;
  lua_getfield(L, index, "r");
  c.r = (float)luaL_optnumber(L, -1, 1.0);
  lua_pop(L, 1);
  lua_getfield(L, index, "g");
  c.g = (float)luaL_optnumber(L, -1, 1.0);
  lua_pop(L, 1);
  lua_getfield(L, index, "b");
  c.b = (float)luaL_optnumber(L, -1, 1.0);
  lua_pop(L, 1);
  lua_getfield(L, index, "a");
  c.a = (float)luaL_optnumber(L, -1, 1.0);
  lua_pop(L, 1);
  return c;
}

// --- Graphics Bindings ---

int Lua_LoadTexture(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  int id = g_Renderer.LoadTexture(path);
  lua_pushinteger(L, id);
  return 1;
}

int Lua_GetTextureSize(lua_State *L) {
  int id = (int)luaL_checkinteger(L, 1);
  int w, h;
  g_Renderer.GetTextureSize(id, &w, &h);
  lua_pushinteger(L, w);
  lua_pushinteger(L, h);
  return 2;
}

int Lua_GetWindowSize(lua_State *L) {
  int w, h;
  g_Renderer.GetWindowSize(&w, &h);
  lua_pushinteger(L, w);
  lua_pushinteger(L, h);
  return 2;
}

int Lua_DrawSprite(lua_State *L) {
  int id = (int)luaL_checkinteger(L, 1);
  float x = (float)luaL_checknumber(L, 2);
  float y = (float)luaL_checknumber(L, 3);
  float w = (float)luaL_checknumber(L, 4);
  float h = (float)luaL_checknumber(L, 5);
  float rot = (float)luaL_optnumber(L, 6, 0.0f);
  Color tint = ParseColor(L, 7);
  bool screenSpace = lua_toboolean(L, 8);
  int zIndex = (int)luaL_optinteger(L, 9, 0);

  g_Renderer.DrawSprite(id, x, y, w, h, rot, false, false, tint, screenSpace,
                        zIndex);
  return 0;
}

int Lua_DrawSpriteRect(lua_State *L) {
  int id = (int)luaL_checkinteger(L, 1);
  float x = (float)luaL_checknumber(L, 2);
  float y = (float)luaL_checknumber(L, 3);
  float w = (float)luaL_checknumber(L, 4);
  float h = (float)luaL_checknumber(L, 5);
  float sx = (float)luaL_checknumber(L, 6);
  float sy = (float)luaL_checknumber(L, 7);
  float sw = (float)luaL_checknumber(L, 8);
  float sh = (float)luaL_checknumber(L, 9);

  // Get texture size for UV normalization
  int texWidth, texHeight;
  g_Renderer.GetTextureSize(id, &texWidth, &texHeight);

  // Normalize UV coordinates (shader expects 0.0-1.0 range, not pixels)
  // sw and sh are WIDTH and HEIGHT in pixels
  float u0 = sx / texWidth;
  float v0 = sy / texHeight;
  float uWidth = sw / texWidth;   // Normalized Width
  float vHeight = sh / texHeight; // Normalized Height

  // DrawSpriteRect expects (x, y, w, h, u0, v0, uWidth, vHeight, ...)
  g_Renderer.DrawSpriteRect(id, x, y, w, h, u0, v0, uWidth, vHeight, 0.0f,
                            false, false, Color::White, true,
                            0); // screenSpace=true for UI elements
  return 0;
}

int Lua_DrawUI(lua_State *L) {
  int id = (int)luaL_checkinteger(L, 1);
  float x = (float)luaL_checknumber(L, 2);
  float y = (float)luaL_checknumber(L, 3);
  float w = (float)luaL_checknumber(L, 4);
  float h = (float)luaL_checknumber(L, 5);
  float rot = (float)luaL_optnumber(L, 6, 0.0f);
  Color tint = ParseColor(L, 7);

  // Screen space = true
  g_Renderer.DrawSprite(id, x, y, w, h, rot, false, false, tint, true);
  return 0;
}

int Lua_DrawRect(lua_State *L) {
  float x = (float)luaL_checknumber(L, 1);
  float y = (float)luaL_checknumber(L, 2);
  float w = (float)luaL_checknumber(L, 3);
  float h = (float)luaL_checknumber(L, 4);
  Color color = ParseColor(L, 5);
  bool screenSpace = lua_toboolean(L, 6);

  g_Renderer.DrawSprite(g_Renderer.GetWhiteTexture(), x, y, w, h, 0.0f, false,
                        false, color, screenSpace);
  return 0;
}

int Lua_SetCamera(lua_State *L) {
  float x = (float)luaL_checknumber(L, 1);
  float y = (float)luaL_checknumber(L, 2);
  g_Renderer.SetCamera(x, y);
  return 0;
}

int Lua_SetViewport(lua_State *L) {
  float width = (float)luaL_checknumber(L, 1);
  float height = (float)luaL_checknumber(L, 2);
  g_Renderer.SetViewport(width, height);
  return 0;
}

int Lua_SetZoom(lua_State *L) {
  float zoom = (float)luaL_checknumber(L, 1);
  g_Renderer.SetZoom(zoom);
  return 0;
}

int Lua_ResetViewport(lua_State *L) {
  (void)L; // Unused parameter
  g_Renderer.ResetViewport();
  return 0;
}

int Lua_Flush(lua_State *L) {
  g_Renderer.Flush();
  return 0;
}

int Lua_SaveScreenshot(lua_State *L) {
  const char *filepath = luaL_checkstring(L, 1);
  bool success = g_Renderer.SaveScreenshot(filepath);
  lua_pushboolean(L, success);
  return 1;
}

// --- Shader Bindings ---

int Lua_LoadShader(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  const char *shaderPath = luaL_checkstring(L, 2);
  bool success = g_Renderer.LoadPostShader(name, shaderPath);
  lua_pushboolean(L, success);
  return 1;
}

int Lua_UnloadShader(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  g_Renderer.UnloadPostShader(name);
  return 0;
}

int Lua_SetShaderUniform(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  if (!lua_istable(L, 2)) {
    luaL_error(L,
               "SetShaderUniform expects table of numbers as second argument");
    return 0;
  }
  float uniforms[64];
  int count = 0;
  lua_pushnil(L);
  while (lua_next(L, 2) != 0 && count < 64) {
    uniforms[count++] = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);
  }
  g_Renderer.SetPostShaderUniform(name, uniforms, count * sizeof(float));
  return 0;
}

int Lua_EnableShader(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  bool enabled = lua_toboolean(L, 2);
  g_Renderer.EnableShader(name, enabled);
  return 0;
}

int Lua_ReloadShader(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  bool success = g_Renderer.ReloadPostShader(name);
  lua_pushboolean(L, success);
  return 1;
}

// --- UI System Bindings ---

int Lua_UIBuild(lua_State *L) {
  g_UISystem.Build(L, &g_Renderer, nullptr);
  return 0;
}

int Lua_UIGet(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  UIElement *element =
      g_UISystem.Get(name); // Included via Engine.h -> UISystem.h
  if (element) {
    lua_pushlightuserdata(L, element);
  } else {
    lua_pushnil(L);
  }
  return 1;
}

int Lua_UISetProperty(lua_State *L) {
  UIElement *element = (UIElement *)lua_touserdata(L, 1);
  const char *prop = luaL_checkstring(L, 2);
  if (!element)
    return 0;
  if (strcmp(prop, "Width") == 0 && lua_isnumber(L, 3)) {
    element->width = (float)lua_tonumber(L, 3);
  } else if (strcmp(prop, "text") == 0 && lua_isstring(L, 3)) {
    element->text = lua_tostring(L, 3);
  }
  return 0;
}

int Lua_UIUpdate(lua_State *L) {
  float dt = (float)luaL_checknumber(L, 1);
  g_UISystem.Update(dt);
  return 0;
}

int Lua_UIDraw(lua_State *L) {
  g_UISystem.Draw(&g_Renderer, nullptr);
  return 0;
}

int Lua_UIShow(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  bool immediate = lua_isboolean(L, 2) ? lua_toboolean(L, 2) : false;
  g_UISystem.Show(name, immediate);
  return 0;
}

int Lua_UIHide(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  bool immediate = lua_isboolean(L, 2) ? lua_toboolean(L, 2) : false;
  g_UISystem.Hide(name, immediate);
  return 0;
}

// --- UILayout Bindings ---

int Lua_LayoutInit(lua_State *L) {
  UILayout::Instance().Init();
  return 0;
}

int Lua_LayoutSetScreenSize(lua_State *L) {
  int w = (int)luaL_checkinteger(L, 1);
  int h = (int)luaL_checkinteger(L, 2);
  UILayout::Instance().SetScreenSize(w, h);
  return 0;
}

int Lua_LayoutRegister(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);

  // Second argument is a table with: anchor, width, height, offsetX, offsetY
  if (!lua_istable(L, 2)) {
    luaL_error(L, "layout.register expects a table as second argument");
    return 0;
  }

  // Get anchor string
  lua_getfield(L, 2, "anchor");
  const char *anchorStr =
      lua_isstring(L, -1) ? lua_tostring(L, -1) : "top-left";
  lua_pop(L, 1);

  // Get dimensions
  lua_getfield(L, 2, "width");
  float w = lua_isnumber(L, -1) ? (float)lua_tonumber(L, -1) : 100.0f;
  lua_pop(L, 1);

  lua_getfield(L, 2, "height");
  float h = lua_isnumber(L, -1) ? (float)lua_tonumber(L, -1) : 100.0f;
  lua_pop(L, 1);

  lua_getfield(L, 2, "offsetX");
  float offsetX = lua_isnumber(L, -1) ? (float)lua_tonumber(L, -1) : 0.0f;
  lua_pop(L, 1);

  lua_getfield(L, 2, "offsetY");
  float offsetY = lua_isnumber(L, -1) ? (float)lua_tonumber(L, -1) : 0.0f;
  lua_pop(L, 1);

  auto anchor = UILayout::AnchorFromString(anchorStr);
  UILayout::Instance().Register(name, anchor, w, h, offsetX, offsetY);
  return 0;
}

int Lua_LayoutGet(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  const UILayout::Region *region = UILayout::Instance().Get(name);

  if (region) {
    // Return a table with x, y, width, height
    lua_newtable(L);
    lua_pushnumber(L, region->x);
    lua_setfield(L, -2, "x");
    lua_pushnumber(L, region->y);
    lua_setfield(L, -2, "y");
    lua_pushnumber(L, region->width);
    lua_setfield(L, -2, "width");
    lua_pushnumber(L, region->height);
    lua_setfield(L, -2, "height");
    return 1;
  }

  lua_pushnil(L);
  return 1;
}

int Lua_LayoutGetPosition(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  auto [x, y] = UILayout::Instance().GetPosition(name);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  return 2;
}

int Lua_LayoutBelow(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  float gap = lua_isnumber(L, 2) ? (float)lua_tonumber(L, 2) : 10.0f;
  auto [x, y] = UILayout::Instance().Below(name, gap);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  return 2;
}

int Lua_LayoutRightOf(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  float gap = lua_isnumber(L, 2) ? (float)lua_tonumber(L, 2) : 10.0f;
  auto [x, y] = UILayout::Instance().RightOf(name, gap);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  return 2;
}

int Lua_LayoutAbove(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  float gap = lua_isnumber(L, 2) ? (float)lua_tonumber(L, 2) : 10.0f;
  auto [x, y] = UILayout::Instance().Above(name, gap);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  return 2;
}

int Lua_LayoutCount(lua_State *L) {
  lua_pushinteger(L, (int)UILayout::Instance().Count());
  return 1;
}

// --- Animation Bindings ---
static const char *ANIMATION_MT = "MagicHands.Animation";

static int Lua_AnimationGC(lua_State *L) {
  Animation **pAnim = (Animation **)luaL_checkudata(L, 1, ANIMATION_MT);
  if (pAnim && *pAnim) {
    s_AnimationPool.Release(*pAnim); // Releasing back to pool
    *pAnim = nullptr;
  }
  return 0;
}

int Lua_NewAnimation(lua_State *L) {
  int textureId = (int)luaL_checkinteger(L, 1);
  int frameW = (int)luaL_checkinteger(L, 2);
  int frameH = (int)luaL_checkinteger(L, 3);
  float duration = (float)luaL_checknumber(L, 4);
  int frameCount = (int)luaL_checkinteger(L, 5);

  Animation **pAnim = (Animation **)lua_newuserdata(L, sizeof(Animation *));
  // Acquire from pool
  *pAnim = s_AnimationPool.Acquire(textureId, frameW, frameH, duration,
                                   frameCount, &g_Renderer);

  luaL_getmetatable(L, ANIMATION_MT);
  lua_setmetatable(L, -2);
  return 1;
}

int Lua_AnimationUpdate(lua_State *L) {
  Animation **pAnim = (Animation **)luaL_checkudata(L, 1, ANIMATION_MT);
  float dt = (float)luaL_checknumber(L, 2);
  if (pAnim && *pAnim) {
    (*pAnim)->Update(dt);
  }
  return 0;
}

int Lua_AnimationDraw(lua_State *L) {
  Animation **pAnim = (Animation **)luaL_checkudata(L, 1, ANIMATION_MT);
  float x = (float)luaL_checknumber(L, 2);
  float y = (float)luaL_checknumber(L, 3);
  float w = (float)luaL_checknumber(L, 4);
  float h = (float)luaL_checknumber(L, 5);
  if (pAnim && *pAnim) {
    (*pAnim)->Draw(&g_Renderer, x, y, w, h, false);
  }
  return 0;
}

int Lua_AnimationSetRow(lua_State *L) {
  Animation **pAnim = (Animation **)luaL_checkudata(L, 1, ANIMATION_MT);
  int row = (int)luaL_checkinteger(L, 2);
  if (pAnim && *pAnim) {
    (*pAnim)->SetRow(row);
  }
  return 0;
}

// --- Assets Bindings ---

int Lua_LoadManifest(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  auto result = g_Assets.loadFromManifest(path);
  lua_pushinteger(L, (lua_Integer)result.loadedAssets);
  lua_pushinteger(L, (lua_Integer)result.totalAssets);
  return 2;
}

int Lua_GetTextureByName(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);

  // Check if asset exists in manifest
  if (!g_Assets.hasAsset(name)) {
    lua_pushinteger(L, 0); // Return 0 (invalid texture id)
    return 1;
  }

  // Get the texture path from alias
  auto texture = g_Assets.getTextureByName(name);
  if (!texture) {
    lua_pushinteger(L, 0);
    return 1;
  }

  // Load texture through SpriteRenderer (which caches by path)
  // The asset manager has the path in the alias
  std::string path = "content/images/" + std::string(name) + ".png";
  int id = g_Renderer.LoadTexture(path.c_str());
  lua_pushinteger(L, id);
  return 1;
}

int Lua_HasAsset(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  lua_pushboolean(L, g_Assets.hasAsset(name));
  return 1;
}

int Lua_SetLocale(lua_State *L) {
  const char *locale = luaL_checkstring(L, 1);
  g_Assets.setLocale(locale);
  return 0;
}

int Lua_AssetLoadFont(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  float size = (float)luaL_checknumber(L, 2);
  int fontId = g_Assets.loadFont(path, size);
  lua_pushinteger(L, fontId);
  return 1;
}

// --- Logger Bindings ---

void LuaBindings::Register(lua_State *L) {
  // Register Graphics
  lua_newtable(L);
  lua_pushcfunction(L, Lua_LoadTexture);
  lua_setfield(L, -2, "loadTexture");
  lua_pushcfunction(L, Lua_GetTextureSize);
  lua_setfield(L, -2, "getTextureSize");
  lua_pushcfunction(L, Lua_GetWindowSize);
  lua_setfield(L, -2, "getWindowSize");
  lua_pushcfunction(L, Lua_DrawSprite);
  lua_setfield(L, -2, "draw");
  lua_pushcfunction(L, Lua_DrawSpriteRect);
  lua_setfield(L, -2, "drawSub");
  lua_pushcfunction(L, Lua_DrawUI);
  lua_setfield(L, -2, "drawUI");
  lua_pushcfunction(L, Lua_SetCamera);
  lua_setfield(L, -2, "setCamera");
  lua_pushcfunction(L, Lua_SetViewport);
  lua_setfield(L, -2, "setViewport");
  lua_pushcfunction(L, Lua_SetZoom);
  lua_setfield(L, -2, "setZoom");
  lua_pushcfunction(L, Lua_ResetViewport);
  lua_setfield(L, -2, "resetViewport");
  lua_pushcfunction(L, Lua_DrawRect);
  lua_setfield(L, -2, "drawRect");
  lua_pushcfunction(L, Lua_LoadShader);
  lua_setfield(L, -2, "loadShader");
  lua_pushcfunction(L, Lua_UnloadShader);
  lua_setfield(L, -2, "unloadShader");
  lua_pushcfunction(L, Lua_SetShaderUniform);
  lua_setfield(L, -2, "setShaderUniform");
  lua_pushcfunction(L, Lua_EnableShader);
  lua_setfield(L, -2, "enableShader");
  lua_pushcfunction(L, Lua_ReloadShader);
  lua_setfield(L, -2, "reloadShader");
  lua_pushcfunction(L, Lua_Flush);
  lua_setfield(L, -2, "flush");
  lua_pushcfunction(L, Lua_SaveScreenshot);
  lua_setfield(L, -2, "saveScreenshot");
  lua_setglobal(L, "graphics");

  // Register FontRenderer bindings (adds to graphics table)
  FontRenderer::RegisterLua(L);

  // Register ParticleSystem bindings
  ParticleSystem::RegisterLua(L, &Engine::Instance().Particles());

  // Register AudioSystem bindings
  AudioSystem::RegisterLua(L);

  // Register UI
  lua_newtable(L);
  lua_pushcfunction(L, Lua_UIBuild);
  lua_setfield(L, -2, "build");
  lua_pushcfunction(L, Lua_UIGet);
  lua_setfield(L, -2, "get");
  lua_pushcfunction(L, Lua_UISetProperty);
  lua_setfield(L, -2, "setProp");
  lua_pushcfunction(L, Lua_UIUpdate);
  lua_setfield(L, -2, "update");
  lua_pushcfunction(L, Lua_UIDraw);
  lua_setfield(L, -2, "draw");
  lua_pushcfunction(L, Lua_UIShow);
  lua_setfield(L, -2, "show");
  lua_pushcfunction(L, Lua_UIHide);
  lua_setfield(L, -2, "hide");
  lua_setglobal(L, "ui");

  // Register Layout
  lua_newtable(L);
  lua_pushcfunction(L, Lua_LayoutInit);
  lua_setfield(L, -2, "init");
  lua_pushcfunction(L, Lua_LayoutSetScreenSize);
  lua_setfield(L, -2, "setScreenSize");
  lua_pushcfunction(L, Lua_LayoutRegister);
  lua_setfield(L, -2, "register");
  lua_pushcfunction(L, Lua_LayoutGet);
  lua_setfield(L, -2, "get");
  lua_pushcfunction(L, Lua_LayoutGetPosition);
  lua_setfield(L, -2, "getPosition");
  lua_pushcfunction(L, Lua_LayoutBelow);
  lua_setfield(L, -2, "below");
  lua_pushcfunction(L, Lua_LayoutRightOf);
  lua_setfield(L, -2, "rightOf");
  lua_pushcfunction(L, Lua_LayoutAbove);
  lua_setfield(L, -2, "above");
  lua_pushcfunction(L, Lua_LayoutCount);
  lua_setfield(L, -2, "count");
  lua_setglobal(L, "layout");

  // Register Animation
  luaL_newmetatable(L, ANIMATION_MT);
  lua_pushcfunction(L, Lua_AnimationGC);
  lua_setfield(L, -2, "__gc");
  lua_pop(L, 1);

  lua_newtable(L);
  lua_pushcfunction(L, Lua_NewAnimation);
  lua_setfield(L, -2, "new");
  lua_pushcfunction(L, Lua_AnimationUpdate);
  lua_setfield(L, -2, "update");
  lua_pushcfunction(L, Lua_AnimationDraw);
  lua_setfield(L, -2, "draw");
  lua_pushcfunction(L, Lua_AnimationSetRow);
  lua_setfield(L, -2, "setRow");
  lua_setglobal(L, "animation");

  // Register Assets
  lua_newtable(L);
  lua_pushcfunction(L, Lua_LoadManifest);
  lua_setfield(L, -2, "loadManifest");
  lua_pushcfunction(L, Lua_GetTextureByName);
  lua_setfield(L, -2, "getTexture");
  lua_pushcfunction(L, Lua_HasAsset);
  lua_setfield(L, -2, "hasAsset");
  lua_pushcfunction(L, Lua_SetLocale);
  lua_setfield(L, -2, "setLocale");
  lua_pushcfunction(L, Lua_AssetLoadFont);
  lua_setfield(L, -2, "loadFont");
  lua_setglobal(L, "assets");

  // Register TileMap bindings
  RegisterTileMapBindings(L);

  // Register Pathfinding bindings
  RegisterPathfindingBindings(L);

  // Register Spatial Partitioning bindings
  RegisterSpatialBindings(L);

  // Register Card bindings
  RegisterCardBindings(L);

  // Register Cribbage bindings
  RegisterCribbageBindings(L);

  // Register Joker bindings
  RegisterJokerBindings(L);

  // Register Blind/Boss bindings
  RegisterBlindBindings(L);
  RegisterBossBindings(L);

  // Register Logger bindings
  Logger::RegisterLuaBindings(L);

  // Register Profiler bindings
  RegisterProfilerBindings(L);

  // Register File I/O bindings
  RegisterJsonUtils(L);

  // Register LuaSocket (socket.core and mime.core)
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "preload");

  lua_pushcfunction(L, luaopen_socket_core);
  lua_setfield(L, -2, "socket.core");

  lua_pushcfunction(L, luaopen_mime_core);
  lua_setfield(L, -2, "mime.core");

  lua_pop(L, 2); // Pop 'preload' and 'package'
}
