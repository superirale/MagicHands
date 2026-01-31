#include "Counter.h"
#include "PatternCounter.h"
#include "CardPropertyCounter.h"
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

/**
 * Factory method - parses "per" string and creates appropriate Counter
 * Replaces GetCountValue() string parsing (43 lines) with Strategy Pattern
 */
std::unique_ptr<Counter> Counter::parse(const std::string &perString) {
  // Empty string = constant multiplier of 1
  if (perString.empty()) {
    return std::make_unique<ConstantCounter>();
  }

  // Pattern counters (cribbage scoring patterns)
  if (perString == "each_15") {
    return std::make_unique<PatternCounter>(PatternCounter::PatternType::Fifteens);
  }
  if (perString == "each_pair") {
    return std::make_unique<PatternCounter>(PatternCounter::PatternType::Pairs);
  }
  if (perString == "each_run") {
    return std::make_unique<PatternCounter>(PatternCounter::PatternType::Runs);
  }
  if (perString == "cards_in_runs") {
    return std::make_unique<PatternCounter>(PatternCounter::PatternType::CardsInRuns);
  }
  if (perString == "card_count") {
    return std::make_unique<PatternCounter>(PatternCounter::PatternType::CardCount);
  }

  // Card property counters
  if (perString == "each_even") {
    return std::make_unique<CardPropertyCounter>(
        CardPropertyCounter::PropertyType::Even);
  }
  if (perString == "each_odd") {
    return std::make_unique<CardPropertyCounter>(
        CardPropertyCounter::PropertyType::Odd);
  }
  if (perString == "each_face") {
    return std::make_unique<CardPropertyCounter>(
        CardPropertyCounter::PropertyType::Face);
  }

  // Generic "each_<rank>" or "each_<suit>" pattern
  if (perString.find("each_") == 0) {
    std::string suffix = perString.substr(5);
    
    // Try parsing as rank (e.g., "each_7", "each_K")
    int rank = ParseRank(suffix);
    if (rank > 0) {
      return std::make_unique<CardPropertyCounter>(
          CardPropertyCounter::PropertyType::SpecificRank, rank);
    }
    
    // Try parsing as suit (e.g., "each_H", "each_S")
    int suit = ParseSuit(suffix);
    if (suit >= 0) {
      return std::make_unique<CardPropertyCounter>(
          CardPropertyCounter::PropertyType::SpecificSuit, suit, true);
    }
  }

  // Unknown counter type - log warning and return constant
  LOG_WARN("Unknown counter type: %s (defaulting to 1)", perString.c_str());
  return std::make_unique<ConstantCounter>();
}

} // namespace gameplay
