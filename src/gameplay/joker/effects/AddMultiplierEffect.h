#pragma once

#include "Effect.h"

namespace gameplay {

/**
 * AddMultiplierEffect - Adds temporary multiplier to the score
 * 
 * Handles: "add_multiplier", "add_temp_mult" (alias)
 */
class AddMultiplierEffect : public Effect {
public:
  explicit AddMultiplierEffect(float value) : m_Value(value) {}

  JokerEffectSystem::EffectResult 
  apply(const HandEvaluator::HandResult &handResult, int count) const override {
    JokerEffectSystem::EffectResult result;
    result.addedTempMult = m_Value * count;
    return result;
  }
  
  float getValue() const override { return m_Value; }

private:
  float m_Value;
};

} // namespace gameplay
