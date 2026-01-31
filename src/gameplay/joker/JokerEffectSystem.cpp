#include "JokerEffectSystem.h"
#include "conditions/Condition.h"
#include "counters/Counter.h"
#include "effects/Effect.h"
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

bool JokerEffectSystem::EvaluateCondition(
    const std::string &condition, const HandEvaluator::HandResult &handResult) {
  // Use new Strategy Pattern condition system (replaces 112 lines!)
  auto conditionObj = Condition::parse(condition);
  return conditionObj->evaluate(handResult);
}

JokerEffectSystem::EffectResult
JokerEffectSystem::ApplyEffect(const JokerEffect &effect,
                               const HandEvaluator::HandResult &handResult) {
  // Get multiplier based on "per" field using Counter system
  int count = 1;
  if (!effect.per.empty()) {
    count = GetCountValue(effect.per, handResult);
  }

  // Use new Strategy Pattern effect system (replaces 24 lines!)
  auto effectObj = Effect::create(effect.type, effect.value);
  return effectObj->apply(handResult, count);
}

int JokerEffectSystem::GetCountValue(
    const std::string &per, const HandEvaluator::HandResult &handResult) {
  // Use new Strategy Pattern counter system (replaces 65 lines!)
  auto counter = Counter::parse(per);
  return counter->count(handResult);
}

} // namespace gameplay
