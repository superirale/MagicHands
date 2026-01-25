#pragma once

#include <string>

namespace gameplay {

/// @brief Type of blind in the campaign
enum class BlindType { SMALL, BIG, BOSS };

/// @brief Represents a blind (round target score) in the campaign
class Blind {
public:
  /// Type of blind
  BlindType type;

  /// Act number (1-3)
  int act;

  /// Base score requirement (before multipliers)
  int baseScore;

  /// Boss ID (empty for non-boss blinds)
  std::string bossId;

  /// @brief Calculate the required score with difficulty modifier
  /// @param difficultyMod Difficulty multiplier
  /// (0.8=easy, 1.0=normal, 1.3=hard)
  /// @return Required score to beat this blind
  int GetRequiredScore(float difficultyMod = 1.0f) const;

  /// @brief Get the act multiplier per GDD spec
  /// @param act Act number (1-3)
  /// @return Multiplier for this act (1.0, 2.5, or 6.0)
  static float GetActMultiplier(int act);

  /// @brief Create a blind for a specific act and type
  /// @param act Act number (1-3)
  /// @param type Blind type
  /// @param bossId Optional boss ID for BOSS blinds
  /// @return Created blind with appropriate base score
  static Blind Create(int act, BlindType type, const std::string &bossId = "");

  /// @brief Get base score for a specific blind type in an act
  /// @param act Act number (1-3)
  /// @param type Blind type
  /// @return Base score per GDD table
  static int GetBaseScore(int act, BlindType type);

  /// @brief Convert BlindType to string
  /// @param type Blind type
  /// @return String representation ("small", "big", "boss")
  static std::string TypeToString(BlindType type);

  /// @brief Convert string to BlindType
  /// @param str String representation
  /// @return Blind type
  static BlindType StringToType(const std::string &str);
};

} // namespace gameplay
