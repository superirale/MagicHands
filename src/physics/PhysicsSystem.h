#pragma once

#include <box2d/box2d.h>
#include <vector>

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

class PhysicsSystem {
public:
  PhysicsSystem();
  ~PhysicsSystem();

  void Init();
  void Update(float dt);
  void Destroy();

  // Box2D Interface
  b2BodyId CreateBody(float x, float y, bool dynamic, bool isSensor = false,
                      float width = 64.0f, float height = 64.0f);
  b2Vec2 GetPosition(b2BodyId bodyId);
  void SetPosition(b2BodyId bodyId, float x, float y);
  void ApplyForce(b2BodyId bodyId, float fx, float fy);
  void SetVelocity(b2BodyId bodyId, float vx, float vy);

  // Lua Registry
  static int Lua_CreateBody(lua_State *L);
  static int Lua_GetPosition(lua_State *L);
  static int Lua_SetPosition(lua_State *L);
  static int Lua_ApplyForce(lua_State *L);
  static int Lua_SetVelocity(lua_State *L);

  void RegisterLua(lua_State *L);

private:
  b2WorldId m_WorldId;
};
