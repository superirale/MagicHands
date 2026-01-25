#pragma once

#include <string>
#include <functional>
#include <map>
#include <vector>
#include <queue>

struct lua_State;

// Event data passed between C++ and Lua
// Supports multiple data types for flexibility
struct EventData {
    std::string type;
    std::map<std::string, std::string> stringData;
    std::map<std::string, float> floatData;
    std::map<std::string, int> intData;
    std::map<std::string, bool> boolData;
    
    // Convenience constructors
    EventData() = default;
    EventData(const std::string& eventType) : type(eventType) {}
    
    // Convenience setters (chainable)
    EventData& SetString(const std::string& key, const std::string& value) {
        stringData[key] = value;
        return *this;
    }
    
    EventData& SetFloat(const std::string& key, float value) {
        floatData[key] = value;
        return *this;
    }
    
    EventData& SetInt(const std::string& key, int value) {
        intData[key] = value;
        return *this;
    }
    
    EventData& SetBool(const std::string& key, bool value) {
        boolData[key] = value;
        return *this;
    }
};

// C++ callback type
using EventCallback = std::function<void(const EventData&)>;

// Subscription info
struct Subscription {
    int id;
    std::string eventType;
    int luaCallbackRef;      // Lua registry reference (-1 if C++ callback)
    EventCallback cppCallback;
    int priority;            // Lower = earlier execution
    bool once;               // Auto-unsubscribe after first call
    bool pendingRemoval;     // Mark for removal during iteration
};

class EventSystem {
public:
    // Singleton access
    static EventSystem& Instance();
    
    // Lifecycle
    void Init(lua_State* L);
    void Destroy();
    
    // C++ API
    int Subscribe(const std::string& eventType, EventCallback callback, 
                  int priority = 0, bool once = false);
    void Unsubscribe(int subscriptionId);
    void Emit(const EventData& event);
    void Emit(const std::string& eventType);  // Convenience overload
    void Queue(const EventData& event);       // Process next frame
    void Flush();                             // Process queued events
    
    // Lua API (called from Lua bindings)
    int SubscribeLua(const std::string& eventType, int luaCallbackRef, 
                     int priority = 0, bool once = false);
    EventData PopEventDataFromLua(int tableIndex);
    
    // Lua bindings
    static void RegisterLua(lua_State* L);
    
private:
    EventSystem() = default;
    ~EventSystem() = default;
    
    // Prevent copying
    EventSystem(const EventSystem&) = delete;
    EventSystem& operator=(const EventSystem&) = delete;
    
    void CallLuaHandler(int luaRef, const EventData& event);
    void PushEventDataToLua(const EventData& event);
    void CleanupRemovedSubscriptions(const std::string& eventType);
    
    std::map<std::string, std::vector<Subscription>> m_Subscribers;
    std::queue<EventData> m_EventQueue;
    int m_NextSubscriptionId = 1;
    lua_State* m_LuaState = nullptr;
    bool m_IsEmitting = false;  // Prevent modification during emit
};
