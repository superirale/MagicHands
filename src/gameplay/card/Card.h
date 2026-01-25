#pragma once

#include <cstdint>
#include <string>

namespace gameplay {

/// @brief Represents a standard playing card
class Card {
public:
  enum class Rank : uint8_t {
    Ace = 1,
    Two = 2,
    Three = 3,
    Four = 4,
    Five = 5,
    Six = 6,
    Seven = 7,
    Eight = 8,
    Nine = 9,
    Ten = 10,
    Jack = 11,
    Queen = 12,
    King = 13
  };

  enum class Suit : uint8_t { Hearts = 0, Diamonds = 1, Clubs = 2, Spades = 3 };

  Card() = default;
  Card(Rank rank, Suit suit);

  Rank getRank() const { return rank_; }
  Suit getSuit() const { return suit_; }

  /// @brief Get card value for Cribbage scoring (Face cards = 10, Ace = 1)
  int getValue() const;

  /// @brief Get rank as integer (1-13)
  int getRankValue() const { return static_cast<int>(rank_); }

  /// @brief Get suit as integer (0-3)
  int getSuitValue() const { return static_cast<int>(suit_); }

  /// @brief Get string representation (e.g., "A♠", "K♥")
  std::string toString() const;

  /// @brief Get rank name (e.g., "Ace", "King")
  static std::string getRankName(Rank rank);

  /// @brief Get suit name (e.g., "Hearts", "Spades")
  static std::string getSuitName(Suit suit);

  /// @brief Get suit symbol (e.g., "♥", "♠")
  static std::string getSuitSymbol(Suit suit);

  // Comparison operators for sorting
  bool operator==(const Card &other) const;
  bool operator!=(const Card &other) const;
  bool operator<(const Card &other) const;

private:
  Rank rank_ = Rank::Ace;
  Suit suit_ = Suit::Hearts;
};

} // namespace gameplay
