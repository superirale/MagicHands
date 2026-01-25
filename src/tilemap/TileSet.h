#pragma once

#include "core/Color.h"
#include <nlohmann/json.hpp>
#include <string>
#include <unordered_map>
#include <vector>

struct TileRect {
  float u, v, w, h; // Normalized UV coordinates
};

struct TileAnimation {
  struct Frame {
    int tileId;
    int duration; // milliseconds
  };
  std::vector<Frame> frames;
};

/**
 * Represents a Tiled tileset.
 * Handles texture loading (via texture ID from SpriteRenderer),
 * UV coordinate calculation, and tile property access.
 */
class TileSet {
public:
  TileSet() = default;

  /**
   * Parse tileset from Tiled JSON (either embedded or external .tsj)
   */
  bool loadFromJson(const nlohmann::json &json, const std::string &basePath);

  /**
   * Get the first GID (Global ID) of this tileset
   */
  int getFirstGid() const { return m_FirstGid; }

  /**
   * Get the last valid GID for this tileset
   */
  int getLastGid() const { return m_FirstGid + m_TileCount - 1; }

  /**
   * Check if a global tile ID belongs to this tileset
   */
  bool containsTile(int gid) const {
    return gid >= m_FirstGid && gid <= getLastGid();
  }

  /**
   * Get UV coordinates for a tile (by global ID)
   * Returns normalized coordinates [0-1]
   */
  TileRect getUV(int gid) const;

  /**
   * Get the texture ID (from SpriteRenderer) for this tileset
   */
  int getTextureId() const { return m_TextureId; }

  /**
   * Get tile dimensions
   */
  int getTileWidth() const { return m_TileWidth; }
  int getTileHeight() const { return m_TileHeight; }

  /**
   * Get a custom property from a specific tile
   * Returns empty string if not found
   */
  std::string getTileProperty(int gid, const std::string &propertyName) const;

  /**
   * Check if a tile has a specific property
   */
  bool hasTileProperty(int gid, const std::string &propertyName) const;

  /**
   * Get tile animation data (if exists)
   */
  const TileAnimation *getTileAnimation(int gid) const;

  /**
   * Get tileset name
   */
  const std::string &getName() const { return m_Name; }

private:
  std::string m_Name;
  std::string m_ImagePath;
  int m_TextureId = 0;

  int m_FirstGid = 1;
  int m_TileWidth = 0;
  int m_TileHeight = 0;
  int m_TileCount = 0;
  int m_Columns = 0;

  int m_ImageWidth = 0;
  int m_ImageHeight = 0;
  int m_Margin = 0;
  int m_Spacing = 0;

  // Tile properties: localTileId -> (propertyName -> value)
  std::unordered_map<int, std::unordered_map<std::string, std::string>>
      m_TileProperties;

  // Tile animations: localTileId -> animation
  std::unordered_map<int, TileAnimation> m_TileAnimations;
};
