#pragma once

#include "../cribbage/HandEvaluator.h"
#include "Joker.h"
#include <vector>

namespace gameplay {

/// @brief System for evaluating joker triggers and applying effects
class JokerEffectSystem {
public:
  /// @brief Result of applying joker effects
  struct EffectResult {
    /// Chips added by jokers
    int addedChips = 0;

    /// Temporary multiplier added by jokers
    float addedTempMult = 0.0f;

    /// Permanent multiplier added by jokers
    float addedPermMult = 0.0f;

    /// Whether any joker ignores caps
    bool ignoresCaps = false;
  };

  /// @brief Apply all active jokers for a given trigger
  /// @param jokers List of active jokers with stack counts
  /// @param handResult Evaluated hand data
  /// @param trigger Trigger name (e.g., "on_score")
  /// @return Aggregate effect result
  static EffectResult ApplyJokers(const std::vector<Joker> &jokers,
                                  const HandEvaluator::HandResult &handResult,
                                  const std::string &trigger);
  
  /// @brief Apply all active jokers with stack counts
  /// @param jokersWithStacks List of jokers paired with their stack counts
  /// @param handResult Evaluated hand data
  /// @param trigger Trigger name (e.g., "on_score")
  /// @return Aggregate effect result
  static EffectResult ApplyJokersWithStacks(
      const std::vector<std::pair<Joker, int>> &jokersWithStacks,
      const HandEvaluator::HandResult &handResult,
      const std::string &trigger);

private:
  /// @brief Evaluate a single condition string
  /// @param condition Condition to evaluate (e.g., "count_15s > 0")
  /// @param handResult Hand data to check against
  /// @return True if condition is met
  static bool EvaluateCondition(const std::string &condition,
                                const HandEvaluator::HandResult &handResult);

  /// @brief Apply a single joker effect
  /// @param effect Effect to apply
  /// @param handResult Hand data for counting
  /// @return Effect result
  static EffectResult ApplyEffect(const JokerEffect &effect,
                                  const HandEvaluator::HandResult &handResult);

  /// @brief Get count value from hand result based on "per" field
  /// @param per What to count ("each_15", "each_pair", etc.)
  /// @param handResult Hand data
  /// @return Count value
  static int GetCountValue(const std::string &per,
                           const HandEvaluator::HandResult &handResult);
};

} // namespace gameplay
