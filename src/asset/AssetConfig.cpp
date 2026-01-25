#include "AssetConfig.h"
#include <SDL3/SDL.h>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

void AssetConfig::resetToDefaults() {
  // Cache settings
  cacheMaxSize = 100;

  // Loading settings
  maxRetries = 3;
  baseDelayMs = 100;
  timeoutMs = 30000;

  // Logging settings
  logLevel = LogLevel::Info;
  logToFile = false;
  logFilePath = "asset_manager.log";

  // Path settings
  assetsBasePath = "./content";
  cacheBasePath = "./cache";
  tempBasePath = "./temp";

  // Async settings
  threadPoolSize = 4;
  progressUpdateIntervalMs = 100;

  // Fallback settings
  fallbacksEnabled = true;
}

bool AssetConfig::loadFromFile(const std::string &path) {
  // Use SDL3 IOStream for file loading
  SDL_IOStream *io = SDL_IOFromFile(path.c_str(), "r");
  if (!io) {
    LOG_WARN("Failed to open config file: %s - using defaults", path.c_str());
    return false;
  }

  // Get file size
  Sint64 fileSize = SDL_GetIOSize(io);
  if (fileSize < 0) {
    SDL_CloseIO(io);
    LOG_ERROR("Failed to get config file size");
    return false;
  }

  // Read entire file
  std::string content;
  content.resize(static_cast<size_t>(fileSize));
  Sint64 bytesRead = SDL_ReadIO(io, &content[0], static_cast<size_t>(fileSize));
  SDL_CloseIO(io);

  if (bytesRead != fileSize) {
    LOG_ERROR("Failed to read config file completely");
    return false;
  }

  // Parse JSON using nlohmann/json
  try {
    json config = json::parse(content);

    // Cache settings
    if (config.contains("cache")) {
      const auto &cache = config["cache"];
      if (cache.contains("maxSize")) {
        cacheMaxSize = cache["maxSize"].get<size_t>();
      }
    }

    // Loading settings
    if (config.contains("loading")) {
      const auto &loading = config["loading"];
      if (loading.contains("maxRetries")) {
        maxRetries = loading["maxRetries"].get<int>();
      }
      if (loading.contains("baseDelayMs")) {
        baseDelayMs = loading["baseDelayMs"].get<int>();
      }
      if (loading.contains("timeout")) {
        timeoutMs = loading["timeout"].get<int>();
      }
    }

    // Logging settings
    if (config.contains("logging")) {
      const auto &logging = config["logging"];
      if (logging.contains("level")) {
        std::string levelStr = logging["level"].get<std::string>();
        if (levelStr == "Trace")
          logLevel = LogLevel::Trace;
        else if (levelStr == "Debug")
          logLevel = LogLevel::Debug;
        else if (levelStr == "Info")
          logLevel = LogLevel::Info;
        else if (levelStr == "Warning" || levelStr == "Warn")
          logLevel = LogLevel::Warn;
        else if (levelStr == "Error")
          logLevel = LogLevel::Error;
      }
      if (logging.contains("logToFile")) {
        logToFile = logging["logToFile"].get<bool>();
      }
      if (logging.contains("logFilePath")) {
        logFilePath = logging["logFilePath"].get<std::string>();
      }
    }

    // Path settings
    if (config.contains("paths")) {
      const auto &paths = config["paths"];
      if (paths.contains("assetsBasePath")) {
        assetsBasePath = paths["assetsBasePath"].get<std::string>();
      }
      if (paths.contains("cacheBasePath")) {
        cacheBasePath = paths["cacheBasePath"].get<std::string>();
      }
      if (paths.contains("tempBasePath")) {
        tempBasePath = paths["tempBasePath"].get<std::string>();
      }
    }

    // Async settings
    if (config.contains("async")) {
      const auto &async = config["async"];
      if (async.contains("threadPoolSize")) {
        threadPoolSize = async["threadPoolSize"].get<int>();
      }
      if (async.contains("progressUpdateIntervalMs")) {
        progressUpdateIntervalMs = async["progressUpdateIntervalMs"].get<int>();
      }
    }

    // Fallback settings
    if (config.contains("fallbacks")) {
      const auto &fallbacks = config["fallbacks"];
      if (fallbacks.contains("enabled")) {
        fallbacksEnabled = fallbacks["enabled"].get<bool>();
      }
    }

    LOG_INFO("Loaded asset configuration from: %s", path.c_str());
    return true;

  } catch (const json::exception &e) {
    LOG_ERROR("Failed to parse config file: %s", e.what());
    return false;
  }
}

bool AssetConfig::saveToFile(const std::string &path) const {
  // Build JSON object
  json config;

  config["cache"] = {{"maxSize", cacheMaxSize}};

  config["loading"] = {{"maxRetries", maxRetries},
                       {"baseDelayMs", baseDelayMs},
                       {"timeout", timeoutMs}};

  config["logging"] = {{"level", logLevelToString(logLevel)},
                       {"logToFile", logToFile},
                       {"logFilePath", logFilePath}};

  config["paths"] = {{"assetsBasePath", assetsBasePath},
                     {"cacheBasePath", cacheBasePath},
                     {"tempBasePath", tempBasePath}};

  config["async"] = {{"threadPoolSize", threadPoolSize},
                     {"progressUpdateIntervalMs", progressUpdateIntervalMs}};

  config["fallbacks"] = {{"enabled", fallbacksEnabled}};

  // Serialize with pretty printing
  std::string jsonStr = config.dump(2);

  SDL_IOStream *io = SDL_IOFromFile(path.c_str(), "w");
  if (!io) {
    LOG_ERROR("Failed to create config file: %s", path.c_str());
    return false;
  }

  size_t bytesWritten = SDL_WriteIO(io, jsonStr.c_str(), jsonStr.length());
  SDL_CloseIO(io);

  if (bytesWritten != jsonStr.length()) {
    LOG_ERROR("Failed to write config file completely");
    return false;
  }

  LOG_INFO("Saved configuration to: %s", path.c_str());
  return true;
}
