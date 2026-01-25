#pragma once

class SpriteRenderer;

class Animation {
public:
    Animation(int textureId, int frameW, int frameH, float duration, int frameCount, SpriteRenderer* renderer);
    
    void Update(float dt);
    void Draw(SpriteRenderer* renderer, float x, float y, float w, float h, bool flipX = false);
    void SetRow(int row);  // Set animation row for multi-directional sprites
    
    int GetTextureId() const { return m_TextureId; }
    int GetCurrentFrame() const { return m_CurrentFrame; }
    
private:
    int m_TextureId;
    int m_FrameW;
    int m_FrameH;
    float m_Duration;
    int m_FrameCount;
    
    float m_Timer;
    int m_CurrentFrame;
    int m_CurrentRow;  // Current animation row (for multi-directional sprites)
    
    int m_TexW;
    int m_TexH;
};
