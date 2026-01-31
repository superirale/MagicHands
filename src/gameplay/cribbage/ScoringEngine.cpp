#include "ScoringEngine.h"
#include "RuleType.h"
#include "effects/EffectFactory.h"
#include <algorithm>
#include <cmath>
#include <string>
#include <unordered_set>
#include <vector>

namespace gameplay {

ScoringEngine::ScoreResult
ScoringEngine::CalculateScore(const HandEvaluator::HandResult &handResult,
                              float tempMult, float permMult,
                              const std::vector<std::string> &bossRules) {
  ScoreResult result;

  // Parse boss rules using enum registry (O(1) hash lookup per rule)
  std::unordered_set<RuleType> activeRules;
  for (const auto &rule : bossRules) {
    RuleType ruleType = RuleRegistry::fromString(rule);
    if (ruleType != RuleType::Unknown) {
      activeRules.insert(ruleType);
    }
  }

  // Check for rule activations
  bool fifteensDisabled = activeRules.count(RuleType::FifteensDisabled) > 0;
  bool multDisabled = activeRules.count(RuleType::MultipliersDisabled) > 0;
  bool flushDisabled = activeRules.count(RuleType::FlushDisabled) > 0;
  bool nobsDisabled = activeRules.count(RuleType::NobsDisabled) > 0;
  bool pairsDisabled = activeRules.count(RuleType::PairsDisabled) > 0;
  bool runsDisabled = activeRules.count(RuleType::RunsDisabled) > 0;
  bool onlyPairsRuns = activeRules.count(RuleType::OnlyPairsRuns) > 0;
  
  // Warp effects are now handled by strategy pattern (no boolean flags needed)

  if (onlyPairsRuns) {
    fifteensDisabled = true;
    flushDisabled = true;
    nobsDisabled = true;
  }

  // Calculate chips per category
  // Base formula from GDD:
  // Fifteens: 10 × count
  // Pairs: 12 × count (or 8 if warp_mirror)
  // Runs: 8 × total_length (or 12 if warp_mirror)
  // Flush: 20 (4 cards), 30 (5 cards)
  // Nobs: 15

  // Fifteens: 10 chips per combination
  if (!fifteensDisabled) {
    result.fifteenChips = static_cast<int>(handResult.fifteens.size()) * 10;
  }

  // Pairs: 12 chips per pair (base value, Mirror effect may modify)
  // Note: Three-of-a-kind = 3 pairs, Four-of-a-kind = 6 pairs
  if (!pairsDisabled) {
    result.pairChips = static_cast<int>(handResult.pairs.size()) * 12;
  }

  // Runs: 8 chips per card in run (base value, Mirror effect may modify)
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

  // Sum base chips before applying warp effects
  result.baseChips = result.fifteenChips + result.pairChips + result.runChips +
                     result.flushChips + result.nobsChips;

  // Apply warp effects via strategy pattern
  // Effects are applied in order they appear in activeRules
  auto &factory = EffectFactory::getInstance();
  for (RuleType ruleType : activeRules) {
    auto effect = factory.create(ruleType);
    if (effect) {
      effect->apply(result, handResult);
    }
  }

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
