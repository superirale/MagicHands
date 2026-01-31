#pragma once

#include "Counter.h"

namespace gameplay {

/**
 * CardPropertyCounter - Counts cards by property (even/odd/face) or value
 * 
 * Handles: each_even, each_odd, each_face, each_<rank>, each_<suit>
 */
class CardPropertyCounter : public Counter {
public:
  enum class PropertyType {
    Even,           // each_even - cards with even rank
    Odd,            // each_odd - cards with odd rank
    Face,           // each_face - cards with rank >= 11 (J, Q, K)
    SpecificRank,   // each_7, each_K, etc.
    SpecificSuit,   // each_H, each_S, etc.
  };

  // Constructor for property-based counters
  explicit CardPropertyCounter(PropertyType type) 
      : m_Type(type), m_Rank(0), m_Suit(-1) {}

  // Constructor for specific rank counter
  CardPropertyCounter(PropertyType type, int rank)
      : m_Type(type), m_Rank(rank), m_Suit(-1) {}

  // Constructor for specific suit counter  
  CardPropertyCounter(PropertyType type, int suit, bool isSuit)
      : m_Type(type), m_Rank(0), m_Suit(suit) {}

  int count(const HandEvaluator::HandResult &handResult) const override {
    int total = 0;
    
    for (const auto &card : handResult.cards) {
      switch (m_Type) {
      case PropertyType::Even:
        if (card.getRankValue() % 2 == 0) {
          total++;
        }
        break;
        
      case PropertyType::Odd:
        if (card.getRankValue() % 2 != 0) {
          total++;
        }
        break;
        
      case PropertyType::Face:
        if (card.getRankValue() >= 11) { // J, Q, K
          total++;
        }
        break;
        
      case PropertyType::SpecificRank:
        if (card.getRankValue() == m_Rank) {
          total++;
        }
        break;
        
      case PropertyType::SpecificSuit:
        if (card.getSuitValue() == m_Suit) {
          total++;
        }
        break;
      }
    }
    
    return total;
  }

private:
  PropertyType m_Type;
  int m_Rank;  // For SpecificRank counter
  int m_Suit;  // For SpecificSuit counter
};

} // namespace gameplay
