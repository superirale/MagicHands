#pragma once

#include "core/Color.h"
#include <nlohmann/json.hpp>
#include <string>
#include <vector>

/**
 * Represents a single tile layer in a Tiled map.
 * Stores tile data as a 2D grid of global tile IDs.
 */
class TileLayer {
public:
  /**
   * Layer type determines rendering behavior
   */
  enum class Type {
    Ground,   // Static, rendered first
    Fringe,   // Y-sorted with entities
    Overhang, // Always on top
    Collision // Invisible, collision only
  };

  TileLayer() = default;

  /**
   * Parse layer from Tiled JSON
   */
  bool loadFromJson(const nlohmann::json &json);

  /**
   * Get tile ID at position (0 = empty)
   */
  int getTileId(int x, int y) const;

  /**
   * Set tile ID at position
   */
  void setTileId(int x, int y, int tileId);

  /**
   * Get layer dimensions
   */
  int getWidth() const { return m_Width; }
  int getHeight() const { return m_Height; }

  /**
   * Get layer name
   */
  const std::string &getName() const { return m_Name; }

  /**
   * Get layer type (based on name prefix)
   */
  Type getType() const { return m_Type; }

  /**
   * Layer visibility
   */
  bool isVisible() const { return m_Visible; }
  void setVisible(bool visible) { m_Visible = visible; }

  /**
   * Layer tint color (multiplied with tile colors)
   */
  Color getTint() const { return m_Tint; }
  void setTint(const Color &tint) { m_Tint = tint; }

  /**
   * Layer opacity [0.0 - 1.0]
   */
  float getOpacity() const { return m_Opacity; }
  void setOpacity(float opacity) { m_Opacity = opacity; }

  /**
   * Layer offset (in pixels)
   */
  float getOffsetX() const { return m_OffsetX; }
  float getOffsetY() const { return m_OffsetY; }

  /**
   * Layer Z-Index for rendering depth
   */
  int getZIndex() const { return m_ZIndex; }
  void setZIndex(int zIndex) { m_ZIndex = zIndex; }

private:
  /**
   * Determine layer type from name prefix
   */
  Type parseTypeFromName(const std::string &name);

  std::string m_Name;
  Type m_Type = Type::Ground;

  int m_Width = 0;
  int m_Height = 0;
  std::vector<int> m_Data; // Row-major tile IDs

  bool m_Visible = true;
  Color m_Tint = Color::White;
  float m_Opacity = 1.0f;
  float m_OffsetX = 0.0f;
  float m_OffsetY = 0.0f;

  // Z-Index for Y-Sorting (-100=Ground, 0=Fringe, 100=Overhang)
  int m_ZIndex = 0;
};
