#pragma once

#include "Condition.h"

namespace gameplay {

/// @brief Condition that checks if hand contains a specific rank
/// Parses strings like "contains_rank:7" or "contains_rank:A"
class ContainsRankCondition : public Condition {
  int targetRank_;

public:
  /// @brief Constructor
  /// @param rank Target rank (1=Ace, 2-10=number cards, 11=Jack, 12=Queen,
  /// 13=King)
  explicit ContainsRankCondition(int rank) : targetRank_(rank) {}

  bool evaluate(const HandEvaluator::HandResult &hand) const override {
    for (const auto &card : hand.cards) {
      if (card.getRankValue() == targetRank_) {
        return true;
      }
    }
    return false;
  }

  std::string getDescription() const override {
    return "Contains rank " + std::to_string(targetRank_);
  }
};

} // namespace gameplay
