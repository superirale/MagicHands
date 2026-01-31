#include "gameplay/joker/effects/Effect.h"
#include "gameplay/joker/effects/AddChipsEffect.h"
#include "gameplay/joker/effects/AddMultiplierEffect.h"
#include "gameplay/joker/effects/AddPermMultEffect.h"
#include <catch2/catch_test_macros.hpp>

using namespace gameplay;

TEST_CASE("Effect System", "[joker][effect]") {
  HandEvaluator::HandResult hand; // Empty hand for testing

  SECTION("AddChipsEffect - adds chips") {
    AddChipsEffect effect(10.0f);

    auto result = effect.apply(hand, 1);
    REQUIRE(result.addedChips == 10);
    REQUIRE(result.addedTempMult == 0.0f);
    REQUIRE(result.addedPermMult == 0.0f);
  }

  SECTION("AddChipsEffect - multiplies by count") {
    AddChipsEffect effect(15.0f);

    auto result = effect.apply(hand, 3);
    REQUIRE(result.addedChips == 45); // 15 * 3
  }

  SECTION("AddMultiplierEffect - adds temporary multiplier") {
    AddMultiplierEffect effect(2.5f);

    auto result = effect.apply(hand, 1);
    REQUIRE(result.addedChips == 0);
    REQUIRE(result.addedTempMult == 2.5f);
    REQUIRE(result.addedPermMult == 0.0f);
  }

  SECTION("AddMultiplierEffect - multiplies by count") {
    AddMultiplierEffect effect(1.0f);

    auto result = effect.apply(hand, 4);
    REQUIRE(result.addedTempMult == 4.0f); // 1.0 * 4
  }

  SECTION("AddPermMultEffect - adds permanent multiplier") {
    AddPermMultEffect effect(0.5f);

    auto result = effect.apply(hand, 1);
    REQUIRE(result.addedChips == 0);
    REQUIRE(result.addedTempMult == 0.0f);
    REQUIRE(result.addedPermMult == 0.5f);
  }

  SECTION("AddPermMultEffect - multiplies by count") {
    AddPermMultEffect effect(0.2f);

    auto result = effect.apply(hand, 5);
    REQUIRE(result.addedPermMult == 1.0f); // 0.2 * 5
  }

  SECTION("Effect Factory - creates AddChipsEffect") {
    auto effect = Effect::create("add_chips", 25.0f);
    auto result = effect->apply(hand, 2);

    REQUIRE(result.addedChips == 50); // 25 * 2
  }

  SECTION("Effect Factory - creates AddMultiplierEffect") {
    auto effect = Effect::create("add_multiplier", 3.0f);
    auto result = effect->apply(hand, 1);

    REQUIRE(result.addedTempMult == 3.0f);
  }

  SECTION("Effect Factory - handles alias add_temp_mult") {
    auto effect = Effect::create("add_temp_mult", 2.0f);
    auto result = effect->apply(hand, 1);

    REQUIRE(result.addedTempMult == 2.0f);
  }

  SECTION("Effect Factory - creates AddPermMultEffect") {
    auto effect = Effect::create("add_permanent_multiplier", 1.5f);
    auto result = effect->apply(hand, 1);

    REQUIRE(result.addedPermMult == 1.5f);
  }

  SECTION("Effect Factory - unknown type returns NoOpEffect") {
    auto effect = Effect::create("unknown_effect", 100.0f);
    auto result = effect->apply(hand, 1);

    // NoOpEffect should return all zeros
    REQUIRE(result.addedChips == 0);
    REQUIRE(result.addedTempMult == 0.0f);
    REQUIRE(result.addedPermMult == 0.0f);
  }

  SECTION("NoOpEffect - does nothing") {
    NoOpEffect effect;
    auto result = effect.apply(hand, 999);

    REQUIRE(result.addedChips == 0);
    REQUIRE(result.addedTempMult == 0.0f);
    REQUIRE(result.addedPermMult == 0.0f);
  }

  SECTION("Effect getValue() works correctly") {
    AddChipsEffect chipsEffect(42.0f);
    REQUIRE(chipsEffect.getValue() == 42.0f);

    AddMultiplierEffect multEffect(3.5f);
    REQUIRE(multEffect.getValue() == 3.5f);

    NoOpEffect noopEffect;
    REQUIRE(noopEffect.getValue() == 0.0f);
  }
}
