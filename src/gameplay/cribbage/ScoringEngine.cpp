#include "ScoringEngine.h"
#include <algorithm>
#include <cmath>

namespace gameplay {

ScoringEngine::ScoreResult
ScoringEngine::CalculateScore(const HandEvaluator::HandResult &handResult,
                              float tempMult, float permMult) {
  ScoreResult result;

  // Calculate chips per category
  // Base formula from GDD:
  // Fifteens: 10 × count
  // Pairs: 12 × count
  // Runs: 8 × total_length
  // Flush: 20 (4 cards), 30 (5 cards)
  // Nobs: 15

  // Fifteens: 10 chips per combination
  result.fifteenChips = static_cast<int>(handResult.fifteens.size()) * 10;

  // Pairs: 12 chips per pair
  // Note: Three-of-a-kind = 3 pairs, Four-of-a-kind = 6 pairs
  result.pairChips = static_cast<int>(handResult.pairs.size()) * 12;

  // Runs: 8 chips per card in run
  for (const auto &run : handResult.runs) {
    result.runChips += static_cast<int>(run.size()) * 8;
  }

  // Flush: 20 for 4 cards, 30 for 5 cards
  if (handResult.flushCount == 4) {
    result.flushChips = 20;
  } else if (handResult.flushCount == 5) {
    result.flushChips = 30;
  }

  // Nobs: 15 chips
  if (handResult.hasNobs) {
    result.nobsChips = 15;
  }

  // Sum all base chips
  result.baseChips = result.fifteenChips + result.pairChips + result.runChips +
                     result.flushChips + result.nobsChips;

  // Apply multipliers with caps
  result.tempMultiplier = std::min(tempMult, 10.0f);
  result.permMultiplier = std::min(permMult, 5.0f);

  // Final score formula: chips × (1 + temp_mult + perm_mult)
  float multiplier = 1.0f + result.tempMultiplier + result.permMultiplier;
  result.finalScore =
      static_cast<int>(std::round(result.baseChips * multiplier));

  return result;
}

float ScoringEngine::applyDiminishingReturns(int triggerCount) {
  // Diminishing returns per GDD:
  // 1st: 100%
  // 2nd: 75%
  // 3rd: 50%
  // 4th+: 25%

  switch (triggerCount) {
  case 1:
    return 1.0f;
  case 2:
    return 0.75f;
  case 3:
    return 0.5f;
  default:
    return 0.25f; // 4+
  }
}

} // namespace gameplay
