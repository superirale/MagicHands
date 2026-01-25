#pragma once

#include <SDL3/SDL.h>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

struct SDLWindowDeleter {
  void operator()(SDL_Window *window) const {
    if (window) {
      SDL_DestroyWindow(window);
    }
  }
};

using SDLWindowPtr = std::unique_ptr<SDL_Window, SDLWindowDeleter>;

class SDLManager {
public:
  static SDLManager &getInstance();

  bool initialize();
  void shutdown();
  bool isInitialized() const { return m_initialized; }

  ~SDLManager();

private:
  SDLManager();
  SDLManager(const SDLManager &) = delete;
  SDLManager &operator=(const SDLManager &) = delete;

  bool m_initialized = false;
  std::mutex m_mutex;
  uint32_t m_refCount = 0;
};

enum class WindowMode { Windowed, Fullscreen, BorderlessFullscreen };

enum class DeviceOrientation {
  Portrait,
  LandscapeRight,
  LandscapeLeft,
  PortraitUpsideDown,
  Unknown
};

enum class CursorType {
  Arrow,
  Hand,
  Crosshair,
  TextInput,
  Wait,
  SizeNS,
  SizeEW,
  SizeNWSE,
  SizeSWNE,
  Move,
  NotAllowed,
  Custom
};

enum class WindowManagerError {
  Success = 0,
  SDLInitFailed,
  WindowCreationFailed,
  WindowNotInitialized,
  InvalidParameter,
  AlreadyInitialized,
  NoMonitorFound,
  InvalidMonitorIndex
};

struct Monitor {
  SDL_DisplayID id;
  std::string name;
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
  int32_t usableX;
  int32_t usableY;
  int32_t usableWidth;
  int32_t usableHeight;
  float dpiScale;
  float refreshRate;
  bool isPrimary;

  Monitor()
      : id(0), x(0), y(0), width(0), height(0), usableX(0), usableY(0),
        usableWidth(0), usableHeight(0), dpiScale(1.0f), refreshRate(60.0f),
        isPrimary(false) {}

  void print() const {
    printf("Monitor %u: %s (%dx%d at %d,%d) Scale: %.2f Refresh: %.1f Hz %s\n",
           (unsigned int)id, name.c_str(), width, height, x, y, dpiScale,
           refreshRate, isPrimary ? "[Primary]" : "");
  }
};

struct WindowConfig {
  uint32_t width = 1920;
  uint32_t height = 1080;
  WindowMode mode = WindowMode::Windowed;
  std::string title = "Game Window";
  bool vsync = true;
  float aspectRatioLocked = 0.0f;
  uint32_t minWidth = 800;
  uint32_t minHeight = 600;

  bool validate() const {
    if (width < 100 || height < 100) {
      return false;
    }
    if (title.empty()) {
      return false;
    }
    if (minWidth > width || minHeight > height) {
      return false;
    }
    if (aspectRatioLocked > 0.0f && aspectRatioLocked < 0.1f) {
      return false;
    }
    return true;
  }
};

struct WindowState {
  uint32_t width;
  uint32_t height;
  WindowMode mode;
  DeviceOrientation orientation;
  bool isFocused;
  bool isMinimized;
  float aspectRatio;
};

using ResizeCallback =
    std::function<void(uint32_t newWidth, uint32_t newHeight)>;
using OrientationCallback =
    std::function<void(DeviceOrientation newOrientation)>;
using FocusCallback = std::function<void(bool focused)>;
using ModeChangeCallback = std::function<void(WindowMode newMode)>;
using DPIChangeCallback = std::function<void(float newDPIScale)>;

using CallbackHandle = uint64_t;

class WindowManager {
public:
  static constexpr uint32_t DEFAULT_MAX_WIDTH = 7680;
  static constexpr uint32_t DEFAULT_MAX_HEIGHT = 4320;
  static constexpr float DEFAULT_REFRESH_RATE = 60.0f;

  static WindowManager &getInstance();

  bool initialize(const WindowConfig &config);
  void shutdown();
  bool isInitialized() const { return m_isInitialized; }
  WindowManagerError getLastError() const { return m_lastError; }
  std::string getErrorString(WindowManagerError error) const;
  std::string getErrorDetails() const;

  // Lua bindings
  static void RegisterLua(struct lua_State *L);

  void logError(WindowManagerError error, const std::string &context = "");

  bool validateConfig(const WindowConfig &config) const;

  bool createWindow(const WindowConfig &config);
  void destroyWindow();
  void updateWindow();
  bool shouldClose() const { return m_shouldClose; }

  void setSize(uint32_t width, uint32_t height);
  void setWidth(uint32_t width);
  void setHeight(uint32_t height);
  uint32_t getWidth() const { return m_state.width; }
  uint32_t getHeight() const { return m_state.height; }
  float getAspectRatio() const { return m_state.aspectRatio; }

  std::vector<Monitor> getMonitors() const;
  const Monitor &getPrimaryMonitor() const;
  std::optional<Monitor> getCurrentMonitor() const;
  bool setMonitor(size_t monitorIndex);
  bool setMonitor(const Monitor &monitor);
  size_t getMonitorCount() const;
  void printMonitors() const;
  float getDPIScale() const;

  uint32_t getScaledWidth() const;
  uint32_t getScaledHeight() const;
  float getUIScaleFactor() const;
  uint32_t getLogicalWidth() const;
  uint32_t getLogicalHeight() const;
  uint32_t scaleToPhysical(uint32_t logicalSize) const;
  uint32_t scaleToLogical(uint32_t physicalSize) const;
  bool hasDPIChanged() const { return m_dpiChanged; }
  void clearDPIChangeFlag() { m_dpiChanged = false; }

  void setWindowMode(WindowMode mode);
  WindowMode getWindowMode() const { return m_state.mode; }
  void toggleFullscreen();

  void setAspectRatioLocked(float aspectRatio);
  void unlockAspectRatio();
  void setMinimumSize(uint32_t minWidth, uint32_t minHeight);
  void setMaximumSize(uint32_t maxWidth, uint32_t maxHeight);

  void setSupportedOrientations(bool portrait, bool landscape);
  void setLockedOrientation(DeviceOrientation orientation);
  void unlockOrientation();
  DeviceOrientation getCurrentOrientation() const {
    return m_state.orientation;
  }
  bool isPortrait() const;
  bool isLandscape() const;

  void centerOnMonitor(size_t monitorIndex = 0);
  void setPosition(int32_t x, int32_t y);
  void getPosition(int32_t &x, int32_t &y) const;

  void setCursorVisible(bool visible);
  bool isCursorVisible() const { return m_cursorVisible; }
  void setCursorType(CursorType type);
  CursorType getCurrentCursorType() const { return m_currentCursorType; }
  bool loadCustomCursor(const std::string &imagePath, uint32_t hotspotX = 0,
                        uint32_t hotspotY = 0);
  void releaseCustomCursor();
  std::string getCursorTypeName(CursorType type) const;

  void setTitle(const std::string &title);
  bool isFocused() const { return m_state.isFocused; }
  bool isMinimized() const { return m_state.isMinimized; }

  void setVSync(bool enabled);
  bool isVSyncEnabled() const { return m_config.vsync; }
  void setFrameRateLimit(uint32_t maxFPS);
  uint32_t getFrameRateLimit() const { return m_frameRateLimit; }
  void setAdaptiveVSync(bool enabled);
  bool isAdaptiveVSyncEnabled() const { return m_adaptiveVSync; }
  float getCurrentFrameTime() const { return m_frameTime; }
  float getCurrentFPS() const { return m_currentFPS; }
  uint64_t getFrameCount() const { return m_frameCount; }
  void updateFrameTiming();
  void limitFrameRate();

  const WindowState &getState() const { return m_state; }

  CallbackHandle subscribeToResizeEvents(ResizeCallback callback);
  CallbackHandle subscribeToOrientationEvents(OrientationCallback callback);
  CallbackHandle subscribeToFocusEvents(FocusCallback callback);
  CallbackHandle subscribeToPCModeChangeEvents(ModeChangeCallback callback);
  CallbackHandle subscribeToDPIChangeEvents(DPIChangeCallback callback);

  void unsubscribeFromResizeEvents(CallbackHandle handle);
  void unsubscribeFromOrientationEvents(CallbackHandle handle);
  void unsubscribeFromFocusEvents(CallbackHandle handle);
  void unsubscribeFromModeChangeEvents(CallbackHandle handle);
  void unsubscribeFromDPIChangeEvents(CallbackHandle handle);
  void unsubscribeAll();

  SDL_Window *getNativeWindowHandle() const { return m_nativeHandle.get(); }

  WindowManager();
  ~WindowManager();

  // Delete copy/move
  WindowManager(const WindowManager &) = delete;
  WindowManager &operator=(const WindowManager &) = delete;

protected:
  // WindowManager(); // Moved to public
  // ~WindowManager(); // Moved to public

private:
  void updateAspectRatio();
  void enforceConstraints(uint32_t &width, uint32_t &height);
  void fireResizeCallbacks(uint32_t width, uint32_t height);
  void fireOrientationCallbacks(DeviceOrientation orientation);
  void fireFocusCallbacks(bool focused);
  void fireModeChangeCallbacks(WindowMode mode);
  void fireDPIChangeCallbacks(float dpiScale);

  bool createWindowImpl(const WindowConfig &config);
  void destroyWindowImpl();
  void updateWindowImpl();
  void setFullscreenImpl(bool fullscreen);
  void setWindowSizeImpl(uint32_t width, uint32_t height);

  void queryMonitors();
  int32_t getCurrentMonitorIndex() const;
  void checkDPIChange();

  void initializeCursors();
  void cleanupCursors();

  WindowState m_state;
  WindowConfig m_config;
  bool m_isInitialized = false;
  bool m_shouldClose = false;
  SDLWindowPtr m_nativeHandle;
  WindowManagerError m_lastError = WindowManagerError::Success;

  uint32_t m_maxWidth = DEFAULT_MAX_WIDTH;
  uint32_t m_maxHeight = DEFAULT_MAX_HEIGHT;
  float m_defaultRefreshRate = DEFAULT_REFRESH_RATE;

  bool m_supportsPortrait = true;
  bool m_supportsLandscape = true;
  DeviceOrientation m_lockedOrientation = DeviceOrientation::Unknown;

  mutable std::mutex m_stateMutex;
  mutable std::mutex m_callbacksMutex;
  mutable std::mutex m_monitorMutex;
  mutable std::mutex m_errorMutex;
  uint64_t m_nextCallbackHandle = 0;

  mutable std::vector<Monitor> m_cachedMonitors;
  mutable size_t m_currentMonitorIndex = 0;

  mutable float m_lastDPIScale = 1.0f;
  mutable bool m_dpiChanged = false;

  bool m_cursorVisible = true;
  CursorType m_currentCursorType = CursorType::Arrow;
  std::map<CursorType, SDL_Cursor *> m_cursors;
  SDL_Cursor *m_defaultCursors[11]; // Array for fast access to system cursors
  SDL_Cursor *m_customCursor = nullptr;
  mutable std::mutex m_cursorMutex;

  uint32_t m_frameRateLimit = 0;
  bool m_adaptiveVSync = false;
  float m_frameTime = 0.0f;
  float m_currentFPS = 0.0f;
  uint64_t m_frameCount = 0;
  uint64_t m_lastFrameTime = 0;
  float m_fpsUpdateTime = 0.0f;
  std::map<CallbackHandle, ResizeCallback> m_resizeCallbacks;
  std::map<CallbackHandle, OrientationCallback> m_orientationCallbacks;
  std::map<CallbackHandle, FocusCallback> m_focusCallbacks;
  std::map<CallbackHandle, ModeChangeCallback> m_modeChangeCallbacks;
  std::map<CallbackHandle, DPIChangeCallback> m_dpiChangeCallbacks;

  std::string m_errorDetails;
};
