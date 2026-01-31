#pragma once

#include <string>
#include <unordered_map>

namespace gameplay {

/// @brief Enum representing all joker/enhancement effect types
/// Replaces string-based effect type parsing with compile-time type safety
enum class EffectType {
  // Basic joker effects
  AddChips,
  AddTempMult,
  AddPermMult,

  // Advanced effects (for future expansion)
  ConvertChipsToMult,
  ModifyRule,
  AddGold,
  ModifyHandSize,

  // Planet/Augment effects
  BoostHandType,

  // Imprint effects
  ChanceEffect,
  ConditionalEffect,

  // Spectral effects
  ModifyDeck,
  TransformCard,

  // Unknown/unregistered effect
  Unknown
};

/// @brief Registry for converting between strings and EffectType enums
/// Provides O(1) hash lookup instead of O(n) string comparisons
class EffectTypeRegistry {
public:
  /// @brief Convert effect type string to enum (O(1) hash lookup)
  /// @param type String effect type (e.g., "add_chips", "add_multiplier")
  /// @return Corresponding EffectType enum, or EffectType::Unknown
  static EffectType fromString(const std::string &type);

  /// @brief Convert enum to string representation
  /// @param type EffectType enum value
  /// @return String representation
  static const std::string &toString(EffectType type);

  /// @brief Check if an effect type string is registered
  /// @param type String effect type
  /// @return True if effect type is known
  static bool isRegistered(const std::string &type);

private:
  static const std::unordered_map<std::string, EffectType> stringToEnum_;
  static const std::unordered_map<EffectType, std::string> enumToString_;
};

} // namespace gameplay
