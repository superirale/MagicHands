-- Joker inventory manager (5 slots max)

JokerManager = {
    slots = {},
    maxSlots = 5
}

function JokerManager:init()
    self.slots = {}
end

function JokerManager:addJoker(jokerId)
    -- Check for existing stackable joker
    for i, joker in ipairs(self.slots) do
        if joker.id == jokerId then
            -- For MVP, assume all are stackable to max 5, or check data
            if joker.stack < 5 then
                joker.stack = joker.stack + 1
                return true, "Stacked " .. jokerId .. " (x" .. joker.stack .. ")"
            else
                return false, "Max stack reached for " .. jokerId
            end
        end
    end

    if #self.slots >= self.maxSlots then
        return false, "Inventory full (5 jokers max)"
    end

    -- Add new joker instance
    table.insert(self.slots, { id = jokerId, stack = 1 })
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
    -- Logic: Selling removes the entire stack? Or just one?
    -- GDD implies slots are slots. Selling normally removes the card.
    local success, removedId = self:removeJoker(index)
    if success then
        Economy:addGold(sellPrice)
        return true, removedId
    end
    return false, removedId
end

function JokerManager:applyEffects(hand, trigger)
    local result = {
        addedChips = 0,
        addedTempMult = 0,
        addedPermMult = 0,
        ignoresCaps = false
    }

    if #self.slots == 0 then return result end

    -- In a real engine, we'd load the JSON data here to check for stack_bonuses
    -- For this MVP refactor, we will rely on the binded C++ or Lua logic to handle specific joker IDs
    -- BUT, the current system relies on "joker.applyEffects(paths...)"

    -- We need to construct a robust list of effects based on stacks
    -- This is tricky because the C++ binding expects file paths.
    -- Option: We interpret the stack in Lua and pass multiplied values to C++?
    -- Or we pass a list of identical paths?

    -- GDD Strategy: "Resolve Jokers -> Resolve Stacks"
    -- Simulating stacks by passing the file multiple times is the easiest way to get xN effects for now,
    -- UNLESS the joker has specific tier bonuses.

    local jokerPaths = {}
    for _, jokerObj in ipairs(self.slots) do
        -- For MVP: Simply treat stack xN as N copies of the joker
        -- The GDD specifies tier bonuses (Amplified, Synergy, etc)
        -- To support that properly requires parsing the JSON here or updating the C++ engine.
        -- Given constraints, we will replicate the base effect N times.

        for k = 1, jokerObj.stack do
            table.insert(jokerPaths, "content/data/jokers/" .. jokerObj.id .. ".json")
        end
    end

    return joker.applyEffects(jokerPaths, hand, trigger)
end

return JokerManager
