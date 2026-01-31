#pragma once

#include "WarpEffect.h"

namespace gameplay {

/// @brief Inversion Warp: Low cards boost score
/// Each card with rank ≤ 5 adds +20% bonus to base chips
class InversionEffect : public WarpEffect {
public:
  void apply(ScoringEngine::ScoreResult &result,
             const HandEvaluator::HandResult &handResult) const override;

  std::string getName() const override { return "Inversion"; }

  RuleType getRuleType() const override { return RuleType::WarpInversion; }

  std::string getDescription() const override {
    return "Low cards (A-5) boost score by +20% each";
  }
};

} // namespace gameplay
