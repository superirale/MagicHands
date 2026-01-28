#include "Joker.h"
#include <fstream>
#include <nlohmann/json.hpp>
#include <sstream>

using json = nlohmann::json;

namespace gameplay {

Joker Joker::FromJSON(const std::string &jsonPath) {
  std::ifstream file(jsonPath);
  if (!file.is_open()) {
    throw std::runtime_error("Failed to open joker file: " + jsonPath);
  }

  std::stringstream buffer;
  buffer << file.rdbuf();
  return FromJSONString(buffer.str());
}

Joker Joker::FromJSONString(const std::string &jsonString) {
  Joker joker;

  try {
    json j = json::parse(jsonString);

    // Required fields
    joker.id = j.at("id").get<std::string>();
    joker.name = j.at("name").get<std::string>();
    joker.rarity = j.at("rarity").get<std::string>();

    // Optional fields
    if (j.contains("description")) {
      joker.description = j["description"].get<std::string>();
    }

    if (j.contains("type")) {
      joker.type = j["type"].get<std::string>();
    }

    if (j.contains("ignores_caps")) {
      joker.ignoresCaps = j["ignores_caps"].get<bool>();
    }

    // Triggers
    if (j.contains("triggers")) {
      for (const auto &trigger : j["triggers"]) {
        joker.triggers.push_back(trigger.get<std::string>());
      }
    }

    // Conditions
    if (j.contains("conditions")) {
      for (const auto &condition : j["conditions"]) {
        joker.conditions.push_back(condition.get<std::string>());
      }
    }

    // Effects (legacy single-tier effects)
    if (j.contains("effects")) {
      for (const auto &effectJson : j["effects"]) {
        JokerEffect effect;
        effect.type = effectJson.at("type").get<std::string>();
        effect.value = effectJson.at("value").get<float>();

        if (effectJson.contains("per")) {
          effect.per = effectJson["per"].get<std::string>();
        }

        joker.effects.push_back(effect);
      }
    }
    
    // Tiered Effects (new tier system)
    if (j.contains("tiers")) {
      joker.stackable = true; // If tiers exist, joker is stackable
      
      for (const auto &tierJson : j["tiers"]) {
        int tierLevel = tierJson.at("level").get<int>();
        std::vector<JokerEffect> tierEffects;
        
        if (tierJson.contains("effects")) {
          for (const auto &effectJson : tierJson["effects"]) {
            JokerEffect effect;
            effect.type = effectJson.at("type").get<std::string>();
            effect.value = effectJson.at("value").get<float>();
            
            if (effectJson.contains("per")) {
              effect.per = effectJson["per"].get<std::string>();
            }
            
            tierEffects.push_back(effect);
          }
        }
        
        joker.tieredEffects[tierLevel] = tierEffects;
      }
    }
    
    // Stackable flag (can be explicit or implied by tiers)
    if (j.contains("stackable")) {
      joker.stackable = j["stackable"].get<bool>();
    }

    // Caps
    if (j.contains("caps")) {
      for (auto &[key, value] : j["caps"].items()) {
        joker.caps[key] = value.get<float>();
      }
    }

  } catch (const json::exception &e) {
    throw std::runtime_error("JSON parsing error: " + std::string(e.what()));
  }

  return joker;
}

} // namespace gameplay
