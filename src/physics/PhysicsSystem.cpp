#include "physics/PhysicsSystem.h"
#include <iostream>

// Helper to access the singleton instance (for Lua wrapper cleanliness)
// In a real engine, we might pass userdata, but static singleton is easier for
// this scale.
static PhysicsSystem *s_Physics = nullptr;

PhysicsSystem::PhysicsSystem() : m_WorldId(b2_nullWorldId) { s_Physics = this; }

PhysicsSystem::~PhysicsSystem() {
  Destroy();
  s_Physics = nullptr;
}

void PhysicsSystem::Init() {
  b2WorldDef worldDef = b2DefaultWorldDef();
  worldDef.gravity = (b2Vec2){
      0.0f, 0.0f}; // No gravity for top-down view (Stardew Valley style)
  m_WorldId = b2CreateWorld(&worldDef);
}

void PhysicsSystem::Update(float dt) {
  if (b2World_IsValid(m_WorldId)) {
    b2World_Step(m_WorldId, dt, 4);
  }
}

void PhysicsSystem::Destroy() {
  if (b2World_IsValid(m_WorldId)) {
    b2DestroyWorld(m_WorldId);
    m_WorldId = b2_nullWorldId;
  }
}

b2BodyId PhysicsSystem::CreateBody(float x, float y, bool dynamic,
                                   bool isSensor, float width, float height) {
  b2BodyDef bodyDef = b2DefaultBodyDef();
  bodyDef.type = dynamic ? b2_dynamicBody : b2_staticBody;
  bodyDef.position = (b2Vec2){x, y};
  bodyDef.fixedRotation = true;
  bodyDef.linearDamping =
      10.0f; // Add damping for top-down movement (prevents sliding)

  b2BodyId bodyId = b2CreateBody(m_WorldId, &bodyDef);

  // Create box shape (dimensions are half-extents for b2MakeBox)
  b2Polygon dynamicBox = b2MakeBox(width * 0.5f, height * 0.5f);
  b2ShapeDef shapeDef = b2DefaultShapeDef();
  shapeDef.density = 0.01f;
  shapeDef.friction = 0.3f;
  shapeDef.isSensor = isSensor;
  b2CreatePolygonShape(bodyId, &shapeDef, &dynamicBox);

  return bodyId;
}

b2Vec2 PhysicsSystem::GetPosition(b2BodyId bodyId) {
  return b2Body_GetPosition(bodyId);
}

void PhysicsSystem::SetPosition(b2BodyId bodyId, float x, float y) {
  b2Rot rotation = b2Body_GetRotation(bodyId);
  b2Body_SetTransform(bodyId, (b2Vec2){x, y}, rotation);
}

void PhysicsSystem::ApplyForce(b2BodyId bodyId, float fx, float fy) {
  b2Body_ApplyForceToCenter(bodyId, (b2Vec2){fx, fy}, true);
}

void PhysicsSystem::SetVelocity(b2BodyId bodyId, float vx, float vy) {
  b2Body_SetLinearVelocity(bodyId, (b2Vec2){vx, vy});
}

// --- Lua Bindings ---

int PhysicsSystem::Lua_CreateBody(lua_State *L) {
  float x = (float)luaL_checknumber(L, 1);
  float y = (float)luaL_checknumber(L, 2);
  bool dynamic = lua_toboolean(L, 3);
  bool isSensor = lua_toboolean(
      L, 4); // param 4: isSensor (optional, defaults false if nil)
  float width = (float)luaL_optnumber(L, 5, 64.0f); // param 5: width (optional)
  float height =
      (float)luaL_optnumber(L, 6, 64.0f); // param 6: height (optional)

  b2BodyId id = s_Physics->CreateBody(x, y, dynamic, isSensor, width, height);

  // Pack ID into a light userdata or just two integers?
  // Box2D v3 uses {index1, world0, revision} struct.
  // We can't just pass an int.
  // For simplicity, let's allocate a full userdata.

  b2BodyId *udata = (b2BodyId *)lua_newuserdata(L, sizeof(b2BodyId));
  *udata = id;

  return 1;
}

int PhysicsSystem::Lua_GetPosition(lua_State *L) {
  b2BodyId *id = (b2BodyId *)lua_touserdata(L, 1);
  b2Vec2 pos = s_Physics->GetPosition(*id);
  lua_pushnumber(L, pos.x);
  lua_pushnumber(L, pos.y);
  return 2;
}

int PhysicsSystem::Lua_SetPosition(lua_State *L) {
  b2BodyId *id = (b2BodyId *)lua_touserdata(L, 1);
  float x = (float)luaL_checknumber(L, 2);
  float y = (float)luaL_checknumber(L, 3);
  s_Physics->SetPosition(*id, x, y);
  return 0;
}

int PhysicsSystem::Lua_ApplyForce(lua_State *L) {
  b2BodyId *id = (b2BodyId *)lua_touserdata(L, 1);
  float fx = (float)luaL_checknumber(L, 2);
  float fy = (float)luaL_checknumber(L, 3);
  s_Physics->ApplyForce(*id, fx, fy);
  return 0;
}

int PhysicsSystem::Lua_SetVelocity(lua_State *L) {
  b2BodyId *id = (b2BodyId *)lua_touserdata(L, 1);
  float vx = (float)luaL_checknumber(L, 2);
  float vy = (float)luaL_checknumber(L, 3);
  s_Physics->SetVelocity(*id, vx, vy);
  return 0;
}

void PhysicsSystem::RegisterLua(lua_State *L) {
  lua_newtable(L);
  lua_pushcfunction(L, Lua_CreateBody);
  lua_setfield(L, -2, "createBody");
  lua_pushcfunction(L, Lua_GetPosition);
  lua_setfield(L, -2, "getPosition");
  lua_pushcfunction(L, Lua_SetPosition);
  lua_setfield(L, -2, "setPosition");
  lua_pushcfunction(L, Lua_ApplyForce);
  lua_setfield(L, -2, "applyForce");
  lua_pushcfunction(L, Lua_SetVelocity);
  lua_setfield(L, -2, "setVelocity");
  lua_setglobal(L, "physics");
}
