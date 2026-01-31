#pragma once

#include "Condition.h"

namespace gameplay {

/// @brief Condition that checks if hand contains a specific suit
/// Parses strings like "contains_suit:H" or "contains_suit:Hearts"
class ContainsSuitCondition : public Condition {
  int targetSuit_;

public:
  /// @brief Constructor
  /// @param suit Target suit (0=Hearts, 1=Diamonds, 2=Clubs, 3=Spades)
  explicit ContainsSuitCondition(int suit) : targetSuit_(suit) {}

  bool evaluate(const HandEvaluator::HandResult &hand) const override {
    for (const auto &card : hand.cards) {
      if (card.getSuitValue() == targetSuit_) {
        return true;
      }
    }
    return false;
  }

  std::string getDescription() const override {
    const char *suitNames[] = {"Hearts", "Diamonds", "Clubs", "Spades"};
    if (targetSuit_ >= 0 && targetSuit_ < 4) {
      return std::string("Contains suit ") + suitNames[targetSuit_];
    }
    return "Contains suit (unknown)";
  }
};

} // namespace gameplay
