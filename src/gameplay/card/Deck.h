#pragma once

#include "Card.h"
#include <cstdint>
#include <random>
#include <vector>

namespace gameplay {

/// @brief Manages a deck of playing cards with seeded RNG for deterministic
/// shuffling
class Deck {
public:
  /// @brief Create a standard 52-card deck with optional seed
  /// @param seed RNG seed (0 = random seed from time)
  explicit Deck(uint64_t seed = 0);

  /// @brief Shuffle the deck using the seeded RNG
  void shuffle();

  /// @brief Draw a single card from the top of the deck
  /// @return The drawn card (throws if deck is empty)
  Card draw();

  /// @brief Draw multiple cards from the deck
  /// @param count Number of cards to draw
  /// @return Vector of drawn cards
  std::vector<Card> drawMultiple(int count);

  /// @brief Reset deck to full 52 cards
  void reset();

  /// @brief Get number of cards remaining in deck
  size_t getSize() const { return cards_.size(); }

  /// @brief Check if deck is empty
  bool isEmpty() const { return cards_.empty(); }

  /// @brief Remove all cards of a specific rank (for shop upgrades)
  /// @param rank Rank to remove
  void removeRank(Card::Rank rank);

  /// @brief Add a duplicate of a specific card (for deck mods)
  /// @param card Card to duplicate
  void duplicateCard(const Card &card);

  /// @brief Get the RNG seed being used
  uint64_t getSeed() const { return seed_; }

private:
  void initializeStandardDeck();

  std::vector<Card> cards_;
  std::mt19937_64 rng_;
  uint64_t seed_;
};

} // namespace gameplay
