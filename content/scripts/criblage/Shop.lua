local events = _G.events or { emit = function(...) end }
local files = _G.files or { load = function(...) end, save = function(...) end, loadJSON = function(...) end }

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
        "warp_mirror", "warp_fortune", "warp_blaze", "warp_phantom"
    },

    -- Sculptors (8 total) - Rare/Mythic Deck Shapers
    sculptorPool = {
        "spectral_remove", "spectral_clone", "spectral_ascend", "spectral_collapse",
        "spectral_split", "spectral_purge", "spectral_rainbow", "spectral_fusion"
    },

    -- Phase 9: Metadata Registry (Fallback for missing JSON tags)
    itemMetadata = {
        fifteen_fever = { weight = 10, power = 4, tags = { "fifteen" }, anti = { "run" } },
        lucky_seven = { weight = 10, power = 3, tags = { "seven", "high_mult" } },
        big_hand = { weight = 10, power = 4, tags = { "hand_size" } },
        face_card_fan = { weight = 10, power = 3, tags = { "face_cards" } },
        even_stevens = { weight = 10, power = 2, tags = { "even" } },
        low_roller = { weight = 10, power = 3, tags = { "low_rank" } },
        pair_power = { weight = 8, power = 5, tags = { "pair" } },
        run_master = { weight = 8, power = 6, tags = { "run" } },
        nobs_hunter = { weight = 8, power = 4, tags = { "nobs" } },
        ace_in_hole = { weight = 8, power = 5, tags = { "ace" } },
        the_multiplier = { weight = 5, power = 8, tags = { "high_mult" } },
        flush_king = { weight = 5, power = 9, tags = { "flush" } },
        combo_king = { weight = 5, power = 10, tags = { "fifteen", "run" } },
        blackjack = { weight = 5, power = 8, tags = { "fifteen" } },
        golden_ratio = { weight = 2, power = 10, tags = { "high_mult" } },
        the_gambler = { weight = 2, power = 9, tags = { "risk" } },

        -- Default for categories
        planet_default = { weight = 10, power = 2, tags = { "augment" } },
        warp_default = { weight = 5, power = 5, tags = { "warp", "risk" } },
        sculptor_default = { weight = 3, power = 8, tags = { "sculptor", "exotic" } }
    }
}

-- Phase 9: Helper for local RNG
local function createRNG(seed)
    local state = seed
    return function()
        state = (1103515245 * state + 12345) % math.max(2147483648, 1)
        return state / 2147483648
    end
end

function Shop:init()
    self.jokers = {}
end

function Shop:getJokerPrice(rarity)
    if rarity == "common" then
        return 20
    elseif rarity == "uncommon" then
        return 50
    elseif rarity == "rare" then
        return 110
    elseif rarity == "legendary" then
        return 200
    end
    return 20
end

function Shop:selectRarity(ante, rng)
    local roll = rng()
    -- Spec Rarity Tables (Jokers)
    if ante <= 2 then
        if roll < 0.70 then
            return "common"
        elseif roll < 0.95 then
            return "uncommon"
        else
            return "rare"
        end
    elseif ante <= 4 then
        if roll < 0.55 then
            return "common"
        elseif roll < 0.90 then
            return "uncommon"
        elseif roll < 0.99 then
            return "rare"
        else
            return "legendary"
        end
    elseif ante <= 6 then
        if roll < 0.45 then
            return "common"
        elseif roll < 0.83 then
            return "uncommon"
        elseif roll < 0.97 then
            return "rare"
        else
            return "legendary"
        end
    elseif ante <= 8 then
        if roll < 0.35 then
            return "common"
        elseif roll < 0.75 then
            return "uncommon"
        elseif roll < 0.95 then
            return "rare"
        else
            return "legendary"
        end
    else -- 9+
        if roll < 0.25 then
            return "common"
        elseif roll < 0.65 then
            return "uncommon"
        elseif roll < 0.90 then
            return "rare"
        else
            return "legendary"
        end
    end
end

function Shop:getItemBuyPrice(id)
    -- Check common
    for _, jId in ipairs(self.jokerPool.common) do if jId == id then return self:getJokerPrice("common") end end
    -- Check uncommon
    for _, jId in ipairs(self.jokerPool.uncommon) do if jId == id then return self:getJokerPrice("uncommon") end end
    -- Check rare
    for _, jId in ipairs(self.jokerPool.rare) do if jId == id then return self:getJokerPrice("rare") end end
    -- Check legendary
    for _, jId in ipairs(self.jokerPool.legendary) do if jId == id then return self:getJokerPrice("legendary") end end

    -- Check enhancements
    for _, eId in ipairs(self.enhancementPool) do if eId == id then return 30 end end
    -- Check sculptors
    for _, sId in ipairs(self.sculptorPool) do if sId == id then return 60 end end

    return 20 -- Default fallback
end

function Shop:canGenerateItem(id, currentShopItems)
    -- 1. Uniqueness check (Universal Duplicate Prevention)
    for _, item in ipairs(currentShopItems) do
        if item.id == id then return false end
    end

    -- 2. Max Stack Filter (Jokers)
    if JokerManager and JokerManager.slots then
        for _, slot in ipairs(JokerManager.slots) do
            if slot.id == id then
                if slot.stack >= 5 then return false end
                -- Also prevent duplicate base jokers in inventory if not stackable
                if not JokerManager:isStackable(id) then return false end
            end
        end
    end

    -- 3. Warp Check (Max 3)
    if string.find(id, "warp") or string.find(id, "spectral_echo") or string.find(id, "spectral_ghost") then
        local EnhancementManager = require("criblage/EnhancementManager")
        if EnhancementManager and #EnhancementManager.warps >= 3 then
            return false
        end
    end

    return true
end

function Shop:getWeight(id, context, ante)
    local meta = self.itemMetadata[id] or
        self.itemMetadata
        [id:gsub("planet_.*", "planet_default"):gsub("warp_.*", "warp_default"):gsub("spectral_.*", "sculptor_default")]
    if not meta then meta = { weight = 10, power = 5, tags = {} } end

    local weight = meta.weight or 10

    -- Ante constraints (optional, can be added to metadata)
    if meta.min_ante and ante < meta.min_ante then return 0 end
    if meta.max_ante and ante > meta.max_ante then return 0 end

    -- Synergy Boost (1.75x)
    if meta.tags and context.dominantTags then
        for _, tag in ipairs(meta.tags) do
            if context.dominantTags[tag] then
                weight = weight * 1.75
                break
            end
        end
    end

    -- Anti-Synergy (0.35x)
    if meta.anti and context.dominantTags then
        for _, tag in ipairs(meta.anti) do
            if context.dominantTags[tag] then
                weight = weight * 0.35
                break
            end
        end
    end

    -- Unique check
    if meta.unique then
        -- This should be handled by canGenerateItem but good for weight zeroing
    end

    return weight
end

function Shop:analyzeBuild(state)
    local context = { dominantTags = {} }
    if not state.recentTriggers or #state.recentTriggers == 0 then return context end

    local counts = {}
    for _, hand in ipairs(state.recentTriggers) do
        for tag, count in pairs(hand) do
            if count > 0 then
                counts[tag] = (counts[tag] or 0) + count
            end
        end
    end

    -- Tag is dominant if it appeared in at least 2 hands or has high count
    for tag, count in pairs(counts) do
        if count >= 3 then -- Arbitrary threshold: 3 triggers over 3 hands
            context.dominantTags[tag] = true
        end
    end

    return context
end

function Shop:generateJokers(ante, resetCost)
    self.jokers = {}
    local CampaignState = require("criblage/CampaignState")

    -- 1. Deterministic Seeding
    local seed = CampaignState.runSeed or 42
    seed = (seed * 31 + (ante or 1)) * 31 + (CampaignState.shopIndex or 0)
    seed = seed * 31 + (CampaignState.playerGoldSpentTotal or 0)
    local rng = createRNG(seed % 2147483647)

    if resetCost then
        self.shopRerollCost = 2 -- Master Spec: Base 2 gold
    end

    -- 2. Entropy Adjustment (Anti-Snowball)
    local synergyMultiplier = 1.75
    if CampaignState.recentShopsSynergyRate and #CampaignState.recentShopsSynergyRate >= 5 then
        local avgRate = 0
        for _, rate in ipairs(CampaignState.recentShopsSynergyRate) do avgRate = avgRate + rate end
        avgRate = avgRate / 5
        if avgRate > 0.6 then        -- Too high synergy
            synergyMultiplier = 1.35 -- Reduce boost
        end
    end

    local context = self:analyzeBuild(CampaignState)
    local maxPower = 6 + (ante * 2)
    local currentPower = 0
    local synergyCount = 0

    local attempts = 0
    while #self.jokers < self.jokerSlots and attempts < 100 do
        attempts = attempts + 1
        local item = nil
        local roll = rng()

        -- Category selection
        if roll < 0.30 then
            -- Enhancements (Rotation bias: 1=Augment, 2=Imprint, 3=Warp)
            local rotation = ((CampaignState.shopIndex or 0) % 3) + 1
            local targetCategory = (rotation == 1 and "planet" or (rotation == 2 and "imprint" or "warp"))

            -- Filter pool by category (rough filter by ID prefix)
            local subPool = {}
            for _, id in ipairs(self.enhancementPool) do
                if string.find(id, targetCategory) or (targetCategory == "imprint" and not string.find(id, "planet") and not string.find(id, "warp")) then
                    table.insert(subPool, id)
                end
            end
            if #subPool == 0 then subPool = self.enhancementPool end -- Fallback

            local id = subPool[math.floor(rng() * #subPool) + 1]
            if self:canGenerateItem(id, self.jokers) then
                local meta = self.itemMetadata[id] or { power = 3 }
                item = { id = id, type = "enhancement", price = 30, rarity = "common", power = meta.power or 3 }
            end
        else
            -- Jokers
            local rarity = self:selectRarity(ante, rng)
            local pool = self.jokerPool[rarity]
            if pool and #pool > 0 then
                -- Weighted selection within pool
                local totalWeight = 0
                local weights = {}
                local synergies = {}
                for _, id in ipairs(pool) do
                    local w = self:getWeight(id, context, ante)
                    local isSynergistic = (w > (self.itemMetadata[id] and self.itemMetadata[id].weight or 10))
                    if isSynergistic then
                        -- Apply adjusted multiplier if synergistic
                        w = (self.itemMetadata[id] and self.itemMetadata[id].weight or 10) * synergyMultiplier
                    end

                    table.insert(weights, w)
                    table.insert(synergies, isSynergistic)
                    totalWeight = totalWeight + w
                end

                if totalWeight > 0 then
                    local wRoll = rng() * totalWeight
                    local currentW = 0
                    for i, w in ipairs(weights) do
                        currentW = currentW + w
                        if wRoll <= currentW then
                            local id = pool[i]
                            if self:canGenerateItem(id, self.jokers) then
                                local meta = self.itemMetadata[id] or { power = 5 }
                                item = {
                                    id = id,
                                    type = "joker",
                                    rarity = rarity,
                                    price = self:getJokerPrice(rarity),
                                    power = meta.power or 5,
                                    synergistic = synergies[i]
                                }
                            end
                            break
                        end
                    end
                end
            end
        end

        if item then
            -- Power Budget check
            if currentPower + item.power > maxPower then
                -- Skip
            else
                currentPower = currentPower + item.power
                if item.synergistic then synergyCount = synergyCount + 1 end
                table.insert(self.jokers, item)
            end
        end
    end

    -- Track synergy rate for entropy meter
    if not CampaignState.recentShopsSynergyRate then CampaignState.recentShopsSynergyRate = {} end
    table.insert(CampaignState.recentShopsSynergyRate, synergyCount / math.max(1, #self.jokers))
    if #CampaignState.recentShopsSynergyRate > 5 then table.remove(CampaignState.recentShopsSynergyRate, 1) end

    -- 3. Pivot Injection Rule (Every 3rd shop)
    if (CampaignState.shopIndex or 0) % 3 == 0 and #self.jokers > 0 then
        -- Replace the last item with one that has ZERO build overlap
        local pivotItem = nil
        local pivotAttempts = 0
        while not pivotItem and pivotAttempts < 50 do
            pivotAttempts = pivotAttempts + 1
            local rarity = self:selectRarity(ante, rng)
            local pool = self.jokerPool[rarity]
            local id = pool[math.floor(rng() * #pool) + 1]

            local hasOverlap = false
            local meta = self.itemMetadata[id]
            if meta and meta.tags then
                for _, tag in ipairs(meta.tags) do
                    if context.dominantTags[tag] then
                        hasOverlap = true
                        break
                    end
                end
            end

            if not hasOverlap and self:canGenerateItem(id, self.jokers) then
                local meta = self.itemMetadata[id] or { power = 5 }
                pivotItem = {
                    id = id,
                    type = "joker",
                    rarity = rarity,
                    price = self:getJokerPrice(rarity),
                    power = meta.power or 5,
                    isPivot = true
                }
            end
        end

        if pivotItem then
            self.jokers[#self.jokers] = pivotItem
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
            -- These spectrals modify the deck structure and need user interaction
            local sculptorSpectrals = {
                spectral_remove = true,
                spectral_clone = true,
                spectral_split = true,
                spectral_purge = true,
                spectral_rainbow = true,
                spectral_fusion = true,
                spectral_ascend = true,
                spectral_collapse = true
            }

            if sculptorSpectrals[item.id] then
                -- Return signal to open DeckView or selection UI
                -- We verify funds first but don't charge yet
                if Economy.gold < item.price then
                    return false, "Not enough gold"
                end

                return { action = "select_card", itemId = item.id, itemIndex = index }, "Select card to modify"
            else
                -- Handle Rule Warps (spectral_echo, spectral_ghost, warp_*, etc.)
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

    -- Increment reroll cost (Base + 2g per reroll per Spec)
    self.shopRerollCost = self.shopRerollCost + 2

    -- Emit reroll event
    events.emit("shop_reroll", { cost = self.shopRerollCost })

    -- Regenerate with current ante, but DON'T reset cost
    local CampaignState = require("criblage/CampaignState")
    self:generateJokers(CampaignState.currentAct or 1, false)

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
    local validSculptors = {
        spectral_remove = true,
        spectral_clone = true,
        spectral_split = true,
        spectral_purge = true,
        spectral_rainbow = true,
        spectral_fusion = true,
        spectral_ascend = true,
        spectral_collapse = true
    }

    if not validSculptors[item.id] then
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
    elseif item.id == "spectral_split" then
        -- Split a card into two adjacent ranks
        success = CampaignState:splitCard(cardIndex)
        msg = success and "Card split into two ranks" or "Failed to split card"
    elseif item.id == "spectral_purge" then
        -- Purge all cards of the selected card's suit
        if cardIndex > 0 and cardIndex <= #CampaignState.masterDeck then
            local targetSuit = CampaignState.masterDeck[cardIndex].suit
            local removed = 0
            success, removed = CampaignState:purgeSuit(targetSuit)
            msg = success and ("Purged " .. removed .. " cards from suit") or "Failed to purge suit"
        else
            success = false
            msg = "Invalid card selection"
        end
    elseif item.id == "spectral_rainbow" then
        -- Equalize suit distribution in deck
        success, msg = CampaignState:equalizeSuits()
        if not msg then
            msg = success and "Deck suits equalized" or "Failed to equalize suits"
        end
    elseif item.id == "spectral_fusion" then
        -- Merge suits: Convert selected card's suit to merge into another
        -- For now, merge into Hearts (suit 0) - could be enhanced with UI selection
        if cardIndex > 0 and cardIndex <= #CampaignState.masterDeck then
            local sourceSuit = CampaignState.masterDeck[cardIndex].suit
            -- Merge into the "opposite" suit (simple logic)
            local targetSuit = (sourceSuit + 2) % 4
            local merged = 0
            success, merged = CampaignState:mergeSuits(targetSuit, sourceSuit)
            msg = success and ("Merged " .. merged .. " cards into new suit") or "Failed to merge suits"
        else
            success = false
            msg = "Invalid card selection"
        end
    elseif item.id == "spectral_ascend" then
        -- Ascend all cards of selected rank to next higher rank
        if cardIndex > 0 and cardIndex <= #CampaignState.masterDeck then
            local upgraded = 0
            success, upgraded = CampaignState:ascendRank(cardIndex)
            msg = success and ("Ascended " .. upgraded .. " cards to higher rank") or "Failed to ascend rank"
        else
            success = false
            msg = "Invalid card selection"
        end
    elseif item.id == "spectral_collapse" then
        -- Collapse lower adjacent rank into selected rank
        if cardIndex > 0 and cardIndex <= #CampaignState.masterDeck then
            local collapsed = 0
            success, collapsed = CampaignState:collapseRank(cardIndex)
            msg = success and ("Collapsed " .. collapsed .. " cards into this rank") or "Failed to collapse rank"
        else
            success = false
            msg = "Invalid card selection"
        end
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
