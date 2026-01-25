#include "Blind.h"
#include <cmath>
#include <stdexcept>

namespace gameplay {

int Blind::GetRequiredScore(float difficultyMod) const {
  // Formula: base × act_multiplier × difficulty_modifier
  float actMult = GetActMultiplier(act);
  float required = baseScore * actMult * difficultyMod;
  return static_cast<int>(std::round(required));
}

float Blind::GetActMultiplier(int act) {
  // Per GDD lines 290-294
  switch (act) {
  case 1:
    return 1.0f;
  case 2:
    return 2.5f;
  case 3:
    return 6.0f;
  default:
    return 1.0f;
  }
}

Blind Blind::Create(int act, BlindType type, const std::string &bossId) {
  Blind blind;
  blind.act = act;
  blind.type = type;
  blind.baseScore = GetBaseScore(act, type);
  blind.bossId = bossId;
  return blind;
}

int Blind::GetBaseScore(int act, BlindType type) {
  // Per GDD table (lines 115-119):
  // Act | Small | Big | Boss
  //  1  |  100  | 250 | 600
  //  2  |  600  | 1400| 3000
  //  3  | 3000  | 8000| 15000

  switch (act) {
  case 1:
    switch (type) {
    case BlindType::SMALL:
      return 100;
    case BlindType::BIG:
      return 250;
    case BlindType::BOSS:
      return 600;
    }
    break;
  case 2:
    switch (type) {
    case BlindType::SMALL:
      return 600;
    case BlindType::BIG:
      return 1400;
    case BlindType::BOSS:
      return 3000;
    }
    break;
  case 3:
    switch (type) {
    case BlindType::SMALL:
      return 3000;
    case BlindType::BIG:
      return 8000;
    case BlindType::BOSS:
      return 15000;
    }
    break;
  }

  throw std::invalid_argument("Invalid act or blind type");
}

std::string Blind::TypeToString(BlindType type) {
  switch (type) {
  case BlindType::SMALL:
    return "small";
  case BlindType::BIG:
    return "big";
  case BlindType::BOSS:
    return "boss";
  default:
    return "unknown";
  }
}

BlindType Blind::StringToType(const std::string &str) {
  if (str == "small")
    return BlindType::SMALL;
  if (str == "big")
    return BlindType::BIG;
  if (str == "boss")
    return BlindType::BOSS;
  throw std::invalid_argument("Invalid blind type string: " + str);
}

} // namespace gameplay
