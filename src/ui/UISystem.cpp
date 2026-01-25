#include "ui/UISystem.h"
#include "graphics/FontRenderer.h"
#include "core/Logger.h"
#include "graphics/SpriteRenderer.h"
#include <algorithm>

extern "C" {
#include <lauxlib.h>
}

// UIElement Methods
void UIElement::GetWorldPosition(float &outX, float &outY) const {
  outX = x + offsetX;
  outY = y + offsetY;

  if (parent) {
    float px, py;
    parent->GetWorldPosition(px, py);
    outX = px + offsetX;
    outY = py + offsetY;
  }
}

void UIElement::Update(float dt) {
  // Fade animation
  if (fadeOpacity != fadeTarget) {
    float diff = fadeTarget - fadeOpacity;
    fadeOpacity += diff * fadeSpeed * dt;
    if (std::abs(diff) < 0.01f) {
      fadeOpacity = fadeTarget;
    }
  }

  // Update children
  for (auto *child : children) {
    child->Update(dt);
  }
}

void UIElement::Draw(SpriteRenderer *renderer, FontRenderer *fontRenderer) {
  if (fadeOpacity <= 0.0f)
    return;

  float wx, wy;
  GetWorldPosition(wx, wy);

  // Draw graphic (in screen space for UI)
  if (textureId > 0 && renderer) {
    float w = width > 0 ? width : 32.0f;
    float h = height > 0 ? height : 32.0f;
    // Use DrawSprite with all parameters: rotation=0, flipX=false, flipY=false,
    // tint=White, screenSpace=true
    renderer->DrawSprite(textureId, wx, wy, w * scale, h * scale, 0.0f, false,
                         false, Color::White, true);
  }

  // Draw text (use static FontRenderer)
  if (!text.empty() && fontId > 0) {
    FontRenderer::DrawText(fontId, text.c_str(), (int)wx, (int)wy);
  }

  // Draw children
  for (auto *child : children) {
    child->Draw(renderer, fontRenderer);
  }
}

// UISystem Methods
UISystem::UISystem() {}

UISystem::~UISystem() {}

void UISystem::Build(lua_State *L, SpriteRenderer *renderer,
                     FontRenderer *fontRenderer) {
  m_Renderer = renderer;
  m_FontRenderer = fontRenderer;
  m_Elements.clear();

  // Get UIDefinitions global table
  lua_getglobal(L, "UIDefinitions");
  if (!lua_istable(L, -1)) {
    LOG_ERROR("UIDefinitions is not a table!");
    lua_pop(L, 1);
    return;
  }

  // Iterate over UIDefinitions
  lua_pushnil(L);
  while (lua_next(L, -2) != 0) {
    if (lua_isstring(L, -2)) {
      std::string name = lua_tostring(L, -2);
      ParseElement(L, name);
    }
    lua_pop(L, 1); // Pop value, keep key
  }

  lua_pop(L, 1); // Pop UIDefinitions

  ResolveHierarchy();
  LoadResources();
}

void UISystem::ParseElement(lua_State *L, const std::string &name) {
  if (!lua_istable(L, -1))
    return;

  auto element = std::make_unique<UIElement>();
  element->name = name;

  // Helper lambda to get number field
  auto getNumber = [&](const char *key, float &out) {
    lua_getfield(L, -1, key);
    if (lua_isnumber(L, -1)) {
      out = (float)lua_tonumber(L, -1);
    }
    lua_pop(L, 1);
  };

  // Helper lambda to get string field
  auto getString = [&](const char *key, std::string &out) {
    lua_getfield(L, -1, key);
    if (lua_isstring(L, -1)) {
      out = lua_tostring(L, -1);
    }
    lua_pop(L, 1);
  };

  // Parse all properties
  getNumber("X", element->x);
  getNumber("Y", element->y);
  getNumber("OffsetX", element->offsetX);
  getNumber("OffsetY", element->offsetY);
  getNumber("Width", element->width);
  getNumber("Height", element->height);
  getNumber("Scale", element->scale);
  getNumber("ZOrder", (float &)element->zOrder);
  getNumber("FadeOpacity", element->fadeOpacity);
  getNumber("FadeTarget", element->fadeTarget);
  getNumber("FadeSpeed", element->fadeSpeed);
  getNumber("FontSize", element->fontSize);
  getNumber("TextRed", element->textRed);
  getNumber("TextGreen", element->textGreen);
  getNumber("TextBlue", element->textBlue);

  getString("Graphic", element->graphic);
  getString("Font", element->font);
  getString("Text", element->text);
  getString("AttachTo", element->attachTo);

  // Handle InheritFrom - copy parent properties first, then override
  std::string inheritFrom;
  getString("InheritFrom", inheritFrom);
  if (!inheritFrom.empty() && m_Elements.count(inheritFrom)) {
    // Copy properties from parent
    auto &parent = *m_Elements[inheritFrom];
    element->x = parent.x;
    element->y = parent.y;
    element->width = parent.width;
    element->height = parent.height;
    element->graphic = parent.graphic;
    element->font = parent.font;
    element->fontSize = parent.fontSize;
    element->zOrder = parent.zOrder;

    // Now re-parse this element to override inherited values
    getNumber("X", element->x);
    getNumber("Y", element->y);
    getNumber("Width", element->width);
    getNumber("Height", element->height);
    getNumber("ZOrder", (float &)element->zOrder);
    getString("Graphic", element->graphic);
    getString("Font", element->font);
    getNumber("FontSize", element->fontSize);
  }

  m_Elements[name] = std::move(element);
}

void UISystem::ResolveHierarchy() {
  for (auto &[name, element] : m_Elements) {
    if (!element->attachTo.empty() && m_Elements.count(element->attachTo)) {
      auto &parent = m_Elements[element->attachTo];
      element->parent = parent.get();
      parent->children.push_back(element.get());
    }
  }
}

void UISystem::LoadResources() {
  for (auto &[name, element] : m_Elements) {
    // Load texture
    if (!element->graphic.empty() && m_Renderer) {
      std::string path = "content/images/" + element->graphic + ".png";
      element->textureId = m_Renderer->LoadTexture(path.c_str());
    }

    // Load font (use static FontRenderer)
    if (!element->font.empty()) {
      element->fontId =
          FontRenderer::LoadFont(element->font.c_str(), element->fontSize);
    }
  }
}

UIElement *UISystem::Get(const std::string &name) {
  auto it = m_Elements.find(name);
  if (it != m_Elements.end()) {
    return it->second.get();
  }
  return nullptr;
}

void UISystem::Update(float dt) {
  for (auto &[name, element] : m_Elements) {
    if (!element->parent) {
      element->Update(dt);
    }
  }
}

void UISystem::Draw(SpriteRenderer *renderer, FontRenderer *fontRenderer) {
  // Sort elements by ZOrder
  std::vector<UIElement *> sorted;
  for (auto &[name, element] : m_Elements) {
    sorted.push_back(element.get());
  }
  std::sort(sorted.begin(), sorted.end(),
            [](UIElement *a, UIElement *b) { return a->zOrder < b->zOrder; });

  // Draw sorted
  for (auto *element : sorted) {
    element->Draw(renderer, fontRenderer);
  }
}

void UISystem::Show(const std::string &name, bool immediate) {
  auto *element = Get(name);
  if (element) {
    element->fadeTarget = 1.0f;
    if (immediate) {
      element->fadeOpacity = 1.0f;
    }
  }
}

void UISystem::Hide(const std::string &name, bool immediate) {
  auto *element = Get(name);
  if (element) {
    element->fadeTarget = 0.0f;
    if (immediate) {
      element->fadeOpacity = 0.0f;
    }
  }
}
