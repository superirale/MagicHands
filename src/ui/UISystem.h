#pragma once

#include <string>
#include <unordered_map>
#include <vector>
#include <memory>

extern "C" {
#include <lua.h>
}

class SpriteRenderer;
class FontRenderer;

struct UIElement {
    std::string name;
    
    // Position
    float x = 0.0f;
    float y = 0.0f;
    float offsetX = 0.0f;
    float offsetY = 0.0f;
    
    // Size
    float width = 0.0f;
    float height = 0.0f;
    
    // Appearance
    float scale = 1.0f;
    int zOrder = 0;
    
    // Opacity/Fade
    float fadeOpacity = 1.0f;
    float fadeTarget = 1.0f;
    float fadeSpeed = 5.0f;
    
    // Graphics
    std::string graphic;
    int textureId = 0;
    
    // Text
    std::string font;
    float fontSize = 20.0f;
    float textRed = 1.0f;
    float textGreen = 1.0f;
    float textBlue = 1.0f;
    std::string text;
    int fontId = 0;
    
    // Hierarchy
    std::string attachTo;
    UIElement* parent = nullptr;
    std::vector<UIElement*> children;
    
    // Methods
    void GetWorldPosition(float& outX, float& outY) const;
    void Update(float dt);
    void Draw(SpriteRenderer* renderer, FontRenderer* fontRenderer);
};

class UISystem {
public:
    UISystem();
    ~UISystem();
    
    void Build(lua_State* L, SpriteRenderer* renderer, FontRenderer* fontRenderer);
    UIElement* Get(const std::string& name);
    void Update(float dt);
    void Draw(SpriteRenderer* renderer, FontRenderer* fontRenderer);
    
    void Show(const std::string& name, bool immediate = false);
    void Hide(const std::string& name, bool immediate = false);
    
private:
    std::unordered_map<std::string, std::unique_ptr<UIElement>> m_Elements;
    SpriteRenderer* m_Renderer = nullptr;
    FontRenderer* m_FontRenderer = nullptr;
    
    void ParseElement(lua_State* L, const std::string& name);
    void ResolveHierarchy();
    void LoadResources();
};
