#pragma once

#include <string>
#include <unordered_map>

namespace gameplay {

/// @brief Enum representing all scoring rule modifications
enum class RuleType {
  // Boss rules (category disablers)
  FifteensDisabled,
  MultipliersDisabled,
  FlushDisabled,
  NobsDisabled,
  PairsDisabled,
  RunsDisabled,
  OnlyPairsRuns,

  // Warp effects
  WarpBlaze,
  WarpMirror,
  WarpInversion,
  WarpWildfire,

  // Unknown/unregistered rule
  Unknown
};

/// @brief Registry for converting between strings and RuleType enums
class RuleRegistry {
public:
  /// @brief Convert rule string to enum (O(1) hash lookup)
  /// @param rule String rule name (e.g., "warp_blaze")
  /// @return Corresponding RuleType enum, or RuleType::Unknown
  static RuleType fromString(const std::string &rule);

  /// @brief Convert enum to string representation
  /// @param rule RuleType enum value
  /// @return String representation
  static const std::string &toString(RuleType rule);

  /// @brief Check if a rule string is registered
  /// @param rule String rule name
  /// @return True if rule is known
  static bool isRegistered(const std::string &rule);

private:
  static const std::unordered_map<std::string, RuleType> stringToEnum_;
  static const std::unordered_map<RuleType, std::string> enumToString_;
};

} // namespace gameplay
