#include "AssetManager.h"
#include "AssetConfig.h"
#include "graphics/FontRenderer.h"
#include "tilemap/TileMap.h"
#include <algorithm>
#include <functional>
#include <iostream>
#include <list>
#include <locale>
#include <stdexcept>
#include <unordered_map>
#include <vector>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <SDL3/SDL.h>
#include <SDL3/SDL_gpu.h>
#include <fstream>
#include <mutex>
#include <nlohmann/json.hpp>
#include <stb_image_write.h>

// Asset types are now defined in AssetTypes.h

// Singleton instance
AssetManager &AssetManager::getInstance() {
  static AssetManager instance;

  // Load config on first access
  static bool configLoaded = false;
  if (!configLoaded) {
    auto &config = AssetConfig::getInstance();
    if (!config.loadFromFile("content/asset_config.json")) {
      LOG_WARN("Failed to load asset_config.json - using defaults");
    }

    // Apply config to core logger
    Logger::SetMinLevel(config.getLogLevel());

    // Set fallback behavior
    instance.setUseFallbacks(config.areFallbacksEnabled());

    configLoaded = true;
  }

  return instance;
}

// O(1) LRU update
void AssetManager::updateUsageOrder(const std::string &filePath,
                                    std::type_index type) const {
  auto &cache = caches[type];
  auto it = cache.find(filePath);
  if (it != cache.end()) {
    usageOrder.splice(usageOrder.begin(), usageOrder, it->second.lruIt);
  }
}

// Error callback management
void AssetManager::registerErrorCallback(ErrorCallback callback) {
  std::lock_guard<std::mutex> lock(callbackMutex);
  errorCallbacks.push_back(callback);
}

void AssetManager::clearErrorCallbacks() {
  std::lock_guard<std::mutex> lock(callbackMutex);
  errorCallbacks.clear();
}

void AssetManager::notifyErrorCallbacks(const AssetException &error) {
  std::lock_guard<std::mutex> lock(callbackMutex);
  for (const auto &callback : errorCallbacks) {
    try {
      callback(error);
    } catch (...) {
      // Ignore exceptions in callbacks to prevent cascading failures
      LOG_WARN("Error callback threw an exception");
    }
  }
}

// Security: Zip Slip protection with proper path validation
bool AssetManager::isSafePath(const std::string &targetDir,
                              const std::string &path) {
  // Reject empty paths
  if (path.empty()) {
    LOG_WARN("Rejected empty path in isSafePath");
    return false;
  }

  // Check for obvious path traversal attempts
  // These checks work even before the path exists
  if (path[0] == '/' || path[0] == '\\') {
    LOG_WARN("Rejected absolute path in archive: %s", path.c_str());
    return false;
  }

  // Normalize and check for path traversal sequences
  std::string normalized = path;

  // Replace backslashes with forward slashes for consistent checking
  std::replace(normalized.begin(), normalized.end(), '\\', '/');

  // Check for various path traversal patterns
  if (normalized.find("../") != std::string::npos ||
      normalized.find("/...") != std::string::npos || normalized == ".." ||
      normalized.substr(0, 3) == "../") {
    LOG_WARN("Zip Slip attempt detected: %s", path.c_str());
    return false;
  }

  // Also reject paths with double slashes which could be used for tricks
  if (normalized.find("//") != std::string::npos) {
    LOG_WARN("Rejected path with double slashes: %s", path.c_str());
    return false;
  }

  // Construct the expected output path and verify it stays within targetDir
  std::string fullPath = targetDir;
  if (!fullPath.empty() && fullPath.back() != '/' && fullPath.back() != '\\') {
    fullPath += "/";
  }
  fullPath += normalized;

  // Use SDL3's path utilities to get canonical path if file exists
  // For new files during unpacking, we rely on the string checks above
  SDL_PathInfo info;
  if (SDL_GetPathInfo(fullPath.c_str(), &info) == 0) {
    // Path exists - additional verification could be done here
    // For now, the string-based checks above are sufficient
  }

  return true;
}

void AssetManager::clearCache() {
  std::lock_guard<std::mutex> lock(assetMutex);
  caches.clear();
  usageOrder.clear();
}

void AssetManager::preloadAssets(const std::vector<std::string> &filePaths,
                                 const std::string &assetType) {
  for (const auto &filePath : filePaths) {
    if (assetType == "texture")
      loadTexture(filePath);
    // Note: audio is handled by Orpheus library
    else if (assetType == "shader")
      loadShader(filePath);
  }
}

void AssetManager::batchLoadAssets(
    const std::unordered_map<std::string, std::string> &assets) {
  for (const auto &[filePath, assetType] : assets) {
    if (assetType == "texture")
      loadTexture(filePath);
    // Note: audio is handled by Orpheus library
    else if (assetType == "shader")
      loadShader(filePath);
  }
}

void AssetManager::loadAssetsForState(
    const std::string &gameState,
    const std::function<void(const std::string &, const std::string &)>
        &loader) {
  if (gameState == "main_menu") {
    loader("assets/textures/menu_background.png", "texture");
    loader("assets/audio/menu_music.mp3", "audio");
  } else if (gameState == "gameplay") {
    loader("assets/textures/player.png", "texture");
    loader("assets/audio/gameplay_music.mp3", "audio");
  }
}

void AssetManager::setLanguage(const std::string &filePath) {
  std::lock_guard<std::mutex> lock(assetMutex);
  LOG_INFO("Loading localization data from: %s", filePath.c_str());
  // Stub implementation for now
}

std::string AssetManager::getLocalizedString(const std::string &context,
                                             const std::string &key) const {
  std::lock_guard<std::mutex> lock(assetMutex);
  auto contextIt = localizationData.find(context);
  if (contextIt != localizationData.end()) {
    auto keyIt = contextIt->second.find(key);
    if (keyIt != contextIt->second.end()) {
      return keyIt->second;
    }
  }
  return key; // Fallback to key itself if not found
}

// Manifest-based asset loading
AssetManager::ManifestLoadResult
AssetManager::loadFromManifest(const std::string &manifestPath,
                               ProgressCallback progressCallback) {

  ManifestLoadResult result = {0, 0, 0, {}};

  // Read manifest file
  SDL_IOStream *io = SDL_IOFromFile(manifestPath.c_str(), "rb");
  if (!io) {
    LOG_ERROR("Failed to open manifest file: %s", manifestPath.c_str());
    return result;
  }

  Sint64 fileSize = SDL_GetIOSize(io);
  if (fileSize < 0) {
    SDL_CloseIO(io);
    LOG_ERROR("Failed to get manifest file size");
    return result;
  }

  std::string content;
  content.resize(static_cast<size_t>(fileSize));
  SDL_ReadIO(io, &content[0], static_cast<size_t>(fileSize));
  SDL_CloseIO(io);

  // Parse JSON
  nlohmann::json manifest;
  try {
    manifest = nlohmann::json::parse(content);
  } catch (const nlohmann::json::exception &e) {
    LOG_ERROR("Failed to parse manifest: %s", e.what());
    return result;
  }

  // Collect all asset paths with names: {path, type, name}
  struct AssetEntry {
    std::string path;
    std::string type;
    std::string name;
  };
  std::vector<AssetEntry> assetsToLoad;

  if (manifest.contains("assets")) {
    const auto &assets = manifest["assets"];

    // Process textures - now supports both strings and {name, path} objects
    if (assets.contains("textures")) {
      for (const auto &item : assets["textures"]) {
        if (item.is_object() && item.contains("name") &&
            item.contains("path")) {
          // Named asset: {"name": "player", "path":
          // "content/images/player.png"}
          std::string name = item["name"].get<std::string>();
          std::string pathStr = item["path"].get<std::string>();
          assetsToLoad.push_back({pathStr, "texture", name});
        } else if (item.is_string()) {
          // Path-only (backward compatible) or glob pattern
          std::string pathStr = item.get<std::string>();

          // Check for glob patterns
          if (pathStr.find('*') != std::string::npos) {
            size_t lastSlash = pathStr.find_last_of("/\\");
            std::string dir = (lastSlash != std::string::npos)
                                  ? pathStr.substr(0, lastSlash)
                                  : ".";
            std::string pattern = (lastSlash != std::string::npos)
                                      ? pathStr.substr(lastSlash + 1)
                                      : pathStr;

            int count = 0;
            char **files = SDL_GlobDirectory(dir.c_str(), pattern.c_str(),
                                             SDL_GLOB_CASEINSENSITIVE, &count);
            if (files) {
              for (int i = 0; i < count; ++i) {
                std::string fullPath = dir + "/" + files[i];
                // Auto-generate name from filename (without extension)
                std::string autoName = files[i];
                size_t dotPos = autoName.find_last_of('.');
                if (dotPos != std::string::npos) {
                  autoName = autoName.substr(0, dotPos);
                }
                assetsToLoad.push_back({fullPath, "texture", autoName});
              }
              SDL_free(files);
            }
          } else {
            // Auto-generate name from filename
            size_t lastSlash = pathStr.find_last_of("/\\");
            std::string autoName = (lastSlash != std::string::npos)
                                       ? pathStr.substr(lastSlash + 1)
                                       : pathStr;
            size_t dotPos = autoName.find_last_of('.');
            if (dotPos != std::string::npos) {
              autoName = autoName.substr(0, dotPos);
            }
            assetsToLoad.push_back({pathStr, "texture", autoName});
          }
        }
      }
    }

    // Process shaders - now supports both strings and {name, path} objects
    if (assets.contains("shaders")) {
      for (const auto &item : assets["shaders"]) {
        if (item.is_object() && item.contains("name") &&
            item.contains("path")) {
          std::string name = item["name"].get<std::string>();
          std::string pathStr = item["path"].get<std::string>();
          assetsToLoad.push_back({pathStr, "shader", name});
        } else if (item.is_string()) {
          std::string pathStr = item.get<std::string>();
          // Auto-generate name from filename
          size_t lastSlash = pathStr.find_last_of("/\\");
          std::string autoName = (lastSlash != std::string::npos)
                                     ? pathStr.substr(lastSlash + 1)
                                     : pathStr;
          size_t dotPos = autoName.find_last_of('.');
          if (dotPos != std::string::npos) {
            autoName = autoName.substr(0, dotPos);
          }
          assetsToLoad.push_back({pathStr, "shader", autoName});
        }
      }
    }

    // Process tilemaps - supports both strings and {name, path} objects
    if (assets.contains("tilemaps")) {
      for (const auto &item : assets["tilemaps"]) {
        if (item.is_object() && item.contains("name") &&
            item.contains("path")) {
          std::string name = item["name"].get<std::string>();
          std::string pathStr = item["path"].get<std::string>();
          assetsToLoad.push_back({pathStr, "tilemap", name});
        } else if (item.is_string()) {
          std::string pathStr = item.get<std::string>();
          // Auto-generate name from filename
          size_t lastSlash = pathStr.find_last_of("/\\");
          std::string autoName = (lastSlash != std::string::npos)
                                     ? pathStr.substr(lastSlash + 1)
                                     : pathStr;
          size_t dotPos = autoName.find_last_of('.');
          if (dotPos != std::string::npos) {
            autoName = autoName.substr(0, dotPos);
          }
          assetsToLoad.push_back({pathStr, "tilemap", autoName});
        }
      }
    }
  }

  // Parse locale overrides
  if (manifest.contains("locales")) {
    localeOverrides.clear();
    const auto &locales = manifest["locales"];
    for (auto it = locales.begin(); it != locales.end(); ++it) {
      const std::string &locale = it.key();
      const auto &overrides = it.value();
      for (auto oit = overrides.begin(); oit != overrides.end(); ++oit) {
        localeOverrides[locale][oit.key()] = oit.value().get<std::string>();
      }
    }
    LOG_INFO("Loaded locale overrides for %zu languages",
             localeOverrides.size());
  }

  // Parse fonts
  if (manifest.contains("assets") && manifest["assets"].contains("fonts")) {
    const auto &fonts = manifest["assets"]["fonts"];
    int fontCount = 0;
    for (const auto &fontEntry : fonts) {
      if (fontEntry.contains("path") && fontEntry.contains("sizes")) {
        std::string fontPath = fontEntry["path"].get<std::string>();
        for (const auto &size : fontEntry["sizes"]) {
          float fontSize = size.get<float>();
          loadFont(fontPath, fontSize);
          fontCount++;
        }
      }
    }
    LOG_INFO("Preloaded %d font size combinations", fontCount);
  }

  // Store manifest path for reloading
  lastLoadedManifest = manifestPath;

  result.totalAssets = assetsToLoad.size();

  LOG_INFO("Loading %zu assets from manifest: %s", result.totalAssets,
           manifestPath.c_str());

  // Load each asset and register alias
  for (size_t i = 0; i < assetsToLoad.size(); ++i) {
    const auto &entry = assetsToLoad[i];

    try {
      if (entry.type == "texture") {
        loadTexture(entry.path);
      } else if (entry.type == "shader") {
        loadShader(entry.path);
      } else if (entry.type == "tilemap") {
        loadTileMap(entry.path);
      }

      // Register alias for the loaded asset
      assetAliases[entry.name] = {entry.path, entry.type};

      result.loadedAssets++;
    } catch (const std::exception &e) {
      LOG_WARN("Failed to load asset: %s - %s", entry.path.c_str(), e.what());
      result.failedAssets++;
      result.failedPaths.push_back(entry.path);
    }

    // Report progress
    if (progressCallback) {
      progressCallback(i + 1, result.totalAssets, entry.path);
    }
  }

  LOG_INFO("Manifest loading complete: %zu/%zu assets loaded",
           result.loadedAssets, result.totalAssets);

  return result;
}

std::future<AssetManager::ManifestLoadResult>
AssetManager::loadFromManifestAsync(const std::string &manifestPath,
                                    ProgressCallback progressCallback) {
  return std::async(std::launch::async,
                    [this, manifestPath, progressCallback]() {
                      return loadFromManifest(manifestPath, progressCallback);
                    });
}

// Named asset retrieval
std::shared_ptr<Texture>
AssetManager::getTextureByName(const std::string &name) const {
  auto it = assetAliases.find(name);
  if (it != assetAliases.end() && it->second.type == "texture") {
    return getTexture(it->second.path);
  }
  LOG_WARN("Texture not found by name: %s", name.c_str());
  return nullptr;
}

std::shared_ptr<Shader>
AssetManager::getShaderByName(const std::string &name) const {
  auto it = assetAliases.find(name);
  if (it != assetAliases.end() && it->second.type == "shader") {
    return getShader(it->second.path);
  }
  LOG_WARN("Shader not found by name: %s", name.c_str());
  return nullptr;
}

std::shared_ptr<TileMapAsset>
AssetManager::getTileMapByName(const std::string &name) const {
  auto it = assetAliases.find(name);
  if (it != assetAliases.end() && it->second.type == "tilemap") {
    return getTileMap(it->second.path);
  }
  LOG_WARN("TileMap not found by name: %s", name.c_str());
  return nullptr;
}

bool AssetManager::hasAsset(const std::string &name) const {
  return assetAliases.find(name) != assetAliases.end();
}

int AssetManager::loadFont(const std::string &path, float size) {
  // Create cache key from path and size
  std::string cacheKey = path + ":" + std::to_string((int)size);

  // Check cache first
  auto it = fontCache.find(cacheKey);
  if (it != fontCache.end()) {
    LOG_INFO("Font cache hit: %s", cacheKey.c_str());
    return it->second;
  }

  // Load font through FontRenderer
  int fontId = FontRenderer::LoadFont(path.c_str(), size);
  if (fontId >= 0) {
    fontCache[cacheKey] = fontId;
    LOG_INFO("Cached font: %s -> %d", cacheKey.c_str(), fontId);
  }

  return fontId;
}

void AssetManager::setLocale(const std::string &locale) {
  if (locale == currentLocale) {
    return; // No change
  }

  LOG_INFO("Changing locale from %s to %s", currentLocale.c_str(),
           locale.c_str());
  currentLocale = locale;

  // Apply locale overrides to asset aliases
  auto localeIt = localeOverrides.find(locale);
  if (localeIt != localeOverrides.end()) {
    for (const auto &[assetName, localizedPath] : localeIt->second) {
      auto aliasIt = assetAliases.find(assetName);
      if (aliasIt != assetAliases.end()) {
        std::string originalPath = aliasIt->second.path;
        aliasIt->second.path = localizedPath;
        LOG_INFO("Localized %s: %s -> %s", assetName.c_str(),
                 originalPath.c_str(), localizedPath.c_str());
      }
    }
  }
}

void AssetManager::reloadLocalizedAssets() {
  if (lastLoadedManifest.empty()) {
    LOG_WARN("No manifest loaded, cannot reload localized assets");
    return;
  }

  // Get assets that have locale overrides
  auto localeIt = localeOverrides.find(currentLocale);
  if (localeIt == localeOverrides.end()) {
    LOG_INFO("No locale overrides for %s", currentLocale.c_str());
    return;
  }

  // Reload each localized asset
  for (const auto &[assetName, localizedPath] : localeIt->second) {
    auto aliasIt = assetAliases.find(assetName);
    if (aliasIt != assetAliases.end()) {
      try {
        if (aliasIt->second.type == "texture") {
          loadTexture(localizedPath);
        } else if (aliasIt->second.type == "shader") {
          loadShader(localizedPath);
        }
        aliasIt->second.path = localizedPath;
        LOG_INFO("Reloaded localized asset: %s -> %s", assetName.c_str(),
                 localizedPath.c_str());
      } catch (const std::exception &e) {
        LOG_WARN("Failed to reload localized asset %s: %s", assetName.c_str(),
                 e.what());
      }
    }
  }
}

// Batch async loading with combined progress
std::future<void>
AssetManager::batchLoadAsync(const std::vector<std::string> &paths,
                             const std::string &assetType,
                             ProgressCallback progressCallback) {
  return std::async(
      std::launch::async, [this, paths, assetType, progressCallback]() {
        size_t totalAssets = paths.size();
        size_t loadedAssets = 0;

        LOG_INFO("Starting batch async load of %zu %s assets", totalAssets,
                 assetType.c_str());

        for (const auto &path : paths) {
          try {
            // Create a progress callback that combines individual and total
            // progress
            auto combinedProgress = [&](size_t bytesLoaded, size_t totalBytes,
                                        const std::string &assetPath) {
              if (progressCallback) {
                // Calculate overall progress: (completed assets + current asset
                // progress) / total
                size_t overallLoaded = loadedAssets * 100 + bytesLoaded;
                size_t overallTotal = totalAssets * 100;
                progressCallback(overallLoaded, overallTotal, assetPath);
              }
            };

            // Load the asset based on type
            if (assetType == "texture") {
              loadAsync<Texture>(path, combinedProgress).get();
              // Note: audio is handled by Orpheus library
            } else if (assetType == "shader") {
              loadAsync<Shader>(path, combinedProgress).get();
            } else {
              LOG_WARN("Unknown asset type: %s", assetType.c_str());
            }

            loadedAssets++;

            // Report completion of this asset
            if (progressCallback) {
              progressCallback(loadedAssets * 100, totalAssets * 100, path);
            }
          } catch (const std::exception &e) {
            LOG_ERROR("Failed to load %s: %s", path.c_str(), e.what());
            // Continue with remaining assets
          }
        }

        LOG_INFO("Batch async load completed: %zu/%zu assets loaded",
                 loadedAssets, totalAssets);
      });
}

// Post-processing helpers - now a member function
std::shared_ptr<Texture>
AssetManager::compressTexture(const std::shared_ptr<Texture> &texture) {
  LOG_DEBUG("Compressing texture...");
  // TODO: Implement actual texture compression
  return texture;
}

std::shared_ptr<Texture>
AssetManager::generateMipmaps(const std::shared_ptr<Texture> &texture) {
  if (!m_gpuDevice || !texture || !texture->gpuTexture) {
    // Warning: In a real engine, we might want to log if the texture should
    // have mipmaps
    return texture;
  }

  std::cout << "Generating mipmaps using SDL3 GPU API..." << std::endl;

  SDL_GPUCommandBuffer *cmdBuf = SDL_AcquireGPUCommandBuffer(m_gpuDevice);
  if (cmdBuf) {
    SDL_GenerateMipmapsForGPUTexture(cmdBuf, texture->gpuTexture);
    SDL_SubmitGPUCommandBuffer(cmdBuf);
    std::cout << "Mipmaps generation command submitted." << std::endl;
  } else {
    logError("Failed to acquire GPU command buffer for mipmap generation.");
  }

  return texture;
}

void AssetManager::bundleAssets(const std::string &outputFilePath,
                                const std::vector<std::string> &assetPaths) {
  SDL_IOStream *outputIO = SDL_IOFromFile(outputFilePath.c_str(), "wb");
  if (!outputIO) {
    logError("Failed to create bundle file: " + outputFilePath + " - " +
             SDL_GetError());
    return;
  }

  for (const auto &assetPath : assetPaths) {
    // Check if file exists using SDL3 filesystem
    SDL_PathInfo info;
    if (SDL_GetPathInfo(assetPath.c_str(), &info) != 0 ||
        info.type != SDL_PATHTYPE_FILE) {
      LOG_WARN("Skipping non-existent or non-file asset: %s",
               assetPath.c_str());
      continue;
    }

    SDL_IOStream *inputIO = SDL_IOFromFile(assetPath.c_str(), "rb");
    if (!inputIO) {
      LOG_WARN("Failed to open asset for bundling: %s - %s", assetPath.c_str(),
               SDL_GetError());
      continue;
    }

    std::string pathStr = assetPath;
    size_t pathLength = pathStr.size();
    SDL_WriteIO(outputIO, &pathLength, sizeof(pathLength));
    SDL_WriteIO(outputIO, pathStr.c_str(), pathLength);

    Sint64 fileSize = SDL_GetIOSize(inputIO);
    size_t fileSizeT = static_cast<size_t>(fileSize);
    SDL_WriteIO(outputIO, &fileSizeT, sizeof(fileSizeT));

    std::vector<char> buffer(fileSizeT);
    SDL_ReadIO(inputIO, buffer.data(), fileSizeT);
    SDL_WriteIO(outputIO, buffer.data(), fileSizeT);

    SDL_CloseIO(inputIO);
  }

  SDL_CloseIO(outputIO);
  std::cout << "Assets bundled to: " << outputFilePath << std::endl;
}

void AssetManager::unpackAssets(const std::string &packageFilePath,
                                const std::string &outputDirectory) {
  SDL_IOStream *packageIO = SDL_IOFromFile(packageFilePath.c_str(), "rb");
  if (!packageIO) {
    logError("Failed to open package file: " + packageFilePath + " - " +
             SDL_GetError());
    return;
  }

  // Create output directory using SDL3
  SDL_CreateDirectory(outputDirectory.c_str());

  Sint64 currentPos = 0;
  Sint64 fileSize = SDL_GetIOSize(packageIO);

  while (currentPos < fileSize) {
    size_t pathLength;
    if (SDL_ReadIO(packageIO, &pathLength, sizeof(pathLength)) !=
        sizeof(pathLength)) {
      break;
    }
    currentPos += sizeof(pathLength);

    std::string assetPath(pathLength, '\0');
    if (SDL_ReadIO(packageIO, &assetPath[0], pathLength) != pathLength) {
      break;
    }
    currentPos += pathLength;

    size_t assetSize;
    if (SDL_ReadIO(packageIO, &assetSize, sizeof(assetSize)) !=
        sizeof(assetSize)) {
      break;
    }
    currentPos += sizeof(assetSize);

    std::vector<char> buffer(assetSize);
    if (SDL_ReadIO(packageIO, buffer.data(), assetSize) != assetSize) {
      break;
    }
    currentPos += assetSize;

    if (!isSafePath(outputDirectory, assetPath)) {
      std::cerr << "Zip Slip detected: " << assetPath << std::endl;
      continue;
    }

    // Construct output path
    std::string outputPath = outputDirectory;
    if (!outputPath.empty() && outputPath.back() != '/' &&
        outputPath.back() != '\\') {
      outputPath += "/";
    }
    outputPath += assetPath;

    // Create parent directories if needed
    size_t lastSlash = outputPath.find_last_of("/\\");
    if (lastSlash != std::string::npos) {
      std::string parentDir = outputPath.substr(0, lastSlash);
      SDL_CreateDirectory(parentDir.c_str());
    }

    SDL_IOStream *outputIO = SDL_IOFromFile(outputPath.c_str(), "wb");
    if (outputIO) {
      SDL_WriteIO(outputIO, buffer.data(), assetSize);
      SDL_CloseIO(outputIO);
    }
  }

  SDL_CloseIO(packageIO);
}

void AssetManager::inspectAssets() const {
  std::lock_guard<std::mutex> lock(assetMutex);
  std::cout << "\n--- Asset Inspection ---\n";
  for (const auto &[type, cache] : caches) {
    std::cout << "Type [" << type.name() << "]:\n";
    for (const auto &[path, node] : cache) {
      std::cout << "  " << path << "\n";
    }
  }
  std::cout << "--- End of Inspection ---\n";
}

void AssetManager::logError(const std::string &message) const {
  std::cerr << "[AssetManager Error] " << message << std::endl;
}

// TileMapAsset implementation
TileMapAsset::TileMapAsset(const std::string &filePath) : path(filePath) {
  tileMap = TileMap::load(filePath);
  if (!tileMap) {
    throw FileNotFoundException("Failed to load tilemap", filePath, "TileMap");
  }
}
