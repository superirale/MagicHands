#include "events/EventSystem.h"
#include "core/Logger.h"
#include <algorithm>

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

// Singleton instance
EventSystem &EventSystem::Instance() {
  static EventSystem instance;
  return instance;
}

void EventSystem::Init(lua_State *L) {
  m_LuaState = L;
  m_NextSubscriptionId = 1;
  m_Subscribers.clear();
  while (!m_EventQueue.empty())
    m_EventQueue.pop();

  LOG_DEBUG("EventSystem initialized");
}

void EventSystem::Destroy() {
  // Release all Lua references
  if (m_LuaState) {
    for (auto &pair : m_Subscribers) {
      for (auto &sub : pair.second) {
        if (sub.luaCallbackRef >= 0) {
          luaL_unref(m_LuaState, LUA_REGISTRYINDEX, sub.luaCallbackRef);
        }
      }
    }
  }

  m_Subscribers.clear();
  while (!m_EventQueue.empty())
    m_EventQueue.pop();
  m_LuaState = nullptr;

  LOG_DEBUG("EventSystem destroyed");
}

int EventSystem::Subscribe(const std::string &eventType, EventCallback callback,
                           int priority, bool once) {
  Subscription sub;
  sub.id = m_NextSubscriptionId++;
  sub.eventType = eventType;
  sub.luaCallbackRef = -1; // C++ callback
  sub.cppCallback = callback;
  sub.priority = priority;
  sub.once = once;
  sub.pendingRemoval = false;

  m_Subscribers[eventType].push_back(sub);
  return sub.id;
}

int EventSystem::SubscribeLua(const std::string &eventType, int luaCallbackRef,
                              int priority, bool once) {
  Subscription sub;
  sub.id = m_NextSubscriptionId++;
  sub.eventType = eventType;
  sub.luaCallbackRef = luaCallbackRef;
  sub.cppCallback = nullptr;
  sub.priority = priority;
  sub.once = once;
  sub.pendingRemoval = false;

  m_Subscribers[eventType].push_back(sub);
  return sub.id;
}

void EventSystem::Unsubscribe(int subscriptionId) {
  for (auto &pair : m_Subscribers) {
    auto &subs = pair.second;
    for (auto &sub : subs) {
      if (sub.id == subscriptionId) {
        // Release Lua reference if exists
        if (sub.luaCallbackRef >= 0 && m_LuaState) {
          luaL_unref(m_LuaState, LUA_REGISTRYINDEX, sub.luaCallbackRef);
          sub.luaCallbackRef = -1;
        }

        if (m_IsEmitting) {
          // Mark for removal later (safe during iteration)
          sub.pendingRemoval = true;
        } else {
          // Remove immediately
          subs.erase(std::remove_if(subs.begin(), subs.end(),
                                    [subscriptionId](const Subscription &s) {
                                      return s.id == subscriptionId;
                                    }),
                     subs.end());
        }
        return;
      }
    }
  }
}

void EventSystem::CleanupRemovedSubscriptions(const std::string &eventType) {
  auto it = m_Subscribers.find(eventType);
  if (it != m_Subscribers.end()) {
    auto &subs = it->second;
    subs.erase(
        std::remove_if(subs.begin(), subs.end(),
                       [](const Subscription &s) { return s.pendingRemoval; }),
        subs.end());
  }
}

void EventSystem::Emit(const std::string &eventType) {
  EventData event(eventType);
  Emit(event);
}

void EventSystem::Emit(const EventData &event) {
  auto it = m_Subscribers.find(event.type);
  if (it == m_Subscribers.end())
    return;

  auto &subs = it->second;
  if (subs.empty())
    return;

  // Sort by priority (lower = earlier)
  std::sort(subs.begin(), subs.end(),
            [](const Subscription &a, const Subscription &b) {
              return a.priority < b.priority;
            });

  m_IsEmitting = true;

  std::vector<int> toRemove;

  for (auto &sub : subs) {
    if (sub.pendingRemoval)
      continue;

    if (sub.luaCallbackRef >= 0) {
      // Call Lua handler
      CallLuaHandler(sub.luaCallbackRef, event);
    } else if (sub.cppCallback) {
      // Call C++ handler
      sub.cppCallback(event);
    }

    if (sub.once) {
      toRemove.push_back(sub.id);
    }
  }

  m_IsEmitting = false;

  // Remove one-time subscriptions
  for (int id : toRemove) {
    Unsubscribe(id);
  }

  // Cleanup any subscriptions marked for removal during emit
  CleanupRemovedSubscriptions(event.type);
}

void EventSystem::Queue(const EventData &event) { m_EventQueue.push(event); }

void EventSystem::Flush() {
  while (!m_EventQueue.empty()) {
    EventData event = m_EventQueue.front();
    m_EventQueue.pop();
    Emit(event);
  }
}

void EventSystem::CallLuaHandler(int luaRef, const EventData &event) {
  if (!m_LuaState || luaRef < 0)
    return;

  // Get the callback function from registry
  lua_rawgeti(m_LuaState, LUA_REGISTRYINDEX, luaRef);

  if (!lua_isfunction(m_LuaState, -1)) {
    lua_pop(m_LuaState, 1);
    return;
  }

  // Push event data as Lua table
  PushEventDataToLua(event);

  // Call the function
  if (lua_pcall(m_LuaState, 1, 0, 0) != LUA_OK) {
    LOG_ERROR("Event handler error: %s", lua_tostring(m_LuaState, -1));
    lua_pop(m_LuaState, 1);
  }
}

void EventSystem::PushEventDataToLua(const EventData &event) {
  lua_newtable(m_LuaState);

  // Add event type
  lua_pushstring(m_LuaState, event.type.c_str());
  lua_setfield(m_LuaState, -2, "type");

  // Add string data
  for (const auto &pair : event.stringData) {
    lua_pushstring(m_LuaState, pair.second.c_str());
    lua_setfield(m_LuaState, -2, pair.first.c_str());
  }

  // Add float data
  for (const auto &pair : event.floatData) {
    lua_pushnumber(m_LuaState, pair.second);
    lua_setfield(m_LuaState, -2, pair.first.c_str());
  }

  // Add int data
  for (const auto &pair : event.intData) {
    lua_pushinteger(m_LuaState, pair.second);
    lua_setfield(m_LuaState, -2, pair.first.c_str());
  }

  // Add bool data
  for (const auto &pair : event.boolData) {
    lua_pushboolean(m_LuaState, pair.second);
    lua_setfield(m_LuaState, -2, pair.first.c_str());
  }
}

EventData EventSystem::PopEventDataFromLua(int tableIndex) {
  EventData event;

  if (!lua_istable(m_LuaState, tableIndex)) {
    return event;
  }

  // Iterate through table
  lua_pushnil(m_LuaState);
  while (lua_next(m_LuaState, tableIndex) != 0) {
    // Key is at -2, value is at -1
    if (lua_isstring(m_LuaState, -2)) {
      const char *key = lua_tostring(m_LuaState, -2);

      if (lua_isstring(m_LuaState, -1)) {
        event.stringData[key] = lua_tostring(m_LuaState, -1);
      } else if (lua_isboolean(m_LuaState, -1)) {
        event.boolData[key] = lua_toboolean(m_LuaState, -1);
      } else if (lua_isinteger(m_LuaState, -1)) {
        event.intData[key] = (int)lua_tointeger(m_LuaState, -1);
      } else if (lua_isnumber(m_LuaState, -1)) {
        event.floatData[key] = (float)lua_tonumber(m_LuaState, -1);
      }
    }

    lua_pop(m_LuaState, 1); // Pop value, keep key for next iteration
  }

  return event;
}

// =============================================================================
// Lua Bindings
// =============================================================================

static int Lua_EventsOn(lua_State *L) {
  const char *eventType = luaL_checkstring(L, 1);
  luaL_checktype(L, 2, LUA_TFUNCTION);

  // Get optional options table
  int priority = 0;
  bool once = false;

  if (lua_istable(L, 3)) {
    lua_getfield(L, 3, "priority");
    if (lua_isinteger(L, -1)) {
      priority = (int)lua_tointeger(L, -1);
    }
    lua_pop(L, 1);

    lua_getfield(L, 3, "once");
    if (lua_isboolean(L, -1)) {
      once = lua_toboolean(L, -1);
    }
    lua_pop(L, 1);
  }

  // Store function reference
  lua_pushvalue(L, 2);
  int luaRef = luaL_ref(L, LUA_REGISTRYINDEX);

  // Create subscription using public method
  int subId =
      EventSystem::Instance().SubscribeLua(eventType, luaRef, priority, once);

  lua_pushinteger(L, subId);
  return 1;
}

static int Lua_EventsOnce(lua_State *L) {
  const char *eventType = luaL_checkstring(L, 1);
  luaL_checktype(L, 2, LUA_TFUNCTION);

  // Get optional priority
  int priority = 0;
  if (lua_istable(L, 3)) {
    lua_getfield(L, 3, "priority");
    if (lua_isinteger(L, -1)) {
      priority = (int)lua_tointeger(L, -1);
    }
    lua_pop(L, 1);
  }

  // Store function reference
  lua_pushvalue(L, 2);
  int luaRef = luaL_ref(L, LUA_REGISTRYINDEX);

  // Create one-time subscription using public method
  int subId =
      EventSystem::Instance().SubscribeLua(eventType, luaRef, priority, true);

  lua_pushinteger(L, subId);
  return 1;
}

static int Lua_EventsOff(lua_State *L) {
  int subscriptionId = (int)luaL_checkinteger(L, 1);
  EventSystem::Instance().Unsubscribe(subscriptionId);
  return 0;
}

static int Lua_EventsEmit(lua_State *L) {
  const char *eventType = luaL_checkstring(L, 1);

  EventData event(eventType);

  // Parse optional data table
  if (lua_istable(L, 2)) {
    event = EventSystem::Instance().PopEventDataFromLua(2);
    event.type = eventType;
  }

  EventSystem::Instance().Emit(event);
  return 0;
}

static int Lua_EventsQueue(lua_State *L) {
  const char *eventType = luaL_checkstring(L, 1);

  EventData event(eventType);

  // Parse optional data table
  if (lua_istable(L, 2)) {
    event = EventSystem::Instance().PopEventDataFromLua(2);
    event.type = eventType;
  }

  EventSystem::Instance().Queue(event);
  return 0;
}

static int Lua_EventsFlush(lua_State *L) {
  EventSystem::Instance().Flush();
  return 0;
}

void EventSystem::RegisterLua(lua_State *L) {
  EventSystem::Instance().m_LuaState = L;

  lua_newtable(L);

  lua_pushcfunction(L, Lua_EventsOn);
  lua_setfield(L, -2, "on");

  lua_pushcfunction(L, Lua_EventsOnce);
  lua_setfield(L, -2, "once");

  lua_pushcfunction(L, Lua_EventsOff);
  lua_setfield(L, -2, "off");

  lua_pushcfunction(L, Lua_EventsEmit);
  lua_setfield(L, -2, "emit");

  lua_pushcfunction(L, Lua_EventsQueue);
  lua_setfield(L, -2, "queue");

  lua_pushcfunction(L, Lua_EventsFlush);
  lua_setfield(L, -2, "flush");

  lua_setglobal(L, "events");

  LOG_DEBUG("Event system Lua bindings registered");
}
