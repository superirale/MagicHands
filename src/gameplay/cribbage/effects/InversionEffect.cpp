#include "InversionEffect.h"
#include <algorithm>
#include <cmath>

namespace gameplay {

void InversionEffect::apply(
    ScoringEngine::ScoreResult &result,
    const HandEvaluator::HandResult &handResult) const {
  if (handResult.cards.empty()) {
    return;
  }

  // Count low cards (Ace through 5)
  int lowCardCount =
      std::count_if(handResult.cards.begin(), handResult.cards.end(),
                    [](const Card &card) { return card.getRankValue() <= 5; });

  if (lowCardCount > 0) {
    // Apply bonus: +20% base chips per low card (max 5 cards = +100%)
    float inversionBonus = lowCardCount * 0.20f;
    int bonusChips =
        static_cast<int>(std::round(result.baseChips * inversionBonus));
    result.baseChips += bonusChips;
  }
}

} // namespace gameplay
