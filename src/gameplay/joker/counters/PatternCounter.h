#pragma once

#include "Counter.h"

namespace gameplay {

/**
 * PatternCounter - Counts cribbage scoring patterns
 * 
 * Handles: each_15, each_pair, each_run, cards_in_runs, card_count
 */
class PatternCounter : public Counter {
public:
  enum class PatternType {
    Fifteens,       // each_15 - count of 15 combinations
    Pairs,          // each_pair - count of pair combinations
    Runs,           // each_run - count of run sequences
    CardsInRuns,    // cards_in_runs - total cards participating in runs
    CardCount,      // card_count - total cards in hand
  };

  explicit PatternCounter(PatternType type) : m_Type(type) {}

  int count(const HandEvaluator::HandResult &handResult) const override {
    switch (m_Type) {
    case PatternType::Fifteens:
      return static_cast<int>(handResult.fifteens.size());
      
    case PatternType::Pairs:
      return static_cast<int>(handResult.pairs.size());
      
    case PatternType::Runs:
      return static_cast<int>(handResult.runs.size());
      
    case PatternType::CardsInRuns: {
      int total = 0;
      for (const auto &run : handResult.runs) {
        total += static_cast<int>(run.size());
      }
      return total;
    }
    
    case PatternType::CardCount:
      return static_cast<int>(handResult.cards.size());
    }
    
    return 1; // Default fallback
  }

private:
  PatternType m_Type;
};

} // namespace gameplay
