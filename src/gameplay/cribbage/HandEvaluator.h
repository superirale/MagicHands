#pragma once

#include "gameplay/card/Card.h"
#include <vector>

namespace gameplay {

/// @brief Evaluates a cribbage hand and detects all scoring patterns
class HandEvaluator {
public:
  /// @brief Result of hand evaluation containing all detected patterns
  struct HandResult {
    /// Indices of cards that make 15 (each vector is one fifteen combo)
    std::vector<std::vector<int>> fifteens;

    /// Indices of cards that form pairs (each vector is one pair)
    std::vector<std::vector<int>> pairs;

    /// Indices of cards that form runs (each vector is one run of length 3+)
    std::vector<std::vector<int>> runs;

    /// Number of cards in flush (0, 4, or 5)
    int flushCount = 0;

    /// True if hand contains Jack matching cut card's suit (Nobs)
    bool hasNobs = false;
  };

  /// @brief Evaluate a hand with a cut card
  /// @param hand The 4-card hand
  /// @param cut The cut card (5th card)
  /// @return All detected scoring patterns
  static HandResult Evaluate(const std::vector<Card> &hand, const Card &cut);

private:
  /// @brief Find all combinations of cards that sum to 15
  static void findFifteens(const std::vector<Card> &cards, HandResult &result);

  /// @brief Find all pairs in the cards
  static void findPairs(const std::vector<Card> &cards, HandResult &result);

  /// @brief Find all runs (3+ sequential cards)
  static void findRuns(const std::vector<Card> &cards, HandResult &result);

  /// @brief Check for flush (4 or 5 cards same suit)
  static int findFlush(const std::vector<Card> &hand, const Card &cut);

  /// @brief Check for nobs (Jack matches cut suit)
  static bool findNobs(const std::vector<Card> &hand, const Card &cut);

  /// @brief Helper: Generate all subsets for fifteen detection
  static void findFifteensRecursive(const std::vector<Card> &cards,
                                    std::vector<int> &current, int start,
                                    int currentSum, HandResult &result);

  /// @brief Helper: Check if indices form a valid run
  static bool isValidRun(const std::vector<Card> &cards,
                         const std::vector<int> &indices);
};

} // namespace gameplay
