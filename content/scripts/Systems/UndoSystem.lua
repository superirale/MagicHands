-- UndoSystem.lua
-- Undo system for discards and card selections

local UndoSystem = {
    history = {},
    maxHistory = 1
}

function UndoSystem:init()
    self.history = {}
    self.maxHistory = 1 -- Only undo last action for simplicity
end

-- Save current state before an action
function UndoSystem:saveState(actionType, data)
    -- Clear history if at max
    if #self.history >= self.maxHistory then
        self.history = {}
    end

    table.insert(self.history, {
        type = actionType,
        timestamp = os.time(),
        data = data
    })
end

-- Check if undo is available
function UndoSystem:canUndo()
    return #self.history > 0
end

-- Get last action info
function UndoSystem:getLastAction()
    if #self.history > 0 then
        return self.history[#self.history]
    end
    return nil
end

-- Undo last action
function UndoSystem:undo()
    if #self.history == 0 then
        return false, "Nothing to undo"
    end

    local action = table.remove(self.history)
    return true, action
end

-- Clear undo history
function UndoSystem:clear()
    self.history = {}
end

-- Get undo hint text
function UndoSystem:getHint()
    if not self:canUndo() then
        return nil
    end

    local action = self:getLastAction()
    if action.type == "discard" then
        return "Press Z to undo discard"
    elseif action.type == "crib_selection" then
        return "Press Z to undo crib selection"
    end

    return "Press Z to undo"
end

return UndoSystem
