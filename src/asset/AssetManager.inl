#ifndef ASSET_MANAGER_INL
#define ASSET_MANAGER_INL

#include "AssetConfig.h"
#include <chrono>
#include <stdexcept>
#include <thread>
#include <typeindex>

// Note: compressTexture is now a member function of AssetManager (see
// AssetManager.h)

// Fallback asset management
template <typename T>
void AssetManager::setFallbackAsset(std::shared_ptr<T> fallback) {
  std::lock_guard<std::mutex> lock(assetMutex);
  std::type_index type(typeid(T));
  fallbackAssets[type] = std::static_pointer_cast<void>(fallback);
  LOG_INFO("Fallback asset set for type: %s", typeid(T).name());
}

template <typename T>
std::shared_ptr<T> AssetManager::getFallbackAsset() const {
  std::lock_guard<std::mutex> lock(assetMutex);
  std::type_index type(typeid(T));
  auto it = fallbackAssets.find(type);
  if (it != fallbackAssets.end()) {
    return std::static_pointer_cast<T>(it->second);
  }
  return nullptr;
}

template <typename T>
std::shared_ptr<T> AssetManager::load(const std::string &filePath) {
  // Cache ALL config values before acquiring any locks to prevent deadlock
  const auto &config = AssetConfig::getInstance();
  const int MAX_RETRIES = config.getMaxRetries();
  const int BASE_DELAY_MS = config.getBaseDelayMs();
  const size_t CACHE_MAX_SIZE = config.getCacheMaxSize();

  std::unique_lock<std::mutex> lock(assetMutex);
  std::type_index type(typeid(T));

  // Retry loop for transient failures
  for (int attempt = 0; attempt < MAX_RETRIES; ++attempt) {
    try {
      // State machine loop - keep trying until we get a result
      while (true) {
        // Step 1: Check if asset is already in cache (fast path)
        auto &cache = caches[type];
        auto cacheIt = cache.find(filePath);
        if (cacheIt != cache.end()) {
          updateUsageOrder(filePath, type);
          return std::static_pointer_cast<T>(cacheIt->second.asset);
        }

        // Step 2: Check if asset is currently being loaded
        auto &loading = loadingMap[type];
        auto loadingIt = loading.find(filePath);

        if (loadingIt != loading.end()) {
          auto &entry = loadingIt->second;

          switch (entry.state) {
          case LoadingState::Loading:
            // Another thread is loading this asset - wait for it
            loadingCV.wait(lock);
            // After waking up, loop back to check cache again
            continue;

          case LoadingState::Loaded:
            // Asset was loaded by another thread while we waited
            // Move it to cache and return
            {
              auto asset = std::static_pointer_cast<T>(entry.asset);
              usageOrder.push_front({filePath, type});
              cache[filePath] = {entry.asset, usageOrder.begin()};
              loading.erase(loadingIt);
              return asset;
            }

          case LoadingState::Failed:
            // Previous load attempt failed - remove error and let this thread
            // retry
            {
              std::string error = entry.errorMessage;
              loading.erase(loadingIt);
              throw std::runtime_error(error);
            }
          }
        }

        // Step 3: No one is loading this asset - we'll do it
        // Mark as "Loading" so other threads know to wait
        loading[filePath] = LoadingEntry{LoadingState::Loading, nullptr, ""};

        // Step 4: Release lock and do the heavy I/O
        lock.unlock();

        std::shared_ptr<T> asset;
        std::string errorMsg;
        bool loadSuccess = false;

        try {
          // Load asset without holding the mutex
          asset = std::make_shared<T>(filePath);

          // Apply specific post-processing if needed
          if constexpr (std::is_same_v<T, Texture>) {
            asset = compressTexture(asset);
            asset = generateMipmaps(asset);
          }

          loadSuccess = true;
        } catch (const AssetException &e) {
          // Custom exception - preserve it
          errorMsg = e.what();

          // Re-acquire lock to notify callbacks
          lock.lock();
          notifyErrorCallbacks(e);
          lock.unlock();

          // Don't retry FileNotFound errors
          if (e.getErrorCode() == AssetErrorCode::FileNotFound) {
            throw;
          }
        } catch (const std::exception &e) {
          errorMsg = e.what();
        } catch (...) {
          errorMsg = "Unknown error loading asset: " + filePath;
        }

        // Step 5: Re-acquire lock and update state
        lock.lock();

        auto &loadingEntry = loading[filePath];

        if (loadSuccess) {
          // Success - add to cache and clean up loading entry
          usageOrder.push_front({filePath, type});
          cache[filePath] = {std::static_pointer_cast<void>(asset),
                             usageOrder.begin()};

          // LRU Eviction - use cached config value
          if (usageOrder.size() > CACHE_MAX_SIZE) {
            const auto &toEvict = usageOrder.back();
            caches[toEvict.type].erase(toEvict.filePath);
            usageOrder.pop_back();
          }

          // Remove from loading map
          loading.erase(filePath);

          // Wake up any threads waiting for this asset
          loadingCV.notify_all();

          LOG_INFO("Successfully loaded asset: %s", filePath.c_str());
          return asset;
        } else {
          // Failure - mark as failed and notify waiters
          loadingEntry.state = LoadingState::Failed;
          loadingEntry.errorMessage = errorMsg;

          // Wake up waiting threads so they can see the error
          loadingCV.notify_all();

          // Throw to trigger retry logic
          throw std::runtime_error(errorMsg);
        }
      }
    } catch (const AssetException &e) {
      // Handle asset-specific exceptions based on error code
      auto &loading = loadingMap[type];
      loading[filePath] = LoadingEntry{LoadingState::Failed, nullptr, e.what()};
      loadingCV.notify_all();

      // File not found - don't retry, but try fallback
      if (e.getErrorCode() == AssetErrorCode::FileNotFound) {
        LOG_ERROR("File not found: %s", filePath.c_str());

        // Try fallback asset if enabled
        if (useFallbacks) {
          auto fallback = getFallbackAsset<T>();
          if (fallback) {
            LOG_WARN("Using fallback asset for: %s", filePath.c_str());
            return fallback;
          }
        }
        throw; // Re-throw if no fallback
      }

      // Other asset errors - still try retry logic below
      if (attempt < MAX_RETRIES - 1) {
        int delay = BASE_DELAY_MS * (1 << attempt);
        LOG_WARN("Retry attempt %d for %s after %dms", attempt + 2,
                 filePath.c_str(), delay);

        lock.unlock();
        std::this_thread::sleep_for(std::chrono::milliseconds(delay));
        lock.lock();

        // Clear failed state to allow retry
        loading.erase(filePath);
      } else {
        // Last retry failed
        LOG_ERROR("Failed to load asset after %d attempts: %s - %s",
                  MAX_RETRIES, filePath.c_str(), e.what());

        // Try fallback
        if (useFallbacks) {
          auto fallback = getFallbackAsset<T>();
          if (fallback) {
            LOG_WARN("Using fallback asset for: %s", filePath.c_str());
            return fallback;
          }
        }
        throw;
      }
    } catch (const std::exception &e) {
      if (attempt < MAX_RETRIES - 1) {
        // Retry with exponential backoff
        int delay = BASE_DELAY_MS * (1 << attempt);
        LOG_WARN("Retry attempt %d for %s after %dms", attempt + 2,
                 filePath.c_str(), delay);

        lock.unlock();
        std::this_thread::sleep_for(std::chrono::milliseconds(delay));
        lock.lock();

        // Clear failed state to allow retry
        auto &loading = loadingMap[type];
        loading.erase(filePath);
      } else {
        // Last retry failed
        LOG_ERROR("Failed to load asset after %d attempts: %s", MAX_RETRIES,
                  filePath.c_str());

        // Try fallback asset if enabled
        if (useFallbacks) {
          auto fallback = getFallbackAsset<T>();
          if (fallback) {
            LOG_WARN("Using fallback asset for: %s", filePath.c_str());
            return fallback;
          }
        }

        throw; // Re-throw final error
      }
    }
  }

  // Should never reach here
  throw std::runtime_error("Unexpected error in load()");
}

template <typename T>
std::shared_ptr<T> AssetManager::get(const std::string &filePath) const {
  std::lock_guard<std::mutex> lock(assetMutex);

  std::type_index type(typeid(T));
  auto typeIt = caches.find(type);
  if (typeIt != caches.end()) {
    auto &cache = typeIt->second;
    auto it = cache.find(filePath);
    if (it != cache.end()) {
      updateUsageOrder(filePath, type);
      return std::static_pointer_cast<T>(it->second.asset);
    }
  }

  throw std::runtime_error("Asset not found: " + filePath);
}

// Async loading - wraps synchronous load in std::async
template <typename T>
std::future<std::shared_ptr<T>>
AssetManager::loadAsync(const std::string &filePath,
                        ProgressCallback progressCallback,
                        std::shared_ptr<CancellationToken> cancellationToken) {
  return std::async(
      std::launch::async,
      [this, filePath, progressCallback,
       cancellationToken]() -> std::shared_ptr<T> {
        try {
          // Initial progress report
          if (progressCallback) {
            progressCallback(0, 100, filePath); // 0% initially
          }

          // Check for cancellation before starting
          if (cancellationToken && cancellationToken->isCancelled()) {
            throw std::runtime_error("Load cancelled: " + filePath);
          }

          // Use the synchronous load method
          auto result = load<T>(filePath);

          // Final progress report
          if (progressCallback) {
            progressCallback(100, 100, filePath); // 100% complete
          }

          return result;
        } catch (...) {
          // Report failure
          if (progressCallback) {
            progressCallback(0, 100, filePath); // Reset to 0 on failure
          }
          throw; // Re-throw to store in future
        }
      });
}

// Check if asset is already loaded (without triggering a load)
template <typename T>
bool AssetManager::isAssetReady(const std::string &filePath) const {
  std::lock_guard<std::mutex> lock(assetMutex);

  std::type_index type(typeid(T));
  auto typeIt = caches.find(type);
  if (typeIt != caches.end()) {
    auto &cache = typeIt->second;
    return cache.find(filePath) != cache.end();
  }

  return false;
}

#endif // ASSET_MANAGER_INL
