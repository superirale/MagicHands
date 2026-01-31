#pragma once

#include "Effect.h"

namespace gameplay {

/**
 * AddPermMultEffect - Adds permanent multiplier to the joker
 * 
 * Handles: "add_permanent_multiplier"
 */
class AddPermMultEffect : public Effect {
public:
  explicit AddPermMultEffect(float value) : m_Value(value) {}

  JokerEffectSystem::EffectResult 
  apply(const HandEvaluator::HandResult &handResult, int count) const override {
    JokerEffectSystem::EffectResult result;
    result.addedPermMult = m_Value * count;
    return result;
  }
  
  float getValue() const override { return m_Value; }

private:
  float m_Value;
};

} // namespace gameplay
