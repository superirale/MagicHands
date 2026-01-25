#include "graphics/Animation.h"
#include "core/Logger.h"
#include "graphics/SpriteRenderer.h"
#include "core/Color.h"
#include <cmath>

Animation::Animation(int textureId, int frameW, int frameH, float duration,
                     int frameCount, SpriteRenderer *renderer)
    : m_TextureId(textureId), m_FrameW(frameW), m_FrameH(frameH),
      m_Duration(duration), m_FrameCount(frameCount), m_Timer(0.0f),
      m_CurrentFrame(0), m_CurrentRow(0) {
  // Get texture size
  renderer->GetTextureSize(textureId, &m_TexW, &m_TexH);
  LOG_DEBUG("Animation Init: TexID=%d W=%d H=%d", textureId, m_TexW, m_TexH);
}

void Animation::Update(float dt) {
  m_Timer += dt;
  if (m_Timer >= m_Duration) {
    m_Timer -= m_Duration;
    m_CurrentFrame = (m_CurrentFrame + 1) % m_FrameCount;
  }
}

void Animation::Draw(SpriteRenderer *renderer, float x, float y, float w,
                     float h, bool flipX) {
  // Calculate UVs (horizontal strip with multiple rows)
  int col = m_CurrentFrame;
  float u = (col * m_FrameW) / (float)m_TexW;
  float v = (m_CurrentRow * m_FrameH) / (float)m_TexH; // Use current row
  float uw = m_FrameW / (float)m_TexW;
  float vh = m_FrameH / (float)m_TexH;

  renderer->DrawSpriteRect(m_TextureId, x, y, w, h, u, v, uw, vh, 0.0f, flipX,
                           false, Color::White, false);
}

void Animation::SetRow(int row) { m_CurrentRow = row; }
