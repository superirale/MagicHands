#ifndef ASSET_CONFIG_H
#define ASSET_CONFIG_H

#include "core/Logger.h"
#include <string>

// Configuration singleton for AssetManager
class AssetConfig {
public:
  static AssetConfig &getInstance() {
    static AssetConfig instance;
    return instance;
  }

  // Delete copy/move constructors
  AssetConfig(const AssetConfig &) = delete;
  AssetConfig &operator=(const AssetConfig &) = delete;

  // Load configuration from JSON file
  bool loadFromFile(const std::string &path);

  // Save current configuration to JSON file
  bool saveToFile(const std::string &path) const;

  // Reset to default values
  void resetToDefaults();

  // Cache settings
  size_t getCacheMaxSize() const { return cacheMaxSize; }
  void setCacheMaxSize(size_t size) { cacheMaxSize = size; }

  // Loading settings
  int getMaxRetries() const { return maxRetries; }
  void setMaxRetries(int retries) { maxRetries = retries; }

  int getBaseDelayMs() const { return baseDelayMs; }
  void setBaseDelayMs(int delay) { baseDelayMs = delay; }

  int getTimeoutMs() const { return timeoutMs; }
  void setTimeoutMs(int timeout) { timeoutMs = timeout; }

  // Logging settings - uses core Logger's LogLevel
  LogLevel getLogLevel() const { return logLevel; }
  void setLogLevel(LogLevel level) { logLevel = level; }

  bool shouldLogToFile() const { return logToFile; }
  void setLogToFile(bool enabled) { logToFile = enabled; }

  std::string getLogFilePath() const { return logFilePath; }
  void setLogFilePath(const std::string &path) { logFilePath = path; }

  // Path settings
  std::string getAssetsBasePath() const { return assetsBasePath; }
  void setAssetsBasePath(const std::string &path) { assetsBasePath = path; }

  std::string getCacheBasePath() const { return cacheBasePath; }
  void setCacheBasePath(const std::string &path) { cacheBasePath = path; }

  // Async settings
  int getThreadPoolSize() const { return threadPoolSize; }
  void setThreadPoolSize(int size) { threadPoolSize = size; }

  int getProgressUpdateIntervalMs() const { return progressUpdateIntervalMs; }
  void setProgressUpdateIntervalMs(int interval) {
    progressUpdateIntervalMs = interval;
  }

  // Fallback settings
  bool areFallbacksEnabled() const { return fallbacksEnabled; }
  void setFallbacksEnabled(bool enabled) { fallbacksEnabled = enabled; }

private:
  AssetConfig() { resetToDefaults(); }

  // Cache settings
  size_t cacheMaxSize;

  // Loading settings
  int maxRetries;
  int baseDelayMs;
  int timeoutMs;

  // Logging settings
  LogLevel logLevel;
  bool logToFile;
  std::string logFilePath;

  // Path settings
  std::string assetsBasePath;
  std::string cacheBasePath;
  std::string tempBasePath;

  // Async settings
  int threadPoolSize;
  int progressUpdateIntervalMs;

  // Fallback settings
  bool fallbacksEnabled;
};

// Helper to convert log level to string for JSON serialization
inline const char *logLevelToString(LogLevel level) {
  switch (level) {
  case LogLevel::Trace:
    return "Trace";
  case LogLevel::Debug:
    return "Debug";
  case LogLevel::Info:
    return "Info";
  case LogLevel::Warn:
    return "Warning";
  case LogLevel::Error:
    return "Error";
  default:
    return "Info";
  }
}

#endif // ASSET_CONFIG_H
