-- UIEvents.lua
-- Event bus for decoupled UI communication
-- Implements observer pattern for card interactions, drag/drop, and UI state changes

local UIEvents = {}

-- Event listeners registry
-- Structure: { eventName = { listenerFunc1, listenerFunc2, ... } }
UIEvents.listeners = {}

-- Event history (for debugging and replay)
UIEvents.history = {}
UIEvents.maxHistorySize = 100
UIEvents.recordHistory = false  -- Set to true for debugging

--- Subscribe to an event
--- @param eventName string Name of the event (e.g., "card:selected", "hand:played")
--- @param callback function Function to call when event fires
--- @return number listenerId ID for unsubscribing
function UIEvents.on(eventName, callback)
    if not UIEvents.listeners[eventName] then
        UIEvents.listeners[eventName] = {}
    end
    
    table.insert(UIEvents.listeners[eventName], callback)
    local listenerId = #UIEvents.listeners[eventName]
    
    return listenerId
end

--- Unsubscribe from an event
--- @param eventName string Name of the event
--- @param listenerId number ID returned from UIEvents.on()
function UIEvents.off(eventName, listenerId)
    if UIEvents.listeners[eventName] and UIEvents.listeners[eventName][listenerId] then
        UIEvents.listeners[eventName][listenerId] = nil
    end
end

--- Emit an event to all subscribers
--- @param eventName string Name of the event
--- @param data table|nil Event data (optional)
function UIEvents.emit(eventName, data)
    -- Record to history if enabled
    if UIEvents.recordHistory then
        table.insert(UIEvents.history, {
            name = eventName,
            data = data,
            timestamp = os.clock()
        })
        
        -- Limit history size
        if #UIEvents.history > UIEvents.maxHistorySize then
            table.remove(UIEvents.history, 1)
        end
    end
    
    -- Notify listeners
    if UIEvents.listeners[eventName] then
        for _, callback in pairs(UIEvents.listeners[eventName]) do
            if callback then
                local success, err = pcall(callback, data)
                if not success then
                    print("[UIEvents] Error in listener for '" .. eventName .. "': " .. tostring(err))
                end
            end
        end
    end
end

--- Clear all listeners (useful for scene transitions)
function UIEvents.clear()
    UIEvents.listeners = {}
    print("[UIEvents] All listeners cleared")
end

--- Clear listeners for a specific event
--- @param eventName string Name of the event to clear
function UIEvents.clearEvent(eventName)
    UIEvents.listeners[eventName] = nil
    print("[UIEvents] Cleared listeners for: " .. eventName)
end

--- Get event history (for debugging)
--- @return table history Array of event records
function UIEvents.getHistory()
    return UIEvents.history
end

--- Clear event history
function UIEvents.clearHistory()
    UIEvents.history = {}
end

--- Print recent events (for debugging)
--- @param count number|nil Number of recent events to print (default: 10)
function UIEvents.printHistory(count)
    count = count or 10
    print("[UIEvents] Recent Events:")
    
    local start = math.max(1, #UIEvents.history - count + 1)
    for i = start, #UIEvents.history do
        local event = UIEvents.history[i]
        print(string.format("  [%.2fs] %s: %s", 
            event.timestamp, 
            event.name, 
            event.data and tostring(event.data) or "nil"))
    end
end

--[[
    STANDARD UI EVENTS
    
    Card Events:
    - "card:selected" { cardIndex, viewportX, viewportY }
    - "card:deselected" { cardIndex }
    - "card:dragStart" { cardIndex, startX, startY }
    - "card:drag" { cardIndex, x, y, deltaX, deltaY }
    - "card:dragEnd" { cardIndex, x, y }
    - "card:drop" { cardIndex, targetZone, x, y }
    - "card:hover" { cardIndex, x, y }
    
    Hand Events:
    - "hand:sorted" { criteria: "rank"|"suit" }
    - "hand:played" { cardIndices, score }
    - "hand:discarded" { cardIndices }
    
    Crib Events:
    - "crib:cardAdded" { cardIndex }
    - "crib:full" { }
    
    UI State Events:
    - "ui:resize" { screenWidth, screenHeight, scale }
    - "ui:stateChanged" { oldState, newState }
    
    Input Events:
    - "input:click" { x, y, button }
    - "input:keyPress" { key }
]]

return UIEvents
