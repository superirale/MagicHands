#include "tilemap/TileSet.h"
#include "core/Engine.h"
#include "core/Logger.h"
#include <fstream>

#define g_Renderer Engine::Instance().Renderer()

bool TileSet::loadFromJson(const nlohmann::json &json,
                           const std::string &basePath) {
  try {
    // Handle external tileset reference
    if (json.contains("source")) {
      std::string externalPath =
          basePath + "/" + json["source"].get<std::string>();
      std::ifstream file(externalPath);
      if (!file.is_open()) {
        LOG_ERROR("Failed to open external tileset: %s", externalPath.c_str());
        return false;
      }
      nlohmann::json externalJson;
      file >> externalJson;
      m_FirstGid = json["firstgid"].get<int>();
      return loadFromJson(externalJson, basePath);
    }

    // Parse tileset properties
    m_Name = json.value("name", "unnamed");
    m_TileWidth = json["tilewidth"].get<int>();
    m_TileHeight = json["tileheight"].get<int>();
    m_TileCount = json["tilecount"].get<int>();
    m_Columns = json["columns"].get<int>();
    m_Margin = json.value("margin", 0);
    m_Spacing = json.value("spacing", 0);

    // FirstGid might be set from external reference or from embedded tileset
    if (json.contains("firstgid")) {
      m_FirstGid = json["firstgid"].get<int>();
    }

    // Load image
    if (json.contains("image")) {
      m_ImagePath = json["image"].get<std::string>();

      // Resolve relative path
      std::string fullPath = basePath + "/" + m_ImagePath;

      m_TextureId = g_Renderer.LoadTexture(fullPath.c_str());
      if (m_TextureId == 0) {
        LOG_ERROR("Failed to load tileset image: %s", fullPath.c_str());
        return false;
      }

      int w, h;
      g_Renderer.GetTextureSize(m_TextureId, &w, &h);
      m_ImageWidth = w;
      m_ImageHeight = h;
    }

    // Parse tile properties
    if (json.contains("tiles")) {
      for (const auto &tile : json["tiles"]) {
        int localId = tile["id"].get<int>();

        // Properties
        if (tile.contains("properties")) {
          for (const auto &prop : tile["properties"]) {
            std::string name = prop["name"].get<std::string>();
            std::string value;

            // Handle different property types
            if (prop["type"] == "string") {
              value = prop["value"].get<std::string>();
            } else if (prop["type"] == "bool") {
              value = prop["value"].get<bool>() ? "true" : "false";
            } else if (prop["type"] == "int") {
              value = std::to_string(prop["value"].get<int>());
            } else if (prop["type"] == "float") {
              value = std::to_string(prop["value"].get<float>());
            } else {
              // Default: convert to string
              value = prop["value"].dump();
            }

            m_TileProperties[localId][name] = value;
          }
        }

        // Animations
        if (tile.contains("animation")) {
          TileAnimation anim;
          for (const auto &frame : tile["animation"]) {
            anim.frames.push_back({frame["tileid"].get<int>() +
                                       m_FirstGid, // Convert to global ID
                                   frame["duration"].get<int>()});
          }
          m_TileAnimations[localId] = anim;
        }
      }
    }

    LOG_INFO("Loaded tileset '%s': %d tiles, %dx%d", m_Name.c_str(),
             m_TileCount, m_TileWidth, m_TileHeight);
    return true;

  } catch (const std::exception &e) {
    LOG_ERROR("Failed to parse tileset JSON: %s", e.what());
    return false;
  }
}

TileRect TileSet::getUV(int gid) const {
  if (!containsTile(gid)) {
    return {0.0f, 0.0f, 0.0f, 0.0f};
  }

  int localId = gid - m_FirstGid;
  int col = localId % m_Columns;
  int row = localId / m_Columns;

  // Calculate pixel position
  float pixelX = static_cast<float>(m_Margin + col * (m_TileWidth + m_Spacing));
  float pixelY =
      static_cast<float>(m_Margin + row * (m_TileHeight + m_Spacing));

  // Convert to normalized UV
  float u = pixelX / static_cast<float>(m_ImageWidth);
  float v = pixelY / static_cast<float>(m_ImageHeight);
  float w = static_cast<float>(m_TileWidth) / static_cast<float>(m_ImageWidth);
  float h =
      static_cast<float>(m_TileHeight) / static_cast<float>(m_ImageHeight);

  return {u, v, w, h};
}

std::string TileSet::getTileProperty(int gid,
                                     const std::string &propertyName) const {
  if (!containsTile(gid)) {
    return "";
  }

  int localId = gid - m_FirstGid;
  auto tileIt = m_TileProperties.find(localId);
  if (tileIt == m_TileProperties.end()) {
    return "";
  }

  auto propIt = tileIt->second.find(propertyName);
  if (propIt == tileIt->second.end()) {
    return "";
  }

  return propIt->second;
}

bool TileSet::hasTileProperty(int gid, const std::string &propertyName) const {
  if (!containsTile(gid)) {
    return false;
  }

  int localId = gid - m_FirstGid;
  auto tileIt = m_TileProperties.find(localId);
  if (tileIt == m_TileProperties.end()) {
    return false;
  }

  return tileIt->second.find(propertyName) != tileIt->second.end();
}

const TileAnimation *TileSet::getTileAnimation(int gid) const {
  if (!containsTile(gid)) {
    return nullptr;
  }

  int localId = gid - m_FirstGid;
  auto it = m_TileAnimations.find(localId);
  if (it == m_TileAnimations.end()) {
    return nullptr;
  }

  return &it->second;
}
