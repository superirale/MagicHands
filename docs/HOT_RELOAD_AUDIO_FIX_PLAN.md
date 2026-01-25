# Hot Reload Audio Fix - Implementation Plan

## Problem Statement

When Lua scripts are hot-reloaded (F5 key), audio events that were triggered before the reload continue playing. This creates issues:
- Music from the previous scene continues playing after reload
- Sound effects persist even though the game state has been reset
- Multiple instances of the same audio can overlap if reload is triggered multiple times

## Root Cause Analysis

### Current Hot Reload Flow (main.cpp:134-173)

1. **F5 Key Pressed** → Hot reload triggered
2. **Shader Reload** → `ReloadAllShaders()` called
3. **Lua State Cleared** → `package.loaded` table cleared
4. **Scripts Reloaded** → `main.lua` re-executed
5. **⚠️ Audio NOT Stopped** → Orpheus AudioManager continues playing all active sounds

### Why Audio Persists

The Orpheus `AudioManager` is a **C++ singleton** (`AudioSystem::s_Engine`) that persists across Lua reloads. When Lua scripts are cleared:
- Lua script state is reset ✅
- C++ audio engine keeps running ❌
- Active voices/handles remain playing ❌

## Solution Options

### Option 1: Stop All Audio on Hot Reload (Recommended)

**Approach**: Add a `StopAllAudio()` method and call it during hot reload.

**Pros**:
- Clean slate - matches expected behavior
- Simple to implement
- No audio overlap issues
- Lua scripts can restart music naturally

**Cons**:
- Brief silence during reload
- Music/ambience needs to restart

**Implementation Complexity**: Low

---

### Option 2: Track Active Audio Handles in Lua

**Approach**: Store audio handles in Lua tables and stop them before reload.

**Pros**:
- Lua-controlled cleanup
- No C++ changes needed

**Cons**:
- Requires refactoring all `audio.playEvent()` calls
- Easy to miss cleanup in some scripts
- More brittle - relies on developers remembering to track handles

**Implementation Complexity**: High

---

### Option 3: Audio State Serialization

**Approach**: Save active audio state before reload, restore after.

**Pros**:
- Seamless audio continuity
- No interruption to music/ambience

**Cons**:
- Very complex implementation
- Requires Orpheus API extensions
- May not preserve exact playback position
- Overkill for development hot-reload feature

**Implementation Complexity**: Very High

---

## Recommended Solution: Option 1 - Stop All Audio

This is the cleanest solution that balances simplicity with effectiveness.

## Implementation Plan

### Phase 1: Add StopAllAudio API to AudioSystem

**Files to Modify**:
- `src/audio/AudioSystem.h`
- `src/audio/AudioSystem.cpp`

**Changes**:

#### 1.1 Add Method Declaration (AudioSystem.h)

```cpp
class AudioSystem {
public:
  // ... existing methods ...
  
  // Hot reload support - stops all playing audio
  static void StopAllAudio();
  
  // Lua binding
  static int Lua_StopAllAudio(lua_State* L);
  
  // ... rest of class ...
};
```

#### 1.2 Implement StopAllAudio (AudioSystem.cpp)

```cpp
void AudioSystem::StopAllAudio() {
  if (s_Engine) {
    // Orpheus uses SoLoud internally which has stopAll()
    // Access via pImpl->engine.stopAll() if exposed
    // Otherwise, we need to stop all voices via VoicePool
    
    LOG_INFO("Stopping all audio for hot reload");
    
    // Option A: If Orpheus exposes StopAll()
    s_Engine->StopAll();
    
    // Option B: If not exposed, stop via voice pool
    // (requires Orpheus API extension - see Phase 2)
  }
}

int AudioSystem::Lua_StopAllAudio(lua_State* L) {
  StopAllAudio();
  return 0;
}

void AudioSystem::RegisterLua(lua_State* L) {
  lua_newtable(L);

  lua_pushcfunction(L, Lua_PlayEvent);
  lua_setfield(L, -2, "playEvent");

  lua_pushcfunction(L, Lua_LoadBank);
  lua_setfield(L, -2, "loadBank");
  
  lua_pushcfunction(L, Lua_StopAllAudio);
  lua_setfield(L, -2, "stopAll");  // NEW

  lua_setglobal(L, "audio");
}
```

### Phase 2: Add StopAll to Orpheus AudioManager (if needed)

**Note**: Check if Orpheus already exposes `stopAll()`. If not, add it.

**Files to Modify**:
- `external/Orpheus/include/AudioManager.h`
- `external/Orpheus/src/AudioManager.cpp`

**Changes**:

#### 2.1 Add Method Declaration (AudioManager.h)

```cpp
namespace Orpheus {

class AudioManager {
public:
  // ... existing methods ...
  
  /**
   * @brief Stop all currently playing audio.
   * 
   * Stops all active voices and resets the voice pool.
   * Useful for scene transitions or hot reloading.
   */
  void StopAll();
  
  // ... rest of class ...
};

} // namespace Orpheus
```

#### 2.2 Implement StopAll (AudioManager.cpp)

```cpp
void AudioManager::StopAll() {
  ORPHEUS_DEBUG("Stopping all audio");
  
  // SoLoud has a stopAll() method
  pImpl->engine.stopAll();
  
  // Also clear the voice pool to reset tracking
  pImpl->voicePool.StopAll();
  
  ORPHEUS_DEBUG("All audio stopped");
}
```

#### 2.3 Add StopAll to VoicePool (if needed)

**File**: `external/Orpheus/include/VoicePool.h`

```cpp
class VoicePool {
public:
  // ... existing methods ...
  
  /// Stop all active voices
  void StopAll();
  
  // ... rest of class ...
};
```

**File**: `external/Orpheus/src/VoicePool.cpp`

```cpp
void VoicePool::StopAll() {
  for (auto& voice : m_voices) {
    if (voice.state == VoiceState::Real) {
      m_stopCallback(voice.handle);
      voice.state = VoiceState::Stopped;
    } else if (voice.state == VoiceState::Virtual) {
      voice.state = VoiceState::Stopped;
    }
  }
  
  // Clear active voices
  m_realCount = 0;
  m_virtualCount = 0;
}
```

### Phase 3: Call StopAllAudio During Hot Reload

**File to Modify**: `src/core/main.cpp`

**Changes**:

```cpp
if (Engine::Instance().Input().IsKeyPressed(SDL_SCANCODE_F5)) {
  LOG_INFO("=== HOT RELOAD (F5) ===");

  // 0. Stop all audio FIRST (NEW)
  LOG_INFO("Stopping all audio...");
  AudioSystem::StopAllAudio();

  // 1. Reload all shaders
  LOG_INFO("Reloading shaders...");
  lua_getglobal(L, "ReloadAllShaders");
  if (lua_isfunction(L, -1)) {
    lua_pcall(L, 0, 0, 0);
  } else {
    LOG_WARN("ReloadAllShaders function not found");
    lua_pop(L, 1);
  }

  // 2. Reload all Lua scripts
  LOG_INFO("Reloading scripts...");

  // Clear package.loaded to force require() to reload all modules
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "loaded");
  lua_pushnil(L);
  while (lua_next(L, -2)) {
    lua_pop(L, 1);        // Pop value
    lua_pushvalue(L, -1); // Duplicate key
    lua_pushnil(L);       // Set to nil
    lua_settable(L, -4);  // package.loaded[key] = nil
  }
  lua_pop(L, 2); // Pop loaded and package

  // Now reload main.lua (will reload all require'd modules)
  int result = luaL_dofile(L, "content/scripts/main.lua");
  if (result != LUA_OK) {
    LOG_ERROR("Script reload error: %s", lua_tostring(L, -1));
    lua_pop(L, 1);
  } else {
    LOG_INFO("Hot reload complete!");
  }
}
```

### Phase 4: Optional Lua-Level Cleanup Hook

**Approach**: Allow Lua scripts to register cleanup callbacks before reload.

**File**: Create `content/scripts/HotReloadHooks.lua`

```lua
-- Hot Reload Hooks System
HotReloadHooks = {}

local cleanupCallbacks = {}

function HotReloadHooks.registerCleanup(callback)
    table.insert(cleanupCallbacks, callback)
end

function HotReloadHooks.runCleanup()
    LOG_INFO("Running Lua cleanup hooks before reload...")
    for _, callback in ipairs(cleanupCallbacks) do
        pcall(callback) -- Safe call in case of errors
    end
    cleanupCallbacks = {}
end

return HotReloadHooks
```

**Usage in GameScene.lua**:

```lua
function GameScene:enter()
    -- ... existing code ...
    
    -- Register cleanup for this scene
    HotReloadHooks.registerCleanup(function()
        LOG_INFO("Cleaning up GameScene before reload")
        -- Any scene-specific cleanup can go here
    end)
end
```

**Call in main.cpp**:

```cpp
// Before clearing package.loaded
lua_getglobal(L, "HotReloadHooks");
if (lua_istable(L, -1)) {
    lua_getfield(L, -1, "runCleanup");
    if (lua_isfunction(L, -1)) {
        lua_pcall(L, 0, 0, 0);
    } else {
        lua_pop(L, 1);
    }
}
lua_pop(L, 1); // Pop HotReloadHooks
```

## Testing Plan

### Test Cases

1. **Basic Music Stop**
   - Start game, play music
   - Press F5
   - Verify music stops
   - Verify music restarts if scene init calls `audio.playEvent()`

2. **Multiple Audio Sources**
   - Trigger multiple sound effects
   - Press F5 mid-playback
   - Verify all sounds stop

3. **Rapid Reload**
   - Press F5 multiple times quickly
   - Verify no audio overlap or crashes

4. **Scene Music Transition**
   - Play music in GameScene
   - Press F5
   - Verify new scene can start different music cleanly

5. **Edge Case: No Audio Playing**
   - Start game without audio
   - Press F5
   - Verify no crashes or errors

### Expected Results

- ✅ All audio stops immediately on F5
- ✅ No audio overlap after reload
- ✅ Lua scripts can restart music/sounds naturally
- ✅ No crashes or memory leaks
- ✅ Clean console output: "Stopping all audio for hot reload"

## Implementation Checklist

- [ ] **Phase 1**: Add `AudioSystem::StopAllAudio()` method
- [ ] **Phase 1**: Add Lua binding `audio.stopAll()`
- [ ] **Phase 2**: Check if Orpheus has `StopAll()` (inspect SoLoud wrapper)
- [ ] **Phase 2**: If not, add `AudioManager::StopAll()` to Orpheus
- [ ] **Phase 2**: Add `VoicePool::StopAll()` if needed
- [ ] **Phase 3**: Call `StopAllAudio()` in hot reload (main.cpp)
- [ ] **Phase 4** (Optional): Implement Lua cleanup hooks
- [ ] **Testing**: Run all test cases
- [ ] **Documentation**: Update API docs with `audio.stopAll()`

## Alternative Quick Fix (Temporary)

If Orpheus modifications are complex, a temporary solution:

```cpp
// In main.cpp hot reload section
LOG_INFO("Stopping audio (temporary solution)...");

// Destroy and reinitialize audio system
AudioSystem::Destroy();
AudioSystem::Init();

// Reload audio banks
lua_getglobal(L, "ReloadAudioBanks");
if (lua_isfunction(L, -1)) {
    lua_pcall(L, 0, 0, 0);
} else {
    lua_pop(L, 1);
}
```

**Pros**: Works immediately without Orpheus changes  
**Cons**: Heavy-handed, loses all audio configuration

## Timeline Estimate

- **Phase 1**: 30 minutes (C++ AudioSystem changes)
- **Phase 2**: 1-2 hours (Orpheus integration, if needed)
- **Phase 3**: 15 minutes (main.cpp integration)
- **Phase 4**: 30 minutes (optional Lua hooks)
- **Testing**: 30 minutes

**Total**: ~2.5 - 3.5 hours

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Orpheus doesn't expose StopAll | High | Use SoLoud's stopAll() directly via pImpl |
| Audio pops/clicks on stop | Medium | Add short fade-out (10-50ms) |
| Music doesn't restart | Low | Ensure scenes call `audio.playEvent()` in enter() |
| Hot reload performance hit | Low | StopAll is very fast (~1ms) |

## Future Enhancements

1. **Fade Out on Reload**: Add 100ms fade before stopping
2. **Audio State Snapshot**: Save/restore music position (advanced)
3. **Selective Stop**: Stop only SFX, keep music (config option)
4. **Hot Reload Sound**: Play subtle "whoosh" SFX on successful reload

---

**Status**: Ready for Implementation  
**Assigned**: [Agent/Developer]  
**Priority**: High (Quality of Life improvement)  
**Version Target**: Next release
