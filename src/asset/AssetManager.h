#ifndef ASSET_MANAGER_H
#define ASSET_MANAGER_H

#include <atomic>
#include <condition_variable>
#include <functional>
#include <future>
#include <iostream>
#include <list>
#include <memory>
#include <mutex>
#include <string>
#include <typeindex>
#include <unordered_map>
#include <vector>

#include "AssetError.h"
#include "AssetTypes.h"
#include "core/Logger.h"

class AssetManager {
public:
  static AssetManager &getInstance();

  AssetManager(const AssetManager &) = delete;
  AssetManager &operator=(const AssetManager &) = delete;

  // Generic Asset Methods (Internal/C++)
  template <typename T> std::shared_ptr<T> load(const std::string &filePath);

  template <typename T>
  std::shared_ptr<T> get(const std::string &filePath) const;

  // Lua-friendly wrappers (Exposed to scripting)
  std::shared_ptr<Texture> loadTexture(const std::string &filePath) {
    return load<Texture>(filePath);
  }
  // Note: Audio is handled by Orpheus library, not AssetManager
  std::shared_ptr<Shader> loadShader(const std::string &filePath) {
    return load<Shader>(filePath);
  }

  std::shared_ptr<Texture> getTexture(const std::string &filePath) const {
    return get<Texture>(filePath);
  }
  std::shared_ptr<Shader> getShader(const std::string &filePath) const {
    return get<Shader>(filePath);
  }

  // TileMap loading/caching
  std::shared_ptr<TileMapAsset> loadTileMap(const std::string &filePath) {
    return load<TileMapAsset>(filePath);
  }
  std::shared_ptr<TileMapAsset> getTileMap(const std::string &filePath) const {
    return get<TileMapAsset>(filePath);
  }

  // Named asset retrieval - get assets by their alias from manifest
  std::shared_ptr<Texture> getTextureByName(const std::string &name) const;
  std::shared_ptr<Shader> getShaderByName(const std::string &name) const;
  std::shared_ptr<TileMapAsset> getTileMapByName(const std::string &name) const;

  // Check if a named asset exists
  bool hasAsset(const std::string &name) const;

  // Font loading with caching (path:size -> fontId)
  int loadFont(const std::string &path, float size);

  // Internationalization (i18n) support
  void setLocale(const std::string &locale);
  const std::string &getLocale() const { return currentLocale; }
  void reloadLocalizedAssets(); // Reload assets with current locale overrides

  void preloadAssets(const std::vector<std::string> &filePaths,
                     const std::string &assetType);
  void
  batchLoadAssets(const std::unordered_map<std::string, std::string> &assets);
  void clearCache();

  void loadAssetsForState(
      const std::string &gameState,
      const std::function<void(const std::string &, const std::string &)>
          &loader);

  // Localization support
  void setLanguage(const std::string &languageCode);
  std::string getLocalizedString(const std::string &context,
                                 const std::string &key) const;

  // Error handling
  using ErrorCallback = std::function<void(const AssetException &)>;
  void registerErrorCallback(ErrorCallback callback);
  void clearErrorCallbacks();

  // Fallback assets - used when loading fails
  template <typename T> void setFallbackAsset(std::shared_ptr<T> fallback);

  template <typename T> std::shared_ptr<T> getFallbackAsset() const;

  void setUseFallbacks(bool enable) { useFallbacks = enable; }
  bool getUseFallbacks() const { return useFallbacks; }

  // Async loading with progress callbacks
  using ProgressCallback = std::function<void(
      size_t bytesLoaded, size_t totalBytes, const std::string &assetPath)>;

  // Manifest-based loading - loads all assets from a JSON manifest file
  struct ManifestLoadResult {
    size_t totalAssets;
    size_t loadedAssets;
    size_t failedAssets;
    std::vector<std::string> failedPaths;
  };

  ManifestLoadResult
  loadFromManifest(const std::string &manifestPath,
                   ProgressCallback progressCallback = nullptr);

  std::future<ManifestLoadResult>
  loadFromManifestAsync(const std::string &manifestPath,
                        ProgressCallback progressCallback = nullptr);

  struct CancellationToken {
    std::atomic<bool> cancelled{false};
    void cancel() { cancelled = true; }
    bool isCancelled() const { return cancelled; }
  };

  template <typename T>
  std::future<std::shared_ptr<T>>
  loadAsync(const std::string &filePath,
            ProgressCallback progressCallback = nullptr,
            std::shared_ptr<CancellationToken> cancellationToken = nullptr);

  // Batch async loading with combined progress
  std::future<void> batchLoadAsync(const std::vector<std::string> &paths,
                                   const std::string &assetType,
                                   ProgressCallback progressCallback = nullptr);

  // Check if async load is complete
  template <typename T> bool isAssetReady(const std::string &filePath) const;

  void bundleAssets(const std::string &outputFilePath,
                    const std::vector<std::string> &assetPaths);
  void unpackAssets(const std::string &packageFilePath,
                    const std::string &outputDirectory);

  void inspectAssets() const;
  void logError(const std::string &message) const;

  // GPU support
  void setGPUDevice(SDL_GPUDevice *device) { m_gpuDevice = device; }
  SDL_GPUDevice *getGPUDevice() const { return m_gpuDevice; }

  std::shared_ptr<Texture>
  generateMipmaps(const std::shared_ptr<Texture> &texture);

private:
  AssetManager() = default;

  struct CacheEntry {
    std::string filePath;
    std::type_index type;
  };

  struct AssetNode {
    std::shared_ptr<void> asset;
    std::list<CacheEntry>::iterator lruIt;
  };

  // Loading state for tracking in-progress loads
  enum class LoadingState {
    Loading, // Asset is currently being loaded
    Loaded,  // Asset was successfully loaded
    Failed   // Asset loading failed
  };

  struct LoadingEntry {
    LoadingState state;
    std::shared_ptr<void> asset; // Only set when state == Loaded
    std::string errorMessage;    // Only set when state == Failed
  };

  // Helper to update LRU cache - $O(1)$
  void updateUsageOrder(const std::string &filePath,
                        std::type_index type) const;

  bool isSafePath(const std::string &targetDir, const std::string &path);

  // Notify all registered error callbacks
  void notifyErrorCallbacks(const AssetException &error);

  // Post-processing helpers
  std::shared_ptr<Texture>
  compressTexture(const std::shared_ptr<Texture> &texture);

  mutable std::mutex assetMutex;
  mutable std::condition_variable loadingCV; // For notifying waiting threads

  SDL_GPUDevice *m_gpuDevice = nullptr;

  // Unified cache: type -> (path -> node)
  mutable std::unordered_map<std::type_index,
                             std::unordered_map<std::string, AssetNode>>
      caches;

  // Global LRU usage order
  mutable std::list<CacheEntry> usageOrder;

  // Track assets currently being loaded: type -> (path -> loading entry)
  mutable std::unordered_map<std::type_index,
                             std::unordered_map<std::string, LoadingEntry>>
      loadingMap;

  std::unordered_map<std::string, std::unordered_map<std::string, std::string>>
      localizationData;

  // Error handling
  std::vector<ErrorCallback> errorCallbacks;
  mutable std::mutex callbackMutex;

  // Fallback assets
  mutable std::unordered_map<std::type_index, std::shared_ptr<void>>
      fallbackAssets;
  bool useFallbacks = true; // Enable fallbacks by default

  // Asset name aliases: name -> {path, type}
  struct AssetAlias {
    std::string path;
    std::string type; // "texture", "shader", "tilemap"
  };
  std::unordered_map<std::string, AssetAlias> assetAliases;

  // Internationalization (i18n)
  std::string currentLocale = "en";
  std::string lastLoadedManifest; // For reloading localized assets
  // locale -> (asset_name -> localized_path)
  std::unordered_map<std::string, std::unordered_map<std::string, std::string>>
      localeOverrides;

  // Font cache: "path:size" -> fontId
  std::unordered_map<std::string, int> fontCache;
};

// Template implementation (must be in header or included)
#include "AssetManager.inl"

#endif // ASSET_MANAGER_H
