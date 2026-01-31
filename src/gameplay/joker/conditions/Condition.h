#pragma once

#include "../../cribbage/HandEvaluator.h"
#include <memory>
#include <string>

namespace gameplay {

/// @brief Base interface for joker condition evaluation
/// Uses Strategy pattern - each condition type is a self-contained class
class Condition {
public:
  virtual ~Condition() = default;

  /// @brief Evaluate this condition against hand data
  /// @param hand Evaluated hand patterns and cards
  /// @return True if condition is met
  virtual bool evaluate(const HandEvaluator::HandResult &hand) const = 0;

  /// @brief Get human-readable description of this condition
  virtual std::string getDescription() const = 0;

  /// @brief Parse condition string and create appropriate Condition instance
  /// @param conditionStr Condition string from JSON (e.g., "contains_rank:7",
  /// "count_15s > 0")
  /// @return Unique pointer to Condition object, or AlwaysTrueCondition if
  /// unknown
  static std::unique_ptr<Condition> parse(const std::string &conditionStr);
};

/// @brief Condition that always evaluates to true (fallback for unknown
/// conditions)
class AlwaysTrueCondition : public Condition {
public:
  bool evaluate(const HandEvaluator::HandResult &hand) const override {
    return true;
  }

  std::string getDescription() const override { return "Always true"; }
};

} // namespace gameplay
