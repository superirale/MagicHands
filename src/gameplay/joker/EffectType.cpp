#include "EffectType.h"

namespace gameplay {

// Initialize string → enum mapping
const std::unordered_map<std::string, EffectType>
    EffectTypeRegistry::stringToEnum_ = {
        // Basic joker effects
        {"add_chips", EffectType::AddChips},
        {"add_multiplier", EffectType::AddTempMult},
        {"add_temp_mult", EffectType::AddTempMult}, // Alias
        {"add_permanent_multiplier", EffectType::AddPermMult},

        // Advanced effects (for future)
        {"convert_chips_to_mult", EffectType::ConvertChipsToMult},
        {"modify_rule", EffectType::ModifyRule},
        {"add_gold", EffectType::AddGold},
        {"modify_hand_size", EffectType::ModifyHandSize},

        // Planet/Augment effects
        {"boost_hand_type", EffectType::BoostHandType},

        // Imprint effects
        {"chance_effect", EffectType::ChanceEffect},
        {"conditional_effect", EffectType::ConditionalEffect},

        // Spectral effects
        {"modify_deck", EffectType::ModifyDeck},
        {"transform_card", EffectType::TransformCard},
};

// Initialize enum → string mapping (for debugging/logging)
const std::unordered_map<EffectType, std::string>
    EffectTypeRegistry::enumToString_ = {
        {EffectType::AddChips, "add_chips"},
        {EffectType::AddTempMult, "add_multiplier"},
        {EffectType::AddPermMult, "add_permanent_multiplier"},
        {EffectType::ConvertChipsToMult, "convert_chips_to_mult"},
        {EffectType::ModifyRule, "modify_rule"},
        {EffectType::AddGold, "add_gold"},
        {EffectType::ModifyHandSize, "modify_hand_size"},
        {EffectType::BoostHandType, "boost_hand_type"},
        {EffectType::ChanceEffect, "chance_effect"},
        {EffectType::ConditionalEffect, "conditional_effect"},
        {EffectType::ModifyDeck, "modify_deck"},
        {EffectType::TransformCard, "transform_card"},
        {EffectType::Unknown, "unknown"},
};

EffectType EffectTypeRegistry::fromString(const std::string &type) {
  auto it = stringToEnum_.find(type);
  if (it != stringToEnum_.end()) {
    return it->second;
  }
  return EffectType::Unknown;
}

const std::string &EffectTypeRegistry::toString(EffectType type) {
  auto it = enumToString_.find(type);
  if (it != enumToString_.end()) {
    return it->second;
  }
  static const std::string unknown = "unknown";
  return unknown;
}

bool EffectTypeRegistry::isRegistered(const std::string &type) {
  return stringToEnum_.find(type) != stringToEnum_.end();
}

} // namespace gameplay
