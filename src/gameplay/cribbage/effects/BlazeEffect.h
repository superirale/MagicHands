#pragma once

#include "WarpEffect.h"

namespace gameplay {

/// @brief Blaze Warp: Only the first scoring category counts
/// Zeros out all categories after the first one with points > 0
class BlazeEffect : public WarpEffect {
public:
  void apply(ScoringEngine::ScoreResult &result,
             const HandEvaluator::HandResult &handResult) const override;

  std::string getName() const override { return "Blaze"; }

  RuleType getRuleType() const override { return RuleType::WarpBlaze; }

  std::string getDescription() const override {
    return "Only the first scoring category counts";
  }
};

} // namespace gameplay
