#pragma once

#include "core/Color.h"
#include <vector>

class SpriteRenderer;

class DebugDraw {
public:
  static void Init(SpriteRenderer *renderer);
  static void Shutdown();

  static void DrawLine(float x1, float y1, float x2, float y2,
                       Color color = Color::Red);
  static void DrawRect(float x, float y, float w, float h,
                       Color color = Color::Red);
  static void DrawSolidRect(float x, float y, float w, float h,
                            Color color = Color::Red);

  // Call this after SpriteRenderer::BeginFrame -> Flush -> DrawUI?
  // Usually debug draw is on top of everything.
  static void Render();
  static void Clear();

private:
  struct Line {
    float x1, y1, x2, y2;
    Color color;
  };

  struct Rect {
    float x, y, w, h;
    Color color;
    bool solid;
  };

  static SpriteRenderer *s_Renderer;
  static std::vector<Line> s_Lines;
  static std::vector<Rect> s_Rects;
};
