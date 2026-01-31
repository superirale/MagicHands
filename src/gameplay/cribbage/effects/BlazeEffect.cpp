#include "BlazeEffect.h"

namespace gameplay {

void BlazeEffect::apply(ScoringEngine::ScoreResult &result,
                        const HandEvaluator::HandResult &handResult) const {
  // Check categories in standard order and zero out all but first
  bool foundFirst = false;

  if (result.fifteenChips > 0 && !foundFirst) {
    foundFirst = true;
  } else if (foundFirst) {
    result.fifteenChips = 0;
  }

  if (result.pairChips > 0 && !foundFirst) {
    foundFirst = true;
  } else if (foundFirst) {
    result.pairChips = 0;
  }

  if (result.runChips > 0 && !foundFirst) {
    foundFirst = true;
  } else if (foundFirst) {
    result.runChips = 0;
  }

  if (result.flushChips > 0 && !foundFirst) {
    foundFirst = true;
  } else if (foundFirst) {
    result.flushChips = 0;
  }

  if (result.nobsChips > 0 && !foundFirst) {
    foundFirst = true;
  } else if (foundFirst) {
    result.nobsChips = 0;
  }

  // Recalculate base chips after zeroing categories
  result.baseChips = result.fifteenChips + result.pairChips +
                     result.runChips + result.flushChips + result.nobsChips;
}

} // namespace gameplay
