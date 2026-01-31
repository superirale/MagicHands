#pragma once

#include "WarpEffect.h"

namespace gameplay {

/// @brief Mirror Warp: Swap pair and run chip values
/// Pairs worth 8 chips (down from 12), Runs worth 12 chips per card (up from
/// 8)
class MirrorEffect : public WarpEffect {
public:
  void apply(ScoringEngine::ScoreResult &result,
             const HandEvaluator::HandResult &handResult) const override;

  std::string getName() const override { return "Mirror"; }

  RuleType getRuleType() const override { return RuleType::WarpMirror; }

  std::string getDescription() const override {
    return "Pairs worth 8 chips, Runs worth 12 chips per card";
  }
};

} // namespace gameplay
