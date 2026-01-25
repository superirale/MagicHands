#include "ui/UILayout.h"
#include "core/Logger.h"

UILayout &UILayout::Instance() {
  static UILayout instance;
  return instance;
}

UILayout::Anchor UILayout::AnchorFromString(const std::string &str) {
  if (str == "top-left")
    return Anchor::TopLeft;
  if (str == "top-right")
    return Anchor::TopRight;
  if (str == "bottom-left")
    return Anchor::BottomLeft;
  if (str == "bottom-right")
    return Anchor::BottomRight;
  if (str == "center")
    return Anchor::Center;
  if (str == "top-center")
    return Anchor::TopCenter;
  if (str == "bottom-center")
    return Anchor::BottomCenter;
  return Anchor::TopLeft; // Default
}

std::pair<float, float>
UILayout::CalculateAnchorPosition(Anchor anchor, float w, float h) const {
  float padding = static_cast<float>(m_EdgePadding);
  float screenW = static_cast<float>(m_ScreenWidth);
  float screenH = static_cast<float>(m_ScreenHeight);

  switch (anchor) {
  case Anchor::TopLeft:
    return {padding, padding};
  case Anchor::TopRight:
    return {screenW - padding - w, padding};
  case Anchor::BottomLeft:
    return {padding, screenH - padding - h};
  case Anchor::BottomRight:
    return {screenW - padding - w, screenH - padding - h};
  case Anchor::Center:
    return {(screenW - w) / 2.0f, (screenH - h) / 2.0f};
  case Anchor::TopCenter:
    return {(screenW - w) / 2.0f, padding};
  case Anchor::BottomCenter:
    return {(screenW - w) / 2.0f, screenH - padding - h};
  default:
    return {padding, padding};
  }
}

void UILayout::Init() {
  m_Regions.clear();

  // Register default regions
  // Survival stats: top-left, 3 bars at 30px each = 90px total
  Register("SurvivalStats", Anchor::TopLeft, 200, 90);

  // Time UI: top-right
  Register("TimeUI", Anchor::TopRight, 120, 60);

  // Season UI: below time (top-right with offset)
  Register("SeasonUI", Anchor::TopRight, 150, 40, 0, 70);

  LOG_DEBUG("[UILayout] Initialized with %zu regions", m_Regions.size());
}

void UILayout::SetScreenSize(int w, int h) {
  m_ScreenWidth = w;
  m_ScreenHeight = h;
  RecalculateAllRegions();
}

void UILayout::SetEdgePadding(int padding) {
  m_EdgePadding = padding;
  RecalculateAllRegions();
}

void UILayout::RecalculateAllRegions() {
  for (auto &[name, region] : m_Regions) {
    auto [baseX, baseY] =
        CalculateAnchorPosition(region.anchor, region.width, region.height);
    region.x = baseX + region.offsetX;
    region.y = baseY + region.offsetY;
  }
}

void UILayout::Register(const std::string &name, Anchor anchor, float w,
                        float h, float offsetX, float offsetY) {
  auto [baseX, baseY] = CalculateAnchorPosition(anchor, w, h);

  Region region;
  region.name = name;
  region.anchor = anchor;
  region.width = w;
  region.height = h;
  region.offsetX = offsetX;
  region.offsetY = offsetY;
  region.x = baseX + offsetX;
  region.y = baseY + offsetY;

  m_Regions[name] = region;
}

const UILayout::Region *UILayout::Get(const std::string &name) const {
  auto it = m_Regions.find(name);
  if (it != m_Regions.end()) {
    return &it->second;
  }
  return nullptr;
}

std::pair<float, float> UILayout::GetPosition(const std::string &name) const {
  const Region *region = Get(name);
  if (region) {
    return {region->x, region->y};
  }
  return {0, 0};
}

std::pair<float, float> UILayout::Below(const std::string &name,
                                        float gap) const {
  const Region *region = Get(name);
  if (region) {
    return {region->x, region->y + region->height + gap};
  }
  return {static_cast<float>(m_EdgePadding), static_cast<float>(m_EdgePadding)};
}

std::pair<float, float> UILayout::RightOf(const std::string &name,
                                          float gap) const {
  const Region *region = Get(name);
  if (region) {
    return {region->x + region->width + gap, region->y};
  }
  return {static_cast<float>(m_EdgePadding), static_cast<float>(m_EdgePadding)};
}

std::pair<float, float> UILayout::Above(const std::string &name,
                                        float gap) const {
  const Region *region = Get(name);
  if (region) {
    return {region->x, region->y - gap};
  }
  return {static_cast<float>(m_EdgePadding), static_cast<float>(m_EdgePadding)};
}
