#include "Deck.h"
#include <algorithm>
#include <chrono>
#include <stdexcept>

namespace gameplay {

Deck::Deck(uint64_t seed) {
  if (seed == 0) {
    // Use current time as seed
    seed_ = static_cast<uint64_t>(
        std::chrono::high_resolution_clock::now().time_since_epoch().count());
  } else {
    seed_ = seed;
  }

  rng_.seed(seed_);
  initializeStandardDeck();
}

void Deck::initializeStandardDeck() {
  cards_.clear();
  cards_.reserve(52);

  // Create all 52 cards
  for (int suit = 0; suit < 4; ++suit) {
    for (int rank = 1; rank <= 13; ++rank) {
      cards_.emplace_back(static_cast<Card::Rank>(rank),
                          static_cast<Card::Suit>(suit));
    }
  }
}

void Deck::shuffle() { std::shuffle(cards_.begin(), cards_.end(), rng_); }

Card Deck::draw() {
  if (cards_.empty()) {
    throw std::runtime_error("Cannot draw from empty deck");
  }

  Card card = cards_.back();
  cards_.pop_back();
  return card;
}

std::vector<Card> Deck::drawMultiple(int count) {
  if (static_cast<size_t>(count) > cards_.size()) {
    throw std::runtime_error("Not enough cards in deck");
  }

  std::vector<Card> drawn;
  drawn.reserve(count);

  for (int i = 0; i < count; ++i) {
    drawn.push_back(draw());
  }

  return drawn;
}

void Deck::reset() { initializeStandardDeck(); }

void Deck::removeRank(Card::Rank rank) {
  cards_.erase(std::remove_if(
                   cards_.begin(), cards_.end(),
                   [rank](const Card &card) { return card.getRank() == rank; }),
               cards_.end());
}

void Deck::duplicateCard(const Card &card) { cards_.push_back(card); }

} // namespace gameplay
