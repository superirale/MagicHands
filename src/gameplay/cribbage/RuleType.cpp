#include "RuleType.h"

namespace gameplay {

// Initialize string → enum mapping
const std::unordered_map<std::string, RuleType>
    RuleRegistry::stringToEnum_ = {
        // Boss rules
        {"fifteens_disabled", RuleType::FifteensDisabled},
        {"multipliers_disabled", RuleType::MultipliersDisabled},
        {"flush_disabled", RuleType::FlushDisabled},
        {"nobs_disabled", RuleType::NobsDisabled},
        {"pairs_disabled", RuleType::PairsDisabled},
        {"runs_disabled", RuleType::RunsDisabled},
        {"only_pairs_runs", RuleType::OnlyPairsRuns},

        // Warp effects
        {"warp_blaze", RuleType::WarpBlaze},
        {"warp_mirror", RuleType::WarpMirror},
        {"warp_inversion", RuleType::WarpInversion},
        {"warp_wildfire", RuleType::WarpWildfire},
};

// Initialize enum → string mapping (for debugging/logging)
const std::unordered_map<RuleType, std::string>
    RuleRegistry::enumToString_ = {
        {RuleType::FifteensDisabled, "fifteens_disabled"},
        {RuleType::MultipliersDisabled, "multipliers_disabled"},
        {RuleType::FlushDisabled, "flush_disabled"},
        {RuleType::NobsDisabled, "nobs_disabled"},
        {RuleType::PairsDisabled, "pairs_disabled"},
        {RuleType::RunsDisabled, "runs_disabled"},
        {RuleType::OnlyPairsRuns, "only_pairs_runs"},
        {RuleType::WarpBlaze, "warp_blaze"},
        {RuleType::WarpMirror, "warp_mirror"},
        {RuleType::WarpInversion, "warp_inversion"},
        {RuleType::WarpWildfire, "warp_wildfire"},
        {RuleType::Unknown, "unknown"},
};

RuleType RuleRegistry::fromString(const std::string &rule) {
  auto it = stringToEnum_.find(rule);
  if (it != stringToEnum_.end()) {
    return it->second;
  }
  return RuleType::Unknown;
}

const std::string &RuleRegistry::toString(RuleType rule) {
  auto it = enumToString_.find(rule);
  if (it != enumToString_.end()) {
    return it->second;
  }
  static const std::string unknown = "unknown";
  return unknown;
}

bool RuleRegistry::isRegistered(const std::string &rule) {
  return stringToEnum_.find(rule) != stringToEnum_.end();
}

} // namespace gameplay
