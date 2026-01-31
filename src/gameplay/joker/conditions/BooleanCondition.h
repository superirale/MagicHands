#pragma once

#include "Condition.h"

namespace gameplay {

/**
 * BooleanCondition - Base class for simple true/false checks
 */
class BooleanCondition : public Condition {
public:
  virtual ~BooleanCondition() = default;
};

/**
 * HasNobsCondition - Checks if hand has nobs (Jack of same suit as cut card)
 */
class HasNobsCondition : public BooleanCondition {
public:
  bool evaluate(const HandEvaluator::HandResult &handResult) const override {
    return handResult.hasNobs;
  }
  
  std::string getDescription() const override {
    return "has_nobs";
  }
};

/**
 * HandTotal21Condition - Checks if hand total equals 21 (Blackjack)
 */
class HandTotal21Condition : public BooleanCondition {
public:
  bool evaluate(const HandEvaluator::HandResult &handResult) const override {
    int sum = 0;
    for (const auto &card : handResult.cards) {
      sum += card.getValue();
    }
    return sum == 21;
  }
  
  std::string getDescription() const override {
    return "hand_total_21";
  }
};

} // namespace gameplay
