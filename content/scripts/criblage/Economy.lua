-- Economy system for gold management

Economy = {
    gold = 0,
    baseReward = 50
}

function Economy:init()
    self.gold = 0
end

function Economy:addGold(amount)
    self.gold = self.gold + amount
end

function Economy:spend(amount)
    if self.gold >= amount then
        self.gold = self.gold - amount
        return true
    end
    return false
end

function Economy:calculateReward(blindType, scoreAchieved, required)
    -- Base reward varies by blind type
    local base = self.baseReward
    if blindType == "big" then
        base = base * 2
    elseif blindType == "boss" then
        base = base * 5
    end

    -- Bonus for exceeding blind requirement
    local excess = scoreAchieved - required
    local bonus = math.floor(excess / 100) * 5

    return base + bonus
end

return Economy
