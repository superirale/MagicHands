#include "MirrorEffect.h"

namespace gameplay {

void MirrorEffect::apply(ScoringEngine::ScoreResult &result,
                         const HandEvaluator::HandResult &handResult) const {
  // Swap values: pairs 12→8, runs 8→12
  // This means we need to recalculate from the pattern counts

  // Recalculate pairs with new value (8 instead of 12)
  int pairCount = static_cast<int>(handResult.pairs.size());
  int oldPairChips = result.pairChips;
  result.pairChips = pairCount * 8; // Mirrored value

  // Recalculate runs with new value (12 instead of 8)
  int runCards = 0;
  for (const auto &run : handResult.runs) {
    runCards += static_cast<int>(run.size());
  }
  int oldRunChips = result.runChips;
  result.runChips = runCards * 12; // Mirrored value

  // Update base chips
  result.baseChips = result.baseChips - oldPairChips - oldRunChips +
                     result.pairChips + result.runChips;
}

} // namespace gameplay
