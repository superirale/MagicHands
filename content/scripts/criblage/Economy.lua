-- Economy system for gold management

Economy = {
    gold = 0,
    baseReward = 20
}

function Economy:init()
    self.gold = 0
end

function Economy:addGold(amount)
    self.gold = self.gold + amount
    events.emit("gold_changed", { amount = self.gold, delta = amount })
end

function Economy:spend(amount)
    if self.gold >= amount then
        self.gold = self.gold - amount
        events.emit("gold_changed", { amount = self.gold, delta = -amount })
        return true
    end
    return false
end

function Economy:calculateReward(blindType, scoreAchieved, required)
    -- Base reward varies by blind type
    local base = self.baseReward
    if blindType == "big" then
        base = 30
    elseif blindType == "boss" then
        base = 50
    end

    -- Bonus for exceeding blind requirement
    local excess = scoreAchieved - required
    local bonus = math.floor(excess / 100) * 1

    -- Cap bonus at 20 gold
    if bonus > 20 then
        bonus = 20
    end

    return base + bonus
end

return Economy
