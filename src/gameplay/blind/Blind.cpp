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
  // Balatro-inspired progression system
  // Follows 2:3:4 ratio (Small:Big:Boss)
  // Scaled for cribbage scoring - Bot data shows avg 28 pts/hand baseline
  // 
  // Act | Small | Big   | Boss  | Points/Hand Needed
  //  1  |  100  |  150  |  200  | 25/37.5/50 (achievable)
  //  2  |  300  |  450  |  600  | 75/112/150
  //  3  |  800  | 1200  | 1600  | 200/300/400
  //  4  | 2000  | 3000  | 4000  | 500/750/1000
  //  5  | 5000  | 7500  | 10000 | 1250/1875/2500
  //  6  | 5000  | 7500  | 10000 | 1x plateau
  //  7  |11000  |16500  | 22000 | 2750/4125/5500
  //  8  |20000  |30000  | 40000 | 5000/7500/10000
  //  9+ |35000  |52500  | 70000 | 8750/13125/17500

  switch (act) {
  case 1:
    switch (type) {
    case BlindType::SMALL:
      return 100;
    case BlindType::BIG:
      return 150;
    case BlindType::BOSS:
      return 200;
    }
    break;
  case 2:
    switch (type) {
    case BlindType::SMALL:
      return 300;
    case BlindType::BIG:
      return 450;
    case BlindType::BOSS:
      return 600;
    }
    break;
  case 3:
    switch (type) {
    case BlindType::SMALL:
      return 800;
    case BlindType::BIG:
      return 1200;
    case BlindType::BOSS:
      return 1600;
    }
    break;
  case 4:
    switch (type) {
    case BlindType::SMALL:
      return 2000;
    case BlindType::BIG:
      return 3000;
    case BlindType::BOSS:
      return 4000;
    }
    break;
  case 5:
    switch (type) {
    case BlindType::SMALL:
      return 5000;
    case BlindType::BIG:
      return 7500;
    case BlindType::BOSS:
      return 10000;
    }
    break;
  case 6:
    switch (type) {
    case BlindType::SMALL:
      return 5000;  // Plateau - same as Act 5
    case BlindType::BIG:
      return 7500;
    case BlindType::BOSS:
      return 10000;
    }
    break;
  case 7:
    switch (type) {
    case BlindType::SMALL:
      return 11000;
    case BlindType::BIG:
      return 16500;
    case BlindType::BOSS:
      return 22000;
    }
    break;
  case 8:
    switch (type) {
    case BlindType::SMALL:
      return 20000;
    case BlindType::BIG:
      return 30000;
    case BlindType::BOSS:
      return 40000;
    }
    break;
  default:  // Act 9+
    switch (type) {
    case BlindType::SMALL:
      return 35000;
    case BlindType::BIG:
      return 52500;
    case BlindType::BOSS:
      return 70000;
    }
  }

  throw std::invalid_argument("Invalid blind type");
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
