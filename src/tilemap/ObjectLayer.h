#pragma once

#include <nlohmann/json.hpp>
#include <string>
#include <unordered_map>
#include <vector>

/**
 * Represents a single object from a Tiled Object Layer.
 */
struct TiledObject {
  int id = 0;
  std::string name;
  std::string type;
  std::string className; // Corresponds to Tiled 'class' property
  float x = 0.0f;
  float y = 0.0f;
  float width = 0.0f;
  float height = 0.0f;
  float rotation = 0.0f;
  bool visible = true;

  // Custom properties
  std::unordered_map<std::string, std::string> properties;

  // Polygon/polyline points (if applicable)
  std::vector<std::pair<float, float>> polygon;
  std::vector<std::pair<float, float>> polyline;
  bool isPoint = false;
  bool isEllipse = false;
};

/**
 * Represents an Object Layer from Tiled.
 * Contains spawnable objects like NPCs, triggers, spawn points, etc.
 */
class ObjectLayer {
public:
  ObjectLayer() = default;

  /**
   * Parse object layer from Tiled JSON
   */
  bool loadFromJson(const nlohmann::json &json);

  /**
   * Get layer name
   */
  const std::string &getName() const { return m_Name; }

  /**
   * Get all objects in this layer
   */
  const std::vector<TiledObject> &getObjects() const { return m_Objects; }

  /**
   * Find object by name (returns nullptr if not found)
   */
  const TiledObject *getObject(const std::string &name) const;

  /**
   * Get all objects of a specific type
   */
  std::vector<const TiledObject *>
  getObjectsByType(const std::string &type) const;

  /**
   * Check if layer is visible
   */
  bool isVisible() const { return m_Visible; }

private:
  std::string m_Name;
  bool m_Visible = true;
  std::vector<TiledObject> m_Objects;
};
