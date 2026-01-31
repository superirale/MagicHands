#pragma once

#include "gameplay/cribbage/HandEvaluator.h"
#include <memory>
#include <string>

namespace gameplay {

/**
 * Counter - Strategy Pattern base class for "per" multipliers
 * 
 * Replaces GetCountValue() string parsing (43 lines) with polymorphic classes.
 * Each counter type (each_15, each_pair, each_even, etc.) is a separate class.
 * 
 * Usage:
 *   auto counter = Counter::parse("each_15");
 *   int count = counter->count(handResult);
 */
class Counter {
public:
  virtual ~Counter() = default;
  
  /**
   * Count occurrences based on counter type
   * @param handResult The evaluated hand with scoring data
   * @return Number of occurrences (multiplier for joker effects)
   */
  virtual int count(const HandEvaluator::HandResult &handResult) const = 0;
  
  /**
   * Factory method - parses string and creates appropriate Counter
   * @param perString "each_15", "each_pair", "each_even", etc.
   * @return Unique pointer to Counter subclass
   */
  static std::unique_ptr<Counter> parse(const std::string &perString);
};

/**
 * ConstantCounter - Always returns 1 (default multiplier)
 * Used when "per" field is empty or unknown
 */
class ConstantCounter : public Counter {
public:
  int count(const HandEvaluator::HandResult &handResult) const override {
    return 1;
  }
};

} // namespace gameplay
