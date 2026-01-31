#pragma once

#include "../RuleType.h"
#include "WarpEffect.h"
#include <functional>
#include <memory>
#include <unordered_map>

namespace gameplay {

/// @brief Factory for creating warp effect instances
/// Uses Singleton + Factory pattern for effect registration and creation
class EffectFactory {
public:
  /// @brief Get singleton instance
  static EffectFactory &getInstance();

  /// @brief Register an effect creator function
  /// @param type The rule type this effect handles
  /// @param creator Function that creates the effect
  void registerEffect(
      RuleType type, std::function<std::unique_ptr<WarpEffect>()> creator);

  /// @brief Create an effect instance for a given rule type
  /// @param type The rule type to create effect for
  /// @return Unique pointer to effect, or nullptr if not registered
  std::unique_ptr<WarpEffect> create(RuleType type) const;

  /// @brief Check if an effect is registered for a rule type
  /// @param type The rule type to check
  /// @return True if effect is registered
  bool isRegistered(RuleType type) const;

  /// @brief Register all built-in warp effects
  /// Called once at engine startup
  static void registerBuiltInEffects();

  // Delete copy/move constructors (singleton)
  EffectFactory(const EffectFactory &) = delete;
  EffectFactory &operator=(const EffectFactory &) = delete;

private:
  EffectFactory() = default;

  std::unordered_map<RuleType, std::function<std::unique_ptr<WarpEffect>()>>
      creators_;
};

} // namespace gameplay
