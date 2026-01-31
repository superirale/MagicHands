#include "WildfireEffect.h"
#include <algorithm>
#include <cmath>

namespace gameplay {

void WildfireEffect::apply(
    ScoringEngine::ScoreResult &result,
    const HandEvaluator::HandResult &handResult) const {
  if (handResult.cards.empty()) {
    return;
  }

  // Count 5s in hand
  int fiveCount =
      std::count_if(handResult.cards.begin(), handResult.cards.end(),
                    [](const Card &card) { return card.getRankValue() == 5; });

  if (fiveCount > 0) {
    // Apply bonus: +30% base chips per 5 (since they're "wild")
    float wildfireBonus = fiveCount * 0.30f;
    int bonusChips =
        static_cast<int>(std::round(result.baseChips * wildfireBonus));
    result.baseChips += bonusChips;
  }
}

} // namespace gameplay
