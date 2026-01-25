#include "core/Base64.h"
#include <catch2/catch_test_macros.hpp>
#include <string>
#include <vector>

TEST_CASE("Base64 Decoding", "[base64]") {
  SECTION("Decodes simple string") {
    // "Hello" in Base64 is "SGVsbG8="
    std::string encoded = "SGVsbG8=";
    std::vector<unsigned char> decoded = Base64::decode(encoded);
    std::string result(decoded.begin(), decoded.end());

    REQUIRE(result == "Hello");
  }

  SECTION("Decodes empty string") {
    std::string encoded = "";
    std::vector<unsigned char> decoded = Base64::decode(encoded);

    REQUIRE(decoded.empty());
  }

  SECTION("Decodes binary data") {
    // 0x01 0x02 0x03 -> "AQID"
    std::string encoded = "AQID";
    std::vector<unsigned char> decoded = Base64::decode(encoded);

    REQUIRE(decoded.size() == 3);
    REQUIRE(decoded[0] == 0x01);
    REQUIRE(decoded[1] == 0x02);
    REQUIRE(decoded[2] == 0x03);
  }
}
