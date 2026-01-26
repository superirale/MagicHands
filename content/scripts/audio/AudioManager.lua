-- AudioManager.lua
-- Wrapper for the C++ AudioSystem bindings

local AudioManager = {
    sounds = {},
    masterVolume = 1.0,
    initialized = false
}

function AudioManager:init()
    if not audio then
        print("Warning: Audio system not bound!")
        return
    end

    -- Preload standard sounds if we had banks, but for now we play events directly
    -- or load a bank if the engine supports it.
    -- Assuming one main sound bank or loose files for MVP

    -- Load default bank if exists
    -- audio.loadBank("content/audio/Master.bank")

    self.initialized = true
    print("AudioManager initialized")
end

-- Play a sound event by name
-- The C++ bind is likely audio.playEvent("name")
function AudioManager:play(name, pitch)
    if not self.initialized or not audio then return end

    -- Potential for logic here:
    -- - Cooldowns (dont play 100 chip sounds in 1 frame)
    -- - Pitch randomization

    audio.playEvent(name)
end

function AudioManager:setVolume(vol)
    if not self.initialized or not audio then return end
    self.masterVolume = math.max(0, math.min(1, vol))
    -- Assuming binding exists for volume control, if not we just store it
    -- audio.setMasterVolume(self.masterVolume)
end

-- Wrapped methods for specific game actions
function AudioManager:playClick()
    self:play("ui_select_sound")
end

function AudioManager:playHover()
    self:play("ui_hover_sound")
end

function AudioManager:playDeal()
    -- Placeholder: Use hover sound for now
    self:play("ui_hover_sound")
end

function AudioManager:playScore(pitch)
    -- Placeholder: Use select sound
    self:play("ui_select_sound")
end

function AudioManager:playError()
    -- No error sound yet
end

return AudioManager
