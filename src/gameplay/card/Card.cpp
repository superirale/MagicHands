#include "Card.h"
#include <sstream>

namespace gameplay {

Card::Card(Rank rank, Suit suit) : rank_(rank), suit_(suit) {}

int Card::getValue() const {
  // Cribbage scoring: Face cards (J, Q, K) = 10, others = rank value
  int rankValue = static_cast<int>(rank_);
  return (rankValue >= 11) ? 10 : rankValue;
}

std::string Card::toString() const {
  std::ostringstream oss;

  // Get rank abbreviation
  int rankVal = static_cast<int>(rank_);
  if (rankVal == 1)
    oss << "A";
  else if (rankVal >= 2 && rankVal <= 10)
    oss << rankVal;
  else if (rankVal == 11)
    oss << "J";
  else if (rankVal == 12)
    oss << "Q";
  else if (rankVal == 13)
    oss << "K";

  oss << getSuitSymbol(suit_);
  return oss.str();
}

std::string Card::getRankName(Rank rank) {
  switch (rank) {
  case Rank::Ace:
    return "Ace";
  case Rank::Two:
    return "Two";
  case Rank::Three:
    return "Three";
  case Rank::Four:
    return "Four";
  case Rank::Five:
    return "Five";
  case Rank::Six:
    return "Six";
  case Rank::Seven:
    return "Seven";
  case Rank::Eight:
    return "Eight";
  case Rank::Nine:
    return "Nine";
  case Rank::Ten:
    return "Ten";
  case Rank::Jack:
    return "Jack";
  case Rank::Queen:
    return "Queen";
  case Rank::King:
    return "King";
  default:
    return "Unknown";
  }
}

std::string Card::getSuitName(Suit suit) {
  switch (suit) {
  case Suit::Hearts:
    return "Hearts";
  case Suit::Diamonds:
    return "Diamonds";
  case Suit::Clubs:
    return "Clubs";
  case Suit::Spades:
    return "Spades";
  default:
    return "Unknown";
  }
}

std::string Card::getSuitSymbol(Suit suit) {
  switch (suit) {
  case Suit::Hearts:
    return "♥";
  case Suit::Diamonds:
    return "♦";
  case Suit::Clubs:
    return "♣";
  case Suit::Spades:
    return "♠";
  default:
    return "?";
  }
}

bool Card::operator==(const Card &other) const {
  return rank_ == other.rank_ && suit_ == other.suit_;
}

bool Card::operator!=(const Card &other) const { return !(*this == other); }

bool Card::operator<(const Card &other) const {
  if (rank_ != other.rank_) {
    return rank_ < other.rank_;
  }
  return suit_ < other.suit_;
}

} // namespace gameplay
