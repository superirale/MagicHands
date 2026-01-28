#include "ScoringEngine.h"
#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

namespace gameplay {

ScoringEngine::ScoreResult
ScoringEngine::CalculateScore(const HandEvaluator::HandResult &handResult,
                              float tempMult, float permMult,
                              const std::vector<std::string> &bossRules) {
  ScoreResult result;

  // Check boss rules
  bool fifteensDisabled = false;
  bool multDisabled = false;
  bool flushDisabled = false;
  bool nobsDisabled = false;
  bool pairsDisabled = false;
  bool runsDisabled = false;
  bool onlyPairsRuns = false;

  for (const auto &rule : bossRules) {
    if (rule == "fifteens_disabled")
      fifteensDisabled = true;
    else if (rule == "multipliers_disabled")
      multDisabled = true;
    else if (rule == "flush_disabled")
      flushDisabled = true;
    else if (rule == "nobs_disabled")
      nobsDisabled = true;
    else if (rule == "pairs_disabled")
      pairsDisabled = true;
    else if (rule == "runs_disabled")
      runsDisabled = true;
    else if (rule == "only_pairs_runs")
      onlyPairsRuns = true;
  }

  if (onlyPairsRuns) {
    fifteensDisabled = true;
    flushDisabled = true;
    nobsDisabled = true;
  }

  // Calculate chips per category
  // Base formula from GDD:
  // Fifteens: 10 × count
  // Pairs: 12 × count
  // Runs: 8 × total_length
  // Flush: 20 (4 cards), 30 (5 cards)
  // Nobs: 15

  // Fifteens: 10 chips per combination
  if (!fifteensDisabled) {
    result.fifteenChips = static_cast<int>(handResult.fifteens.size()) * 10;
  }

  // Pairs: 12 chips per pair
  // Note: Three-of-a-kind = 3 pairs, Four-of-a-kind = 6 pairs
  if (!pairsDisabled) {
    result.pairChips = static_cast<int>(handResult.pairs.size()) * 12;
  }

  // Runs: 8 chips per card in run
  if (!runsDisabled) {
    for (const auto &run : handResult.runs) {
      result.runChips += static_cast<int>(run.size()) * 8;
    }
  }

  // Flush: 20 for 4 cards, 30 for 5 cards
  if (!flushDisabled) {
    if (handResult.flushCount == 4) {
      result.flushChips = 20;
    } else if (handResult.flushCount == 5) {
      result.flushChips = 30;
    }
  }

  // Nobs: 15 chips
  if (!nobsDisabled) {
    if (handResult.hasNobs) {
      result.nobsChips = 15;
    }
  }

  // Sum all base chips
  result.baseChips = result.fifteenChips + result.pairChips + result.runChips +
                     result.flushChips + result.nobsChips;

  // Apply multipliers with caps
  result.tempMultiplier = std::min(tempMult, 10.0f);
  result.permMultiplier = std::min(permMult, 5.0f);

  if (multDisabled) {
    result.tempMultiplier = 0.0f;
    result.permMultiplier = 0.0f;
  }

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
