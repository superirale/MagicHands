#pragma once

#include "Condition.h"

namespace gameplay {

/// @brief Type of count to extract from hand
enum class CountType {
  Fifteens,       // count_15s
  Pairs,          // count_pairs
  Runs,           // count_runs
  FlushCount,     // flush_count
  UniqueCategories // unique_categories
};

/// @brief Comparison operator
enum class ComparisonOp {
  Greater,       // >
  GreaterEqual,  // >=
  Less,          // <
  LessEqual,     // <=
  Equal,         // ==
  NotEqual       // !=
};

/// @brief Condition that compares a count value against a threshold
/// Parses strings like "count_15s > 0", "count_pairs >= 2", etc.
class CountComparisonCondition : public Condition {
  CountType type_;
  ComparisonOp op_;
  int value_;

public:
  /// @brief Constructor
  CountComparisonCondition(CountType type, ComparisonOp op, int value)
      : type_(type), op_(op), value_(value) {}

  bool evaluate(const HandEvaluator::HandResult &hand) const override {
    int actualValue = getCount(type_, hand);
    return compare(actualValue, op_, value_);
  }

  std::string getDescription() const override {
    return getCountName(type_) + " " + getOpString(op_) + " " +
           std::to_string(value_);
  }

private:
  /// @brief Get count value from hand based on type
  int getCount(CountType type, const HandEvaluator::HandResult &hand) const {
    switch (type) {
    case CountType::Fifteens:
      return static_cast<int>(hand.fifteens.size());
    case CountType::Pairs:
      return static_cast<int>(hand.pairs.size());
    case CountType::Runs:
      return static_cast<int>(hand.runs.size());
    case CountType::FlushCount:
      return hand.flushCount;
    case CountType::UniqueCategories: {
      int cats = 0;
      if (!hand.fifteens.empty())
        cats++;
      if (!hand.pairs.empty())
        cats++;
      if (!hand.runs.empty())
        cats++;
      if (hand.flushCount >= 4)
        cats++;
      if (hand.hasNobs)
        cats++;
      return cats;
    }
    }
    return 0;
  }

  /// @brief Compare two values based on operator
  bool compare(int actual, ComparisonOp op, int expected) const {
    switch (op) {
    case ComparisonOp::Greater:
      return actual > expected;
    case ComparisonOp::GreaterEqual:
      return actual >= expected;
    case ComparisonOp::Less:
      return actual < expected;
    case ComparisonOp::LessEqual:
      return actual <= expected;
    case ComparisonOp::Equal:
      return actual == expected;
    case ComparisonOp::NotEqual:
      return actual != expected;
    }
    return false;
  }

  /// @brief Get string representation of count type
  std::string getCountName(CountType type) const {
    switch (type) {
    case CountType::Fifteens:
      return "count_15s";
    case CountType::Pairs:
      return "count_pairs";
    case CountType::Runs:
      return "count_runs";
    case CountType::FlushCount:
      return "flush_count";
    case CountType::UniqueCategories:
      return "unique_categories";
    }
    return "unknown";
  }

  /// @brief Get string representation of operator
  std::string getOpString(ComparisonOp op) const {
    switch (op) {
    case ComparisonOp::Greater:
      return ">";
    case ComparisonOp::GreaterEqual:
      return ">=";
    case ComparisonOp::Less:
      return "<";
    case ComparisonOp::LessEqual:
      return "<=";
    case ComparisonOp::Equal:
      return "==";
    case ComparisonOp::NotEqual:
      return "!=";
    }
    return "?";
  }
};

} // namespace gameplay
