#pragma once

#include <map>
#include <string>
#include <vector>

namespace gameplay {

/// @brief Defines a single effect that a joker can apply
struct JokerEffect {
  /// Type of effect: "add_chips", "add_multiplier", "add_permanent_multiplier",
  /// etc.
  std::string type;

  /// Numeric value for the effect
  float value = 0.0f;

  /// Optional: what to count ("each_15", "each_pair", "each_run", etc.)
  std::string per;
};

/// @brief Data-driven Joker definition loaded from JSON
class Joker {
public:
  /// Unique identifier
  std::string id;

  /// Display name
  std::string name;

  /// UI description
  std::string description;

  /// Rarity: "common", "uncommon", "rare", "legendary"
  std::string rarity;

  /// Type: "category_amplifier", "rule_bender", "risk_reward", "economy",
  /// "chaos"
  std::string type;

  /// When to trigger: "on_score", "on_discard", "on_shop", etc.
  std::vector<std::string> triggers;

  /// Conditions to evaluate (e.g., "count_15s > 0", "count_pairs > 1")
  std::vector<std::string> conditions;

  /// Effects to apply when triggered and conditions met
  std::vector<JokerEffect> effects;

  /// Whether this joker ignores global multiplier caps
  bool ignoresCaps = false;

  /// Per-joker caps (e.g., {"per_hand": 2.0})
  std::map<std::string, float> caps;

  /// @brief Load a joker definition from a JSON file
  /// @param jsonPath Path to the JSON file
  /// @return Loaded Joker object
  static Joker FromJSON(const std::string &jsonPath);

  /// @brief Load a joker definition from a JSON string
  /// @param jsonString JSON string content
  /// @return Loaded Joker object
  static Joker FromJSONString(const std::string &jsonString);
};

} // namespace gameplay
