#include "tilemap/TileMap.h"
#include "core/Logger.h"
#include "graphics/SpriteRenderer.h"
#include "physics/PhysicsSystem.h"
#include <algorithm>
#include <fstream>

std::unique_ptr<TileMap> TileMap::load(const std::string &path) {
  std::ifstream file(path);
  if (!file.is_open()) {
    LOG_ERROR("Failed to open tilemap file: %s", path.c_str());
    return nullptr;
  }

  nlohmann::json json;
  try {
    file >> json;
  } catch (const std::exception &e) {
    LOG_ERROR("Failed to parse tilemap JSON: %s", e.what());
    return nullptr;
  }

  auto map = std::make_unique<TileMap>();

  // Parse map dimensions
  map->m_Width = json["width"].get<int>();
  map->m_Height = json["height"].get<int>();
  map->m_TileWidth = json["tilewidth"].get<int>();
  map->m_TileHeight = json["tileheight"].get<int>();

  // Get base path for relative asset paths
  std::string basePath = path.substr(0, path.find_last_of("/\\"));

  // Parse map properties
  if (json.contains("properties")) {
    for (const auto &prop : json["properties"]) {
      std::string name = prop["name"].get<std::string>();
      std::string value;
      if (prop["type"] == "string") {
        value = prop["value"].get<std::string>();
      } else if (prop["type"] == "bool") {
        value = prop["value"].get<bool>() ? "true" : "false";
      } else if (prop["type"] == "int") {
        value = std::to_string(prop["value"].get<int>());
      } else if (prop["type"] == "float") {
        value = std::to_string(prop["value"].get<float>());
      } else {
        value = prop["value"].dump();
      }
      map->m_Properties[name] = value;
    }
  }

  // Parse tilesets
  if (json.contains("tilesets")) {
    for (const auto &tsJson : json["tilesets"]) {
      TileSet tileset;
      if (tileset.loadFromJson(tsJson, basePath)) {
        map->m_Tilesets.push_back(std::move(tileset));
      }
    }
  }

  // Sort tilesets by firstGid (descending) for efficient lookup
  std::sort(map->m_Tilesets.begin(), map->m_Tilesets.end(),
            [](const TileSet &a, const TileSet &b) {
              return a.getFirstGid() > b.getFirstGid();
            });

  // Parse layers
  if (json.contains("layers")) {
    for (const auto &layerJson : json["layers"]) {
      std::string layerType = layerJson["type"].get<std::string>();

      if (layerType == "tilelayer") {
        TileLayer layer;
        if (layer.loadFromJson(layerJson)) {
          map->m_TileLayers.push_back(std::move(layer));
        }
      } else if (layerType == "objectgroup") {
        ObjectLayer objLayer;
        if (objLayer.loadFromJson(layerJson)) {
          map->m_ObjectLayers.push_back(std::move(objLayer));
        }
      }
      // Note: "group" layers could be handled recursively if needed
    }
  }

  LOG_INFO("Loaded tilemap '%s': %dx%d tiles (Tile Size: %dx%d)", path.c_str(),
           map->m_Width, map->m_Height, map->m_TileWidth, map->m_TileHeight);

  if (!map->m_Properties.empty()) {
    LOG_INFO("Map Properties:");
    for (const auto &[key, value] : map->m_Properties) {
      LOG_INFO("  %s: %s", key.c_str(), value.c_str());
    }
  }

  LOG_INFO("Tilesets: %zu", map->m_Tilesets.size());
  LOG_INFO("Layers: %zu", map->m_TileLayers.size());
  for (const auto &layer : map->m_TileLayers) {
    LOG_INFO("  Layer '%s': %dx%d", layer.getName().c_str(), layer.getWidth(),
             layer.getHeight());
  }
  LOG_INFO("Object Layers: %zu", map->m_ObjectLayers.size());

  return map;
}

std::unique_ptr<TileMap> TileMap::create(int width, int height, int tileWidth,
                                         int tileHeight) {
  auto map = std::make_unique<TileMap>();
  map->m_Width = width;
  map->m_Height = height;
  map->m_TileWidth = tileWidth;
  map->m_TileHeight = tileHeight;

  LOG_INFO("Created empty tilemap: %dx%d tiles (%dx%d pixels)", width, height,
           width * tileWidth, height * tileHeight);
  return map;
}

void TileMap::draw(SpriteRenderer &renderer, float cameraX, float cameraY,
                   int viewportWidth, int viewportHeight, bool ignoreCulling,
                   float scale) {
  // Calculate visible tile range with buffer
  int startX, startY, endX, endY;

  if (ignoreCulling) {
    startX = 0;
    startY = 0;
    endX = m_Width;
    endY = m_Height;
  } else {
    startX = std::max(0, static_cast<int>(cameraX / m_TileWidth) - 1);
    startY = std::max(0, static_cast<int>(cameraY / m_TileHeight) - 1);
    endX = std::min(m_Width, startX + (viewportWidth / m_TileWidth) + 3);
    endY = std::min(m_Height, startY + (viewportHeight / m_TileHeight) + 3);
  }

  // Render layers in order: Ground -> Fringe -> Overhang
  // Collision layers are skipped (invisible)
  for (const auto &layer : m_TileLayers) {
    if (!layer.isVisible()) {
      continue;
    }
    if (layer.getType() == TileLayer::Type::Collision) {
      continue; // Don't render collision layers
    }

    // Calculate combined tint
    Color layerTint = layer.getTint();
    Color combinedTint(m_GlobalTint.r * layerTint.r,
                       m_GlobalTint.g * layerTint.g,
                       m_GlobalTint.b * layerTint.b,
                       m_GlobalTint.a * layerTint.a * layer.getOpacity());

    for (int y = startY; y < endY; ++y) {
      for (int x = startX; x < endX; ++x) {
        int tileId = layer.getTileId(x, y);
        if (tileId == 0) {
          continue; // Empty tile
        }

        // Handle tile flipping flags (Tiled stores these in high bits)
        const uint32_t FLIPPED_H = 0x80000000;
        const uint32_t FLIPPED_V = 0x40000000;
        const uint32_t FLIPPED_D = 0x20000000; // Diagonal flip
        const uint32_t FLIP_MASK = FLIPPED_H | FLIPPED_V | FLIPPED_D;

        bool flipX = (tileId & FLIPPED_H) != 0;
        bool flipY = (tileId & FLIPPED_V) != 0;
        // Note: Diagonal flip is more complex, ignored for now
        tileId &= ~FLIP_MASK;

        const TileSet *tileset = getTilesetForTile(tileId);
        if (!tileset) {
          continue;
        }

        // Handle Animation
        const TileAnimation *anim = tileset->getTileAnimation(tileId);
        if (anim && !anim->frames.empty()) {
          int totalDuration = 0;
          for (const auto &frame : anim->frames) {
            totalDuration += frame.duration;
          }

          if (totalDuration > 0) {
            int time =
                static_cast<int>(m_AnimationTime * 1000.0f) % totalDuration;
            for (const auto &frame : anim->frames) {
              time -= frame.duration;
              if (time < 0) {
                tileId = frame.tileId;
                break;
              }
            }

            // If the new tileId is in a different tileset (rare but possible),
            // we might need to find the new tileset.
            // However, Tiled animation frames are usually within the same
            // tileset. We'll assume it is, but check if we need to re-fetch UVs
            // from a different tileset
            if (!tileset->containsTile(tileId)) {
              tileset = getTilesetForTile(tileId);
            }
          }
        }

        if (!tileset)
          continue;

        TileRect uv = tileset->getUV(tileId);

        float drawX = (x * m_TileWidth + layer.getOffsetX()) * scale;
        float drawY = (y * m_TileHeight + layer.getOffsetY()) * scale;
        float drawW = m_TileWidth * scale;
        float drawH = m_TileHeight * scale;

        renderer.DrawSpriteRect(tileset->getTextureId(), drawX, drawY, drawW,
                                drawH, uv.u, uv.v, uv.w, uv.h, 0.0f, flipX,
                                flipY, combinedTint, false, layer.getZIndex());
      }
    }
  }
}

void TileMap::update(float dt) { m_AnimationTime += dt; }

int TileMap::getTileId(int x, int y, const std::string &layerName) const {
  const TileLayer *layer = getLayer(layerName);
  if (!layer) {
    return 0;
  }
  return layer->getTileId(x, y);
}

void TileMap::setTileId(int x, int y, const std::string &layerName,
                        int tileId) {
  TileLayer *layer = getLayer(layerName);
  if (!layer) {
    LOG_WARN("Layer not found: %s", layerName.c_str());
    return;
  }

  int oldTile = layer->getTileId(x, y);
  layer->setTileId(x, y, tileId);

  if (m_OnTileChanged && oldTile != tileId) {
    m_OnTileChanged(x, y, layerName, oldTile, tileId);
  }
}

std::string TileMap::getProperty(int x, int y,
                                 const std::string &propertyName) const {
  // Search through tile layers to find the tile
  for (const auto &layer : m_TileLayers) {
    int tileId = layer.getTileId(x, y);
    if (tileId == 0) {
      continue;
    }

    // Remove flip flags
    tileId &= ~(0x80000000 | 0x40000000 | 0x20000000);

    const TileSet *tileset = getTilesetForTile(tileId);
    if (tileset && tileset->hasTileProperty(tileId, propertyName)) {
      return tileset->getTileProperty(tileId, propertyName);
    }
  }
  return "";
}

std::string TileMap::getMapProperty(const std::string &propertyName) const {
  auto it = m_Properties.find(propertyName);
  if (it != m_Properties.end()) {
    return it->second;
  }
  return "";
}

TileLayer *TileMap::getLayer(const std::string &name) {
  for (auto &layer : m_TileLayers) {
    if (layer.getName() == name) {
      return &layer;
    }
  }
  return nullptr;
}

const TileLayer *TileMap::getLayer(const std::string &name) const {
  for (const auto &layer : m_TileLayers) {
    if (layer.getName() == name) {
      return &layer;
    }
  }
  return nullptr;
}

void TileMap::setLayerVisible(const std::string &name, bool visible) {
  TileLayer *layer = getLayer(name);
  if (layer) {
    layer->setVisible(visible);
  }
}

void TileMap::setLayerTint(const std::string &name, const Color &tint) {
  TileLayer *layer = getLayer(name);
  if (layer) {
    layer->setTint(tint);
  }
}

ObjectLayer *TileMap::getObjectLayer(const std::string &name) {
  for (auto &layer : m_ObjectLayers) {
    if (layer.getName() == name) {
      return &layer;
    }
  }
  return nullptr;
}

const ObjectLayer *TileMap::getObjectLayer(const std::string &name) const {
  for (const auto &layer : m_ObjectLayers) {
    if (layer.getName() == name) {
      return &layer;
    }
  }
  return nullptr;
}

std::vector<const TiledObject *>
TileMap::getObjects(const std::string &layerName) const {
  const ObjectLayer *layer = getObjectLayer(layerName);
  if (!layer) {
    return {};
  }

  std::vector<const TiledObject *> result;
  for (const auto &obj : layer->getObjects()) {
    result.push_back(&obj);
  }
  return result;
}

const TiledObject *TileMap::getObject(const std::string &name) const {
  for (const auto &layer : m_ObjectLayers) {
    const TiledObject *obj = layer.getObject(name);
    if (obj) {
      return obj;
    }
  }
  return nullptr;
}

std::vector<const TiledObject *>
TileMap::getObjectsByType(const std::string &type) const {
  std::vector<const TiledObject *> result;
  for (const auto &layer : m_ObjectLayers) {
    auto objects = layer.getObjectsByType(type);
    result.insert(result.end(), objects.begin(), objects.end());
  }
  return result;
}

void TileMap::createCollisionBodies(PhysicsSystem &physics,
                                    const std::string &layerName) {
  const TileLayer *layer = getLayer(layerName);
  if (!layer) {
    LOG_WARN("Collision layer not found: %s", layerName.c_str());
    return;
  }

  int bodyCount = 0;
  for (int y = 0; y < m_Height; ++y) {
    for (int x = 0; x < m_Width; ++x) {
      if (layer->getTileId(x, y) != 0) {
        // Create static body at tile center
        float px = x * m_TileWidth + m_TileWidth * 0.5f;
        float py = y * m_TileHeight + m_TileHeight * 0.5f;
        physics.CreateBody(px, py, false); // false = static
        bodyCount++;
      }
    }
  }

  LOG_INFO("Created %d collision bodies from layer '%s'", bodyCount,
           layerName.c_str());
}

void TileMap::createCollisionBodiesFromObjectLayer(
    PhysicsSystem &physics, const std::string &layerName) {
  const ObjectLayer *layer = getObjectLayer(layerName);
  if (!layer) {
    LOG_WARN("Object layer not found: %s", layerName.c_str());
    return;
  }

  int bodyCount = 0;
  for (const auto &obj : layer->getObjects()) {
    if (!obj.polygon.empty()) {
      // TODO: Create chain shape from polygon vertices
      LOG_DEBUG("Polygon collision object '%s' - chain shapes not yet "
                "implemented",
                obj.name.c_str());
    } else if (obj.width > 0 && obj.height > 0) {
      // Rectangle collision
      float cx = obj.x + obj.width * 0.5f;
      float cy = obj.y + obj.height * 0.5f;
      physics.CreateBody(cx, cy, false);
      bodyCount++;
    }
  }

  LOG_INFO("Created %d collision bodies from object layer '%s'", bodyCount,
           layerName.c_str());
}

const TileSet *TileMap::getTilesetForTile(int gid) const {
  // Tilesets are sorted by firstGid descending
  for (const auto &tileset : m_Tilesets) {
    if (tileset.containsTile(gid)) {
      return &tileset;
    }
  }
  return nullptr;
}
