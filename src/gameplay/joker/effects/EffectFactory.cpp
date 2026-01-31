#include "Effect.h"
#include "AddChipsEffect.h"
#include "AddMultiplierEffect.h"
#include "AddPermMultEffect.h"
#include "core/Logger.h"

namespace gameplay {

/**
 * Factory method - creates appropriate Effect from type and value
 * Replaces ApplyEffect() string parsing (24 lines) with Strategy Pattern
 */
std::unique_ptr<Effect> Effect::create(const std::string &type, float value) {
  // AddChips effect
  if (type == "add_chips") {
    return std::make_unique<AddChipsEffect>(value);
  }
  
  // AddMultiplier effect (with alias support)
  if (type == "add_multiplier" || type == "add_temp_mult") {
    return std::make_unique<AddMultiplierEffect>(value);
  }
  
  // AddPermMult effect
  if (type == "add_permanent_multiplier") {
    return std::make_unique<AddPermMultEffect>(value);
  }
  
  // Future effects (not yet implemented)
  if (type == "convert_chips_to_mult") {
    LOG_WARN("Effect type '%s' not yet implemented", type.c_str());
    return std::make_unique<NoOpEffect>();
  }
  
  if (type == "modify_rule") {
    LOG_WARN("Effect type '%s' not yet implemented", type.c_str());
    return std::make_unique<NoOpEffect>();
  }
  
  if (type == "add_gold") {
    LOG_WARN("Effect type '%s' not yet implemented", type.c_str());
    return std::make_unique<NoOpEffect>();
  }
  
  if (type == "modify_hand_size") {
    LOG_WARN("Effect type '%s' not yet implemented", type.c_str());
    return std::make_unique<NoOpEffect>();
  }
  
  // Unknown effect type
  LOG_WARN("Unknown effect type: %s (ignoring)", type.c_str());
  return std::make_unique<NoOpEffect>();
}

} // namespace gameplay
