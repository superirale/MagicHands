#ifndef ASSET_TYPES_H
#define ASSET_TYPES_H

#include "AssetError.h"
#include <SDL3/SDL.h>
#include <SDL3/SDL_gpu.h>
#include <iostream>
#include <memory>
#include <stb_image.h>
#include <string>

// Forward declaration
class AssetManager;

// Texture class with stb_image loading (same as SpriteRenderer uses)
class Texture {
public:
  virtual ~Texture() { cleanup(); }

  // Get the raw pixel data
  unsigned char *getData() const { return data; }

  // Get the GPU texture (if uploaded)
  SDL_GPUTexture *getGPUTexture() const { return gpuTexture; }

  // Get texture properties
  int getWidth() const { return width; }
  int getHeight() const { return height; }
  int getChannels() const { return channels; }

  // Public member for backward compatibility
  SDL_GPUTexture *gpuTexture;

  // Constructor is public for std::make_shared, but should only be called by
  // AssetManager DO NOT use directly - use AssetManager::load<Texture>()
  // instead
  explicit Texture(const std::string &path)
      : gpuTexture(nullptr), data(nullptr), width(0), height(0), channels(0) {
    // Use stb_image to load (consistent with SpriteRenderer)
    data = stbi_load(path.c_str(), &width, &height, &channels,
                     4); // force 4 channels (RGBA)
    if (!data) {
      throw FileNotFoundException("Failed to load image: " +
                                      std::string(stbi_failure_reason()),
                                  path, "Texture");
    }

    std::cout << "Loaded texture: " << path << " (" << width << "x" << height
              << ")" << std::endl;
  }

  void cleanup() {
    if (data) {
      stbi_image_free(data);
      data = nullptr;
    }
    // Note: gpuTexture should be destroyed by the GPU device that created it
    // We don't own it directly, so we just null it out
    gpuTexture = nullptr;
  }

  unsigned char *data;
  int width;
  int height;
  int channels;
};

// Note: Audio is handled by the Orpheus library, not the AssetManager
// The Audio class has been removed to avoid SDL_mixer dependency

// Shader class with SDL3 IOStream loading
class Shader {
public:
  virtual ~Shader() = default;

  // Get shader source
  const std::string &getSource() const { return source; }

  // Get shader path
  const std::string &getPath() const { return path; }

  bool isValid() const { return !source.empty(); }

  // Constructor is public for std::make_shared, but should only be called by
  // AssetManager DO NOT use directly - use AssetManager::load<Shader>() instead
  explicit Shader(const std::string &filePath) : path(filePath) {
    // Use SDL3 IOStream for file loading
    SDL_IOStream *io = SDL_IOFromFile(filePath.c_str(), "rb");
    if (!io) {
      throw FileNotFoundException("Could not open shader file: " +
                                      std::string(SDL_GetError()),
                                  filePath, "Shader");
    }

    // Get file size
    Sint64 fileSize = SDL_GetIOSize(io);
    if (fileSize < 0) {
      SDL_CloseIO(io);
      throw InvalidDataException("Failed to get file size: " +
                                     std::string(SDL_GetError()),
                                 filePath, "Shader");
    }

    // Read shader source
    source.resize(static_cast<size_t>(fileSize));
    Sint64 bytesRead =
        SDL_ReadIO(io, source.data(), static_cast<size_t>(fileSize));
    SDL_CloseIO(io);

    if (bytesRead != fileSize) {
      throw InvalidDataException("Failed to read complete file: " +
                                     std::string(SDL_GetError()),
                                 filePath, "Shader");
    }

    std::cout << "Loaded shader: " << filePath << " (" << source.size()
              << " bytes)" << std::endl;
  }

  std::string path;
  std::string source;
};

// TileMapAsset class - wrapper for TileMap to integrate with AssetManager
class TileMap; // Forward declaration

class TileMapAsset {
public:
  virtual ~TileMapAsset() = default;

  // Get the underlying TileMap
  TileMap *getTileMap() const { return tileMap.get(); }
  std::shared_ptr<TileMap> getSharedTileMap() const { return tileMap; }

  // Get asset path
  const std::string &getPath() const { return path; }

  bool isValid() const { return tileMap != nullptr; }

  // Constructor - loads TileMap from path
  explicit TileMapAsset(const std::string &filePath);

  std::string path;
  std::shared_ptr<TileMap> tileMap;
};

#endif // ASSET_TYPES_H
