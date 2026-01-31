#pragma once

#include "gameplay/cribbage/HandEvaluator.h"
#include "gameplay/joker/JokerEffectSystem.h"
#include <memory>
#include <string>

namespace gameplay {

/**
 * Effect - Strategy Pattern base class for joker effects
 * 
 * Replaces ApplyEffect() string parsing (24 lines) with polymorphic classes.
 * Each effect type (add_chips, add_multiplier, etc.) is a separate class.
 * 
 * Usage:
 *   auto effect = Effect::create(effectData);
 *   auto result = effect->apply(handResult);
 */
class Effect {
public:
  virtual ~Effect() = default;
  
  /**
   * Apply the effect and return the result
   * @param handResult The evaluated hand with scoring data
   * @param count Multiplier from "per" counter (already calculated)
   * @return EffectResult with chips/multiplier changes
   */
  virtual JokerEffectSystem::EffectResult 
  apply(const HandEvaluator::HandResult &handResult, int count) const = 0;
  
  /**
   * Factory method - creates appropriate Effect from JokerEffect data
   * @param effectData The effect definition from JSON
   * @return Unique pointer to Effect subclass
   */
  static std::unique_ptr<Effect> create(const std::string &type, float value);
  
  /**
   * Get the effect value
   */
  virtual float getValue() const = 0;
};

/**
 * NoOpEffect - Does nothing (for unknown/unimplemented effects)
 */
class NoOpEffect : public Effect {
public:
  JokerEffectSystem::EffectResult 
  apply(const HandEvaluator::HandResult &handResult, int count) const override {
    return JokerEffectSystem::EffectResult();
  }
  
  float getValue() const override { return 0.0f; }
};

} // namespace gameplay
