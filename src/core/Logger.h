#pragma once

#include <cstdarg>
#include <cstdio>
#include <string>

// Log levels
enum class LogLevel { Trace = 0, Debug = 1, Info = 2, Warn = 3, Error = 4 };

class Logger {
public:
  // Initialize the logger (optional: set minimum log level)
  static void Init(LogLevel minLevel = LogLevel::Info);

  // Core logging function
  static void Log(LogLevel level, const char *file, int line, const char *fmt,
                  ...);

  // Set minimum log level (messages below this level are ignored)
  static void SetMinLevel(LogLevel level);

  // Get current log level
  static LogLevel GetMinLevel();

private:
  static LogLevel s_MinLevel;
  static const char *LevelToString(LogLevel level);
  static const char *LevelToColor(LogLevel level);
};

// Convenience macros - include file and line info for debugging
#define LOG_TRACE(...)                                                         \
  Logger::Log(LogLevel::Trace, __FILE__, __LINE__, __VA_ARGS__)
#define LOG_DEBUG(...)                                                         \
  Logger::Log(LogLevel::Debug, __FILE__, __LINE__, __VA_ARGS__)
#define LOG_INFO(...)                                                          \
  Logger::Log(LogLevel::Info, __FILE__, __LINE__, __VA_ARGS__)
#define LOG_WARN(...)                                                          \
  Logger::Log(LogLevel::Warn, __FILE__, __LINE__, __VA_ARGS__)
#define LOG_ERROR(...)                                                         \
  Logger::Log(LogLevel::Error, __FILE__, __LINE__, __VA_ARGS__)
