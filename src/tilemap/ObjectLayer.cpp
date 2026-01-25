#include "tilemap/ObjectLayer.h"
#include "core/Logger.h"

bool ObjectLayer::loadFromJson(const nlohmann::json &json) {
  try {
    m_Name = json["name"].get<std::string>();
    m_Visible = json.value("visible", true);

    if (!json.contains("objects")) {
      LOG_WARN("Object layer '%s' has no objects array", m_Name.c_str());
      return true;
    }

    for (const auto &objJson : json["objects"]) {
      TiledObject obj;
      obj.id = objJson.value("id", 0);
      obj.name = objJson.value("name", "");
      obj.type = objJson.value("type", "");
      // Support for Tiled 1.9+ 'class' property, falling back to 'type' as
      // Tiled 1.10+ reverted to using 'type' in JSON
      if (objJson.contains("class")) {
        obj.className = objJson.value("class", "");
      } else {
        obj.className = obj.type;
      }
      obj.x = objJson.value("x", 0.0f);
      obj.y = objJson.value("y", 0.0f);
      obj.width = objJson.value("width", 0.0f);
      obj.height = objJson.value("height", 0.0f);
      obj.rotation = objJson.value("rotation", 0.0f);
      obj.visible = objJson.value("visible", true);
      obj.isPoint = objJson.value("point", false);
      obj.isEllipse = objJson.value("ellipse", false);

      // Parse properties
      if (objJson.contains("properties")) {
        for (const auto &prop : objJson["properties"]) {
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
            value = prop["value"].dump();
          }

          obj.properties[name] = value;
        }
      }

      // Parse polygon
      if (objJson.contains("polygon")) {
        for (const auto &point : objJson["polygon"]) {
          obj.polygon.emplace_back(point["x"].get<float>(),
                                   point["y"].get<float>());
        }
      }

      // Parse polyline
      if (objJson.contains("polyline")) {
        for (const auto &point : objJson["polyline"]) {
          obj.polyline.emplace_back(point["x"].get<float>(),
                                    point["y"].get<float>());
        }
      }

      m_Objects.push_back(std::move(obj));
    }

    LOG_DEBUG("Loaded object layer '%s': %zu objects", m_Name.c_str(),
              m_Objects.size());
    return true;

  } catch (const std::exception &e) {
    LOG_ERROR("Failed to parse object layer JSON: %s", e.what());
    return false;
  }
}

const TiledObject *ObjectLayer::getObject(const std::string &name) const {
  for (const auto &obj : m_Objects) {
    if (obj.name == name) {
      return &obj;
    }
  }
  return nullptr;
}

std::vector<const TiledObject *>
ObjectLayer::getObjectsByType(const std::string &type) const {
  std::vector<const TiledObject *> result;
  for (const auto &obj : m_Objects) {
    if (obj.type == type) {
      result.push_back(&obj);
    }
  }
  return result;
}
