#include "graphics/SpriteRenderer.h"
#include "asset/AssetManager.h"
#include "core/Logger.h"
#include "core/Profiler.h"
#include "core/WindowManager.h"
#include <fstream>

#include <sstream>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

// Helper function to read shader file
static std::string ReadShaderFile(const char *path) {
  std::ifstream file(path);
  if (!file.is_open()) {
    LOG_ERROR("Failed to open shader file: %s", path);
    return "";
  }
  std::stringstream buffer;
  buffer << file.rdbuf();
  return buffer.str();
}

// MAX SPRITES per frame
const int MAX_SPRITES = 10000;
const int MAX_VERTICES = MAX_SPRITES * 6;

// MSL Shaders
const char *MSL_VERTEX_SHADER = R"(
#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float4 color [[attribute(2)]];
};

struct VertexOutput {
    float4 position [[position]];
    float2 texCoord;
    float4 color;
};

struct ScreenUniforms {
    float screenWidth;
    float screenHeight;
};

vertex VertexOutput vertex_main(VertexInput in [[stage_in]],
                                 constant ScreenUniforms& uniforms [[buffer(0)]]) {
    VertexOutput out;
    // Transform from pixel coordinates to NDC (-1..1, -1..1)
    float x = (in.position.x / uniforms.screenWidth) * 2.0f - 1.0f;
    float y = (in.position.y / uniforms.screenHeight) * -2.0f + 1.0f; 
    
    out.position = float4(x, y, 0.0f, 1.0f);
    out.texCoord = in.texCoord;
    out.color = in.color;
    return out;
}
)";

const char *MSL_FRAGMENT_SHADER = R"(
#include <metal_stdlib>
using namespace metal;

struct VertexOutput {
    float4 position [[position]];
    float2 texCoord;
    float4 color;
};

fragment float4 fragment_main(VertexOutput in [[stage_in]],
                              texture2d<float> tex [[texture(0)]],
                              sampler samp [[sampler(0)]]) {
    return tex.sample(samp, in.texCoord) * in.color;
}
)";

// Post-processing vertex shader (fullscreen triangle)
const char *MSL_POST_VERTEX = R"(
#include <metal_stdlib>
using namespace metal;

struct VertexOutput {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOutput post_vertex(uint vertexID [[vertex_id]]) {
    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
    VertexOutput out;
    out.texCoord = uv;
    out.position = float4(uv * 2.0 - 1.0, 0.0, 1.0);
    out.position.y = -out.position.y;
    return out;
}
)";

SpriteRenderer::SpriteRenderer()
    : m_Device(nullptr), m_Window(nullptr), m_Pipeline(nullptr),
      m_Sampler(nullptr), m_VertexBuffer(nullptr), m_TransferBuffer(nullptr) {
  m_RenderTextures[0] = nullptr;
  m_RenderTextures[1] = nullptr;
}

SpriteRenderer::~SpriteRenderer() {
  // Cleanup handled explicitly in main() via Destroy()
}

bool SpriteRenderer::Init(SDL_GPUDevice *device, SDL_Window *window) {
  m_Device = device;
  m_Window = window;

  // Set Swapchain Parameters (Enable VSync based on config)
  bool vsync = WindowManager::getInstance().isVSyncEnabled();
  LOG_INFO("SpriteRenderer: VSync configured to %s",
           vsync ? "ENABLED" : "DISABLED");
  SDL_SetGPUSwapchainParameters(
      m_Device, m_Window, SDL_GPU_SWAPCHAINCOMPOSITION_SDR,
      vsync ? SDL_GPU_PRESENTMODE_VSYNC : SDL_GPU_PRESENTMODE_IMMEDIATE);

  // 1. Create Shaders
  SDL_GPUShaderCreateInfo vertexShaderInfo = {};
  vertexShaderInfo.code_size = strlen(MSL_VERTEX_SHADER);
  vertexShaderInfo.code = (const Uint8 *)MSL_VERTEX_SHADER;
  vertexShaderInfo.entrypoint = "vertex_main";
  vertexShaderInfo.format = SDL_GPU_SHADERFORMAT_MSL;
  vertexShaderInfo.stage = SDL_GPU_SHADERSTAGE_VERTEX;
  vertexShaderInfo.num_uniform_buffers = 1; // Screen dimensions uniform

  SDL_GPUShader *vertexShader =
      SDL_CreateGPUShader(m_Device, &vertexShaderInfo);
  if (!vertexShader)
    return false;

  SDL_GPUShaderCreateInfo fragmentShaderInfo = {};
  fragmentShaderInfo.code_size = strlen(MSL_FRAGMENT_SHADER);
  fragmentShaderInfo.code = (const Uint8 *)MSL_FRAGMENT_SHADER;
  fragmentShaderInfo.entrypoint = "fragment_main";
  fragmentShaderInfo.format = SDL_GPU_SHADERFORMAT_MSL;
  fragmentShaderInfo.stage = SDL_GPU_SHADERSTAGE_FRAGMENT;
  fragmentShaderInfo.num_samplers = 1;

  SDL_GPUShader *fragmentShader =
      SDL_CreateGPUShader(m_Device, &fragmentShaderInfo);
  if (!fragmentShader)
    return false;

  // 2. Create Pipeline
  SDL_GPUGraphicsPipelineCreateInfo pipelineInfo = {};
  pipelineInfo.vertex_shader = vertexShader;
  pipelineInfo.fragment_shader = fragmentShader;

  SDL_GPUVertexAttribute attributes[3];
  attributes[0].location = 0;
  attributes[0].buffer_slot = 0;
  attributes[0].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3;
  attributes[0].offset = 0;

  attributes[1].location = 1;
  attributes[1].buffer_slot = 0;
  attributes[1].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2;
  attributes[1].offset = sizeof(float) * 3;

  attributes[2].location = 2;
  attributes[2].buffer_slot = 0;
  attributes[2].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4;
  attributes[2].offset = sizeof(float) * 5;

  SDL_GPUVertexBufferDescription binding = {};
  binding.slot = 0;
  binding.pitch = sizeof(Vertex);
  binding.input_rate = SDL_GPU_VERTEXINPUTRATE_VERTEX;

  pipelineInfo.vertex_input_state.vertex_attributes = attributes;
  pipelineInfo.vertex_input_state.num_vertex_attributes = 3;
  pipelineInfo.vertex_input_state.vertex_buffer_descriptions = &binding;
  pipelineInfo.vertex_input_state.num_vertex_buffers = 1;

  pipelineInfo.rasterizer_state.fill_mode = SDL_GPU_FILLMODE_FILL;
  pipelineInfo.rasterizer_state.front_face =
      SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;

  SDL_GPUColorTargetDescription colorTarget = {};
  colorTarget.format = SDL_GetGPUSwapchainTextureFormat(m_Device, m_Window);
  colorTarget.blend_state.enable_blend = true;
  colorTarget.blend_state.src_color_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
  colorTarget.blend_state.dst_color_blendfactor =
      SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
  colorTarget.blend_state.color_blend_op = SDL_GPU_BLENDOP_ADD;
  colorTarget.blend_state.src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
  colorTarget.blend_state.dst_alpha_blendfactor =
      SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
  colorTarget.blend_state.alpha_blend_op = SDL_GPU_BLENDOP_ADD;

  pipelineInfo.target_info.color_target_descriptions = &colorTarget;
  pipelineInfo.target_info.num_color_targets = 1;
  pipelineInfo.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;

  m_Pipeline = SDL_CreateGPUGraphicsPipeline(m_Device, &pipelineInfo);

  SDL_ReleaseGPUShader(m_Device, vertexShader);
  SDL_ReleaseGPUShader(m_Device, fragmentShader);

  if (!m_Pipeline)
    return false;

  // 3. Create Sampler
  SDL_GPUSamplerCreateInfo samplerInfo = {};
  samplerInfo.min_filter = SDL_GPU_FILTER_NEAREST;
  samplerInfo.mag_filter = SDL_GPU_FILTER_NEAREST;
  samplerInfo.mipmap_mode = SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
  samplerInfo.address_mode_u = SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
  samplerInfo.address_mode_v = SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
  samplerInfo.address_mode_w = SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
  m_Sampler = SDL_CreateGPUSampler(m_Device, &samplerInfo);

  // 4. Create Vertex Buffers
  SDL_GPUBufferCreateInfo bufferInfo = {};
  bufferInfo.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
  bufferInfo.size = MAX_VERTICES * sizeof(Vertex);
  m_VertexBuffer = SDL_CreateGPUBuffer(m_Device, &bufferInfo);

  SDL_GPUTransferBufferCreateInfo transferInfo = {};
  transferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
  transferInfo.size = MAX_VERTICES * sizeof(Vertex);
  m_TransferBuffer = SDL_CreateGPUTransferBuffer(m_Device, &transferInfo);

  // Prereserve
  m_BatchedVertices.reserve(MAX_VERTICES);

  // 5. Get window dimensions from WindowManager (with DPI scaling)
  m_WindowWidth = WindowManager::getInstance().getScaledWidth();
  m_WindowHeight = WindowManager::getInstance().getScaledHeight();

  LOG_INFO("SpriteRenderer: Using window dimensions %dx%d (DPI scale: %.2f)",
           m_WindowWidth, m_WindowHeight,
           WindowManager::getInstance().getDPIScale());

  // 6. Create Ping-Pong Textures for Multi-Pass Rendering
  SDL_GPUTextureCreateInfo renderTexInfo = {};
  renderTexInfo.type = SDL_GPU_TEXTURETYPE_2D;
  renderTexInfo.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
  renderTexInfo.width = m_WindowWidth;
  renderTexInfo.height = m_WindowHeight;
  renderTexInfo.layer_count_or_depth = 1;
  renderTexInfo.num_levels = 1;
  renderTexInfo.usage =
      SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER;

  m_RenderTextures[0] = SDL_CreateGPUTexture(m_Device, &renderTexInfo);
  m_RenderTextures[1] = SDL_CreateGPUTexture(m_Device, &renderTexInfo);

  return true;
}

void SpriteRenderer::Destroy() {
  // Guard against invalid device (e.g., during program exit)
  if (!m_Device)
    return;

  for (auto &pair : m_Textures) {
    SDL_ReleaseGPUTexture(m_Device, pair.second.texture);
  }
  m_Textures.clear();

  if (m_Sampler)
    SDL_ReleaseGPUSampler(m_Device, m_Sampler);
  if (m_Pipeline)
    SDL_ReleaseGPUGraphicsPipeline(m_Device, m_Pipeline);
  if (m_VertexBuffer)
    SDL_ReleaseGPUBuffer(m_Device, m_VertexBuffer);
  if (m_TransferBuffer)
    SDL_ReleaseGPUTransferBuffer(m_Device, m_TransferBuffer);

  // Post-processing cleanup
  for (auto &pair : m_PostShaders) {
    if (pair.second.pipeline)
      SDL_ReleaseGPUGraphicsPipeline(m_Device, pair.second.pipeline);
    if (pair.second.uniformBuffer)
      SDL_ReleaseGPUBuffer(m_Device, pair.second.uniformBuffer);
    if (pair.second.transferBuffer)
      SDL_ReleaseGPUTransferBuffer(m_Device, pair.second.transferBuffer);
  }
  m_PostShaders.clear();

  if (m_RenderTextures[0])
    SDL_ReleaseGPUTexture(m_Device, m_RenderTextures[0]);
  if (m_RenderTextures[1])
    SDL_ReleaseGPUTexture(m_Device, m_RenderTextures[1]);
}

void SpriteRenderer::OnWindowResize(uint32_t newWidth, uint32_t newHeight) {
  // Apply DPI scaling
  float dpiScale = WindowManager::getInstance().getDPIScale();
  uint32_t scaledWidth = static_cast<uint32_t>(newWidth * dpiScale);
  uint32_t scaledHeight = static_cast<uint32_t>(newHeight * dpiScale);

  if (m_WindowWidth == scaledWidth && m_WindowHeight == scaledHeight) {
    return; // No change
  }

  LOG_INFO("SpriteRenderer: Window resized to %dx%d (scaled: %dx%d, DPI: %.2f)",
           newWidth, newHeight, scaledWidth, scaledHeight, dpiScale);

  m_WindowWidth = scaledWidth;
  m_WindowHeight = scaledHeight;

  RecreateRenderTargets();
  UpdateShaderDimensions();
}

void SpriteRenderer::RecreateRenderTargets() {
  if (!m_Device)
    return;

  // Release old render textures
  if (m_RenderTextures[0]) {
    SDL_ReleaseGPUTexture(m_Device, m_RenderTextures[0]);
    m_RenderTextures[0] = nullptr;
  }
  if (m_RenderTextures[1]) {
    SDL_ReleaseGPUTexture(m_Device, m_RenderTextures[1]);
    m_RenderTextures[1] = nullptr;
  }

  // Create new render textures with updated dimensions
  SDL_GPUTextureCreateInfo renderTexInfo = {};
  renderTexInfo.type = SDL_GPU_TEXTURETYPE_2D;
  renderTexInfo.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
  renderTexInfo.width = m_WindowWidth;
  renderTexInfo.height = m_WindowHeight;
  renderTexInfo.layer_count_or_depth = 1;
  renderTexInfo.num_levels = 1;
  renderTexInfo.usage =
      SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER;

  m_RenderTextures[0] = SDL_CreateGPUTexture(m_Device, &renderTexInfo);
  m_RenderTextures[1] = SDL_CreateGPUTexture(m_Device, &renderTexInfo);

  if (!m_RenderTextures[0] || !m_RenderTextures[1]) {
    LOG_ERROR("Failed to recreate render textures");
  }
}

void SpriteRenderer::UpdateShaderDimensions() {
  // Screen dimensions are now passed dynamically via
  // SDL_PushGPUVertexUniformData in Flush() and EndFrame() render passes
  LOG_DEBUG("Window dimensions updated to: %dx%d", m_WindowWidth,
            m_WindowHeight);
}

int SpriteRenderer::LoadTexture(const char *path) {
  int w, h, n;
  unsigned char *data = stbi_load(path, &w, &h, &n, 4);
  if (!data) {
    LOG_ERROR("Failed to load image: %s", path);
    return 0;
  }
  int id = LoadTextureFromMemory(data, w, h);
  stbi_image_free(data);
  return id;
}

void SpriteRenderer::GetTextureSize(int id, int *w, int *h) {
  auto it = m_Textures.find(id);
  if (it != m_Textures.end()) {
    *w = it->second.width;
    *h = it->second.height;
  } else {
    *w = 0;
    *h = 0;
  }
}

void SpriteRenderer::GetWindowSize(int *w, int *h) {
  *w = m_WindowWidth;
  *h = m_WindowHeight;
}

int SpriteRenderer::LoadTextureFromMemory(const unsigned char *data, int w,
                                          int h) {
  // Create GPU Texture
  SDL_GPUTextureCreateInfo textureInfo = {};
  textureInfo.type = SDL_GPU_TEXTURETYPE_2D;
  textureInfo.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
  textureInfo.width = w;
  textureInfo.height = h;
  textureInfo.layer_count_or_depth = 1;
  textureInfo.num_levels = 1;
  textureInfo.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER;

  SDL_GPUTexture *texture = SDL_CreateGPUTexture(m_Device, &textureInfo);

  // Upload Data
  SDL_GPUTransferBufferCreateInfo transferInfo = {};
  transferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
  transferInfo.size = w * h * 4;
  SDL_GPUTransferBuffer *transferBuffer =
      SDL_CreateGPUTransferBuffer(m_Device, &transferInfo);

  Uint8 *map =
      (Uint8 *)SDL_MapGPUTransferBuffer(m_Device, transferBuffer, false);
  memcpy(map, data, w * h * 4);
  SDL_UnmapGPUTransferBuffer(m_Device, transferBuffer);

  SDL_GPUCommandBuffer *cmd = SDL_AcquireGPUCommandBuffer(m_Device);
  SDL_GPUCopyPass *copyPass = SDL_BeginGPUCopyPass(cmd);

  SDL_GPUTextureTransferInfo source = {};
  source.transfer_buffer = transferBuffer;
  source.offset = 0;
  source.pixels_per_row = w;
  source.rows_per_layer = h;

  SDL_GPUTextureRegion destination = {};
  destination.texture = texture;
  destination.w = w;
  destination.h = h;
  destination.d = 1;

  SDL_UploadToGPUTexture(copyPass, &source, &destination, false);
  SDL_EndGPUCopyPass(copyPass);
  SDL_SubmitGPUCommandBuffer(cmd);
  SDL_ReleaseGPUTransferBuffer(m_Device, transferBuffer);

  int id = m_NextTextureId++;
  m_Textures[id] = {texture, w, h};
  return id;
}

void SpriteRenderer::BeginFrame(SDL_GPUCommandBuffer *cmdBuf) {
  m_CurrentCmdBuf = cmdBuf;
  m_BatchedVertices.clear();
  m_Batches.clear();
  m_WorldDrawQueue.clear();
  m_ScreenDrawQueue.clear();
  m_Flushed = false;
  m_SwapchainTexture = nullptr;
}

void SpriteRenderer::SetCamera(float x, float y) {
  m_CameraX = x;
  m_CameraY = y;
}

void SpriteRenderer::GetCamera(float *x, float *y) {
  if (x)
    *x = m_CameraX;
  if (y)
    *y = m_CameraY;
}

void SpriteRenderer::SetViewport(float width, float height) {
  m_ViewportWidth = width;
  m_ViewportHeight = height;
  // Auto-calculate zoom to fit window while maintaining aspect ratio
  if (width > 0 && height > 0) {
    float scaleX = static_cast<float>(m_WindowWidth) / width;
    float scaleY = static_cast<float>(m_WindowHeight) / height;
    m_Zoom = std::min(scaleX, scaleY); // Fit without stretching
  }
}

void SpriteRenderer::SetZoom(float zoom) { m_Zoom = zoom; }

void SpriteRenderer::ResetViewport() {
  m_ViewportWidth = 0;
  m_ViewportHeight = 0;
  m_Zoom = 1.0f;
}

void SpriteRenderer::DrawSprite(int textureId, float x, float y, float w,
                                float h, float rotation, bool flipX, bool flipY,
                                Color tint, bool screenSpace, int zIndex) {
  DrawSpriteRect(textureId, x, y, w, h, 0.0f, 0.0f, 1.0f, 1.0f, rotation, flipX,
                 flipY, tint, screenSpace, zIndex);
}

void SpriteRenderer::DrawSpriteRect(int textureId, float x, float y, float w,
                                    float h, float sx, float sy, float sw,
                                    float sh, float rotation, bool flipX,
                                    bool flipY, Color tint, bool screenSpace,
                                    int zIndex) {
  DrawCommand cmd;
  cmd.textureId = textureId;
  cmd.x = x;
  cmd.y = y;
  cmd.w = w;
  cmd.h = h;
  cmd.sx = sx;
  cmd.sy = sy;
  cmd.sw = sw;
  cmd.sh = sh;
  cmd.rotation = rotation;
  cmd.flipX = flipX;
  cmd.flipY = flipY;
  cmd.screenSpace = screenSpace;
  cmd.tint = tint;
  cmd.zIndex = zIndex;
  // Sort by bottom of sprite (Y + H) for correct depth
  cmd.sortY = y + h;

  if (screenSpace) {
    m_ScreenDrawQueue.push_back(cmd);
  } else {
    m_WorldDrawQueue.push_back(cmd);
  }
}

void SpriteRenderer::GenerateVerticesForCommand(const DrawCommand &cmd) {
  if (m_BatchedVertices.size() + 6 >= MAX_VERTICES) {
    static bool warned = false;
    if (!warned) {
      LOG_WARN("Vertex buffer full (MAX_VERTICES=%d), dropping sprites",
               MAX_VERTICES);
      warned = true;
    }
    return;
  }

  float finalX = cmd.x;
  float finalY = cmd.y;
  float finalW = cmd.w;
  float finalH = cmd.h;

  if (!cmd.screenSpace) {
    // Apply camera offset
    finalX -= m_CameraX;
    finalY -= m_CameraY;

    // Apply zoom scaling for viewport mode
    if (m_Zoom != 1.0f) {
      finalX *= m_Zoom;
      finalY *= m_Zoom;
      finalW *= m_Zoom;
      finalH *= m_Zoom;
    }

    // Center viewport on screen (letterboxing if aspect ratios differ)
    if (m_ViewportWidth > 0 && m_ViewportHeight > 0) {
      float scaledViewW = m_ViewportWidth * m_Zoom;
      float scaledViewH = m_ViewportHeight * m_Zoom;
      float offsetX = (static_cast<float>(m_WindowWidth) - scaledViewW) / 2.0f;
      float offsetY = (static_cast<float>(m_WindowHeight) - scaledViewH) / 2.0f;
      finalX += offsetX;
      finalY += offsetY;
    }
  }

  // Rotation logic (around center)
  float cx = finalX + finalW * 0.5f;
  float cy = finalY + finalH * 0.5f;

  float c = cosf(cmd.rotation);
  float s = sinf(cmd.rotation);

  float dx = -finalW * 0.5f;
  float dy = -finalH * 0.5f;

  auto transform = [&](float lx, float ly) -> std::pair<float, float> {
    return {cx + lx * c - ly * s, cy + lx * s + ly * c};
  };

  if (m_Batches.empty() || m_Batches.back().textureId != cmd.textureId) {
    RenderBatch newBatch;
    newBatch.textureId = cmd.textureId;
    newBatch.startVertex = (int)m_BatchedVertices.size();
    newBatch.vertexCount = 0;
    m_Batches.push_back(newBatch);
  }
  RenderBatch &currentBatch = m_Batches.back();

  float u0 = cmd.sx;
  float v0 = cmd.sy;
  float u1 = cmd.sx + cmd.sw;
  float v1 = cmd.sy + cmd.sh;

  if (cmd.flipX)
    std::swap(u0, u1);
  if (cmd.flipY)
    std::swap(v0, v1);

  auto p0 = transform(dx, dy);                   // TL
  auto p1 = transform(dx + finalW, dy);          // TR
  auto p2 = transform(dx + finalW, dy + finalH); // BR
  auto p3 = transform(dx, dy + finalH);          // BL

  float r = cmd.tint.r;
  float g = cmd.tint.g;
  float b = cmd.tint.b;
  float a = cmd.tint.a;

  // BL
  m_BatchedVertices.push_back({p3.first, p3.second, 0.0f, u0, v1, r, g, b, a});
  // TL
  m_BatchedVertices.push_back({p0.first, p0.second, 0.0f, u0, v0, r, g, b, a});
  // TR
  m_BatchedVertices.push_back({p1.first, p1.second, 0.0f, u1, v0, r, g, b, a});

  // BL
  m_BatchedVertices.push_back({p3.first, p3.second, 0.0f, u0, v1, r, g, b, a});
  // TR
  m_BatchedVertices.push_back({p1.first, p1.second, 0.0f, u1, v0, r, g, b, a});
  // BR
  m_BatchedVertices.push_back({p2.first, p2.second, 0.0f, u1, v1, r, g, b, a});

  currentBatch.vertexCount += 6;
}

void SpriteRenderer::Flush() {
  PROFILE_SCOPE_N("Renderer::Flush");

  // Sort World Queue
  if (m_SortMode == SortMode::YSort) {
    // Use stable_sort to preserve submission order for identical sort keys
    std::stable_sort(m_WorldDrawQueue.begin(), m_WorldDrawQueue.end(),
                     [](const DrawCommand &a, const DrawCommand &b) {
                       // Primary: Z-Index (layer)
                       if (a.zIndex != b.zIndex)
                         return a.zIndex < b.zIndex;
                       // Secondary: Y-position (depth)
                       if (a.sortY != b.sortY)
                         return a.sortY < b.sortY;
                       // Tertiary: Texture ID (batching)
                       return a.textureId < b.textureId;
                     });
  }

  // Generate Vertices from World Queue
  for (const auto &cmd : m_WorldDrawQueue) {
    GenerateVerticesForCommand(cmd);
  }
  m_WorldDrawQueue.clear();

  if (m_BatchedVertices.empty())
    return;

  // 1. Upload Vertices
  Uint8 *map =
      (Uint8 *)SDL_MapGPUTransferBuffer(m_Device, m_TransferBuffer, true);
  memcpy(map, m_BatchedVertices.data(),
         m_BatchedVertices.size() * sizeof(Vertex));
  SDL_UnmapGPUTransferBuffer(m_Device, m_TransferBuffer);

  SDL_GPUCopyPass *copyPass = SDL_BeginGPUCopyPass(m_CurrentCmdBuf);

  // Upload vertex data
  SDL_GPUTransferBufferLocation source = {};
  source.transfer_buffer = m_TransferBuffer;
  source.offset = 0;
  SDL_GPUBufferRegion dest = {};
  dest.buffer = m_VertexBuffer;
  dest.offset = 0;
  dest.size = m_BatchedVertices.size() * sizeof(Vertex);
  SDL_UploadToGPUBuffer(copyPass, &source, &dest, true);

  // Upload uniforms for all active shaders
  for (const auto &shaderName : m_ShaderOrder) {
    auto it = m_PostShaders.find(shaderName);
    if (it != m_PostShaders.end()) {
      SDL_GPUTransferBufferLocation uniformSrc = {};
      uniformSrc.transfer_buffer = it->second.transferBuffer;
      uniformSrc.offset = 0;
      SDL_GPUBufferRegion uniformDst = {};
      uniformDst.buffer = it->second.uniformBuffer;
      uniformDst.offset = 0;
      uniformDst.size = 256;
      SDL_UploadToGPUBuffer(copyPass, &uniformSrc, &uniformDst, false);
    }
  }

  SDL_EndGPUCopyPass(copyPass);

  // 2. Acquire swapchain (store for later UI rendering)
  SDL_AcquireGPUSwapchainTexture(m_CurrentCmdBuf, m_Window, &m_SwapchainTexture,
                                 NULL, NULL);

  // Check if swapchain acquisition failed (e.g., window minimized)
  if (!m_SwapchainTexture) {
    // Swapchain unavailable - skip rendering but keep state valid
    m_BatchedVertices.clear();
    m_Batches.clear();
    m_Flushed = true;
    return;
  }

  // 3. Determine rendering path
  if (m_ShaderOrder.empty()) {
    // No shaders - render directly to swapchain
    SDL_GPUColorTargetInfo colorTarget = {};
    colorTarget.texture = m_SwapchainTexture;
    colorTarget.clear_color = {0.1f, 0.1f, 0.1f, 1.0f};
    colorTarget.load_op = SDL_GPU_LOADOP_CLEAR;
    colorTarget.store_op = SDL_GPU_STOREOP_STORE;

    m_CurrentRenderPass =
        SDL_BeginGPURenderPass(m_CurrentCmdBuf, &colorTarget, 1, NULL);
    SDL_BindGPUGraphicsPipeline(m_CurrentRenderPass, m_Pipeline);

    // Push screen dimensions uniform
    float screenDims[2] = {static_cast<float>(m_WindowWidth),
                           static_cast<float>(m_WindowHeight)};
    SDL_PushGPUVertexUniformData(m_CurrentCmdBuf, 0, screenDims,
                                 sizeof(screenDims));

    SDL_GPUBufferBinding vertexBinding = {};
    vertexBinding.buffer = m_VertexBuffer;
    vertexBinding.offset = 0;
    SDL_BindGPUVertexBuffers(m_CurrentRenderPass, 0, &vertexBinding, 1);

    for (const auto &batch : m_Batches) {
      auto it = m_Textures.find(batch.textureId);
      if (it != m_Textures.end()) {
        SDL_GPUTextureSamplerBinding binding = {it->second.texture, m_Sampler};
        SDL_BindGPUFragmentSamplers(m_CurrentRenderPass, 0, &binding, 1);
        SDL_DrawGPUPrimitives(m_CurrentRenderPass, batch.vertexCount, 1,
                              batch.startVertex, 0);
      }
    }
    SDL_EndGPURenderPass(m_CurrentRenderPass);
  } else {
    // With shaders - multi-pass rendering

    // PASS 1: Render scene to renderTextures[0]
    SDL_GPUColorTargetInfo sceneTarget = {};
    sceneTarget.texture = m_RenderTextures[0];
    sceneTarget.clear_color = {0.1f, 0.1f, 0.1f, 1.0f};
    sceneTarget.load_op = SDL_GPU_LOADOP_CLEAR;
    sceneTarget.store_op = SDL_GPU_STOREOP_STORE;

    m_CurrentRenderPass =
        SDL_BeginGPURenderPass(m_CurrentCmdBuf, &sceneTarget, 1, NULL);
    SDL_BindGPUGraphicsPipeline(m_CurrentRenderPass, m_Pipeline);

    // Push screen dimensions uniform
    float screenDimsScene[2] = {static_cast<float>(m_WindowWidth),
                                static_cast<float>(m_WindowHeight)};
    SDL_PushGPUVertexUniformData(m_CurrentCmdBuf, 0, screenDimsScene,
                                 sizeof(screenDimsScene));

    SDL_GPUBufferBinding vertexBinding = {};
    vertexBinding.buffer = m_VertexBuffer;
    vertexBinding.offset = 0;
    SDL_BindGPUVertexBuffers(m_CurrentRenderPass, 0, &vertexBinding, 1);

    for (const auto &batch : m_Batches) {
      auto it = m_Textures.find(batch.textureId);
      if (it != m_Textures.end()) {
        SDL_GPUTextureSamplerBinding binding = {it->second.texture, m_Sampler};
        SDL_BindGPUFragmentSamplers(m_CurrentRenderPass, 0, &binding, 1);
        SDL_DrawGPUPrimitives(m_CurrentRenderPass, batch.vertexCount, 1,
                              batch.startVertex, 0);
      }
    }
    SDL_EndGPURenderPass(m_CurrentRenderPass);

    // PASS 2+: Apply shaders in chain (ping-pong between textures)
    for (size_t i = 0; i < m_ShaderOrder.size(); ++i) {
      const std::string &shaderName = m_ShaderOrder[i];
      auto it = m_PostShaders.find(shaderName);
      if (it == m_PostShaders.end())
        continue;
      if (!it->second.enabled)
        continue; // Skip disabled shaders

      SDL_GPUTexture *sourceTexture = m_RenderTextures[i % 2];
      SDL_GPUTexture *targetTexture = (i == m_ShaderOrder.size() - 1)
                                          ? m_SwapchainTexture
                                          : m_RenderTextures[(i + 1) % 2];

      SDL_GPUColorTargetInfo postTarget = {};
      postTarget.texture = targetTexture;
      postTarget.load_op = SDL_GPU_LOADOP_DONT_CARE;
      postTarget.store_op = SDL_GPU_STOREOP_STORE;

      SDL_GPURenderPass *postPass =
          SDL_BeginGPURenderPass(m_CurrentCmdBuf, &postTarget, 1, NULL);
      SDL_BindGPUGraphicsPipeline(postPass, it->second.pipeline);

      // Bind source texture
      SDL_GPUTextureSamplerBinding texBinding = {sourceTexture, m_Sampler};
      SDL_BindGPUFragmentSamplers(postPass, 0, &texBinding, 1);

      // Bind uniforms
      SDL_GPUBuffer *storageBuffers[] = {it->second.uniformBuffer};
      SDL_BindGPUFragmentStorageBuffers(postPass, 0, storageBuffers, 1);

      // Draw fullscreen triangle
      SDL_DrawGPUPrimitives(postPass, 3, 1, 0, 0);
      SDL_EndGPURenderPass(postPass);
    }
  }

  // Clear batches for UI rendering
  m_BatchedVertices.clear();
  m_Batches.clear();
  m_Flushed = true;
}

void SpriteRenderer::EndFrame() {
  PROFILE_SCOPE_N("Renderer::EndFrame");

  // Ensure world is flushed (if user didn't call Flush explicitly)
  if (!m_Flushed) {
    Flush();
  }

  // Generate vertices for Screen Space (UI)
  // UI elements MUST preserve submission order for correct layering/blending
  // DO NOT sort by texture - draw order matters for UI!
  for (const auto &cmd : m_ScreenDrawQueue) {
    GenerateVerticesForCommand(cmd);
  }
  m_ScreenDrawQueue.clear();

  if (m_BatchedVertices.empty())
    return;

  // 1. Upload UI Vertices
  Uint8 *map =
      (Uint8 *)SDL_MapGPUTransferBuffer(m_Device, m_TransferBuffer, true);
  memcpy(map, m_BatchedVertices.data(),
         m_BatchedVertices.size() * sizeof(Vertex));
  SDL_UnmapGPUTransferBuffer(m_Device, m_TransferBuffer);

  SDL_GPUCopyPass *copyPass = SDL_BeginGPUCopyPass(m_CurrentCmdBuf);

  SDL_GPUTransferBufferLocation source = {};
  source.transfer_buffer = m_TransferBuffer;
  source.offset = 0;
  SDL_GPUBufferRegion dest = {};
  dest.buffer = m_VertexBuffer;
  dest.offset = 0;
  dest.size = m_BatchedVertices.size() * sizeof(Vertex);
  SDL_UploadToGPUBuffer(copyPass, &source, &dest, true);
  SDL_EndGPUCopyPass(copyPass);

  // 2. Acquire Swapchain if not already held
  if (!m_SwapchainTexture) {
    SDL_AcquireGPUSwapchainTexture(m_CurrentCmdBuf, m_Window,
                                   &m_SwapchainTexture, NULL, NULL);
  }

  if (!m_SwapchainTexture) {
    // Failed to acquire swapchain, can't render
    return;
  }

  // 3. Render UI
  // If world was flushed, we LOAD existing content.
  // If world was empty (Flush did nothing), we CLEAR.
  SDL_GPUColorTargetInfo colorTarget = {};
  colorTarget.texture = m_SwapchainTexture;
  // If flushed, load content. If NOT flushed (empty world), clear to black/gray
  colorTarget.load_op = m_Flushed ? SDL_GPU_LOADOP_LOAD : SDL_GPU_LOADOP_CLEAR;
  colorTarget.store_op = SDL_GPU_STOREOP_STORE;
  if (!m_Flushed) {
    colorTarget.clear_color = {0.1f, 0.1f, 0.1f, 1.0f};
  }

  m_CurrentRenderPass =
      SDL_BeginGPURenderPass(m_CurrentCmdBuf, &colorTarget, 1, NULL);
  SDL_BindGPUGraphicsPipeline(m_CurrentRenderPass, m_Pipeline);

  // Push screen dimensions uniform
  float screenDims[2] = {static_cast<float>(m_WindowWidth),
                         static_cast<float>(m_WindowHeight)};
  SDL_PushGPUVertexUniformData(m_CurrentCmdBuf, 0, screenDims,
                               sizeof(screenDims));

  SDL_GPUBufferBinding vertexBinding = {};
  vertexBinding.buffer = m_VertexBuffer;
  vertexBinding.offset = 0;
  SDL_BindGPUVertexBuffers(m_CurrentRenderPass, 0, &vertexBinding, 1);

  for (const auto &batch : m_Batches) {
    auto it = m_Textures.find(batch.textureId);
    if (it != m_Textures.end()) {
      SDL_GPUTextureSamplerBinding binding = {it->second.texture, m_Sampler};
      SDL_BindGPUFragmentSamplers(m_CurrentRenderPass, 0, &binding, 1);
      SDL_DrawGPUPrimitives(m_CurrentRenderPass, batch.vertexCount, 1,
                            batch.startVertex, 0);
    }
  }
  SDL_EndGPURenderPass(m_CurrentRenderPass);
}

// Post-processing shader loading (multi-shader support)
bool SpriteRenderer::LoadPostShader(const char *name,
                                    const char *fragmentShaderPath) {
  // Check if shader already loaded
  if (m_PostShaders.find(name) != m_PostShaders.end()) {
    LOG_DEBUG("Shader '%s' already loaded", name);
    return true;
  }

  std::string shaderCode;

  // Try AssetManager cache first
  try {
    auto &assets = AssetManager::getInstance();
    auto cachedShader = assets.getShader(fragmentShaderPath);
    if (cachedShader && cachedShader->isValid()) {
      shaderCode = cachedShader->getSource();
      LOG_INFO("Loaded shader '%s' from AssetManager cache", name);
    }
  } catch (...) {
    // Shader not in cache, will fall back to file read
  }

  // Fallback to direct file read if not found in cache
  if (shaderCode.empty()) {
    shaderCode = ReadShaderFile(fragmentShaderPath);
    if (shaderCode.empty()) {
      return false;
    }
    LOG_INFO("Loaded shader '%s' from %s", name, fragmentShaderPath);
  }

  // Create shader pipeline
  SDL_GPUShaderCreateInfo vertInfo = {};
  vertInfo.code = (const Uint8 *)MSL_POST_VERTEX;
  vertInfo.code_size = strlen(MSL_POST_VERTEX);
  vertInfo.entrypoint = "post_vertex";
  vertInfo.format = SDL_GPU_SHADERFORMAT_MSL;
  vertInfo.stage = SDL_GPU_SHADERSTAGE_VERTEX;
  SDL_GPUShader *vertShader = SDL_CreateGPUShader(m_Device, &vertInfo);

  SDL_GPUShaderCreateInfo fragInfo = {};
  fragInfo.code = (const Uint8 *)shaderCode.c_str();
  fragInfo.code_size = shaderCode.size();
  fragInfo.entrypoint = "post_fragment";
  fragInfo.format = SDL_GPU_SHADERFORMAT_MSL;
  fragInfo.stage = SDL_GPU_SHADERSTAGE_FRAGMENT;
  fragInfo.num_samplers = 1;
  fragInfo.num_storage_buffers = 1;
  SDL_GPUShader *fragShader = SDL_CreateGPUShader(m_Device, &fragInfo);

  if (!vertShader || !fragShader) {
    LOG_ERROR("Failed to compile shader '%s': %s", name, fragmentShaderPath);
    if (vertShader)
      SDL_ReleaseGPUShader(m_Device, vertShader);
    if (fragShader)
      SDL_ReleaseGPUShader(m_Device, fragShader);
    return false;
  }

  SDL_GPUGraphicsPipelineCreateInfo pipelineInfo = {};
  pipelineInfo.vertex_shader = vertShader;
  pipelineInfo.fragment_shader = fragShader;
  pipelineInfo.vertex_input_state.num_vertex_attributes = 0;
  pipelineInfo.vertex_input_state.num_vertex_buffers = 0;
  pipelineInfo.rasterizer_state.fill_mode = SDL_GPU_FILLMODE_FILL;
  pipelineInfo.rasterizer_state.front_face =
      SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;

  SDL_GPUColorTargetDescription colorTarget = {};
  colorTarget.format = SDL_GetGPUSwapchainTextureFormat(m_Device, m_Window);
  colorTarget.blend_state.enable_blend = false;

  pipelineInfo.target_info.color_target_descriptions = &colorTarget;
  pipelineInfo.target_info.num_color_targets = 1;
  pipelineInfo.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;

  SDL_GPUGraphicsPipeline *pipeline =
      SDL_CreateGPUGraphicsPipeline(m_Device, &pipelineInfo);

  SDL_ReleaseGPUShader(m_Device, vertShader);
  SDL_ReleaseGPUShader(m_Device, fragShader);

  if (!pipeline) {
    LOG_ERROR("Failed to create pipeline for shader '%s'", name);
    return false;
  }

  // Create per-shader uniform buffer
  SDL_GPUBufferCreateInfo uniformBufferInfo = {};
  uniformBufferInfo.usage = SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ;
  uniformBufferInfo.size = 256;
  SDL_GPUBuffer *uniformBuffer =
      SDL_CreateGPUBuffer(m_Device, &uniformBufferInfo);

  SDL_GPUTransferBufferCreateInfo uniformTransferInfo = {};
  uniformTransferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
  uniformTransferInfo.size = 256;
  SDL_GPUTransferBuffer *transferBuffer =
      SDL_CreateGPUTransferBuffer(m_Device, &uniformTransferInfo);

  // Store shader data
  ShaderData data;
  data.pipeline = pipeline;
  data.uniformBuffer = uniformBuffer;
  data.transferBuffer = transferBuffer;
  data.path = fragmentShaderPath;
  data.enabled = true; // Newly loaded shaders start enabled

  m_PostShaders[name] = data;
  m_ShaderOrder.push_back(name);

  LOG_INFO("Loaded shader '%s' from %s", name, fragmentShaderPath);
  return true;
}

void SpriteRenderer::UnloadPostShader(const char *name) {
  auto it = m_PostShaders.find(name);
  if (it == m_PostShaders.end()) {
    LOG_WARN("Shader '%s' not found", name);
    return;
  }

  // Release GPU resources
  if (it->second.pipeline)
    SDL_ReleaseGPUGraphicsPipeline(m_Device, it->second.pipeline);
  if (it->second.uniformBuffer)
    SDL_ReleaseGPUBuffer(m_Device, it->second.uniformBuffer);
  if (it->second.transferBuffer)
    SDL_ReleaseGPUTransferBuffer(m_Device, it->second.transferBuffer);

  // Remove from map
  m_PostShaders.erase(it);

  // Remove from order vector
  m_ShaderOrder.erase(std::remove(m_ShaderOrder.begin(), m_ShaderOrder.end(),
                                  std::string(name)),
                      m_ShaderOrder.end());

  LOG_INFO("Unloaded shader '%s'", name);
}

void SpriteRenderer::SetPostShaderUniform(const char *name, const void *data,
                                          size_t size) {
  auto it = m_PostShaders.find(name);
  if (it == m_PostShaders.end()) {
    LOG_WARN("Shader '%s' not found", name);
    return;
  }

  if (size > 256) {
    LOG_ERROR("Uniform data too large (%zu bytes)", size);
    return;
  }

  Uint8 *map = (Uint8 *)SDL_MapGPUTransferBuffer(
      m_Device, it->second.transferBuffer, true);
  memcpy(map, data, size);
  SDL_UnmapGPUTransferBuffer(m_Device, it->second.transferBuffer);
}

void SpriteRenderer::EnableShader(const char *name, bool enabled) {
  auto it = m_PostShaders.find(name);
  if (it == m_PostShaders.end()) {
    LOG_WARN("EnableShader: Shader '%s' not found", name);
    return;
  }

  it->second.enabled = enabled;
  LOG_INFO("Shader '%s' %s", name, (enabled ? "enabled" : "disabled"));
}

bool SpriteRenderer::ReloadPostShader(const char *name) {
  auto it = m_PostShaders.find(name);
  if (it == m_PostShaders.end()) {
    LOG_WARN("ReloadPostShader: Shader '%s' not found", name);
    return false;
  }

  // Read shader file again
  std::string shaderCode = ReadShaderFile(it->second.path.c_str());
  if (shaderCode.empty()) {
    LOG_ERROR("ReloadPostShader: Failed to read shader file '%s'",
              it->second.path.c_str());
    return false;
  }

  // Compile new shaders
  SDL_GPUShaderCreateInfo vertInfo = {};
  vertInfo.code = (const Uint8 *)MSL_POST_VERTEX;
  vertInfo.code_size = strlen(MSL_POST_VERTEX);
  vertInfo.entrypoint = "post_vertex";
  vertInfo.format = SDL_GPU_SHADERFORMAT_MSL;
  vertInfo.stage = SDL_GPU_SHADERSTAGE_VERTEX;
  SDL_GPUShader *vertShader = SDL_CreateGPUShader(m_Device, &vertInfo);

  SDL_GPUShaderCreateInfo fragInfo = {};
  fragInfo.code = (const Uint8 *)shaderCode.c_str();
  fragInfo.code_size = shaderCode.size();
  fragInfo.entrypoint = "post_fragment";
  fragInfo.format = SDL_GPU_SHADERFORMAT_MSL;
  fragInfo.stage = SDL_GPU_SHADERSTAGE_FRAGMENT;
  fragInfo.num_samplers = 1;
  fragInfo.num_storage_buffers = 1;
  SDL_GPUShader *fragShader = SDL_CreateGPUShader(m_Device, &fragInfo);

  if (!vertShader || !fragShader) {
    LOG_ERROR("ReloadPostShader: Failed to compile shader '%s'", name);
    if (vertShader)
      SDL_ReleaseGPUShader(m_Device, vertShader);
    if (fragShader)
      SDL_ReleaseGPUShader(m_Device, fragShader);
    return false;
  }

  // Create new pipeline
  SDL_GPUGraphicsPipelineCreateInfo pipelineInfo = {};
  pipelineInfo.vertex_shader = vertShader;
  pipelineInfo.fragment_shader = fragShader;
  pipelineInfo.vertex_input_state.num_vertex_attributes = 0;
  pipelineInfo.vertex_input_state.num_vertex_buffers = 0;
  pipelineInfo.rasterizer_state.fill_mode = SDL_GPU_FILLMODE_FILL;
  pipelineInfo.rasterizer_state.front_face =
      SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;

  SDL_GPUColorTargetDescription colorTarget = {};
  colorTarget.format = SDL_GetGPUSwapchainTextureFormat(m_Device, m_Window);
  colorTarget.blend_state.enable_blend = false;

  pipelineInfo.target_info.color_target_descriptions = &colorTarget;
  pipelineInfo.target_info.num_color_targets = 1;
  pipelineInfo.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;

  SDL_GPUGraphicsPipeline *newPipeline =
      SDL_CreateGPUGraphicsPipeline(m_Device, &pipelineInfo);

  SDL_ReleaseGPUShader(m_Device, vertShader);
  SDL_ReleaseGPUShader(m_Device, fragShader);

  if (!newPipeline) {
    LOG_ERROR("ReloadPostShader: Failed to create pipeline for shader '%s'",
              name);
    return false;
  }

  // Release old pipeline
  if (it->second.pipeline) {
    SDL_ReleaseGPUGraphicsPipeline(m_Device, it->second.pipeline);
  }

  // Update with new pipeline (preserve uniforms and enabled state)
  it->second.pipeline = newPipeline;

  LOG_INFO("Reloaded shader '%s' from %s", name, it->second.path.c_str());
  return true;
}

void SpriteRenderer::CreateWhiteTexture() {
  unsigned char whitePixel[4] = {255, 255, 255, 255};
  m_WhiteTextureId = LoadTextureFromMemory(whitePixel, 1, 1);
}

int SpriteRenderer::GetWhiteTexture() {
  if (m_WhiteTextureId == -1)
    CreateWhiteTexture();
  return m_WhiteTextureId;
}
