#include "WindowManager.h"
#include "Engine.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <thread>

static std::mutex g_sdlManagerMutex;
static std::unique_ptr<SDLManager> g_sdlManager;

SDLManager &SDLManager::getInstance() {
  std::lock_guard<std::mutex> lock(g_sdlManagerMutex);
  if (!g_sdlManager) {
    g_sdlManager.reset(new SDLManager());
  }
  return *g_sdlManager;
}

SDLManager::SDLManager() : m_initialized(false), m_refCount(0) {}

SDLManager::~SDLManager() {
  if (m_initialized && m_refCount > 0) {
    SDL_Quit();
    m_initialized = false;
    m_refCount = 0;
  }
}

bool SDLManager::initialize() {
  std::lock_guard<std::mutex> lock(m_mutex);

  if (m_initialized && m_refCount > 0) {
    m_refCount++;
    return true;
  }

  if (SDL_WasInit(SDL_INIT_VIDEO)) {
    m_initialized = true;
    m_refCount = 1;
    return true;
  }

  if (!SDL_Init(SDL_INIT_VIDEO)) {
    return false;
  }

  m_initialized = true;
  m_refCount = 1;
  return true;
}

void SDLManager::shutdown() {
  std::lock_guard<std::mutex> lock(m_mutex);

  if (!m_initialized || m_refCount == 0) {
    return;
  }

  m_refCount--;

  if (m_refCount == 0) {
    SDL_Quit();
    m_initialized = false;
  }
}

static std::mutex g_singletonMutex;
static std::unique_ptr<WindowManager> g_instance;

WindowManager &WindowManager::getInstance() {
  std::lock_guard<std::mutex> lock(g_singletonMutex);
  if (!g_instance) {
    g_instance.reset(new WindowManager());
  }
  return *g_instance;
}

WindowManager::WindowManager() {
  m_state.width = 1920;
  m_state.height = 1080;
  m_state.mode = WindowMode::Windowed;
  m_state.orientation = DeviceOrientation::Portrait;
  m_state.isFocused = false;
  m_state.isMinimized = false;
  m_state.aspectRatio = 16.0f / 9.0f;

  for (int i = 0; i < 11; ++i) {
    m_defaultCursors[i] = nullptr;
  }
}

WindowManager::~WindowManager() {
  cleanupCursors(); // Ensure all dynamically allocated cursors are freed

  if (m_customCursor) {
    SDL_DestroyCursor(m_customCursor);
    m_customCursor = nullptr;
  }

  // Additional cleanup logic if necessary
}

bool WindowManager::initialize(const WindowConfig &config) {
  if (m_isInitialized) {
    m_lastError = WindowManagerError::AlreadyInitialized;
    return false;
  }

  if (!validateConfig(config)) {
    m_lastError = WindowManagerError::InvalidParameter;
    return false;
  }

  if (!SDLManager::getInstance().initialize()) {
    m_lastError = WindowManagerError::SDLInitFailed;
    return false;
  }

  m_config = config;

  if (!createWindow(config)) {
    m_lastError = WindowManagerError::WindowCreationFailed;
    SDLManager::getInstance().shutdown();
    return false;
  }

  m_isInitialized = true;
  m_lastError = WindowManagerError::Success;

  queryMonitors();
  centerOnMonitor(0); // Center on primary monitor

  initializeCursors();

  return true;
}

void WindowManager::shutdown() {
  if (!m_isInitialized) {
    return;
  }

  destroyWindow();
  m_isInitialized = false;
  m_resizeCallbacks.clear();
  m_orientationCallbacks.clear();
  m_focusCallbacks.clear();
  m_modeChangeCallbacks.clear();

  SDLManager::getInstance().shutdown();
}

bool WindowManager::createWindow(const WindowConfig &config) {
  m_config = config;
  m_state.width = config.width;
  m_state.height = config.height;
  m_state.mode = config.mode;

  updateAspectRatio();

  return createWindowImpl(config);
}

void WindowManager::destroyWindow() {
  destroyWindowImpl();
  m_shouldClose = false;
}

void WindowManager::updateWindow() {
  updateWindowImpl();

  checkDPIChange();
}

void WindowManager::setSize(uint32_t width, uint32_t height) {
  if (!m_isInitialized) {
    m_lastError = WindowManagerError::WindowNotInitialized;
    return;
  }

  if (width < 100 || height < 100) {
    m_lastError = WindowManagerError::InvalidParameter;
    return;
  }

  uint32_t newWidth = width;
  uint32_t newHeight = height;

  enforceConstraints(newWidth, newHeight);

  {
    std::lock_guard<std::mutex> lock(m_stateMutex);

    if (newWidth == m_state.width && newHeight == m_state.height) {
      return;
    }

    m_state.width = newWidth;
    m_state.height = newHeight;
    updateAspectRatio();
  }

  setWindowSizeImpl(newWidth, newHeight);
  fireResizeCallbacks(newWidth, newHeight);

  m_lastError = WindowManagerError::Success;
}

void WindowManager::setWidth(uint32_t width) { setSize(width, m_state.height); }

void WindowManager::setHeight(uint32_t height) {
  setSize(m_state.width, height);
}

void WindowManager::setWindowMode(WindowMode mode) {
  {
    std::lock_guard<std::mutex> lock(m_stateMutex);

    if (m_state.mode == mode) {
      return;
    }

    m_state.mode = mode;
  }

  bool fullscreen = (mode != WindowMode::Windowed);
  setFullscreenImpl(fullscreen);
  fireModeChangeCallbacks(mode);
}

void WindowManager::toggleFullscreen() {
  WindowMode newMode = (m_state.mode == WindowMode::Windowed)
                           ? WindowMode::Fullscreen
                           : WindowMode::Windowed;
  setWindowMode(newMode);
}

void WindowManager::setAspectRatioLocked(float aspectRatio) {
  if (!m_isInitialized) {
    m_lastError = WindowManagerError::WindowNotInitialized;
    return;
  }

  if (aspectRatio <= 0.0f) {
    m_lastError = WindowManagerError::InvalidParameter;
    return;
  }

  m_config.aspectRatioLocked = aspectRatio;

  uint32_t newHeight = static_cast<uint32_t>(m_state.width / aspectRatio);
  setSize(m_state.width, newHeight);

  m_lastError = WindowManagerError::Success;
}

void WindowManager::unlockAspectRatio() { m_config.aspectRatioLocked = 0.0f; }

void WindowManager::setMinimumSize(uint32_t minWidth, uint32_t minHeight) {
  m_config.minWidth = minWidth;
  m_config.minHeight = minHeight;
}

void WindowManager::setMaximumSize(uint32_t maxWidth, uint32_t maxHeight) {
  m_maxWidth = maxWidth;
  m_maxHeight = maxHeight;
}

void WindowManager::setSupportedOrientations(bool portrait, bool landscape) {
  m_supportsPortrait = portrait;
  m_supportsLandscape = landscape;
}

void WindowManager::setLockedOrientation(DeviceOrientation orientation) {
  m_lockedOrientation = orientation;
}

void WindowManager::unlockOrientation() {
  m_lockedOrientation = DeviceOrientation::Unknown;
}

bool WindowManager::isPortrait() const {
  std::lock_guard<std::mutex> lock(m_stateMutex);
  return m_state.orientation == DeviceOrientation::Portrait ||
         m_state.orientation == DeviceOrientation::PortraitUpsideDown;
}

bool WindowManager::isLandscape() const {
  std::lock_guard<std::mutex> lock(m_stateMutex);
  return m_state.orientation == DeviceOrientation::LandscapeLeft ||
         m_state.orientation == DeviceOrientation::LandscapeRight;
}

void WindowManager::setTitle(const std::string &title) {
  m_config.title = title;
}

void WindowManager::setVSync(bool enabled) { m_config.vsync = enabled; }

CallbackHandle WindowManager::subscribeToResizeEvents(ResizeCallback callback) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  CallbackHandle handle = m_nextCallbackHandle++;
  m_resizeCallbacks[handle] = callback;
  return handle;
}

CallbackHandle
WindowManager::subscribeToOrientationEvents(OrientationCallback callback) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  CallbackHandle handle = m_nextCallbackHandle++;
  m_orientationCallbacks[handle] = callback;
  return handle;
}

CallbackHandle WindowManager::subscribeToFocusEvents(FocusCallback callback) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  CallbackHandle handle = m_nextCallbackHandle++;
  m_focusCallbacks[handle] = callback;
  return handle;
}

CallbackHandle
WindowManager::subscribeToPCModeChangeEvents(ModeChangeCallback callback) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  CallbackHandle handle = m_nextCallbackHandle++;
  m_modeChangeCallbacks[handle] = callback;
  return handle;
}

CallbackHandle
WindowManager::subscribeToDPIChangeEvents(DPIChangeCallback callback) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  CallbackHandle handle = m_nextCallbackHandle++;
  m_dpiChangeCallbacks[handle] = callback;
  return handle;
}

void WindowManager::unsubscribeFromResizeEvents(CallbackHandle handle) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  m_resizeCallbacks.erase(handle);
}

void WindowManager::unsubscribeFromOrientationEvents(CallbackHandle handle) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  m_orientationCallbacks.erase(handle);
}

void WindowManager::unsubscribeFromFocusEvents(CallbackHandle handle) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  m_focusCallbacks.erase(handle);
}

void WindowManager::unsubscribeFromModeChangeEvents(CallbackHandle handle) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  m_modeChangeCallbacks.erase(handle);
}

void WindowManager::unsubscribeFromDPIChangeEvents(CallbackHandle handle) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  m_dpiChangeCallbacks.erase(handle);
}

void WindowManager::unsubscribeAll() {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  m_resizeCallbacks.clear();
  m_orientationCallbacks.clear();
  m_focusCallbacks.clear();
  m_modeChangeCallbacks.clear();
  m_dpiChangeCallbacks.clear();
}

void WindowManager::updateAspectRatio() {
  if (m_state.height > 0) {
    m_state.aspectRatio =
        static_cast<float>(m_state.width) / static_cast<float>(m_state.height);
  }
}

void WindowManager::enforceConstraints(uint32_t &width, uint32_t &height) {
  width = std::max(width, m_config.minWidth);
  height = std::max(height, m_config.minHeight);

  width = std::min(width, m_maxWidth);
  height = std::min(height, m_maxHeight);

  if (m_config.aspectRatioLocked > 0.0f) {
    uint32_t calculatedHeight =
        static_cast<uint32_t>(width / m_config.aspectRatioLocked);
    if (calculatedHeight <= m_maxHeight &&
        calculatedHeight >= m_config.minHeight) {
      height = calculatedHeight;
    } else {
      uint32_t calculatedWidth =
          static_cast<uint32_t>(height * m_config.aspectRatioLocked);
      width = calculatedWidth;
    }
  }
}

void WindowManager::fireResizeCallbacks(uint32_t width, uint32_t height) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  for (auto &pair : m_resizeCallbacks) {
    pair.second(width, height);
  }
}

void WindowManager::fireOrientationCallbacks(DeviceOrientation orientation) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  for (auto &pair : m_orientationCallbacks) {
    pair.second(orientation);
  }
}

void WindowManager::fireFocusCallbacks(bool focused) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  for (auto &pair : m_focusCallbacks) {
    pair.second(focused);
  }
}

void WindowManager::fireModeChangeCallbacks(WindowMode mode) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  for (auto &pair : m_modeChangeCallbacks) {
    pair.second(mode);
  }
}

void WindowManager::fireDPIChangeCallbacks(float dpiScale) {
  std::lock_guard<std::mutex> lock(m_callbacksMutex);
  for (auto &pair : m_dpiChangeCallbacks) {
    pair.second(dpiScale);
  }
}

bool WindowManager::createWindowImpl(const WindowConfig &config) {
  if (!SDLManager::getInstance().isInitialized()) {
    m_lastError = WindowManagerError::SDLInitFailed;
    return false;
  }

  SDL_WindowFlags flags = SDL_WINDOW_HIDDEN;

  if (config.mode == WindowMode::Fullscreen) {
    flags |= SDL_WINDOW_FULLSCREEN;
  } else if (config.mode == WindowMode::BorderlessFullscreen) {
    flags |= SDL_WINDOW_FULLSCREEN;
  }

  flags |= SDL_WINDOW_RESIZABLE;

  SDL_Window *window = SDL_CreateWindow(config.title.c_str(), config.width,
                                        config.height, flags);

  if (!window) {
    m_lastError = WindowManagerError::WindowCreationFailed;
    return false;
  }

  try {
    m_nativeHandle = SDLWindowPtr(window);

    m_state.isFocused = true;
    m_state.isMinimized = false;

    SDL_ShowWindow(window);

    m_lastError = WindowManagerError::Success;

    return true;
  } catch (const std::exception &e) {
    m_lastError = WindowManagerError::WindowCreationFailed;
    SDL_DestroyWindow(window);
    return false;
  }
}

void WindowManager::destroyWindowImpl() {
  m_nativeHandle.reset(); // Explicitly release, though destructor would do this
}

void WindowManager::updateWindowImpl() {
  if (!m_nativeHandle)
    return;

  SDL_Window *window = m_nativeHandle.get(); // Get raw pointer from unique_ptr
  SDL_Event event;
  while (SDL_PollEvent(&event)) {

    switch (event.type) {
    case SDL_EVENT_WINDOW_RESIZED: {
      {
        std::lock_guard<std::mutex> lock(m_stateMutex);
        m_state.width = event.window.data1;
        m_state.height = event.window.data2;
        updateAspectRatio();
      }
      fireResizeCallbacks(event.window.data1, event.window.data2);
      break;
    }
    case SDL_EVENT_WINDOW_FOCUS_GAINED: {
      std::lock_guard<std::mutex> lock(m_stateMutex);
      m_state.isFocused = true;
    }
      fireFocusCallbacks(true);
      break;
    case SDL_EVENT_WINDOW_FOCUS_LOST: {
      std::lock_guard<std::mutex> lock(m_stateMutex);
      m_state.isFocused = false;
    }
      fireFocusCallbacks(false);
      break;
    case SDL_EVENT_WINDOW_MINIMIZED: {
      std::lock_guard<std::mutex> lock(m_stateMutex);
      m_state.isMinimized = true;
    } break;
    case SDL_EVENT_WINDOW_RESTORED: {
      std::lock_guard<std::mutex> lock(m_stateMutex);
      m_state.isMinimized = false;
    } break;
    case SDL_EVENT_WINDOW_EXPOSED:
    case SDL_EVENT_WINDOW_SHOWN: {
      // Window is being shown/exposed - ensure it's not marked as minimized
      std::lock_guard<std::mutex> lock(m_stateMutex);
      m_state.isMinimized = false;
    } break;
    case SDL_EVENT_WINDOW_CLOSE_REQUESTED: {
      std::lock_guard<std::mutex> lock(m_stateMutex);
      m_shouldClose = true;
    } break;
    case SDL_EVENT_WINDOW_OCCLUDED: {
      std::lock_guard<std::mutex> lock(m_stateMutex);
      m_state.isMinimized = true;
    } break;
    case SDL_EVENT_DISPLAY_ORIENTATION: {
      SDL_DisplayOrientation orientation =
          static_cast<SDL_DisplayOrientation>(event.display.data1);
      DeviceOrientation newOrientation = DeviceOrientation::Unknown;

      switch (orientation) {
      case SDL_ORIENTATION_PORTRAIT:
        newOrientation = DeviceOrientation::Portrait;
        break;
      case SDL_ORIENTATION_LANDSCAPE:
        newOrientation = DeviceOrientation::LandscapeLeft;
        break;
      case SDL_ORIENTATION_LANDSCAPE_FLIPPED:
        newOrientation = DeviceOrientation::LandscapeRight;
        break;
      case SDL_ORIENTATION_PORTRAIT_FLIPPED:
        newOrientation = DeviceOrientation::PortraitUpsideDown;
        break;
      default:
        break;
      }

      {
        std::lock_guard<std::mutex> lock(m_stateMutex);
        if (newOrientation != m_state.orientation) {
          if (m_lockedOrientation == DeviceOrientation::Unknown ||
              m_lockedOrientation == newOrientation) {

            m_state.orientation = newOrientation;
            fireOrientationCallbacks(newOrientation);
          }
        }
      }
      break;
    }
    case SDL_EVENT_TEXT_INPUT: {
      // Pass text input to InputSystem
      Engine::Instance().Input().OnTextInput(event.text.text);
      break;
    }
    default:
      break;
    }
  }
}

void WindowManager::setFullscreenImpl(bool fullscreen) {
  if (!m_nativeHandle)
    return;

  SDL_Window *window = m_nativeHandle.get(); // Get raw pointer from unique_ptr
  SDL_WindowFlags flags = fullscreen ? SDL_WINDOW_FULLSCREEN : 0;

  if (!SDL_SetWindowFullscreen(window, fullscreen)) {
  }
}

void WindowManager::setWindowSizeImpl(uint32_t width, uint32_t height) {
  if (!m_nativeHandle)
    return;

  SDL_Window *window = m_nativeHandle.get(); // Get raw pointer from unique_ptr

  if (!SDL_SetWindowSize(window, width, height)) {
  }
}

std::string WindowManager::getErrorString(WindowManagerError error) const {
  switch (error) {
  case WindowManagerError::Success:
    return "Success";
  case WindowManagerError::SDLInitFailed:
    return "SDL initialization failed";
  case WindowManagerError::WindowCreationFailed:
    return "Window creation failed";
  case WindowManagerError::WindowNotInitialized:
    return "Window manager not initialized";
  case WindowManagerError::InvalidParameter:
    return "Invalid parameter";
  case WindowManagerError::AlreadyInitialized:
    return "Window manager already initialized";
  case WindowManagerError::NoMonitorFound:
    return "No monitor found";
  case WindowManagerError::InvalidMonitorIndex:
    return "Invalid monitor index";
  default:
    return "Unknown error";
  }
}

bool WindowManager::validateConfig(const WindowConfig &config) const {

  if (!config.validate()) {
    return false;
  }

  return true;
}

void WindowManager::initializeCursors() {
  std::lock_guard<std::mutex> lock(m_cursorMutex);

  m_defaultCursors[static_cast<int>(CursorType::Arrow)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_DEFAULT);
  m_defaultCursors[static_cast<int>(CursorType::Hand)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_POINTER);
  m_defaultCursors[static_cast<int>(CursorType::Crosshair)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_CROSSHAIR);
  m_defaultCursors[static_cast<int>(CursorType::TextInput)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_TEXT);
  m_defaultCursors[static_cast<int>(CursorType::Wait)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_WAIT);
  m_defaultCursors[static_cast<int>(CursorType::SizeNS)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_NS_RESIZE);
  m_defaultCursors[static_cast<int>(CursorType::SizeEW)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_EW_RESIZE);
  m_defaultCursors[static_cast<int>(CursorType::SizeNWSE)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_NWSE_RESIZE);
  m_defaultCursors[static_cast<int>(CursorType::SizeSWNE)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_NESW_RESIZE);
  m_defaultCursors[static_cast<int>(CursorType::Move)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_MOVE);
  m_defaultCursors[static_cast<int>(CursorType::NotAllowed)] =
      SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_NOT_ALLOWED);

  m_currentCursorType = CursorType::Arrow;
  if (m_defaultCursors[0]) {
    SDL_SetCursor(m_defaultCursors[0]);
  }
}

void WindowManager::cleanupCursors() {
  std::lock_guard<std::mutex> lock(m_cursorMutex);

  if (m_customCursor) {
    SDL_DestroyCursor(m_customCursor);
    m_customCursor = nullptr;
  }

  for (int i = 0; i < 11; ++i) {
    if (m_defaultCursors[i]) {
      SDL_DestroyCursor(m_defaultCursors[i]);
      m_defaultCursors[i] = nullptr;
    }
  }
}

void WindowManager::setCursorVisible(bool visible) {
  if (!m_isInitialized) {
    m_lastError = WindowManagerError::WindowNotInitialized;
    return;
  }

  std::lock_guard<std::mutex> lock(m_cursorMutex);

  if (visible) {
    SDL_ShowCursor();
  } else {
    SDL_HideCursor();
  }

  m_cursorVisible = visible;
  m_lastError = WindowManagerError::Success;
}

void WindowManager::setCursorType(CursorType type) {
  if (!m_isInitialized) {
    m_lastError = WindowManagerError::WindowNotInitialized;
    return;
  }

  std::lock_guard<std::mutex> lock(m_cursorMutex);

  if (type == CursorType::Custom && !m_customCursor) {
    m_lastError = WindowManagerError::InvalidParameter;
    return;
  }

  SDL_Cursor *cursor = nullptr;

  if (type == CursorType::Custom) {
    cursor = m_customCursor;
  } else {
    int typeIndex = static_cast<int>(type);
    if (typeIndex >= 0 && typeIndex < 11 && m_defaultCursors[typeIndex]) {
      cursor = m_defaultCursors[typeIndex];
    }
  }

  if (cursor) {
    SDL_SetCursor(cursor);
    m_currentCursorType = type;
    m_lastError = WindowManagerError::Success;
  } else {
    m_lastError = WindowManagerError::InvalidParameter;
  }
}

bool WindowManager::loadCustomCursor(const std::string &imagePath,
                                     uint32_t hotspotX, uint32_t hotspotY) {
  if (!m_isInitialized) {
    m_lastError = WindowManagerError::WindowNotInitialized;
    return false;
  }

  std::lock_guard<std::mutex> lock(m_cursorMutex);

  if (m_customCursor) {
    SDL_DestroyCursor(m_customCursor);
    m_customCursor = nullptr;
  }

  SDL_Surface *surface = SDL_LoadBMP(imagePath.c_str());
  if (!surface) {
    m_lastError = WindowManagerError::InvalidParameter;
    return false;
  }

  m_customCursor = SDL_CreateColorCursor(surface, hotspotX, hotspotY);
  SDL_DestroySurface(surface);

  if (!m_customCursor) {
    m_lastError = WindowManagerError::InvalidParameter;
    return false;
  }

  m_lastError = WindowManagerError::Success;

  return true;
}

void WindowManager::releaseCustomCursor() {
  std::lock_guard<std::mutex> lock(m_cursorMutex);

  if (m_customCursor) {
    SDL_DestroyCursor(m_customCursor);
    m_customCursor = nullptr;

    if (m_defaultCursors[0]) {
      SDL_SetCursor(m_defaultCursors[0]);
    }
    m_currentCursorType = CursorType::Arrow;
  }
}

std::string WindowManager::getCursorTypeName(CursorType type) const {
  switch (type) {
  case CursorType::Arrow:
    return "Arrow";
  case CursorType::Hand:
    return "Hand";
  case CursorType::Crosshair:
    return "Crosshair";
  case CursorType::TextInput:
    return "TextInput";
  case CursorType::Wait:
    return "Wait";
  case CursorType::SizeNS:
    return "SizeNS (Vertical Resize)";
  case CursorType::SizeEW:
    return "SizeEW (Horizontal Resize)";
  case CursorType::SizeNWSE:
    return "SizeNWSE (Diagonal Resize)";
  case CursorType::SizeSWNE:
    return "SizeSWNE (Diagonal Resize)";
  case CursorType::Move:
    return "Move";
  case CursorType::NotAllowed:
    return "NotAllowed";
  case CursorType::Custom:
    return "Custom";
  default:
    return "Unknown";
  }
}

// Redundant setVSync removed (defined inline in header or earlier)

void WindowManager::setFrameRateLimit(uint32_t maxFPS) {
  if (maxFPS == 0) {
    m_frameRateLimit = 0;
  } else if (maxFPS < 15 || maxFPS > 240) {
    m_lastError = WindowManagerError::InvalidParameter;
    return;
  } else {
    m_frameRateLimit = maxFPS;
  }

  m_lastError = WindowManagerError::Success;
}

void WindowManager::setAdaptiveVSync(bool enabled) {
  if (!m_nativeHandle) {
    m_lastError = WindowManagerError::WindowNotInitialized;
    return;
  }

  m_adaptiveVSync = enabled;

  SDL_Window *window = m_nativeHandle.get();

  // SDL_SetWindowVSync not available/reliable in SDL3 with GPU?
  // Assuming VSync is handled via Swapchain parameters or config.
  // For now, just update internal state.
  if (enabled && m_config.vsync) {
    // Logic for adaptive vsync check via SDL_GetWindowFlags?
  } else {
    m_adaptiveVSync = false;
  }

  m_lastError = WindowManagerError::Success;
}

void WindowManager::updateFrameTiming() {
  uint64_t currentTime =
      SDL_GetTicksNS() / 1000; // Convert nanoseconds to microseconds

  if (m_lastFrameTime == 0) {
    m_lastFrameTime = currentTime;
    m_frameCount = 0;
    m_currentFPS = 0.0f;
    m_frameTime = 0.0f;
    return;
  }

  uint64_t deltaTime = currentTime - m_lastFrameTime;
  m_frameTime = deltaTime / 1000.0f; // Convert to milliseconds
  m_lastFrameTime = currentTime;

  m_frameCount++;

  m_fpsUpdateTime += m_frameTime;
  if (m_fpsUpdateTime >= 500.0f) {
    float fps = (m_frameCount * 500.0f) / m_fpsUpdateTime;
    m_currentFPS = fps;
    m_fpsUpdateTime = 0.0f;
    m_frameCount = 0;
  }
}

void WindowManager::limitFrameRate() {
  if (m_frameRateLimit == 0 || m_config.vsync) {
    return; // VSync or no limit
  }

  float targetFrameTime = 1000.0f / m_frameRateLimit;

  if (m_frameTime > 0.0f && m_frameTime < targetFrameTime) {
    uint32_t sleepTime = static_cast<uint32_t>(targetFrameTime - m_frameTime);
    if (sleepTime > 0) {
      SDL_Delay(sleepTime);
    }
  }
}

void WindowManager::queryMonitors() {
  std::lock_guard<std::mutex> lock(m_monitorMutex);

  m_cachedMonitors.clear();

  int displayCount = 0;
  SDL_DisplayID *displays = SDL_GetDisplays(&displayCount);

  if (!displays || displayCount <= 0) {
    SDL_free(displays);
    return;
  }

  SDL_DisplayID primaryDisplay = SDL_GetPrimaryDisplay();

  for (int i = 0; i < displayCount; ++i) {
    Monitor monitor;
    monitor.id = displays[i];
    monitor.isPrimary = (displays[i] == primaryDisplay);

    const char *name = SDL_GetDisplayName(displays[i]);
    monitor.name = name ? name : ("Monitor " + std::to_string(i + 1));

    SDL_Rect bounds;
    if (SDL_GetDisplayBounds(displays[i], &bounds)) {
      monitor.x = bounds.x;
      monitor.y = bounds.y;
      monitor.width = bounds.w;
      monitor.height = bounds.h;
    }

    SDL_Rect usableBounds;
    if (SDL_GetDisplayUsableBounds(displays[i], &usableBounds)) {
      monitor.usableX = usableBounds.x;
      monitor.usableY = usableBounds.y;
      monitor.usableWidth = usableBounds.w;
      monitor.usableHeight = usableBounds.h;
    }

    float scale = SDL_GetDisplayContentScale(displays[i]);
    monitor.dpiScale = scale > 0.0f ? scale : 1.0f;

    const SDL_DisplayMode *mode = SDL_GetDesktopDisplayMode(displays[i]);
    float refreshRate = mode ? mode->refresh_rate : 60.0f;

    m_cachedMonitors.push_back(monitor);
  }

  SDL_free(displays);
}

std::vector<Monitor> WindowManager::getMonitors() const {
  std::lock_guard<std::mutex> lock(m_monitorMutex);

  if (m_cachedMonitors.empty()) {
    const_cast<WindowManager *>(this)->queryMonitors();
  }

  return m_cachedMonitors;
}

const Monitor &WindowManager::getPrimaryMonitor() const {
  std::lock_guard<std::mutex> lock(m_monitorMutex);

  if (m_cachedMonitors.empty()) {
    const_cast<WindowManager *>(this)->queryMonitors();
  }

  for (const auto &monitor : m_cachedMonitors) {
    if (monitor.isPrimary) {
      return monitor;
    }
  }

  static Monitor emptyMonitor;
  return emptyMonitor;
}

std::optional<Monitor> WindowManager::getCurrentMonitor() const {
  std::lock_guard<std::mutex> lock(m_monitorMutex);

  if (m_cachedMonitors.empty()) {
    const_cast<WindowManager *>(this)->queryMonitors();
  }

  if (m_currentMonitorIndex < m_cachedMonitors.size()) {
    return m_cachedMonitors[m_currentMonitorIndex];
  }

  return std::nullopt;
}

int32_t WindowManager::getCurrentMonitorIndex() const {
  if (!m_nativeHandle) {
    return 0;
  }

  SDL_Window *window = m_nativeHandle.get();
  SDL_DisplayID currentDisplay = SDL_GetDisplayForWindow(window);

  std::lock_guard<std::mutex> lock(m_monitorMutex);

  for (size_t i = 0; i < m_cachedMonitors.size(); ++i) {
    if (m_cachedMonitors[i].id == currentDisplay) {
      m_currentMonitorIndex = i;
      return i;
    }
  }

  return 0;
}

bool WindowManager::setMonitor(size_t monitorIndex) {
  if (!m_isInitialized) {
    m_lastError = WindowManagerError::WindowNotInitialized;
    return false;
  }

  std::lock_guard<std::mutex> lock(m_monitorMutex);

  if (m_cachedMonitors.empty()) {
    queryMonitors();
  }

  if (monitorIndex >= m_cachedMonitors.size()) {
    m_lastError = WindowManagerError::InvalidMonitorIndex;
    return false;
  }

  const Monitor &monitor = m_cachedMonitors[monitorIndex];
  m_currentMonitorIndex = monitorIndex;

  if (m_state.mode == WindowMode::Fullscreen) {
    SDL_Window *window = m_nativeHandle.get();
    if (!SDL_SetWindowFullscreen(window, true)) {
      return false;
    }
  }

  m_lastError = WindowManagerError::Success;
  return true;
}

bool WindowManager::setMonitor(const Monitor &monitor) {
  std::lock_guard<std::mutex> lock(m_monitorMutex);

  for (size_t i = 0; i < m_cachedMonitors.size(); ++i) {
    if (m_cachedMonitors[i].id == monitor.id) {
      return setMonitor(i);
    }
  }

  m_lastError = WindowManagerError::NoMonitorFound;
  return false;
}

size_t WindowManager::getMonitorCount() const {
  std::lock_guard<std::mutex> lock(m_monitorMutex);

  if (m_cachedMonitors.empty()) {
    const_cast<WindowManager *>(this)->queryMonitors();
  }

  return m_cachedMonitors.size();
}

void WindowManager::printMonitors() const {
  auto monitors = getMonitors();
  for (size_t i = 0; i < monitors.size(); ++i) {
    monitors[i].print();
  }
}

float WindowManager::getDPIScale() const {
  auto monitor = getCurrentMonitor();
  return monitor ? monitor->dpiScale : 1.0f;
}

void WindowManager::centerOnMonitor(size_t monitorIndex) {
  if (!m_isInitialized) {
    m_lastError = WindowManagerError::WindowNotInitialized;
    return;
  }

  std::lock_guard<std::mutex> lock(m_monitorMutex);

  if (m_cachedMonitors.empty()) {
    queryMonitors();
  }

  if (monitorIndex >= m_cachedMonitors.size()) {
    m_lastError = WindowManagerError::InvalidMonitorIndex;
    return;
  }

  const Monitor &monitor = m_cachedMonitors[monitorIndex];

  int32_t centerX =
      monitor.x + (monitor.width - static_cast<int32_t>(m_state.width)) / 2;
  int32_t centerY =
      monitor.y + (monitor.height - static_cast<int32_t>(m_state.height)) / 2;

  setPosition(centerX, centerY);

  m_lastError = WindowManagerError::Success;
}

void WindowManager::setPosition(int32_t x, int32_t y) {
  if (!m_isInitialized || !m_nativeHandle) {
    m_lastError = WindowManagerError::WindowNotInitialized;
    return;
  }

  SDL_Window *window = m_nativeHandle.get();
  SDL_SetWindowPosition(window, x, y);

  m_lastError = WindowManagerError::Success;
}

void WindowManager::getPosition(int32_t &x, int32_t &y) const {
  if (!m_nativeHandle) {
    x = 0;
    y = 0;
    return;
  }

  SDL_Window *window = m_nativeHandle.get();
  SDL_GetWindowPosition(window, &x, &y);
}

uint32_t WindowManager::getScaledWidth() const {
  return static_cast<uint32_t>(m_state.width * getDPIScale());
}

uint32_t WindowManager::getScaledHeight() const {
  return static_cast<uint32_t>(m_state.height * getDPIScale());
}

float WindowManager::getUIScaleFactor() const {
  float dpiScale = getDPIScale();
  return dpiScale;
}

uint32_t WindowManager::getLogicalWidth() const { return m_state.width; }

uint32_t WindowManager::getLogicalHeight() const { return m_state.height; }

uint32_t WindowManager::scaleToPhysical(uint32_t logicalSize) const {
  return static_cast<uint32_t>(logicalSize * getDPIScale());
}

uint32_t WindowManager::scaleToLogical(uint32_t physicalSize) const {
  float dpiScale = getDPIScale();
  if (dpiScale > 0.0f) {
    return static_cast<uint32_t>(physicalSize / dpiScale);
  }
  return physicalSize;
}

void WindowManager::checkDPIChange() {
  float currentDPI = getDPIScale();

  if (currentDPI != m_lastDPIScale) {
    m_lastDPIScale = currentDPI;
    m_dpiChanged = true;
    fireDPIChangeCallbacks(currentDPI);
  }
}
