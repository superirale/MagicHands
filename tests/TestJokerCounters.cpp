#include "gameplay/joker/counters/Counter.h"
#include "gameplay/joker/counters/PatternCounter.h"
#include "gameplay/joker/counters/CardPropertyCounter.h"
#include "gameplay/card/Card.h"
#include <catch2/catch_test_macros.hpp>

using namespace gameplay;

// Helper to create a test hand result
static HandEvaluator::HandResult createTestHand(const std::vector<Card> &cards) {
  HandEvaluator::HandResult result;
  result.cards = cards;
  return result;
}

TEST_CASE("Counter System", "[joker][counter]") {
  SECTION("PatternCounter - counts fifteens") {
    HandEvaluator::HandResult hand;
    hand.fifteens = {{0, 1}, {2, 3}, {0, 4}};

    PatternCounter counter(PatternCounter::PatternType::Fifteens);
    REQUIRE(counter.count(hand) == 3);
  }

  SECTION("PatternCounter - counts pairs") {
    HandEvaluator::HandResult hand;
    hand.pairs = {{0, 1}, {2, 3}};

    PatternCounter counter(PatternCounter::PatternType::Pairs);
    REQUIRE(counter.count(hand) == 2);
  }

  SECTION("PatternCounter - counts runs") {
    HandEvaluator::HandResult hand;
    hand.runs = {{0, 1, 2}, {3, 4, 5, 6}};

    PatternCounter counter(PatternCounter::PatternType::Runs);
    REQUIRE(counter.count(hand) == 2);
  }

  SECTION("PatternCounter - counts cards in runs") {
    HandEvaluator::HandResult hand;
    hand.runs = {{0, 1, 2}, {3, 4}};

    PatternCounter counter(PatternCounter::PatternType::CardsInRuns);
    REQUIRE(counter.count(hand) == 5); // 3 + 2
  }

  SECTION("PatternCounter - counts total cards") {
    std::vector<Card> cards = {
        Card(Card::Rank::Seven, Card::Suit::Hearts),
        Card(Card::Rank::Eight, Card::Suit::Diamonds),
        Card(Card::Rank::Nine, Card::Suit::Spades)};
    auto hand = createTestHand(cards);

    PatternCounter counter(PatternCounter::PatternType::CardCount);
    REQUIRE(counter.count(hand) == 3);
  }

  SECTION("CardPropertyCounter - counts even cards") {
    std::vector<Card> cards = {
        Card(Card::Rank::Two, Card::Suit::Hearts),   // 2 - even
        Card(Card::Rank::Four, Card::Suit::Diamonds), // 4 - even
        Card(Card::Rank::Seven, Card::Suit::Spades)   // 7 - odd
    };
    auto hand = createTestHand(cards);

    CardPropertyCounter counter(CardPropertyCounter::PropertyType::Even);
    REQUIRE(counter.count(hand) == 2);
  }

  SECTION("CardPropertyCounter - counts odd cards") {
    std::vector<Card> cards = {
        Card(Card::Rank::Three, Card::Suit::Hearts), // 3 - odd
        Card(Card::Rank::Five, Card::Suit::Diamonds), // 5 - odd
        Card(Card::Rank::Six, Card::Suit::Spades)    // 6 - even
    };
    auto hand = createTestHand(cards);

    CardPropertyCounter counter(CardPropertyCounter::PropertyType::Odd);
    REQUIRE(counter.count(hand) == 2);
  }

  SECTION("CardPropertyCounter - counts face cards") {
    std::vector<Card> cards = {
        Card(Card::Rank::Jack, Card::Suit::Hearts),  // Face
        Card(Card::Rank::Queen, Card::Suit::Diamonds), // Face
        Card(Card::Rank::Seven, Card::Suit::Spades)   // Not face
    };
    auto hand = createTestHand(cards);

    CardPropertyCounter counter(CardPropertyCounter::PropertyType::Face);
    REQUIRE(counter.count(hand) == 2);
  }

  SECTION("CardPropertyCounter - counts specific rank") {
    std::vector<Card> cards = {
        Card(Card::Rank::Seven, Card::Suit::Hearts),
        Card(Card::Rank::Seven, Card::Suit::Diamonds),
        Card(Card::Rank::Eight, Card::Suit::Spades)};
    auto hand = createTestHand(cards);

    CardPropertyCounter counter(CardPropertyCounter::PropertyType::SpecificRank,
                                7);
    REQUIRE(counter.count(hand) == 2);
  }

  SECTION("CardPropertyCounter - counts specific suit") {
    std::vector<Card> cards = {
        Card(Card::Rank::Seven, Card::Suit::Hearts),
        Card(Card::Rank::Eight, Card::Suit::Hearts),
        Card(Card::Rank::Nine, Card::Suit::Spades)};
    auto hand = createTestHand(cards);

    CardPropertyCounter counter(
        CardPropertyCounter::PropertyType::SpecificSuit, 0, true); // Hearts = 0
    REQUIRE(counter.count(hand) == 2);
  }

  SECTION("Counter Factory - parses each_15") {
    HandEvaluator::HandResult hand;
    hand.fifteens = {{0, 1}, {2, 3}};

    auto counter = Counter::parse("each_15");
    REQUIRE(counter->count(hand) == 2);
  }

  SECTION("Counter Factory - parses each_pair") {
    HandEvaluator::HandResult hand;
    hand.pairs = {{0, 1}};

    auto counter = Counter::parse("each_pair");
    REQUIRE(counter->count(hand) == 1);
  }

  SECTION("Counter Factory - parses each_even") {
    std::vector<Card> cards = {
        Card(Card::Rank::Two, Card::Suit::Hearts),
        Card(Card::Rank::Four, Card::Suit::Diamonds)};
    auto hand = createTestHand(cards);

    auto counter = Counter::parse("each_even");
    REQUIRE(counter->count(hand) == 2);
  }

  SECTION("Counter Factory - parses each_<rank>") {
    std::vector<Card> cards = {
        Card(Card::Rank::King, Card::Suit::Hearts),
        Card(Card::Rank::King, Card::Suit::Diamonds),
        Card(Card::Rank::Seven, Card::Suit::Spades)};
    auto hand = createTestHand(cards);

    auto counter = Counter::parse("each_K");
    REQUIRE(counter->count(hand) == 2);
  }

  SECTION("Counter Factory - parses empty string as constant") {
    HandEvaluator::HandResult hand;

    auto counter = Counter::parse("");
    REQUIRE(counter->count(hand) == 1);
  }

  SECTION("ConstantCounter - always returns 1") {
    HandEvaluator::HandResult hand;
    ConstantCounter counter;
    REQUIRE(counter.count(hand) == 1);
  }
}
