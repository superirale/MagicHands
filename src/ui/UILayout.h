#pragma once

#include <string>
#include <unordered_map>
#include <utility>

class UILayout {
public:
  enum class Anchor {
    TopLeft,
    TopRight,
    BottomLeft,
    BottomRight,
    Center,
    TopCenter,
    BottomCenter
  };

  struct Region {
    std::string name;
    Anchor anchor;
    float x, y;
    float width, height;
    float offsetX, offsetY;
  };

  static UILayout &Instance();

  void Init();
  void SetScreenSize(int w, int h);
  void SetEdgePadding(int padding);

  void Register(const std::string &name, Anchor anchor, float w, float h,
                float offsetX = 0, float offsetY = 0);
  const Region *Get(const std::string &name) const;
  std::pair<float, float> GetPosition(const std::string &name) const;
  std::pair<float, float> Below(const std::string &name, float gap = 10) const;
  std::pair<float, float> RightOf(const std::string &name,
                                  float gap = 10) const;
  std::pair<float, float> Above(const std::string &name, float gap = 10) const;

  int GetScreenWidth() const { return m_ScreenWidth; }
  int GetScreenHeight() const { return m_ScreenHeight; }
  int GetEdgePadding() const { return m_EdgePadding; }
  size_t Count() const { return m_Regions.size(); }

  // Convert string to anchor enum
  static Anchor AnchorFromString(const std::string &str);

private:
  UILayout() = default;
  std::pair<float, float> CalculateAnchorPosition(Anchor anchor, float w,
                                                  float h) const;
  void RecalculateAllRegions();

  int m_ScreenWidth = 1280;
  int m_ScreenHeight = 720;
  int m_EdgePadding = 20;
  std::unordered_map<std::string, Region> m_Regions;
};
