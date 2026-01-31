#include "EffectFactory.h"
#include "BlazeEffect.h"
#include "InversionEffect.h"
#include "MirrorEffect.h"
#include "WildfireEffect.h"

namespace gameplay {

EffectFactory &EffectFactory::getInstance() {
  static EffectFactory instance;
  return instance;
}

void EffectFactory::registerEffect(
    RuleType type, std::function<std::unique_ptr<WarpEffect>()> creator) {
  creators_[type] = std::move(creator);
}

std::unique_ptr<WarpEffect> EffectFactory::create(RuleType type) const {
  auto it = creators_.find(type);
  if (it != creators_.end()) {
    return it->second(); // Call creator function
  }
  return nullptr;
}

bool EffectFactory::isRegistered(RuleType type) const {
  return creators_.find(type) != creators_.end();
}

void EffectFactory::registerBuiltInEffects() {
  auto &factory = getInstance();

  // Register all 4 warp effects
  factory.registerEffect(RuleType::WarpBlaze,
                         []() { return std::make_unique<BlazeEffect>(); });

  factory.registerEffect(RuleType::WarpMirror,
                         []() { return std::make_unique<MirrorEffect>(); });

  factory.registerEffect(RuleType::WarpInversion, []() {
    return std::make_unique<InversionEffect>();
  });

  factory.registerEffect(RuleType::WarpWildfire,
                         []() { return std::make_unique<WildfireEffect>(); });
}

} // namespace gameplay
