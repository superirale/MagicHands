#pragma once

#include <SDL3/SDL.h>
#include <vector>
#include <map>
#include <random>

// Forward declarations
class SpriteRenderer;
struct lua_State;

// Individual particle state
struct Particle {
    float x, y;           // Position
    float vx, vy;         // Velocity
    float life;           // Remaining lifetime (seconds)
    float maxLife;        // Initial lifetime
    float size;           // Current size
    float startSize, endSize;
    float r, g, b, a;     // Current color
    float startR, startG, startB, startA;
    float endR, endG, endB, endA;
    float rotation;       // Rotation angle
    float rotationSpeed;
    bool active;
};

// Emitter configuration - can be modified at runtime
struct EmitterConfig {
    // Spawn properties
    float spawnRate;      // Particles per second
    int maxParticles;     // Pool size
    
    // Position & area
    float x, y;           // Emitter center
    float width, height;  // Spawn area (0 = point emitter)
    bool worldSpace;      // true = particles stay in world, false = follow emitter
    bool screenSpace;     // Render in screen space (for UI effects)
    
    // Velocity
    float minSpeed, maxSpeed;
    float direction;      // Angle in degrees (0 = right, 90 = up, 180 = left, 270 = down)
    float spread;         // Cone spread in degrees
    
    // Acceleration
    float gravityX, gravityY;
    
    // Lifetime
    float minLife, maxLife;
    
    // Size
    float startSize, endSize;
    float sizeVariation;  // ±variation
    
    // Color (RGBA 0-1)
    float r, g, b, a;
    float endR, endG, endB, endA;
    bool colorInterpolation;  // Interpolate color over lifetime
    
    // Texture (0 for default white texture)
    int textureId;
    
    // Enabled state
    bool enabled;
    
    // Default constructor with sensible defaults
    EmitterConfig() 
        : spawnRate(100.0f), maxParticles(500)
        , x(0), y(0), width(0), height(0)
        , worldSpace(true), screenSpace(false)
        , minSpeed(50.0f), maxSpeed(100.0f)
        , direction(90.0f), spread(30.0f)
        , gravityX(0), gravityY(0)
        , minLife(1.0f), maxLife(2.0f)
        , startSize(4.0f), endSize(4.0f), sizeVariation(0)
        , r(1.0f), g(1.0f), b(1.0f), a(1.0f)
        , endR(1.0f), endG(1.0f), endB(1.0f), endA(0.0f)
        , colorInterpolation(true)
        , textureId(0)
        , enabled(true)
    {}
};

// Internal emitter state
struct Emitter {
    EmitterConfig config;
    std::vector<Particle> particles;
    float spawnAccumulator;  // Fractional particle spawning
    
    Emitter() : spawnAccumulator(0) {}
};

class ParticleSystem {
public:
    ParticleSystem();
    ~ParticleSystem();
    
    void Init(SpriteRenderer* renderer);
    void Destroy();
    
    // Emitter management
    int CreateEmitter(const EmitterConfig& config);  // Returns emitter ID
    void SetEmitterPosition(int id, float x, float y);
    void SetEmitterEnabled(int id, bool enabled);
    void DestroyEmitter(int id);
    EmitterConfig* GetEmitterConfig(int id);  // For runtime property updates
    
    // Burst spawn - spawn particles immediately
    void Burst(int id, int count);
    
    // Update and render
    void Update(float dt);
    void Draw();
    
    // Lua registration
    static void RegisterLua(lua_State* L, ParticleSystem* system);
    
private:
    void SpawnParticle(Emitter& emitter);
    void UpdateParticle(Particle& p, const EmitterConfig& config, float dt);
    
    SpriteRenderer* m_Renderer;
    std::map<int, Emitter> m_Emitters;
    int m_NextEmitterId;
    int m_DefaultTextureId;  // White 4x4 texture for colored particles
    
    // Random number generation
    std::mt19937 m_Rng;
    std::uniform_real_distribution<float> m_Dist01;  // 0.0 to 1.0
};
