#pragma once

#include "../HandEvaluator.h"
#include "../RuleType.h"
#include "../ScoringEngine.h"
#include <memory>
#include <string>

namespace gameplay {

/// @brief Base interface for warp effects that modify scoring
/// Uses Strategy pattern - each warp is a self-contained strategy
class WarpEffect {
public:
  virtual ~WarpEffect() = default;

  /// @brief Apply this effect to the score result
  /// @param result Score result to modify (passed by reference)
  /// @param handResult Evaluated hand patterns (for card inspection)
  virtual void apply(ScoringEngine::ScoreResult &result,
                     const HandEvaluator::HandResult &handResult) const = 0;

  /// @brief Get human-readable name of this effect
  virtual std::string getName() const = 0;

  /// @brief Get the rule type this effect corresponds to
  virtual RuleType getRuleType() const = 0;

  /// @brief Get description of what this effect does
  virtual std::string getDescription() const = 0;
};

} // namespace gameplay
