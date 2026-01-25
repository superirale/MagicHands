-- Shop system for purchasing jokers and upgrades

Shop = {
    jokers = {},

    -- Prices
    jokerSlots = 3,
    shopRerollCost = 10,

    -- Available joker pool (would be expanded)
    jokerPool = {
        common = { "fifteen_fever", "pair_power" },
        uncommon = { "pair_power" },
        rare = { "the_multiplier" },
        legendary = { "the_multiplier" }
    }
}

function Shop:init()
    self.jokers = {}
end

function Shop:getJokerPrice(rarity)
    if rarity == "common" then
        return 50
    elseif rarity == "uncommon" then
        return 100
    elseif rarity == "rare" then
        return 200
    elseif rarity == "legendary" then
        return 500
    end
    return 50
end

function Shop:selectRarity(act)
    -- Rarity chances increase with act
    local roll = math.random()

    if act == 1 then
        if roll < 0.7 then
            return "common"
        elseif roll < 0.95 then
            return "uncommon"
        else
            return "rare"
        end
    elseif act == 2 then
        if roll < 0.5 then
            return "common"
        elseif roll < 0.85 then
            return "uncommon"
        elseif roll < 0.98 then
            return "rare"
        else
            return "legendary"
        end
    else -- Act 3+
        if roll < 0.3 then
            return "common"
        elseif roll < 0.65 then
            return "uncommon"
        elseif roll < 0.92 then
            return "rare"
        else
            return "legendary"
        end
    end
end

function Shop:generateJokers(act)
    self.jokers = {}

    for i = 1, self.jokerSlots do
        local rarity = self:selectRarity(act)

        -- Select random joker from pool
        local pool = self.jokerPool[rarity]
        if pool and #pool > 0 then
            local joker_id = pool[math.random(#pool)]

            table.insert(self.jokers, {
                id = joker_id,
                rarity = rarity,
                price = self:getJokerPrice(rarity)
            })
        end
    end
end

function Shop:buyJoker(index)
    if index < 1 or index > #self.jokers then
        return false, "Invalid joker index"
    end

    local joker = self.jokers[index]

    -- Check if can afford
    if not Economy:spend(joker.price) then
        return false, "Not enough gold (" .. joker.price .. "g needed)"
    end

    -- Try to add to inventory
    local success, msg = JokerManager:addJoker(joker.id)
    if not success then
        Economy:addGold(joker.price) -- Refund
        return false, msg
    end

    -- Remove from shop
    table.remove(self.jokers, index)
    return true, "Purchased " .. joker.id
end

function Shop:reroll()
    if not Economy:spend(self.shopRerollCost) then
        return false, "Not enough gold for reroll"
    end

    -- Regenerate with current act
    self:generateJokers(CampaignState.currentAct or 1)
    return true, "Shop rerolled"
end

return Shop
