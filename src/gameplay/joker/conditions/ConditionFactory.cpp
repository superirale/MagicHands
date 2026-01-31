#include "Condition.h"
#include "ContainsRankCondition.h"
#include "ContainsSuitCondition.h"
#include "CountComparisonCondition.h"
#include "BooleanCondition.h"
#include "core/Logger.h"
#include <sstream>

namespace gameplay {

// Helper function to parse rank from string
static int ParseRank(const std::string &s) {
  if (s == "A" || s == "Ace")
    return 1;
  if (s == "J" || s == "Jack")
    return 11;
  if (s == "Q" || s == "Queen")
    return 12;
  if (s == "K" || s == "King")
    return 13;
  try {
    return std::stoi(s);
  } catch (...) {
    return 0;
  }
}

// Helper function to parse suit from string
static int ParseSuit(const std::string &s) {
  if (s == "H" || s == "Hearts")
    return 0;
  if (s == "D" || s == "Diamonds")
    return 1;
  if (s == "C" || s == "Clubs")
    return 2;
  if (s == "S" || s == "Spades")
    return 3;
  return -1;
}

// Parse comparison operator from string
static ComparisonOp ParseOperator(const std::string &op) {
  if (op == ">")
    return ComparisonOp::Greater;
  if (op == ">=")
    return ComparisonOp::GreaterEqual;
  if (op == "<")
    return ComparisonOp::Less;
  if (op == "<=")
    return ComparisonOp::LessEqual;
  if (op == "==")
    return ComparisonOp::Equal;
  if (op == "!=")
    return ComparisonOp::NotEqual;
  return ComparisonOp::Greater; // Default
}

// Parse count type from string
static CountType ParseCountType(const std::string &var) {
  if (var == "count_15s")
    return CountType::Fifteens;
  if (var == "count_pairs")
    return CountType::Pairs;
  if (var == "count_runs")
    return CountType::Runs;
  if (var == "flush_count")
    return CountType::FlushCount;
  if (var == "unique_categories")
    return CountType::UniqueCategories;
  return CountType::Fifteens; // Default
}

// Main parsing function (replaces 112 lines in JokerEffectSystem.cpp)
std::unique_ptr<Condition> Condition::parse(const std::string &conditionStr) {
  // Pattern: "contains_rank:7"
  if (conditionStr.find("contains_rank:") == 0) {
    std::string rankStr = conditionStr.substr(14);
    int rank = ParseRank(rankStr);
    return std::make_unique<ContainsRankCondition>(rank);
  }

  // Pattern: "contains_suit:H"
  if (conditionStr.find("contains_suit:") == 0) {
    std::string suitStr = conditionStr.substr(14);
    int suit = ParseSuit(suitStr);
    return std::make_unique<ContainsSuitCondition>(suit);
  }

  // Pattern: "count_15s > 0" (variable operator value)
  std::istringstream iss(conditionStr);
  std::string var, op;
  int value;

  iss >> var >> op >> value;

  // Check if parsing succeeded
  if (iss.fail()) {
    // Boolean conditions without operator (e.g., "has_nobs", "hand_total_21")
    if (conditionStr == "has_nobs") {
      return std::make_unique<HasNobsCondition>();
    }
    
    if (conditionStr == "hand_total_21") {
      return std::make_unique<HandTotal21Condition>();
    }

    // Unknown condition format
    LOG_WARN("Unknown condition format: %s", conditionStr.c_str());
    return std::make_unique<AlwaysTrueCondition>();
  }

  // Parse as count comparison
  CountType countType = ParseCountType(var);
  ComparisonOp compOp = ParseOperator(op);

  return std::make_unique<CountComparisonCondition>(countType, compOp, value);
}

} // namespace gameplay
