-- Shop system for purchasing jokers and upgrades

Shop = {
    jokers = {},

    -- Prices
    jokerSlots = 3,
    shopRerollCost = 10,

    -- Available joker pool (would be expanded)
    jokerPool = {
        common = { "fifteen_fever", "lucky_seven", "big_hand", "face_card_fan", "even_stevens" },
        uncommon = { "pair_power", "run_master", "nobs_hunter", "ace_in_hole", "the_trio" },
        rare = { "the_multiplier", "flush_king", "combo_king", "blackjack" },
        legendary = { "golden_ratio" }
    },

    -- Enhancement Pool (Planets, Imprints, Warps, Spectrals)
    enhancementPool = {
        "planet_pair", "planet_run", "planet_15", "planet_flush",
        "planet_noble", "planet_triad",
        "gold_inlay", "lucky_pips", "steel_plating",
        "spectral_ghost", "spectral_echo", "spectral_void",
        "spectral_remove", "spectral_clone"
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

    local attempts = 0
    while #self.jokers < self.jokerSlots and attempts < 50 do
        attempts = attempts + 1

        -- 30% chance to be an Enhancement instead of a Joker
        local isEnhancement = math.random() < 0.3

        if isEnhancement then
            -- Pick random enhancement (Planet, Imprint, Warp)
            local itemID = self.enhancementPool[math.random(#self.enhancementPool)]
            table.insert(self.jokers, {
                id = itemID,
                type = "enhancement",
                price = 75, -- Flat price for enhancements
                rarity = "common"
            })
        else
            local rarity = self:selectRarity(act)

            -- Select random joker from pool
            local pool = self.jokerPool[rarity]
            if pool and #pool > 0 then
                local joker_id = pool[math.random(#pool)]

                -- Validation 1: Don't allow duplicates in the same shop
                local alreadyInShop = false
                for _, j in ipairs(self.jokers) do
                    if j.id == joker_id then
                        alreadyInShop = true
                        break
                    end
                end

                -- Validation 2: Check current stack count
                -- JokerManager is global
                local currentStack = 0
                if JokerManager and JokerManager.slots then
                    for _, slot in ipairs(JokerManager.slots) do
                        if slot.id == joker_id then
                            currentStack = slot.stack
                            break
                        end
                    end
                end
                local isMaxed = (currentStack >= 5)

                if not alreadyInShop and not isMaxed then
                    table.insert(self.jokers, {
                        id = joker_id,
                        type = "joker",
                        rarity = rarity,
                        price = self:getJokerPrice(rarity)
                    })
                end
            end
        end
    end
end

function Shop:buyJoker(index)
    if index < 1 or index > #self.jokers then
        return false, "Invalid index"
    end

    local item = self.jokers[index]

    -- Check if can afford
    if not Economy:spend(item.price) then
        return false, "Not enough gold (" .. item.price .. "g needed)"
    end

    if item.type == "enhancement" then
        local EnhancementManager = require("criblage/EnhancementManager")

        -- Check if it's a Planet (Augment), Imprint (Card Mod), or Warp (Spectral)
        if string.find(item.id, "planet") then
            -- Handle Planet
            local cat = "pairs"
            if item.id == "planet_run" then cat = "runs" end
            if item.id == "planet_15" then cat = "fifteens" end
            if item.id == "planet_flush" then cat = "flush" end
            if item.id == "planet_noble" then cat = "nobs" end
            if item.id == "planet_triad" then cat = "three_kind" end

            local success, msg = EnhancementManager:addAugment(cat)
            table.remove(self.jokers, index)
            return true, "Used " .. item.id
        elseif string.find(item.id, "spectral") then
            -- Check for Sculptors (Action requiring selection)
            if item.id == "spectral_remove" or item.id == "spectral_clone" then
                -- Return signal to open DeckView
                -- We verify funds first but don't charge yet
                if not Economy:canAfford(item.price) then
                    return false, "Not enough gold"
                end

                return { action = "select_card", itemId = item.id, itemIndex = index }, "Select card to modify"
            else
                -- Handle Rule Warps
                local success, msg = EnhancementManager:addWarp(item.id)
                if not success then
                    Economy:addGold(item.price) -- Refund if charged (logic above charges before this check)
                    return false, msg
                end
                table.remove(self.jokers, index)
                return true, msg
            end
        else
            -- Handle Imprint (Apply to random card for MVP)
            -- For MVP: Pick a random card stub to simulate imprinting
            local ranks = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }
            local suits = { "H", "D", "S", "C" }
            local r = ranks[math.random(#ranks)]
            local s = suits[math.random(#suits)]
            local cardStub = { rank = r, suit = s } -- Mock card

            local success, msg = EnhancementManager:imprintCard(cardStub, item.id)

            table.remove(self.jokers, index)
            return true, "Imprinted " .. r .. s .. " with " .. item.id
        end
    else
        -- Handle Joker
        local success, msg = JokerManager:addJoker(item.id)
        if not success then
            Economy:addGold(item.price) -- Refund
            return false, msg
        end

        table.remove(self.jokers, index)
        return true, "Purchased " .. item.id
    end
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
