#include "JokerEffectSystem.h"
#include <algorithm>
#include <sstream>

namespace gameplay {

JokerEffectSystem::EffectResult
JokerEffectSystem::ApplyJokers(const std::vector<Joker> &jokers,
                               const HandEvaluator::HandResult &handResult,
                               const std::string &trigger) {
  // Default stack count of 1 for each joker
  std::vector<std::pair<Joker, int>> jokersWithStacks;
  for (const auto &joker : jokers) {
    jokersWithStacks.push_back({joker, 1});
  }
  return ApplyJokersWithStacks(jokersWithStacks, handResult, trigger);
}

JokerEffectSystem::EffectResult JokerEffectSystem::ApplyJokersWithStacks(
    const std::vector<std::pair<Joker, int>> &jokersWithStacks,
    const HandEvaluator::HandResult &handResult, const std::string &trigger) {
  EffectResult result;

  for (const auto &[joker, stackCount] : jokersWithStacks) {
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

    // Determine which effects to use: tiered or legacy
    std::vector<JokerEffect> effectsToApply;
    
    if (!joker.tieredEffects.empty() && stackCount > 0) {
      // Use tier system (GDD tiers: 1-5)
      int tierLevel = std::min(stackCount, 5);
      
      // Get effects for this tier level
      auto tierIt = joker.tieredEffects.find(tierLevel);
      if (tierIt != joker.tieredEffects.end()) {
        effectsToApply = tierIt->second;
      } else {
        // Fallback to tier 1 if specific tier not defined
        auto tier1It = joker.tieredEffects.find(1);
        if (tier1It != joker.tieredEffects.end()) {
          effectsToApply = tier1It->second;
        }
      }
    } else {
      // Legacy system: multiply effects by stack count
      effectsToApply = joker.effects;
    }

    // Apply all effects
    for (const auto &effect : effectsToApply) {
      EffectResult effectResult = ApplyEffect(effect, handResult);
      
      // For legacy system (no tiers), multiply by stack count
      int multiplier = joker.tieredEffects.empty() ? stackCount : 1;
      
      result.addedChips += effectResult.addedChips * multiplier;
      result.addedTempMult += effectResult.addedTempMult * multiplier;
      result.addedPermMult += effectResult.addedPermMult * multiplier;
    }

    // Track if any joker ignores caps
    if (joker.ignoresCaps) {
      result.ignoresCaps = true;
    }
  }

  return result;
}

// Helper to parse rank from string
static int ParseRank(const std::string &s) {
  if (s == "A" || s == "Ace")
    return 1;
  if (s == "J" || s == "Jack")
    return 11;
  if (s == "Q" || s == "Queen")
    return 12;
  if (s == "K" || s == "King")
    return 13;
  try {
    return std::stoi(s);
  } catch (...) {
    return 0;
  }
}

// Helper to parse suit from string
static int ParseSuit(const std::string &s) {
  if (s == "H" || s == "Hearts")
    return 0;
  if (s == "D" || s == "Diamonds")
    return 1;
  if (s == "C" || s == "Clubs")
    return 2;
  if (s == "S" || s == "Spades")
    return 3;
  return -1;
}

bool JokerEffectSystem::EvaluateCondition(
    const std::string &condition, const HandEvaluator::HandResult &handResult) {
  // Simple condition parser for common patterns

  // Pattern: contains_rank:X
  if (condition.find("contains_rank:") == 0) {
    std::string rankStr = condition.substr(14);
    int targetRank = ParseRank(rankStr);
    for (const auto &card : handResult.cards) {
      if (card.getRankValue() == targetRank)
        return true;
    }
    return false;
  }

  // Pattern: contains_suit:X
  if (condition.find("contains_suit:") == 0) {
    std::string suitStr = condition.substr(14);
    int targetSuit = ParseSuit(suitStr);
    for (const auto &card : handResult.cards) {
      if (card.getSuitValue() == targetSuit)
        return true;
    }
    return false;
  }

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
  } else if (var == "unique_categories") {
    int cats = 0;
    if (!handResult.fifteens.empty())
      cats++;
    if (!handResult.pairs.empty())
      cats++;
    if (!handResult.runs.empty())
      cats++;
    if (handResult.flushCount >= 4)
      cats++;
    if (handResult.hasNobs)
      cats++;
    actualValue = cats;
  } else if (var == "hand_total_21") {
    int sum = 0;
    for (const auto &c : handResult.cards)
      sum += c.getValue();
    actualValue = (sum == 21) ? 1 : 0;
    // Blackjack usually just checks boolean, so if we use "hand_total_21 == 1"
    // it works. Or we can return sum and let condition be "hand_total == 21".
    // But user json has "condition": "hand_total_21" which implies boolean flag
    // check (like has_nobs). If I return 1/0, condition "hand_total_21" without
    // op defaults to >0 check? My parser requires "var op value". But I can add
    // simple boolean check? The current parser expects "var op value". If
    // condition string is Just "hand_total_21", parsing fails? "iss >> var >>
    // op >> value;" If op missing, fail. So I should validly parse
    // "hand_total_21" as special case OR update JSON to "hand_total == 21". I
    // will update JSON to "hand_total == 21" and implement var "hand_total".
    actualValue = sum;
  } else if (var == "hand_total") {
    int sum = 0;
    for (const auto &c : handResult.cards)
      sum += c.getValue();
    actualValue = sum;
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

  // Implicit boolean check support: if condition is just "has_nobs" or
  // "hand_total_21"
  if (condition == "has_nobs")
    return handResult.hasNobs;
  if (condition == "hand_total_21") {
    int sum = 0;
    for (const auto &c : handResult.cards)
      sum += c.getValue();
    return sum == 21;
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
  // Support add_temp_mult as alias for add_multiplier
  if (effect.type == "add_chips") {
    result.addedChips = static_cast<int>(effect.value * count);
  } else if (effect.type == "add_multiplier" ||
             effect.type == "add_temp_mult") {
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
  } else if (per == "card_count") {
    return static_cast<int>(handResult.cards.size());
  } else if (per == "each_even") {
    int total = 0;
    for (const auto &card : handResult.cards) {
      if (card.getRankValue() % 2 == 0)
        total++;
    }
    return total;
  } else if (per == "each_odd") {
    int total = 0;
    for (const auto &card : handResult.cards) {
      if (card.getRankValue() % 2 != 0)
        total++;
    }
    return total;
  } else if (per == "each_face") {
    int total = 0;
    for (const auto &card : handResult.cards) {
      if (card.getRankValue() >= 11)
        total++;
    }
    return total;
  }

  // Generic each_rank fallback
  if (per.find("each_") == 0) {
    std::string suffix = per.substr(5);
    // Try parsing rank
    int rank = ParseRank(suffix);
    if (rank > 0) {
      int total = 0;
      for (const auto &card : handResult.cards) {
        if (card.getRankValue() == rank)
          total++;
      }
      return total;
    }
    // Try parsing suit
    int suit = ParseSuit(suffix);
    if (suit >= 0) {
      int total = 0;
      for (const auto &card : handResult.cards) {
        if (card.getSuitValue() == suit)
          total++;
      }
      return total;
    }
  }

  return 1; // Default multiplier
}

} // namespace gameplay
