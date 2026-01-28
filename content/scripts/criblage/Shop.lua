-- Shop system for purchasing jokers and upgrades

Shop = {
    jokers = {},

    -- Prices
    jokerSlots = 3,
    shopRerollCost = 10,

    -- Available joker pool (expanded with Phase 2 content)
    jokerPool = {
        common = {
            "fifteen_fever", "lucky_seven", "big_hand", "face_card_fan", "even_stevens",
            "low_roller", "fifteen_fever_tiered", "lucky_seven_tiered", "even_stevens_tiered",
            "ace_power_tiered"
        },
        uncommon = {
            "pair_power", "run_master", "nobs_hunter", "ace_in_hole", "the_trio",
            "his_nobs", "the_collector", "the_economist", "the_polymath", "high_roller",
            "pair_power_tiered", "run_master_tiered", "nobs_hunter_tiered"
        },
        rare = {
            "the_multiplier", "flush_king", "combo_king", "blackjack",
            "the_dealer", "starter_card", "the_converter", "the_streaker",
            "the_minimalist", "royal_flush", "flush_king_tiered", "combo_king_tiered",
            "blackjack_tiered"
        },
        legendary = {
            "golden_ratio", "the_gambler", "wild_card", "the_doubler"
        }
    },

    -- Enhancement Pool (Planets, Imprints, Warps, Spectrals - Phase 2 expanded)
    enhancementPool = {
        -- Planets (20 total)
        "planet_pair", "planet_run", "planet_fifteen", "planet_flush",
        "planet_noble", "planet_triad", "planet_jupiter", "planet_mars",
        "planet_venus", "planet_saturn", "planet_neptune", "planet_uranus",
        "planet_mercury", "planet_pluto", "planet_earth", "planet_moon",
        "planet_sun", "planet_comet", "planet_asteroid", "planet_nebula",

        -- Imprints (25 total)
        "gold_inlay", "lucky_pips", "steel_plating", "mint", "tax",
        "investment", "insurance", "dividend", "echo", "cascade",
        "fractal", "resonance", "spark", "ripple", "pulse",
        "crown", "underdog", "clutch", "opener", "majority",
        "minority", "wildcard_imprint", "suit_shifter", "mimic", "nullifier",

        -- Warps (15 total)
        "spectral_ghost", "spectral_echo", "spectral_void",
        "warp_wildfire", "warp_ascension", "warp_greed", "warp_gambit",
        "warp_time", "warp_infinity", "warp_chaos", "warp_inversion",
        "warp_mirror", "warp_fortune", "warp_blaze", "warp_phantom",

        -- Sculptors (8 total)
        "spectral_remove", "spectral_clone", "spectral_ascend", "spectral_collapse",
        "spectral_split", "spectral_purge", "spectral_rainbow", "spectral_fusion"
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

    -- Emit shop purchase event
    events.emit("shop_purchase", { id = item.id, type = item.type, price = item.price })

    if item.type == "enhancement" then
        local EnhancementManager = require("criblage/EnhancementManager")

        -- Check if it's a Planet (Augment), Imprint (Card Mod), or Warp (Spectral)
        if string.find(item.id, "planet") then
            local success, msg = EnhancementManager:addEnhancement(item.id, "augment")
            if not success then
                Economy:addGold(item.price)
                return false, msg
            end
            table.remove(self.jokers, index)
            return true, msg
        elseif string.find(item.id, "spectral") or string.find(item.id, "warp") then
            -- Check for Sculptors (Action requiring selection)
            if item.id == "spectral_remove" or item.id == "spectral_clone" then
                -- Return signal to open DeckView
                -- We verify funds first but don't charge yet
                if Economy.gold < item.price then
                    return false, "Not enough gold"
                end

                return { action = "select_card", itemId = item.id, itemIndex = index }, "Select card to modify"
            else
                -- Handle Rule Warps
                local success, msg = EnhancementManager:addEnhancement(item.id, "warp")
                if not success then
                    Economy:addGold(item.price) -- Refund if charged (logic above charges before this check)
                    return false, msg
                end
                table.remove(self.jokers, index)
                return true, msg
            end
        else
            -- Handle Imprint (Requires card selection)
            if Economy.gold < item.price then
                return false, "Not enough gold"
            end

            -- Return signal to open card selection for imprinting
            return { action = "select_card_for_imprint", itemId = item.id, itemIndex = index }, "Select card to imprint"
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

    -- Emit reroll event
    events.emit("shop_reroll", { cost = self.shopRerollCost })

    -- Regenerate with current act
    self:generateJokers(CampaignState.currentAct or 1)
    return true, "Shop rerolled"
end

-- Complete imprint purchase after card selection
function Shop:applyImprint(shopIndex, cardId)
    if shopIndex < 1 or shopIndex > #self.jokers then
        return false, "Invalid shop index"
    end

    local item = self.jokers[shopIndex]

    -- Verify it's an imprint item
    -- Known imprints (all 25 from Phase 2)
    local imprints = {
        gold_inlay = true,
        lucky_pips = true,
        steel_plating = true,
        mint = true,
        tax = true,
        investment = true,
        insurance = true,
        dividend = true,
        echo = true,
        cascade = true,
        fractal = true,
        resonance = true,
        spark = true,
        ripple = true,
        pulse = true,
        crown = true,
        underdog = true,
        clutch = true,
        opener = true,
        majority = true,
        minority = true,
        wildcard_imprint = true,
        suit_shifter = true,
        mimic = true,
        nullifier = true
    }

    if item.type ~= "enhancement" or not imprints[item.id] then
        return false, "Item is not an imprint"
    end

    -- Charge player
    if not Economy:spend(item.price) then
        return false, "Not enough gold"
    end

    -- Apply imprint to card via CampaignState
    local success, msg = CampaignState:addImprintToCard(cardId, item.id)

    if not success then
        -- Refund on failure
        Economy:addGold(item.price)
        return false, msg
    end

    -- Remove from shop
    table.remove(self.jokers, shopIndex)
    return true, "Imprinted with " .. item.id
end

-- Complete deck sculptor action after card selection
function Shop:applySculptor(shopIndex, cardIndex, action)
    if shopIndex < 1 or shopIndex > #self.jokers then
        return false, "Invalid shop index"
    end

    local item = self.jokers[shopIndex]

    -- Verify it's a sculptor item
    if item.id ~= "spectral_remove" and item.id ~= "spectral_clone" then
        return false, "Item is not a deck sculptor"
    end

    -- Charge player
    if not Economy:spend(item.price) then
        return false, "Not enough gold"
    end

    local success = false
    local msg = ""

    if item.id == "spectral_remove" then
        success = CampaignState:removeCard(cardIndex)
        msg = success and "Card removed from deck" or "Failed to remove card"
    elseif item.id == "spectral_clone" then
        success = CampaignState:duplicateCard(cardIndex)
        msg = success and "Card duplicated" or "Failed to duplicate card"
    end

    if success then
        -- Emit sculptor used event
        events.emit("sculptor_used", {
            id = item.id,
            newDeckSize = #CampaignState.masterDeck
        })

        -- Remove from shop
        table.remove(self.jokers, shopIndex)
    else
        -- Refund on failure
        Economy:addGold(item.price)
    end

    return success, msg
end

return Shop
