-- Joker inventory manager (5 slots max)

JokerManager = {
    slots = {},
    maxSlots = 5
}

function JokerManager:init()
    self.slots = {}
end

function JokerManager:addJoker(jokerId)
    if #self.slots >= self.maxSlots then
        return false, "Inventory full (5 jokers max)"
    end
    table.insert(self.slots, jokerId)
    return true, "Added " .. jokerId
end

function JokerManager:removeJoker(index)
    if index >= 1 and index <= #self.slots then
        local removed = self.slots[index]
        table.remove(self.slots, index)
        return true, removed
    end
    return false, "Invalid index"
end

function JokerManager:getJokers()
    return self.slots
end

function JokerManager:isFull()
    return #self.slots >= self.maxSlots
end

function JokerManager:sellJoker(index, sellPrice)
    local success, removed = self:removeJoker(index)
    if success then
        Economy:addGold(sellPrice)
        return true, removed
    end
    return false, removed
end

function JokerManager:applyEffects(hand, trigger)
    if #self.slots == 0 then
        return {
            addedChips = 0,
            addedTempMult = 0,
            addedPermMult = 0,
            ignoresCaps = false
        }
    end

    -- Build list of joker paths
    local jokerPaths = {}
    for _, id in ipairs(self.slots) do
        table.insert(jokerPaths, "content/data/jokers/" .. id .. ".json")
    end

    return joker.applyEffects(jokerPaths, hand, trigger)
end

return JokerManager
