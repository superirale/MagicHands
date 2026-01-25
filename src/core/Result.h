#pragma once

#include <optional>
#include <string>
#include <variant>

// Error type with message
struct Error {
  std::string message;

  Error() = default;
  Error(const char *msg) : message(msg) {}
  Error(std::string msg) : message(std::move(msg)) {}
};

// Result<T> - Represents either a successful value or an error
// Usage:
//   Result<int> LoadTexture(path) { return textureId; }  // Success
//   Result<int> LoadTexture(path) { return Error{"File not found"}; }  // Error
//
//   auto result = LoadTexture("image.png");
//   if (result.IsOk()) {
//       int id = result.GetValue();
//   } else {
//       LOG_ERROR("%s", result.GetError().message.c_str());
//   }
template <typename T> class Result {
public:
  // Implicit construction from value (success)
  Result(const T &value) : m_Value(value) {}
  Result(T &&value) : m_Value(std::move(value)) {}

  // Implicit construction from Error (failure)
  Result(const Error &error) : m_Value(error) {}
  Result(Error &&error) : m_Value(std::move(error)) {}

  // Check if result is success or error
  bool IsOk() const { return std::holds_alternative<T>(m_Value); }
  bool IsError() const { return std::holds_alternative<Error>(m_Value); }

  // Explicit operator for if() checks
  explicit operator bool() const { return IsOk(); }

  // Get the value (undefined behavior if IsError())
  T &GetValue() & { return std::get<T>(m_Value); }
  const T &GetValue() const & { return std::get<T>(m_Value); }
  T &&GetValue() && { return std::get<T>(std::move(m_Value)); }

  // Get the error (undefined behavior if IsOk())
  Error &GetError() & { return std::get<Error>(m_Value); }
  const Error &GetError() const & { return std::get<Error>(m_Value); }

  // Get value or default
  T GetValueOr(const T &defaultValue) const {
    return IsOk() ? GetValue() : defaultValue;
  }

  // Map: transform the value if success
  template <typename F>
  auto Map(F &&f) const -> Result<decltype(f(std::declval<T>()))> {
    using U = decltype(f(std::declval<T>()));
    if (IsOk()) {
      return f(GetValue());
    }
    return GetError();
  }

private:
  std::variant<T, Error> m_Value;
};

// Specialization for void results (just success or error)
template <> class Result<void> {
public:
  Result() : m_Error(std::nullopt) {}
  Result(const Error &error) : m_Error(error) {}
  Result(Error &&error) : m_Error(std::move(error)) {}

  bool IsOk() const { return !m_Error.has_value(); }
  bool IsError() const { return m_Error.has_value(); }
  explicit operator bool() const { return IsOk(); }

  const Error &GetError() const { return m_Error.value(); }

  // Static factory for success
  static Result<void> Ok() { return Result<void>(); }

private:
  std::optional<Error> m_Error;
};

// Convenience functions
template <typename T> Result<T> Ok(T value) {
  return Result<T>(std::move(value));
}

inline Result<void> Ok() { return Result<void>::Ok(); }

template <typename T = void> Result<T> Err(const char *message) {
  return Result<T>(Error{message});
}

template <typename T = void> Result<T> Err(std::string message) {
  return Result<T>(Error{std::move(message)});
}
