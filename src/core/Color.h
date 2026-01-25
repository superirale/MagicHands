#pragma once

#include <cstdint>

struct Color {
  float r, g, b, a;

  Color() : r(1.0f), g(1.0f), b(1.0f), a(1.0f) {} // White default
  Color(float red, float green, float blue, float alpha = 1.0f)
      : r(red), g(green), b(blue), a(alpha) {}

  static const Color White;
  static const Color Black;
  static const Color Red;
  static const Color Green;
  static const Color Blue;
  static const Color Yellow;
};

inline const Color Color::White(1.0f, 1.0f, 1.0f);
inline const Color Color::Black(0.0f, 0.0f, 0.0f);
inline const Color Color::Red(1.0f, 0.0f, 0.0f);
inline const Color Color::Green(0.0f, 1.0f, 0.0f);
inline const Color Color::Blue(0.0f, 0.0f, 1.0f);
inline const Color Color::Yellow(1.0f, 1.0f, 0.0f);
