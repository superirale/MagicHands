#include "graphics/ParticleSystem.h"
#include "core/Logger.h"
#include "graphics/SpriteRenderer.h"
#include <cmath>

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

// Degrees to radians
static float DegToRad(float deg) { return deg * 3.14159265f / 180.0f; }

// Linear interpolation
static float Lerp(float a, float b, float t) { return a + (b - a) * t; }

ParticleSystem::ParticleSystem()
    : m_Renderer(nullptr), m_NextEmitterId(1), m_DefaultTextureId(0),
      m_Rng(std::random_device{}()), m_Dist01(0.0f, 1.0f) {}

ParticleSystem::~ParticleSystem() {
  // Cleanup handled in Destroy()
}

void ParticleSystem::Init(SpriteRenderer *renderer) {
  m_Renderer = renderer;

  // Create a default 4x4 white texture for simple colored particles
  unsigned char whitePixels[4 * 4 * 4];
  memset(whitePixels, 255, sizeof(whitePixels)); // All white, full alpha
  m_DefaultTextureId = m_Renderer->LoadTextureFromMemory(whitePixels, 4, 4);

  LOG_DEBUG("ParticleSystem initialized (default texture ID: %d)",
            m_DefaultTextureId);
}

void ParticleSystem::Destroy() {
  m_Emitters.clear();
  LOG_DEBUG("ParticleSystem destroyed");
}

int ParticleSystem::CreateEmitter(const EmitterConfig &config) {
  int id = m_NextEmitterId++;

  Emitter emitter;
  emitter.config = config;
  emitter.particles.resize(config.maxParticles);
  emitter.spawnAccumulator = 0;

  // Initialize all particles as inactive
  for (auto &p : emitter.particles) {
    p.active = false;
  }

  m_Emitters[id] = std::move(emitter);

  LOG_DEBUG("Created particle emitter %d (max particles: %d)", id,
            config.maxParticles);
  return id;
}

void ParticleSystem::SetEmitterPosition(int id, float x, float y) {
  auto it = m_Emitters.find(id);
  if (it != m_Emitters.end()) {
    it->second.config.x = x;
    it->second.config.y = y;
  }
}

void ParticleSystem::SetEmitterEnabled(int id, bool enabled) {
  auto it = m_Emitters.find(id);
  if (it != m_Emitters.end()) {
    it->second.config.enabled = enabled;
  }
}

void ParticleSystem::DestroyEmitter(int id) {
  auto it = m_Emitters.find(id);
  if (it != m_Emitters.end()) {
    m_Emitters.erase(it);
    LOG_DEBUG("Destroyed particle emitter %d", id);
  }
}

EmitterConfig *ParticleSystem::GetEmitterConfig(int id) {
  auto it = m_Emitters.find(id);
  if (it != m_Emitters.end()) {
    return &it->second.config;
  }
  return nullptr;
}

void ParticleSystem::Burst(int id, int count) {
  auto it = m_Emitters.find(id);
  if (it == m_Emitters.end())
    return;

  Emitter &emitter = it->second;
  for (int i = 0; i < count; ++i) {
    SpawnParticle(emitter);
  }
}

void ParticleSystem::SpawnParticle(Emitter &emitter) {
  const EmitterConfig &config = emitter.config;

  // Find an inactive particle in the pool
  Particle *p = nullptr;
  for (auto &particle : emitter.particles) {
    if (!particle.active) {
      p = &particle;
      break;
    }
  }

  if (!p)
    return; // Pool exhausted

  // Initialize particle
  p->active = true;

  // Random position within spawn area
  float offsetX = (m_Dist01(m_Rng) - 0.5f) * config.width;
  float offsetY = (m_Dist01(m_Rng) - 0.5f) * config.height;
  p->x = config.x + offsetX;
  p->y = config.y + offsetY;

  // Random velocity within direction cone
  float speed = Lerp(config.minSpeed, config.maxSpeed, m_Dist01(m_Rng));
  float angle = config.direction + (m_Dist01(m_Rng) - 0.5f) * config.spread;
  float rad = DegToRad(angle);
  p->vx = cos(rad) * speed;
  p->vy = -sin(rad) * speed; // Negative because Y increases downward

  // Lifetime
  p->life = Lerp(config.minLife, config.maxLife, m_Dist01(m_Rng));
  p->maxLife = p->life;

  // Size with variation
  float sizeVar = (m_Dist01(m_Rng) - 0.5f) * 2.0f * config.sizeVariation;
  p->startSize = config.startSize + sizeVar;
  p->endSize = config.endSize + sizeVar;
  p->size = p->startSize;

  // Color
  p->startR = config.r;
  p->startG = config.g;
  p->startB = config.b;
  p->startA = config.a;
  p->endR = config.endR;
  p->endG = config.endG;
  p->endB = config.endB;
  p->endA = config.endA;
  p->r = p->startR;
  p->g = p->startG;
  p->b = p->startB;
  p->a = p->startA;

  // Rotation (optional)
  p->rotation = 0;
  p->rotationSpeed = 0;
}

void ParticleSystem::UpdateParticle(Particle &p, const EmitterConfig &config,
                                    float dt) {
  // Apply acceleration
  p.vx += config.gravityX * dt;
  p.vy += config.gravityY * dt;

  // Update position
  p.x += p.vx * dt;
  p.y += p.vy * dt;

  // Update lifetime
  p.life -= dt;

  if (p.life <= 0) {
    p.active = false;
    return;
  }

  // Calculate lifetime progress (0 = just spawned, 1 = about to die)
  float progress = 1.0f - (p.life / p.maxLife);

  // Interpolate size
  p.size = Lerp(p.startSize, p.endSize, progress);

  // Interpolate color
  if (config.colorInterpolation) {
    p.r = Lerp(p.startR, p.endR, progress);
    p.g = Lerp(p.startG, p.endG, progress);
    p.b = Lerp(p.startB, p.endB, progress);
    p.a = Lerp(p.startA, p.endA, progress);
  }

  // Update rotation
  p.rotation += p.rotationSpeed * dt;
}

void ParticleSystem::Update(float dt) {
  for (auto &pair : m_Emitters) {
    Emitter &emitter = pair.second;
    const EmitterConfig &config = emitter.config;

    // Spawn new particles if enabled
    if (config.enabled && config.spawnRate > 0) {
      emitter.spawnAccumulator += config.spawnRate * dt;

      while (emitter.spawnAccumulator >= 1.0f) {
        SpawnParticle(emitter);
        emitter.spawnAccumulator -= 1.0f;
      }
    }

    // Update existing particles
    for (auto &p : emitter.particles) {
      if (p.active) {
        UpdateParticle(p, config, dt);
      }
    }
  }
}

void ParticleSystem::Draw() {
  if (!m_Renderer)
    return;

  for (auto &pair : m_Emitters) {
    Emitter &emitter = pair.second;
    const EmitterConfig &config = emitter.config;

    int textureId =
        config.textureId > 0 ? config.textureId : m_DefaultTextureId;

    for (const auto &p : emitter.particles) {
      if (!p.active)
        continue;

      // Draw particle as a colored quad
      float halfSize = p.size * 0.5f;
      float drawX = p.x - halfSize;
      float drawY = p.y - halfSize;

      // Use particle color as tint
      Color tint(p.r, p.g, p.b, p.a);

      // DrawSprite signature: (textureId, x, y, w, h, rotation, flipX, flipY,
      // tint, screenSpace)
      m_Renderer->DrawSprite(textureId, drawX, drawY, p.size, p.size,
                             p.rotation, false, false, tint,
                             config.screenSpace);
    }
  }
}

// =============================================================================
// Lua Bindings
// =============================================================================

static ParticleSystem *g_ParticleSystem = nullptr;

static int Lua_CreateEmitter(lua_State *L) {
  if (!g_ParticleSystem || !lua_istable(L, 1)) {
    lua_pushinteger(L, 0);
    return 1;
  }

  EmitterConfig config;

  // Helper lambda to read optional float from table
  auto getFloat = [L](const char *key, float defaultVal) -> float {
    lua_getfield(L, 1, key);
    float val = lua_isnumber(L, -1) ? (float)lua_tonumber(L, -1) : defaultVal;
    lua_pop(L, 1);
    return val;
  };

  // Helper lambda to read optional int from table
  auto getInt = [L](const char *key, int defaultVal) -> int {
    lua_getfield(L, 1, key);
    int val = lua_isinteger(L, -1) ? (int)lua_tointeger(L, -1) : defaultVal;
    lua_pop(L, 1);
    return val;
  };

  // Helper lambda to read optional bool from table
  auto getBool = [L](const char *key, bool defaultVal) -> bool {
    lua_getfield(L, 1, key);
    bool val = lua_isboolean(L, -1) ? lua_toboolean(L, -1) : defaultVal;
    lua_pop(L, 1);
    return val;
  };

  // Read all config values
  config.spawnRate = getFloat("spawnRate", 100.0f);
  config.maxParticles = getInt("maxParticles", 500);

  config.x = getFloat("x", 0);
  config.y = getFloat("y", 0);
  config.width = getFloat("width", 0);
  config.height = getFloat("height", 0);
  config.worldSpace = getBool("worldSpace", true);
  config.screenSpace = getBool("screenSpace", false);

  config.minSpeed = getFloat("minSpeed", 50.0f);
  config.maxSpeed = getFloat("maxSpeed", 100.0f);
  config.direction = getFloat("direction", 90.0f);
  config.spread = getFloat("spread", 30.0f);

  config.gravityX = getFloat("gravityX", 0);
  config.gravityY = getFloat("gravityY", 0);

  config.minLife = getFloat("minLife", 1.0f);
  config.maxLife = getFloat("maxLife", 2.0f);

  config.startSize = getFloat("startSize", 4.0f);
  config.endSize = getFloat("endSize", 4.0f);
  config.sizeVariation = getFloat("sizeVariation", 0);

  config.r = getFloat("r", 1.0f);
  config.g = getFloat("g", 1.0f);
  config.b = getFloat("b", 1.0f);
  config.a = getFloat("a", 1.0f);
  config.endR = getFloat("endR", config.r);
  config.endG = getFloat("endG", config.g);
  config.endB = getFloat("endB", config.b);
  config.endA = getFloat("endA", 0.0f);
  config.colorInterpolation = getBool("colorInterpolation", true);

  config.textureId = getInt("textureId", 0);
  config.enabled = getBool("enabled", true);

  int id = g_ParticleSystem->CreateEmitter(config);
  lua_pushinteger(L, id);
  return 1;
}

static int Lua_SetEmitterPosition(lua_State *L) {
  if (!g_ParticleSystem)
    return 0;

  int id = (int)luaL_checkinteger(L, 1);
  float x = (float)luaL_checknumber(L, 2);
  float y = (float)luaL_checknumber(L, 3);

  g_ParticleSystem->SetEmitterPosition(id, x, y);
  return 0;
}

static int Lua_SetEmitterEnabled(lua_State *L) {
  if (!g_ParticleSystem)
    return 0;

  int id = (int)luaL_checkinteger(L, 1);
  bool enabled = lua_toboolean(L, 2);

  g_ParticleSystem->SetEmitterEnabled(id, enabled);
  return 0;
}

static int Lua_DestroyEmitter(lua_State *L) {
  if (!g_ParticleSystem)
    return 0;

  int id = (int)luaL_checkinteger(L, 1);
  g_ParticleSystem->DestroyEmitter(id);
  return 0;
}

static int Lua_SetEmitterProperty(lua_State *L) {
  if (!g_ParticleSystem)
    return 0;

  int id = (int)luaL_checkinteger(L, 1);
  const char *prop = luaL_checkstring(L, 2);

  EmitterConfig *config = g_ParticleSystem->GetEmitterConfig(id);
  if (!config)
    return 0;

  // Handle different property types
  if (strcmp(prop, "spawnRate") == 0) {
    config->spawnRate = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "direction") == 0) {
    config->direction = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "spread") == 0) {
    config->spread = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "minSpeed") == 0) {
    config->minSpeed = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "maxSpeed") == 0) {
    config->maxSpeed = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "gravityX") == 0) {
    config->gravityX = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "gravityY") == 0) {
    config->gravityY = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "startSize") == 0) {
    config->startSize = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "endSize") == 0) {
    config->endSize = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "r") == 0) {
    config->r = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "g") == 0) {
    config->g = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "b") == 0) {
    config->b = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "a") == 0) {
    config->a = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "screenSpace") == 0) {
    config->screenSpace = lua_toboolean(L, 3);
  } else if (strcmp(prop, "width") == 0) {
    config->width = (float)luaL_checknumber(L, 3);
  } else if (strcmp(prop, "height") == 0) {
    config->height = (float)luaL_checknumber(L, 3);
  }

  return 0;
}

static int Lua_Burst(lua_State *L) {
  if (!g_ParticleSystem)
    return 0;

  int id = (int)luaL_checkinteger(L, 1);
  int count = (int)luaL_checkinteger(L, 2);

  g_ParticleSystem->Burst(id, count);
  return 0;
}

static int Lua_UpdateParticles(lua_State *L) {
  if (!g_ParticleSystem)
    return 0;

  float dt = (float)luaL_checknumber(L, 1);
  g_ParticleSystem->Update(dt);
  return 0;
}

static int Lua_DrawParticles(lua_State *L) {
  if (!g_ParticleSystem)
    return 0;

  g_ParticleSystem->Draw();
  return 0;
}

void ParticleSystem::RegisterLua(lua_State *L, ParticleSystem *system) {
  g_ParticleSystem = system;

  lua_newtable(L);

  lua_pushcfunction(L, Lua_CreateEmitter);
  lua_setfield(L, -2, "createEmitter");

  lua_pushcfunction(L, Lua_SetEmitterPosition);
  lua_setfield(L, -2, "setPosition");

  lua_pushcfunction(L, Lua_SetEmitterEnabled);
  lua_setfield(L, -2, "setEnabled");

  lua_pushcfunction(L, Lua_DestroyEmitter);
  lua_setfield(L, -2, "destroy");

  lua_pushcfunction(L, Lua_SetEmitterProperty);
  lua_setfield(L, -2, "setProperty");

  lua_pushcfunction(L, Lua_Burst);
  lua_setfield(L, -2, "burst");

  lua_pushcfunction(L, Lua_UpdateParticles);
  lua_setfield(L, -2, "update");

  lua_pushcfunction(L, Lua_DrawParticles);
  lua_setfield(L, -2, "draw");

  lua_setglobal(L, "particles");

  LOG_DEBUG("Particle system Lua bindings registered");
}
