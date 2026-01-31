#pragma once

#include "Effect.h"

namespace gameplay {

/**
 * AddChipsEffect - Adds chips to the score
 * 
 * Handles: "add_chips"
 */
class AddChipsEffect : public Effect {
public:
  explicit AddChipsEffect(float value) : m_Value(value) {}

  JokerEffectSystem::EffectResult 
  apply(const HandEvaluator::HandResult &handResult, int count) const override {
    JokerEffectSystem::EffectResult result;
    result.addedChips = static_cast<int>(m_Value * count);
    return result;
  }
  
  float getValue() const override { return m_Value; }

private:
  float m_Value;
};

} // namespace gameplay
