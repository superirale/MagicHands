#include "HandEvaluator.h"
#include <algorithm>
#include <set>

namespace gameplay {

HandEvaluator::HandResult HandEvaluator::Evaluate(const std::vector<Card> &hand,
                                                  const Card &cut) {
  HandResult result;

  // Combine hand + cut for evaluation
  std::vector<Card> allCards = hand;
  allCards.push_back(cut);

  // Find all scoring patterns
  findFifteens(allCards, result);
  findPairs(allCards, result);
  findRuns(allCards, result);
  result.flushCount = findFlush(hand, cut);
  result.hasNobs = findNobs(hand, cut);

  return result;
}

// ===== FIFTEENS =====

void HandEvaluator::findFifteens(const std::vector<Card> &cards,
                                 HandResult &result) {
  std::vector<int> current;
  findFifteensRecursive(cards, current, 0, 0, result);
}

void HandEvaluator::findFifteensRecursive(const std::vector<Card> &cards,
                                          std::vector<int> &current, int start,
                                          int currentSum, HandResult &result) {
  // Check if current combination sums to 15
  if (currentSum == 15 && !current.empty()) {
    result.fifteens.push_back(current);
    return;
  }

  // Prune: if sum exceeds 15, stop exploring this branch
  if (currentSum > 15) {
    return;
  }

  // Try adding each remaining card
  for (size_t i = start; i < cards.size(); ++i) {
    current.push_back(static_cast<int>(i));
    findFifteensRecursive(cards, current, i + 1,
                          currentSum + cards[i].getValue(), result);
    current.pop_back();
  }
}

// ===== PAIRS =====

void HandEvaluator::findPairs(const std::vector<Card> &cards,
                              HandResult &result) {
  // Check all pairs of cards
  for (size_t i = 0; i < cards.size(); ++i) {
    for (size_t j = i + 1; j < cards.size(); ++j) {
      if (cards[i].getRank() == cards[j].getRank()) {
        result.pairs.push_back({static_cast<int>(i), static_cast<int>(j)});
      }
    }
  }
}

// ===== RUNS =====

void HandEvaluator::findRuns(const std::vector<Card> &cards,
                             HandResult &result) {
  // Sort cards by rank for run detection
  std::vector<int> indices(cards.size());
  for (size_t i = 0; i < cards.size(); ++i) {
    indices[i] = static_cast<int>(i);
  }

  std::sort(indices.begin(), indices.end(), [&cards](int a, int b) {
    return cards[a].getRankValue() < cards[b].getRankValue();
  });

  // Find all runs of length 3, 4, and 5
  // We need to handle duplicates carefully (e.g., 3-3-4-5 = two runs of 3-4-5)

  // Check for 5-card run first
  if (isValidRun(cards, indices)) {
    result.runs.push_back(indices);
    return; // If 5-card run exists, no smaller runs
  }

  // Check for 4-card runs (5 choose 4 = 5 combinations)
  std::set<std::vector<int>> uniqueRuns;
  for (size_t skip = 0; skip < indices.size(); ++skip) {
    std::vector<int> fourCardIndices;
    for (size_t i = 0; i < indices.size(); ++i) {
      if (i != skip)
        fourCardIndices.push_back(indices[i]);
    }
    if (isValidRun(cards, fourCardIndices)) {
      std::vector<int> sorted = fourCardIndices;
      std::sort(sorted.begin(), sorted.end());
      uniqueRuns.insert(sorted);
    }
  }

  if (!uniqueRuns.empty()) {
    for (const auto &run : uniqueRuns) {
      result.runs.push_back(run);
    }
    return; // If 4-card runs exist, no 3-card runs count
  }

  // Check for 3-card runs (5 choose 3 = 10 combinations)
  for (size_t i = 0; i < indices.size(); ++i) {
    for (size_t j = i + 1; j < indices.size(); ++j) {
      for (size_t k = j + 1; k < indices.size(); ++k) {
        std::vector<int> threeCardIndices = {indices[i], indices[j],
                                             indices[k]};
        if (isValidRun(cards, threeCardIndices)) {
          std::vector<int> sorted = threeCardIndices;
          std::sort(sorted.begin(), sorted.end());
          uniqueRuns.insert(sorted);
        }
      }
    }
  }

  for (const auto &run : uniqueRuns) {
    result.runs.push_back(run);
  }
}

bool HandEvaluator::isValidRun(const std::vector<Card> &cards,
                               const std::vector<int> &indices) {
  if (indices.size() < 3)
    return false;

  // Get ranks and sort
  std::vector<int> ranks;
  for (int idx : indices) {
    ranks.push_back(cards[idx].getRankValue());
  }
  std::sort(ranks.begin(), ranks.end());

  // Check if sequential
  for (size_t i = 1; i < ranks.size(); ++i) {
    if (ranks[i] != ranks[i - 1] + 1) {
      return false;
    }
  }

  return true;
}

// ===== FLUSH =====

int HandEvaluator::findFlush(const std::vector<Card> &hand, const Card &cut) {
  if (hand.size() != 4)
    return 0;

  // Check if all 4 hand cards have same suit
  Card::Suit firstSuit = hand[0].getSuit();
  bool allSameSuit = true;

  for (size_t i = 1; i < hand.size(); ++i) {
    if (hand[i].getSuit() != firstSuit) {
      allSameSuit = false;
      break;
    }
  }

  if (!allSameSuit)
    return 0;

  // 4-card flush found. Check if cut matches for 5-card flush
  if (cut.getSuit() == firstSuit) {
    return 5;
  }

  return 4;
}

// ===== NOBS =====

bool HandEvaluator::findNobs(const std::vector<Card> &hand, const Card &cut) {
  Card::Suit cutSuit = cut.getSuit();

  // Check if hand contains Jack with same suit as cut
  for (const Card &card : hand) {
    if (card.getRank() == Card::Rank::Jack && card.getSuit() == cutSuit) {
      return true;
    }
  }

  return false;
}

} // namespace gameplay
