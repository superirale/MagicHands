#pragma once

#include "WarpEffect.h"

namespace gameplay {

/// @brief Wildfire Warp: 5s boost score (simplified wild implementation)
/// Each 5 in hand adds +30% bonus to base chips
/// Note: Full wild card implementation would require HandEvaluator changes
class WildfireEffect : public WarpEffect {
public:
  void apply(ScoringEngine::ScoreResult &result,
             const HandEvaluator::HandResult &handResult) const override;

  std::string getName() const override { return "Wildfire"; }

  RuleType getRuleType() const override { return RuleType::WarpWildfire; }

  std::string getDescription() const override {
    return "Each 5 boosts score by +30% (simplified wild)";
  }
};

} // namespace gameplay
