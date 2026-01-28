#pragma once

#include "HandEvaluator.h"
#include <string>
#include <vector>

namespace gameplay {

/// @brief Calculates scores from hand evaluation results with multipliers
class ScoringEngine {
public:
  /// @brief Complete score breakdown
  struct ScoreResult {
    // Base chips per category
    int fifteenChips = 0;
    int pairChips = 0;
    int runChips = 0;
    int flushChips = 0;
    int nobsChips = 0;

    // Total base chips
    int baseChips = 0;

    // Multipliers (capped)
    float tempMultiplier = 0.0f;
    float permMultiplier = 0.0f;

    // Final score with multipliers applied
    int finalScore = 0;
  };

  /// @brief Calculate score from hand evaluation
  /// @param handResult The evaluated hand patterns
  /// @param tempMult Temporary multiplier (capped at 10x)
  /// @param permMult Permanent multiplier (capped at 5x)
  /// @return Complete score breakdown
  static ScoreResult
  CalculateScore(const HandEvaluator::HandResult &handResult,
                 float tempMult = 0.0f, float permMult = 0.0f,
                 const std::vector<std::string> &bossRules = {});

private:
  /// @brief Apply diminishing returns for repeated category triggers
  /// @param triggerCount Number of times category triggered
  /// @return Multiplier (1.0, 0.75, 0.5, or 0.25)
  static float applyDiminishingReturns(int triggerCount);
};

} // namespace gameplay
