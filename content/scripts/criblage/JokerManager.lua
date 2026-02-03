-- Joker inventory manager (5 slots max)

JokerManager = {
    slots = {},
    maxSlots = 5
}

function JokerManager:init()
    self.slots = {}
end

function JokerManager:isStackable(jokerId)
    local path = "content/data/jokers/" .. jokerId .. ".json"
    if files and files.loadJSON then
        local data = files.loadJSON(path)
        if data then
            return data.stackable == true
        end
    end
    -- Fallback: check if id contains tiered
    return string.find(jokerId, "tiered") ~= nil
end

function JokerManager:addJoker(jokerId)
    -- Check for existing joker to stack
    local stackable = self:isStackable(jokerId)

    for i, joker in ipairs(self.slots) do
        if joker.id == jokerId then
            if stackable then
                if joker.stack < 5 then
                    joker.stack = joker.stack + 1
                    events.emit("joker_added", { id = jokerId, stack = joker.stack })
                    return true, "Stacked " .. jokerId .. " (x" .. joker.stack .. ")"
                else
                    return false, "Max stack reached for " .. jokerId
                end
            else
                return false, "Joker " .. jokerId .. " is not stackable"
            end
        end
    end

    if #self.slots >= self.maxSlots then
        return false, "Inventory full (5 jokers max)"
    end

    -- Add new joker instance
    table.insert(self.slots, { id = jokerId, stack = 1 })

    -- Emit joker added event
    events.emit("joker_added", { id = jokerId, stack = 1 })

    -- Check if slots are full
    if #self.slots >= self.maxSlots then
        events.emit("joker_slots_full", { count = self.maxSlots })
    end

    return true, "Added " .. jokerId
end

function JokerManager:removeJoker(index)
    if index >= 1 and index <= #self.slots then
        local removed = self.slots[index]
        table.remove(self.slots, index)
        return true, removed.id
    end
    return false, "Invalid index"
end

function JokerManager:getJokers()
    -- Return list of display strings for HUD
    local display = {}
    for _, joker in ipairs(self.slots) do
        local str = joker.id
        if joker.stack > 1 then
            str = str .. " (x" .. joker.stack .. ")"
        end
        table.insert(display, str)
    end
    return display
end

function JokerManager:isFull()
    -- Only full if 5 distinct slots used
    return #self.slots >= self.maxSlots
end

function JokerManager:sellJoker(index, sellPrice)
    -- Sell one joker from the stack at a time
    if index < 1 or index > #self.slots then
        return false, "Invalid index"
    end

    local joker = self.slots[index]
    local jokerId = joker.id

    if joker.stack > 1 then
        -- Decrease stack by 1
        joker.stack = joker.stack - 1
        Economy:addGold(sellPrice)

        -- Emit event
        events.emit("joker_sold", { id = jokerId, stack = joker.stack, remaining = true })

        return true, jokerId .. " (x" .. (joker.stack + 1) .. " -> x" .. joker.stack .. ")"
    else
        -- Stack is 1, remove the joker entirely
        local success, removedId = self:removeJoker(index)
        if success then
            Economy:addGold(sellPrice)

            -- Emit event
            events.emit("joker_sold", { id = jokerId, stack = 0, remaining = false })

            return true, removedId
        end
        return false, removedId
    end
end

function JokerManager:applyEffects(hand, trigger)
    local result = {
        addedChips = 0,
        addedTempMult = 0,
        addedPermMult = 0,
        ignoresCaps = false
    }

    if #self.slots == 0 then return result end

    -- Build paths and stack counts for tier system
    local jokerPaths = {}
    local stackCounts = {}

    for _, jokerObj in ipairs(self.slots) do
        table.insert(jokerPaths, "content/data/jokers/" .. jokerObj.id .. ".json")
        table.insert(stackCounts, jokerObj.stack)
    end

    -- Pass stack counts to C++ for tier-based effect resolution
    return joker.applyEffects(jokerPaths, hand, trigger, stackCounts)
end

function JokerManager:getPaths()
    -- Return list of JSON paths for all active jokers (handling stacks)
    local paths = {}
    for _, jokerObj in ipairs(self.slots) do
        for k = 1, jokerObj.stack do
            table.insert(paths, "content/data/jokers/" .. jokerObj.id .. ".json")
        end
    end
    return paths
end

return JokerManager
