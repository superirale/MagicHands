#include "core/Logger.h"
#include <ctime>

// Static member initialization
LogLevel Logger::s_MinLevel = LogLevel::Info;

void Logger::Init(LogLevel minLevel) {
  s_MinLevel = minLevel;
  LOG_INFO("Logger initialized (min level: %s)", LevelToString(minLevel));
}

void Logger::SetMinLevel(LogLevel level) { s_MinLevel = level; }

LogLevel Logger::GetMinLevel() { return s_MinLevel; }

const char *Logger::LevelToString(LogLevel level) {
  switch (level) {
  case LogLevel::Trace:
    return "TRACE";
  case LogLevel::Debug:
    return "DEBUG";
  case LogLevel::Info:
    return "INFO";
  case LogLevel::Warn:
    return "WARN";
  case LogLevel::Error:
    return "ERROR";
  default:
    return "UNKNOWN";
  }
}

const char *Logger::LevelToColor(LogLevel level) {
  // ANSI color codes for terminal
  switch (level) {
  case LogLevel::Trace:
    return "\033[90m"; // Gray
  case LogLevel::Debug:
    return "\033[36m"; // Cyan
  case LogLevel::Info:
    return "\033[32m"; // Green
  case LogLevel::Warn:
    return "\033[33m"; // Yellow
  case LogLevel::Error:
    return "\033[31m"; // Red
  default:
    return "\033[0m";
  }
}

void Logger::Log(LogLevel level, const char *file, int line, const char *fmt,
                 ...) {
  // Skip if below minimum level
  if (static_cast<int>(level) < static_cast<int>(s_MinLevel)) {
    return;
  }

  // Get current time
  time_t now = time(nullptr);
  tm *localTime = localtime(&now);

  // Format timestamp
  char timestamp[32];
  strftime(timestamp, sizeof(timestamp), "%H:%M:%S", localTime);

  // Extract just the filename from the full path
  const char *filename = file;
  for (const char *p = file; *p; ++p) {
    if (*p == '/' || *p == '\\') {
      filename = p + 1;
    }
  }

  // Print prefix with color
  const char *color = LevelToColor(level);
  const char *reset = "\033[0m";

  fprintf(stderr, "%s[%s][%s]%s %s:%d: ", color, timestamp,
          LevelToString(level), reset, filename, line);

  // Print the actual message
  va_list args;
  va_start(args, fmt);
  vfprintf(stderr, fmt, args);
  va_end(args);

  fprintf(stderr, "\n");
  fflush(stderr);
}
