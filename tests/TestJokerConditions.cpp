#include "gameplay/joker/conditions/Condition.h"
#include "gameplay/joker/conditions/ContainsRankCondition.h"
#include "gameplay/joker/conditions/ContainsSuitCondition.h"
#include "gameplay/joker/conditions/CountComparisonCondition.h"
#include "gameplay/joker/conditions/BooleanCondition.h"
#include "gameplay/card/Card.h"
#include <catch2/catch_test_macros.hpp>

using namespace gameplay;

// Helper to create a test hand result
static HandEvaluator::HandResult createTestHand(const std::vector<Card> &cards) {
  HandEvaluator::HandResult result;
  result.cards = cards;
  return result;
}

TEST_CASE("Condition System", "[joker][condition]") {
  SECTION("ContainsRankCondition - finds specific rank") {
    // Create hand with cards: 7H, 7D, 8S
    std::vector<Card> cards = {
        Card(Card::Rank::Seven, Card::Suit::Hearts),
        Card(Card::Rank::Seven, Card::Suit::Diamonds),
        Card(Card::Rank::Eight, Card::Suit::Spades)};
    auto hand = createTestHand(cards);

    ContainsRankCondition condition7(7);
    REQUIRE(condition7.evaluate(hand) == true);

    ContainsRankCondition condition9(9);
    REQUIRE(condition9.evaluate(hand) == false);
  }

  SECTION("ContainsSuitCondition - finds specific suit") {
    // Create hand with cards: 7H, 8H, 9S
    std::vector<Card> cards = {
        Card(Card::Rank::Seven, Card::Suit::Hearts),
        Card(Card::Rank::Eight, Card::Suit::Hearts),
        Card(Card::Rank::Nine, Card::Suit::Spades)};
    auto hand = createTestHand(cards);

    ContainsSuitCondition conditionHearts(0); // Hearts = 0
    REQUIRE(conditionHearts.evaluate(hand) == true);

    ContainsSuitCondition conditionClubs(2); // Clubs = 2
    REQUIRE(conditionClubs.evaluate(hand) == false);
  }

  SECTION("CountComparisonCondition - Greater operator") {
    HandEvaluator::HandResult hand;
    // Simulate 3 fifteens
    hand.fifteens = {{0, 1}, {2, 3}, {0, 4}};

    CountComparisonCondition condition(CountType::Fifteens,
                                       ComparisonOp::Greater, 0);
    REQUIRE(condition.evaluate(hand) == true);

    CountComparisonCondition condition2(CountType::Fifteens,
                                        ComparisonOp::Greater, 5);
    REQUIRE(condition2.evaluate(hand) == false);
  }

  SECTION("CountComparisonCondition - Equal operator") {
    HandEvaluator::HandResult hand;
    hand.pairs = {{0, 1}, {2, 3}};

    CountComparisonCondition condition(CountType::Pairs, ComparisonOp::Equal,
                                       2);
    REQUIRE(condition.evaluate(hand) == true);

    CountComparisonCondition condition2(CountType::Pairs, ComparisonOp::Equal,
                                        3);
    REQUIRE(condition2.evaluate(hand) == false);
  }

  SECTION("Condition Factory - parses contains_rank") {
    std::vector<Card> cards = {Card(Card::Rank::King, Card::Suit::Hearts)};
    auto hand = createTestHand(cards);

    auto condition = Condition::parse("contains_rank:K");
    REQUIRE(condition->evaluate(hand) == true);

    auto condition2 = Condition::parse("contains_rank:7");
    REQUIRE(condition2->evaluate(hand) == false);
  }

  SECTION("Condition Factory - parses contains_suit") {
    std::vector<Card> cards = {Card(Card::Rank::Seven, Card::Suit::Spades)};
    auto hand = createTestHand(cards);

    auto condition = Condition::parse("contains_suit:S");
    REQUIRE(condition->evaluate(hand) == true);

    auto condition2 = Condition::parse("contains_suit:H");
    REQUIRE(condition2->evaluate(hand) == false);
  }

  SECTION("Condition Factory - parses count comparison") {
    HandEvaluator::HandResult hand;
    hand.fifteens = {{0, 1}, {2, 3}};

    auto condition = Condition::parse("count_15s > 0");
    REQUIRE(condition->evaluate(hand) == true);

    auto condition2 = Condition::parse("count_15s == 2");
    REQUIRE(condition2->evaluate(hand) == true);

    auto condition3 = Condition::parse("count_15s < 1");
    REQUIRE(condition3->evaluate(hand) == false);
  }

  SECTION("AlwaysTrueCondition - always returns true") {
    HandEvaluator::HandResult hand;
    AlwaysTrueCondition condition;
    REQUIRE(condition.evaluate(hand) == true);
  }

  SECTION("HasNobsCondition - checks for nobs") {
    HandEvaluator::HandResult hand;
    hand.hasNobs = true;

    HasNobsCondition condition;
    REQUIRE(condition.evaluate(hand) == true);

    hand.hasNobs = false;
    REQUIRE(condition.evaluate(hand) == false);
  }

  SECTION("HandTotal21Condition - checks if total equals 21") {
    // Hand totaling 21: K (10) + J (10) + A (1) = 21
    std::vector<Card> cards = {
        Card(Card::Rank::King, Card::Suit::Hearts),  // 10
        Card(Card::Rank::Jack, Card::Suit::Diamonds), // 10
        Card(Card::Rank::Ace, Card::Suit::Spades)     // 1
    };
    auto hand = createTestHand(cards);

    HandTotal21Condition condition;
    REQUIRE(condition.evaluate(hand) == true);

    // Hand not totaling 21
    std::vector<Card> cards2 = {
        Card(Card::Rank::Seven, Card::Suit::Hearts),
        Card(Card::Rank::Eight, Card::Suit::Diamonds)
    };
    auto hand2 = createTestHand(cards2);
    REQUIRE(condition.evaluate(hand2) == false);
  }

  SECTION("Condition Factory - parses has_nobs") {
    HandEvaluator::HandResult hand;
    hand.hasNobs = true;

    auto condition = Condition::parse("has_nobs");
    REQUIRE(condition->evaluate(hand) == true);
  }

  SECTION("Condition Factory - parses hand_total_21") {
    std::vector<Card> cards = {
        Card(Card::Rank::King, Card::Suit::Hearts),
        Card(Card::Rank::Jack, Card::Suit::Diamonds),
        Card(Card::Rank::Ace, Card::Suit::Spades)
    };
    auto hand = createTestHand(cards);

    auto condition = Condition::parse("hand_total_21");
    REQUIRE(condition->evaluate(hand) == true);
  }
}
