#pragma once

#include <string>
#include <vector>

namespace gameplay {

/// @brief Boss definition loaded from JSON
class Boss {
public:
  /// Unique boss identifier
  std::string id;

  /// Display name
  std::string name;

  /// Description shown to player
  std::string description;

  /// List of effect IDs this boss applies
  std::vector<std::string> effects;

  /// @brief Load boss from JSON file
  /// @param jsonPath Path to boss JSON file
  /// @return Loaded boss
  static Boss FromJSON(const std::string &jsonPath);

  /// @brief Load boss from JSON string
  /// @param jsonString JSON string content
  /// @return Loaded boss
  static Boss FromJSONString(const std::string &jsonString);
};

} // namespace gameplay
