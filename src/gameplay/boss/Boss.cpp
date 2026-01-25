#include "Boss.h"
#include <fstream>
#include <nlohmann/json.hpp>
#include <sstream>

using json = nlohmann::json;

namespace gameplay {

Boss Boss::FromJSON(const std::string &jsonPath) {
  std::ifstream file(jsonPath);
  if (!file.is_open()) {
    throw std::runtime_error("Failed to open boss file: " + jsonPath);
  }

  std::stringstream buffer;
  buffer << file.rdbuf();
  return FromJSONString(buffer.str());
}

Boss Boss::FromJSONString(const std::string &jsonString) {
  Boss boss;

  try {
    json j = json::parse(jsonString);

    // Required fields
    boss.id = j.at("id").get<std::string>();
    boss.name = j.at("name").get<std::string>();
    boss.description = j.at("description").get<std::string>();

    // Effects array
    if (j.contains("effects")) {
      for (const auto &effect : j["effects"]) {
        boss.effects.push_back(effect.get<std::string>());
      }
    }

  } catch (const json::exception &e) {
    throw std::runtime_error("JSON parsing error: " + std::string(e.what()));
  }

  return boss;
}

} // namespace gameplay
