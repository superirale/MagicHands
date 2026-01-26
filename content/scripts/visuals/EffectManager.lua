-- EffectManager.lua
-- High-level wrapper for Particle Effects (The Juice)

local EffectManager = {
    emitters = {},
    nextId = 1,
    shakeTime = 0,
    shakeStrength = 0
}

function EffectManager:init()
    if not particles then
        print("Warning: Particle system not bound!")
        return
    end
    print("EffectManager initialized")
end

function EffectManager:update(dt)
    if particles then
        particles.update(dt)
    end

    -- Handle Screen Shake
    if self.shakeTime > 0 then
        self.shakeTime = self.shakeTime - dt
        local x = (math.random() - 0.5) * 2 * self.shakeStrength
        local y = (math.random() - 0.5) * 2 * self.shakeStrength
        graphics.setCamera(x, y)

        if self.shakeTime <= 0 then
            graphics.setCamera(0, 0)
            self.shakeStrength = 0
        end
    end
end

function EffectManager:draw()
    if particles then
        particles.draw()
    end
end

function EffectManager:shake(strength, duration)
    self.shakeStrength = strength
    self.shakeTime = duration
end

-- =========================================================
-- Specific Effects
-- =========================================================

-- Spawn a burst of chips (e.g. on scoring)
function EffectManager:spawnChips(x, y, count)
    if not particles then return end

    local config = {
        spawnRate = 0, -- Burst only
        maxParticles = 100,
        x = x,
        y = y,
        minSpeed = 100,
        maxSpeed = 300,
        direction = 270,
        spread = 90, -- Downward
        gravityY = 800,
        minLife = 0.5,
        maxLife = 1.0,
        startSize = 12,
        endSize = 8,
        r = 1.0,
        g = 0.8,
        b = 0.2,
        a = 1.0, -- Gold
        endA = 0.0
    }

    local id = particles.createEmitter(config)
    particles.burst(id, count or 10)

    -- Auto-cleanup via timer or just let them expire and manually cleanup?
    -- For MVP, we can keep emitter or destroy it after maxLife.
    -- ParticleSystem cleans up individual particles, but Emitters persist.
    -- We should track and clean up short-lived emitters.
end

-- Spawn sparkles (e.g. card selection, joker processing)
function EffectManager:spawnSparkles(x, y, count)
    if not particles then return end

    local config = {
        spawnRate = 0,
        maxParticles = 50,
        x = x,
        y = y,
        minSpeed = 20,
        maxSpeed = 80,
        direction = 90,
        spread = 360,   -- All directions
        gravityY = -20, -- Float up slightly
        minLife = 0.5,
        maxLife = 1.5,
        startSize = 6,
        endSize = 0,
        r = 0.2,
        g = 0.8,
        b = 1.0,
        a = 1.0, -- Cyan
        endA = 0.0
    }

    local id = particles.createEmitter(config)
    particles.burst(id, count or 5)
end

-- Spawn debris (e.g. card destroyed)
function EffectManager:spawnDebris(x, y)
    if not particles then return end

    local config = {
        spawnRate = 0,
        maxParticles = 30,
        x = x,
        y = y,
        minSpeed = 50,
        maxSpeed = 200,
        direction = 90,
        spread = 360,
        gravityY = 400,
        minLife = 0.8,
        maxLife = 1.2,
        startSize = 10,
        endSize = 2,
        r = 0.8,
        g = 0.8,
        b = 0.8,
        a = 1.0, -- Grey
        endA = 0.0
    }

    local id = particles.createEmitter(config)
    particles.burst(id, 20)
end

return EffectManager
