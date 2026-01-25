#include "graphics/DebugDraw.h"
#include "graphics/SpriteRenderer.h"
#include <cmath>

SpriteRenderer *DebugDraw::s_Renderer = nullptr;
std::vector<DebugDraw::Line> DebugDraw::s_Lines;
std::vector<DebugDraw::Rect> DebugDraw::s_Rects;

void DebugDraw::Init(SpriteRenderer *renderer) { s_Renderer = renderer; }

void DebugDraw::Shutdown() {
  s_Lines.clear();
  s_Rects.clear();
  s_Renderer = nullptr;
}

void DebugDraw::DrawLine(float x1, float y1, float x2, float y2, Color color) {
  s_Lines.push_back({x1, y1, x2, y2, color});
}

void DebugDraw::DrawRect(float x, float y, float w, float h, Color color) {
  // Hollow rect = 4 lines
  DrawLine(x, y, x + w, y, color);         // Top
  DrawLine(x + w, y, x + w, y + h, color); // Right
  DrawLine(x + w, y + h, x, y + h, color); // Bottom
  DrawLine(x, y + h, x, y, color);         // Left
}

void DebugDraw::DrawSolidRect(float x, float y, float w, float h, Color color) {
  s_Rects.push_back({x, y, w, h, color, true});
}

void DebugDraw::Render() {
  if (!s_Renderer)
    return;

  int whiteTex = s_Renderer->GetWhiteTexture();

  // Draw Rects (Solid)
  for (const auto &r : s_Rects) {
    if (r.solid) {
      s_Renderer->DrawSpriteRect(whiteTex, r.x, r.y, r.w, r.h, 0, 0, 1, 1, 0.0f,
                                 false, false, r.color, false);
    }
  }

  // Draw Lines
  // Drawing lines with quads: Position center at midpoint, scale width to
  // length, height to thickness (e.g. 2px), rotate angle
  for (const auto &l : s_Lines) {
    float dx = l.x2 - l.x1;
    float dy = l.y2 - l.y1;
    float len = sqrtf(dx * dx + dy * dy);
    if (len < 0.1f)
      continue;

    float angle = atan2f(dy, dx);
    // Center of line
    float cx = (l.x1 + l.x2) * 0.5f;
    float cy = (l.y1 + l.y2) * 0.5f;

    // Draw 2px thick line (1px around center)
    // SpriteRenderer draws from top-left.
    // We need to adjust x,y to be top-left of the rotated quad?
    // Wait, our DrawSprite takes x,y as Top-Left.
    // And rotates around Center (which is x+w/2, y+h/2).

    // So:
    float thickness = 2.0f;
    float w = len;
    float h = thickness;

    // Top-Left position so that Center is (cx, cy)
    float x = cx - w * 0.5f;
    float y = cy - h * 0.5f;

    s_Renderer->DrawSpriteRect(whiteTex, x, y, w, h, 0, 0, 1, 1, angle, false,
                               false, l.color, false);
  }
}

void DebugDraw::Clear() {
  s_Lines.clear();
  s_Rects.clear();
}
