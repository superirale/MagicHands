#pragma once

#include "core/Color.h"
#include "tilemap/ObjectLayer.h"
#include "tilemap/TileLayer.h"
#include "tilemap/TileSet.h"
#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

class SpriteRenderer;
class PhysicsSystem;

/**
 * Main tilemap class that manages map data and rendering.
 * Supports loading from Tiled JSON (.tmj) files.
 */
class TileMap {
public:
  TileMap() = default;
  ~TileMap() = default;

  // Disable copy (large resource)
  TileMap(const TileMap &) = delete;
  TileMap &operator=(const TileMap &) = delete;

  // Enable move
  TileMap(TileMap &&) = default;
  TileMap &operator=(TileMap &&) = default;

  /**
   * Load a tilemap from a Tiled JSON file
   */
  static std::unique_ptr<TileMap> load(const std::string &path);

  /**
   * Create an empty tilemap for procedural generation
   */
  static std::unique_ptr<TileMap> create(int width, int height, int tileWidth,
                                         int tileHeight);

  /**
   * Render the tilemap
   * @param renderer The sprite renderer to use
   * @param cameraX Camera X position
   * @param cameraY Camera Y position
   * @param viewportWidth Viewport width in pixels
   * @param viewportHeight Viewport height in pixels
   * @param ignoreCulling If true, render all tiles (for minimap)
   * @param scale Scale factor for rendering
   */
  void draw(SpriteRenderer &renderer, float cameraX, float cameraY,
            int viewportWidth, int viewportHeight, bool ignoreCulling = false,
            float scale = 1.0f);

  /**
   * Update map animations
   * @param dt Delta time in seconds
   */
  void update(float dt);

  // --- Map Properties ---

  int getWidth() const { return m_Width; }
  int getHeight() const { return m_Height; }
  int getTileWidth() const { return m_TileWidth; }
  int getTileHeight() const { return m_TileHeight; }

  /**
   * Get map dimensions in pixels
   */
  int getPixelWidth() const { return m_Width * m_TileWidth; }
  int getPixelHeight() const { return m_Height * m_TileHeight; }

  // --- Tile Queries ---

  /**
   * Get tile ID at position on a specific layer
   */
  int getTileId(int x, int y, const std::string &layerName) const;

  /**
   * Set tile ID at position on a specific layer
   */
  void setTileId(int x, int y, const std::string &layerName, int tileId);

  /**
   * Get a custom property from a tile
   */
  std::string getProperty(int x, int y, const std::string &propertyName) const;

  /**
   * Get a custom map-level property
   */
  std::string getMapProperty(const std::string &propertyName) const;

  // --- Layer Access ---

  TileLayer *getLayer(const std::string &name);
  const TileLayer *getLayer(const std::string &name) const;
  size_t getLayerCount() const { return m_TileLayers.size(); }

  void setLayerVisible(const std::string &name, bool visible);
  void setLayerTint(const std::string &name, const Color &tint);

  // --- Object Layer Access ---

  ObjectLayer *getObjectLayer(const std::string &name);
  const ObjectLayer *getObjectLayer(const std::string &name) const;

  /**
   * Get all objects from a named object layer
   */
  std::vector<const TiledObject *>
  getObjects(const std::string &layerName) const;

  /**
   * Get a specific object by name (searches all object layers)
   */
  const TiledObject *getObject(const std::string &name) const;

  /**
   * Get all objects of a specific type (searches all object layers)
   */
  std::vector<const TiledObject *>
  getObjectsByType(const std::string &type) const;

  // --- Tinting ---

  void setGlobalTint(const Color &tint) { m_GlobalTint = tint; }
  Color getGlobalTint() const { return m_GlobalTint; }

  // --- Collision ---

  /**
   * Create Box2D static bodies from a collision layer
   */
  void createCollisionBodies(PhysicsSystem &physics,
                             const std::string &layerName);

  /**
   * Create Box2D bodies from polygon objects in an object layer
   */
  void createCollisionBodiesFromObjectLayer(PhysicsSystem &physics,
                                            const std::string &layerName);

  // --- Modification Callbacks ---

  using TileChangedCallback = std::function<void(
      int x, int y, const std::string &layer, int oldTile, int newTile)>;

  void setOnTileChanged(TileChangedCallback callback) {
    m_OnTileChanged = std::move(callback);
  }

private:
  friend class TiledParser;

  /**
   * Find the tileset that contains a given tile GID
   */
  const TileSet *getTilesetForTile(int gid) const;

  int m_Width = 0;
  int m_Height = 0;
  int m_TileWidth = 0;
  int m_TileHeight = 0;

  std::vector<TileSet> m_Tilesets;
  std::vector<TileLayer> m_TileLayers;
  std::vector<ObjectLayer> m_ObjectLayers;

  // Map-level custom properties
  std::unordered_map<std::string, std::string> m_Properties;

  float m_AnimationTime = 0.0f;
  Color m_GlobalTint = Color::White;

  TileChangedCallback m_OnTileChanged;
};
