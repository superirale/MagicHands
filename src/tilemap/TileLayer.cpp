#include "tilemap/TileLayer.h"
#include "core/Base64.h"
#include "core/Logger.h"
#include <cctype>
#include <zlib.h>

bool TileLayer::loadFromJson(const nlohmann::json &json) {
  try {
    m_Name = json["name"].get<std::string>();
    m_Width = json["width"].get<int>();
    m_Height = json["height"].get<int>();
    m_Visible = json.value("visible", true);
    m_Opacity = json.value("opacity", 1.0f);
    m_OffsetX = json.value("offsetx", 0.0f);
    m_OffsetY = json.value("offsety", 0.0f);

    // Determine layer type from name prefix
    m_Type = parseTypeFromName(m_Name);

    // Set default Z-Index based on type
    switch (m_Type) {
    case Type::Ground:
      m_ZIndex = -100;
      break;
    case Type::Fringe:
      m_ZIndex = 0;
      break;
    case Type::Overhang:
      m_ZIndex = 100;
      break;
    case Type::Collision:
      m_ZIndex = 0;
      break;
    }

    // Parse custom properties
    if (json.contains("properties") && json["properties"].is_array()) {
      for (const auto &prop : json["properties"]) {
        if (prop.contains("name") && prop["name"] == "z_index" &&
            prop.contains("value")) {
          m_ZIndex = prop["value"].get<int>();
        }
      }
    }

    // Parse tint color if present (Tiled format: #AARRGGBB or #RRGGBB)
    if (json.contains("tintcolor")) {
      std::string tintStr = json["tintcolor"].get<std::string>();
      if (tintStr.length() >= 7 && tintStr[0] == '#') {
        unsigned int r, g, b, a = 255;
        if (tintStr.length() == 9) {
          // #AARRGGBB
          sscanf(tintStr.c_str(), "#%02x%02x%02x%02x", &a, &r, &g, &b);
        } else {
          // #RRGGBB
          sscanf(tintStr.c_str(), "#%02x%02x%02x", &r, &g, &b);
        }
        m_Tint = Color(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);
      }
    }

    // Parse layer data
    const auto &data = json["data"];

    if (data.is_array()) {
      // CSV format
      m_Data.reserve(data.size());
      for (const auto &tile : data) {
        m_Data.push_back(tile.get<int>());
      }
    } else if (data.is_string()) {
      // Base64 encoded
      std::string encoded = data.get<std::string>();
      std::string encoding = json.value("encoding", "");
      std::string compression = json.value("compression", "");

      if (encoding == "base64") {
        std::vector<unsigned char> decoded = Base64::decode(encoded);

        if (compression.empty()) {
          // Raw Base64
          if (decoded.size() % 4 != 0) {
            LOG_ERROR("Invalid Base64 data size for layer '%s'",
                      m_Name.c_str());
            return false;
          }
          // Copy data (32-bit integers, little endian)
          m_Data.resize(decoded.size() / 4);
          memcpy(m_Data.data(), decoded.data(), decoded.size());
        } else if (compression == "zlib" || compression == "gzip") {
          // Decompress
          uLongf destLen = m_Width * m_Height * 4; // 4 bytes per tile
          std::vector<unsigned char> decompressed(destLen);

          int result = Z_OK;
          if (compression == "zlib") {
            result = uncompress(decompressed.data(), &destLen, decoded.data(),
                                decoded.size());
          } else {
            // Gzip requires inflateInit2
            z_stream zs;
            zs.zalloc = Z_NULL;
            zs.zfree = Z_NULL;
            zs.opaque = Z_NULL;
            zs.avail_in = (uInt)decoded.size();
            zs.next_in = (Bytef *)decoded.data();
            zs.avail_out = (uInt)destLen;
            zs.next_out = (Bytef *)decompressed.data();

            // 16 + MAX_WBITS prompts inflate to look for gzip data
            if (inflateInit2(&zs, 16 + MAX_WBITS) != Z_OK) {
              LOG_ERROR("Failed to initialize gzip inflater for layer '%s'",
                        m_Name.c_str());
              return false;
            }

            result = inflate(&zs, Z_FINISH);
            inflateEnd(&zs);

            if (result != Z_STREAM_END) {
              result = Z_DATA_ERROR; // forcing error if incomplete
            } else {
              result = Z_OK;
            }
          }

          if (result != Z_OK) {
            LOG_ERROR("Decompression failed for layer '%s': error %d",
                      m_Name.c_str(), result);
            return false;
          }

          if (decompressed.size() % 4 != 0) {
            LOG_ERROR("Invalid decompressed size for layer '%s'",
                      m_Name.c_str());
            return false;
          }

          m_Data.resize(decompressed.size() / 4);
          memcpy(m_Data.data(), decompressed.data(), decompressed.size());

        } else {
          LOG_ERROR("Unsupported compression '%s' for layer '%s'",
                    compression.c_str(), m_Name.c_str());
          return false;
        }
      } else {
        LOG_ERROR("Unsupported encoding '%s' for layer '%s'", encoding.c_str(),
                  m_Name.c_str());
        return false;
      }
    }

    // Validate data size
    if (m_Data.size() != static_cast<size_t>(m_Width * m_Height)) {
      LOG_ERROR("Layer '%s' data size mismatch: expected %d, got %zu",
                m_Name.c_str(), m_Width * m_Height, m_Data.size());
      return false;
    }

    LOG_DEBUG("Loaded tile layer '%s': %dx%d, type=%d", m_Name.c_str(), m_Width,
              m_Height, static_cast<int>(m_Type));
    return true;

  } catch (const std::exception &e) {
    LOG_ERROR("Failed to parse tile layer JSON: %s", e.what());
    return false;
  }
}

int TileLayer::getTileId(int x, int y) const {
  if (x < 0 || x >= m_Width || y < 0 || y >= m_Height) {
    return 0;
  }
  return m_Data[y * m_Width + x];
}

void TileLayer::setTileId(int x, int y, int tileId) {
  if (x < 0 || x >= m_Width || y < 0 || y >= m_Height) {
    return;
  }
  m_Data[y * m_Width + x] = tileId;
}

TileLayer::Type TileLayer::parseTypeFromName(const std::string &name) {
  // Check for prefixes (case-insensitive)
  std::string lowerName = name;
  for (char &c : lowerName) {
    c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  }

  if (lowerName.find("ground") == 0 || lowerName.find("ground_") == 0) {
    return Type::Ground;
  }
  if (lowerName.find("fringe") == 0 || lowerName.find("fringe_") == 0) {
    return Type::Fringe;
  }
  if (lowerName.find("overhang") == 0 || lowerName.find("overhang_") == 0) {
    return Type::Overhang;
  }
  if (lowerName.find("collision") == 0 || lowerName.find("collision_") == 0) {
    return Type::Collision;
  }

  // Default to Ground for unknown prefixes
  return Type::Ground;
}
