#include "JokerEffectSystem.h"
#include <algorithm>
#include <sstream>

namespace gameplay {

JokerEffectSystem::EffectResult
JokerEffectSystem::ApplyJokers(const std::vector<Joker> &jokers,
                               const HandEvaluator::HandResult &handResult,
                               const std::string &trigger) {
  EffectResult result;

  for (const auto &joker : jokers) {
    // Check if this joker triggers on this event
    bool shouldTrigger = false;
    for (const auto &jokTrigger : joker.triggers) {
      if (jokTrigger == trigger) {
        shouldTrigger = true;
        break;
      }
    }

    if (!shouldTrigger) {
      continue;
    }

    // Evaluate all conditions
    bool allConditionsMet = true;
    for (const auto &condition : joker.conditions) {
      if (!EvaluateCondition(condition, handResult)) {
        allConditionsMet = false;
        break;
      }
    }

    if (!allConditionsMet) {
      continue;
    }

    // Apply all effects
    for (const auto &effect : joker.effects) {
      EffectResult effectResult = ApplyEffect(effect, handResult);
      result.addedChips += effectResult.addedChips;
      result.addedTempMult += effectResult.addedTempMult;
      result.addedPermMult += effectResult.addedPermMult;
    }

    // Track if any joker ignores caps
    if (joker.ignoresCaps) {
      result.ignoresCaps = true;
    }
  }

  return result;
}

bool JokerEffectSystem::EvaluateCondition(
    const std::string &condition, const HandEvaluator::HandResult &handResult) {
  // Simple condition parser for common patterns
  // Format: "count_15s > 0", "count_pairs >= 2", etc.

  std::istringstream iss(condition);
  std::string var, op;
  int value;

  iss >> var >> op >> value;

  int actualValue = 0;

  // Extract count from hand result
  if (var == "count_15s") {
    actualValue = static_cast<int>(handResult.fifteens.size());
  } else if (var == "count_pairs") {
    actualValue = static_cast<int>(handResult.pairs.size());
  } else if (var == "count_runs") {
    actualValue = static_cast<int>(handResult.runs.size());
  } else if (var == "has_flush") {
    actualValue = handResult.flushCount > 0 ? 1 : 0;
  } else if (var == "has_nobs") {
    actualValue = handResult.hasNobs ? 1 : 0;
  } else if (var == "flush_count") {
    actualValue = handResult.flushCount;
  }

  // Evaluate operator
  if (op == ">") {
    return actualValue > value;
  } else if (op == ">=") {
    return actualValue >= value;
  } else if (op == "<") {
    return actualValue < value;
  } else if (op == "<=") {
    return actualValue <= value;
  } else if (op == "==") {
    return actualValue == value;
  } else if (op == "!=") {
    return actualValue != value;
  }

  return false;
}

JokerEffectSystem::EffectResult
JokerEffectSystem::ApplyEffect(const JokerEffect &effect,
                               const HandEvaluator::HandResult &handResult) {
  EffectResult result;

  // Get multiplier based on "per" field
  int count = 1;
  if (!effect.per.empty()) {
    count = GetCountValue(effect.per, handResult);
  }

  // Apply effect based on type
  if (effect.type == "add_chips") {
    result.addedChips = static_cast<int>(effect.value * count);
  } else if (effect.type == "add_multiplier") {
    result.addedTempMult = effect.value * count;
  } else if (effect.type == "add_permanent_multiplier") {
    result.addedPermMult = effect.value * count;
  }
  // TODO: Other effect types (convert_chips_to_multiplier, modify_rule, etc.)

  return result;
}

int JokerEffectSystem::GetCountValue(
    const std::string &per, const HandEvaluator::HandResult &handResult) {
  if (per == "each_15") {
    return static_cast<int>(handResult.fifteens.size());
  } else if (per == "each_pair") {
    return static_cast<int>(handResult.pairs.size());
  } else if (per == "each_run") {
    return static_cast<int>(handResult.runs.size());
  } else if (per == "cards_in_runs") {
    int total = 0;
    for (const auto &run : handResult.runs) {
      total += static_cast<int>(run.size());
    }
    return total;
  }

  return 1; // Default multiplier
}

} // namespace gameplay
