#pragma once

#include "core/Color.h"
#include <SDL3/SDL.h>
#include <SDL3/SDL_gpu.h>
#include <map>
#include <string>
#include <unordered_map>
#include <vector>

struct Vertex {
  float x, y, z;
  float u, v;
  float r, g, b, a;
};

class SpriteRenderer {
public:
  SpriteRenderer();
  ~SpriteRenderer();

  bool Init(SDL_GPUDevice *device, SDL_Window *window);
  void Destroy();

  int LoadTexture(const char *path);
  int LoadTextureFromMemory(const unsigned char *data, int w, int h);
  void GetTextureSize(int id, int *w, int *h);
  void GetWindowSize(int *w, int *h);

  void SetCamera(float x, float y);
  void GetCamera(float *x, float *y);
  float GetZoom() const { return m_Zoom; }

  // Viewport/Zoom support for pixel-art scaling
  void SetViewport(float width, float height); // Virtual viewport size
  void SetZoom(float zoom);                    // Explicit zoom/scale factor
  void ResetViewport();                        // Reset to window size

  // Post-processing (multi-shader support)
  bool LoadPostShader(const char *name, const char *fragmentShaderPath);
  void UnloadPostShader(const char *name);
  void SetPostShaderUniform(const char *name, const void *data, size_t size);
  void EnableShader(const char *name, bool enabled);
  bool ReloadPostShader(const char *name);

  int GetWhiteTexture();
  void BeginFrame(SDL_GPUCommandBuffer *cmdBuf);

  // Screenshot support
  bool SaveScreenshot(const char *filepath);

  // Window resize handling
  void OnWindowResize(uint32_t newWidth, uint32_t newHeight);

  // Enhanced DrawSprite with Tint, Rotation, Flip, Z-Index
  void DrawSprite(int textureId, float x, float y, float w, float h,
                  float rotation = 0.0f, bool flipX = false, bool flipY = false,
                  Color tint = Color::White, bool screenSpace = false,
                  int zIndex = 0);

  // Enhanced DrawSpriteRect with Tint, Rotation, Flip, Z-Index
  void DrawSpriteRect(int textureId, float x, float y, float w, float h,
                      float sx, float sy, float sw, float sh,
                      float rotation = 0.0f, bool flipX = false,
                      bool flipY = false, Color tint = Color::White,
                      bool screenSpace = false, int zIndex = 0);

  enum class SortMode {
    None, // Submission order (current behavior)
    YSort // Z-index + Y-position sorting
  };

  void SetSortMode(SortMode mode) { m_SortMode = mode; }

  // Flush world queue with Y-sorting and post-processing.
  // Subsequent DrawSprite calls (with screenSpace=false) will queue for next
  // frame. UI elements (screenSpace=true) are drawn on top during EndFrame().
  void Flush();

  // End frame rendering. Auto-flushes world queue if not already flushed.
  // Renders UI elements (screen-space) on top of world content.
  void EndFrame();

private:
  float m_CameraX = 0;
  float m_CameraY = 0;

  // Viewport/Zoom for pixel-art scaling
  float m_ViewportWidth = 0; // 0 = use window size
  float m_ViewportHeight = 0;
  float m_Zoom = 1.0f;
  SDL_GPUDevice *m_Device;
  SDL_Window *m_Window;
  SDL_GPUGraphicsPipeline *m_Pipeline;
  SDL_GPUSampler *m_Sampler;
  int m_WhiteTextureId = -1;
  void CreateWhiteTexture();

  // Window dimensions
  uint32_t m_WindowWidth = 1280;
  uint32_t m_WindowHeight = 720;
  void RecreateRenderTargets();
  void UpdateShaderDimensions();

  // Post-processing multi-shader support
  struct ShaderData {
    SDL_GPUGraphicsPipeline *pipeline;
    SDL_GPUBuffer *uniformBuffer;
    SDL_GPUTransferBuffer *transferBuffer;
    std::string path;
    bool enabled; // Can toggle shader on/off without unloading
  };

  std::map<std::string, ShaderData> m_PostShaders;
  std::vector<std::string> m_ShaderOrder;
  SDL_GPUTexture *m_RenderTextures[2]; // Ping-pong buffers for multi-pass

  // Batching support
  SDL_GPUBuffer *m_VertexBuffer;
  SDL_GPUTransferBuffer *m_TransferBuffer;

  // Simple texture management
  struct Texture {
    SDL_GPUTexture *texture;
    int width;
    int height;
  };
  std::unordered_map<int, Texture> m_Textures;
  int m_NextTextureId = 1;

  // Deferred Rendering
  struct DrawCommand {
    int textureId;
    float x, y, w, h;     // World position/size
    float sx, sy, sw, sh; // UVs
    float rotation;
    bool flipX, flipY;
    bool screenSpace; // If true, bypass Y-sorting
    Color tint;

    // Sorting keys
    int zIndex;  // Primary sort key (Layer)
    float sortY; // Secondary sort key (Y-position for depth)
  };

  std::vector<DrawCommand> m_WorldDrawQueue;
  std::vector<DrawCommand> m_ScreenDrawQueue;
  SortMode m_SortMode = SortMode::YSort; // Default to Y-Sorting

  // Batching
  std::vector<Vertex> m_BatchedVertices;
  struct RenderBatch {
    int textureId;
    int vertexCount;
    int startVertex;
  };
  std::vector<RenderBatch> m_Batches;

  SDL_GPUCommandBuffer *m_CurrentCmdBuf;
  SDL_GPURenderPass *m_CurrentRenderPass;

  // Flush state tracking
  bool m_Flushed = false;
  SDL_GPUTexture *m_SwapchainTexture = nullptr;

  // Internal helper to generate vertices from a command
  void GenerateVerticesForCommand(const DrawCommand &cmd);
};
