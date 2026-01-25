// test_result.cpp
// Unit tests for the Result<T> type

#include "core/Result.h"
#include <catch2/catch_test_macros.hpp>

TEST_CASE("Result<T> - Success cases", "[result]") {
  SECTION("Create success result with value") {
    Result<int> result = 42;

    REQUIRE(result.IsOk());
    REQUIRE_FALSE(result.IsError());
    REQUIRE(result.GetValue() == 42);
  }

  SECTION("Implicit bool conversion for success") {
    Result<int> result = 100;

    if (result) {
      REQUIRE(result.GetValue() == 100);
    } else {
      FAIL("Result should be Ok");
    }
  }

  SECTION("GetValueOr returns value on success") {
    Result<int> result = 42;
    REQUIRE(result.GetValueOr(0) == 42);
  }
}

TEST_CASE("Result<T> - Error cases", "[result]") {
  SECTION("Create error result") {
    Result<int> result = Error{"Something went wrong"};

    REQUIRE(result.IsError());
    REQUIRE_FALSE(result.IsOk());
    REQUIRE(result.GetError().message == "Something went wrong");
  }

  SECTION("Implicit bool conversion for error") {
    Result<int> result = Error{"Failed"};

    if (result) {
      FAIL("Result should be Error");
    } else {
      REQUIRE(result.GetError().message == "Failed");
    }
  }

  SECTION("GetValueOr returns default on error") {
    Result<int> result = Error{"Failed"};
    REQUIRE(result.GetValueOr(99) == 99);
  }
}

TEST_CASE("Result<T> - Err convenience function", "[result]") {
  auto result = Err<int>("Custom error");

  REQUIRE(result.IsError());
  REQUIRE(result.GetError().message == "Custom error");
}

TEST_CASE("Result<void> - Specialization", "[result]") {
  SECTION("Success void result") {
    Result<void> result = Ok();

    REQUIRE(result.IsOk());
    REQUIRE_FALSE(result.IsError());
  }

  SECTION("Error void result") {
    Result<void> result = Error{"Operation failed"};

    REQUIRE(result.IsError());
    REQUIRE(result.GetError().message == "Operation failed");
  }

  SECTION("Implicit bool conversion") {
    Result<void> success = Ok();
    Result<void> failure = Error{"Failed"};

    REQUIRE(static_cast<bool>(success) == true);
    REQUIRE(static_cast<bool>(failure) == false);
  }
}

TEST_CASE("Result<T> - Map transformation", "[result]") {
  SECTION("Map success value") {
    Result<int> result = 10;
    auto mapped = result.Map([](int x) { return x * 2; });

    REQUIRE(mapped.IsOk());
    REQUIRE(mapped.GetValue() == 20);
  }

  SECTION("Map propagates error") {
    Result<int> result = Error{"Original error"};
    auto mapped = result.Map([](int x) { return x * 2; });

    REQUIRE(mapped.IsError());
    REQUIRE(mapped.GetError().message == "Original error");
  }

  SECTION("Map changes type") {
    Result<int> result = 42;
    auto mapped = result.Map([](int x) { return std::to_string(x); });

    REQUIRE(mapped.IsOk());
    REQUIRE(mapped.GetValue() == "42");
  }
}
