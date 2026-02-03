-- Campaign state manager
local Economy = require("criblage/Economy")
local JokerManager = require("criblage/JokerManager")
local Shop = require("criblage/Shop")
local BossManager = require("criblage/BossManager")
local StartingAdvantage = require("criblage/StartingAdvantage")
-- blind module is typically global or engine provided, but let's assume it's global for now or needed
-- local blind = require("criblage/blind") -- assuming this might be needed later

CampaignState = {
    currentAct = 1,
    currentBlind = 1, -- 1=small, 2=big, 3=boss
    difficulty = 1.0,

    handsRemaining = 4,
    discardsRemaining = 3,
    currentScore = 0,

    blindsCleared = 0,
    crib = {}, -- Persistent crib for the current blind

    -- Shop Generation Metrics (Phase 9)
    runSeed = 42,
    shopIndex = 0,
    playerGoldSpentTotal = 0,
    recentTriggers = {}, -- Queue of last 3 hands trigger counts

    -- Starting advantage (roguelike blessing)
    startingAdvantage = nil,
    firstBlindHandBonus = 0 -- Extra cards for first blind only
}

function CampaignState:init()
    self.currentAct = 1
    self.currentBlind = 1
    self.difficulty = 1.0
    self.handsRemaining = 4
    self.discardsRemaining = 3
    self.currentScore = 0
    self.blindsCleared = 0
    self.crib = {} -- Initialize empty crib
    self.firstBlindHandBonus = 0

    -- Phase 9 Init
    self.runSeed = math.random(1000000)
    self.shopIndex = 0
    self.playerGoldSpentTotal = 0
    self.recentTriggers = {}

    -- Initialize subsystems
    Economy:init()
    JokerManager:init()
    Shop:init()
    BossManager:init()

    self:initDeck()

    -- Roll and apply starting advantage
    self.startingAdvantage = StartingAdvantage:rollAdvantage()
    StartingAdvantage:apply(self.startingAdvantage, self)
end

function CampaignState:initDeck()
    self.masterDeck = {}
    self.cardImprints = {} -- Track imprints: { [cardId] = { imprint1_id, imprint2_id } }

    local ranks = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }
    local suits = { "H", "D", "S", "C" }

    -- Standard 52 card deck
    for _, s in ipairs(suits) do
        for _, r in ipairs(ranks) do
            local cardId = r .. "_" .. s
            table.insert(self.masterDeck, {
                rank = r,
                suit = s,
                id = cardId
            })
            -- Initialize empty imprint array for this card
            self.cardImprints[cardId] = {}
        end
    end
end

-- Reset campaign state (for new game)
function CampaignState:reset()
    self:init()
end

-- Return a COPY of the master deck for the current hand
function CampaignState:getDeck()
    local deckCopy = {}
    for _, card in ipairs(self.masterDeck) do
        -- Deep copy card to prevent reference issues if hand modifies it temporarily
        local cardCopy = {
            rank = card.rank,
            suit = card.suit,
            id = card.id,
            imprints = {} -- Copy imprints for this card
        }

        -- Copy imprints array
        if self.cardImprints[card.id] then
            for _, imprintId in ipairs(self.cardImprints[card.id]) do
                table.insert(cardCopy.imprints, imprintId)
            end
        end

        table.insert(deckCopy, cardCopy)
    end
    return deckCopy
end

function CampaignState:removeCard(idx)
    if idx > 0 and idx <= #self.masterDeck then
        local card = self.masterDeck[idx]
        -- Remove imprints when card is removed (per GDD: "Destroyed if card is removed")
        if card and self.cardImprints[card.id] then
            self.cardImprints[card.id] = nil
        end
        table.remove(self.masterDeck, idx)
        return true
    end
    return false
end

function CampaignState:duplicateCard(idx)
    if idx > 0 and idx <= #self.masterDeck then
        local original = self.masterDeck[idx]
        local copyId = original.id .. "_copy" .. os.time()
        local copy = {
            rank = original.rank,
            suit = original.suit,
            id = copyId
        }
        table.insert(self.masterDeck, copy)

        -- Copy imprints to the duplicated card
        self.cardImprints[copyId] = {}
        if self.cardImprints[original.id] then
            for _, imprintId in ipairs(self.cardImprints[original.id]) do
                table.insert(self.cardImprints[copyId], imprintId)
            end
        end

        return true
    end
    return false
end

-- Split a rank: Remove card and add 2 cards of ranks above/below
function CampaignState:splitCard(idx)
    if idx > 0 and idx <= #self.masterDeck then
        local card = self.masterDeck[idx]
        local rank = card.rank
        local suit = card.suit

        -- Rank lookup tables
        local rankValues = {
            A = 1,
            ["2"] = 2,
            ["3"] = 3,
            ["4"] = 4,
            ["5"] = 5,
            ["6"] = 6,
            ["7"] = 7,
            ["8"] = 8,
            ["9"] = 9,
            ["10"] = 10,
            J = 11,
            Q = 12,
            K = 13
        }
        local valueToRank = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }

        -- Remove original card
        table.remove(self.masterDeck, idx)

        -- Get numeric value of current rank
        local rankValue = rankValues[rank]
        if not rankValue then
            print("ERROR: Invalid rank: " .. tostring(rank))
            return false
        end

        -- Add lower rank card (wrapping from A to K)
        local lowerValue = rankValue - 1
        if lowerValue < 1 then lowerValue = 13 end
        local lowerRank = valueToRank[lowerValue]
        table.insert(self.masterDeck, {
            rank = lowerRank,
            suit = suit,
            id = "split_" .. lowerRank .. suit .. os.time()
        })

        -- Add higher rank card (wrapping from K to A)
        local higherValue = rankValue + 1
        if higherValue > 13 then higherValue = 1 end
        local higherRank = valueToRank[higherValue]
        table.insert(self.masterDeck, {
            rank = higherRank,
            suit = suit,
            id = "split_" .. higherRank .. suit .. (os.time() + 1)
        })

        return true
    end
    return false
end

-- Purge all cards of a specific suit
function CampaignState:purgeSuit(suit)
    local removed = 0
    local i = 1
    while i <= #self.masterDeck do
        if self.masterDeck[i].suit == suit then
            -- Remove imprints
            if self.cardImprints[self.masterDeck[i].id] then
                self.cardImprints[self.masterDeck[i].id] = nil
            end
            table.remove(self.masterDeck, i)
            removed = removed + 1
        else
            i = i + 1
        end
    end
    return removed > 0, removed
end

-- Equalize suits: Redistribute cards to have equal suit distribution
function CampaignState:equalizeSuits()
    if #self.masterDeck < 4 then
        return false, "Deck too small to equalize"
    end

    local suits = { 0, 1, 2, 3 } -- Hearts, Diamonds, Clubs, Spades
    local cardsPerSuit = math.floor(#self.masterDeck / 4)
    local remainder = #self.masterDeck % 4

    -- Collect all cards
    local allCards = {}
    for _, card in ipairs(self.masterDeck) do
        table.insert(allCards, card)
    end

    -- Redistribute suits evenly
    local newDeck = {}
    local suitIdx = 1
    for i, card in ipairs(allCards) do
        card.suit = suits[suitIdx]
        -- Assign extra cards to first suits
        if suitIdx <= remainder then
            if #newDeck >= (cardsPerSuit + 1) * suitIdx then
                suitIdx = suitIdx + 1
            end
        else
            if #newDeck >= cardsPerSuit * suitIdx + remainder then
                suitIdx = suitIdx + 1
            end
        end
        if suitIdx > 4 then suitIdx = 4 end
        table.insert(newDeck, card)
    end

    self.masterDeck = newDeck
    return true, "Deck equalized"
end

-- Merge two suits: Convert all cards of suit2 to suit1
function CampaignState:mergeSuits(suit1, suit2)
    local merged = 0
    for _, card in ipairs(self.masterDeck) do
        if card.suit == suit2 then
            card.suit = suit1
            merged = merged + 1
        end
    end
    return merged > 0, merged
end

-- Ascend all cards of a rank to the next higher rank
function CampaignState:ascendRank(idx)
    if idx < 1 or idx > #self.masterDeck then
        return false, 0
    end

    local targetCard = self.masterDeck[idx]
    local targetRank = targetCard.rank

    -- Rank lookup tables
    local rankValues = {
        A = 1,
        ["2"] = 2,
        ["3"] = 3,
        ["4"] = 4,
        ["5"] = 5,
        ["6"] = 6,
        ["7"] = 7,
        ["8"] = 8,
        ["9"] = 9,
        ["10"] = 10,
        J = 11,
        Q = 12,
        K = 13
    }
    local valueToRank = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }

    -- Calculate next rank (wrap King → Ace)
    local rankValue = rankValues[targetRank]
    if not rankValue then
        return false, 0
    end

    local newValue = rankValue + 1
    if newValue > 13 then
        newValue = 1
    end
    local newRank = valueToRank[newValue]

    local upgraded = 0

    -- Find and upgrade all cards with target rank
    for _, card in ipairs(self.masterDeck) do
        if card.rank == targetRank then
            card.rank = newRank
            -- Update card ID to avoid conflicts
            card.id = "ascend_" .. newRank .. card.suit .. os.time() .. upgraded
            upgraded = upgraded + 1

            -- Clear imprints when rank changes
            if self.cardImprints[card.id] then
                self.cardImprints[card.id] = nil
            end
        end
    end

    return upgraded > 0, upgraded
end

-- Collapse adjacent rank into selected rank (absorb lower rank)
function CampaignState:collapseRank(idx)
    if idx < 1 or idx > #self.masterDeck then
        return false, 0
    end

    local targetCard = self.masterDeck[idx]
    local targetRank = targetCard.rank

    -- Rank lookup tables
    local rankValues = {
        A = 1,
        ["2"] = 2,
        ["3"] = 3,
        ["4"] = 4,
        ["5"] = 5,
        ["6"] = 6,
        ["7"] = 7,
        ["8"] = 8,
        ["9"] = 9,
        ["10"] = 10,
        J = 11,
        Q = 12,
        K = 13
    }
    local valueToRank = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }

    -- Calculate lower rank (wrap Ace → King)
    local rankValue = rankValues[targetRank]
    if not rankValue then
        return false, 0
    end

    local lowerValue = rankValue - 1
    if lowerValue < 1 then
        lowerValue = 13
    end
    local lowerRank = valueToRank[lowerValue]

    local collapsed = 0

    -- Find and collapse all cards with lower rank into target rank
    for _, card in ipairs(self.masterDeck) do
        if card.rank == lowerRank then
            card.rank = targetRank
            -- Update card ID to avoid conflicts
            card.id = "collapse_" .. targetRank .. card.suit .. os.time() .. collapsed
            collapsed = collapsed + 1

            -- Clear imprints when rank changes
            if self.cardImprints[card.id] then
                self.cardImprints[card.id] = nil
            end
        end
    end

    return collapsed > 0, collapsed
end

-- Add imprint to a specific card (max 2 per card)
function CampaignState:addImprintToCard(cardId, imprintId)
    if not self.cardImprints then
        self.cardImprints = {}
    end

    if not self.cardImprints[cardId] then
        self.cardImprints[cardId] = {}
    end

    local imprints = self.cardImprints[cardId]

    -- Check if already has this imprint
    for _, existing in ipairs(imprints) do
        if existing == imprintId then
            return false, "Card already has this imprint"
        end
    end

    -- GDD: Max 2 imprints per card
    if #imprints >= 2 then
        return false, "Card already has maximum imprints (2)"
    end

    table.insert(imprints, imprintId)
    return true, "Imprint applied successfully"
end

-- Get imprints for a specific card
function CampaignState:getCardImprints(cardId)
    if not self.cardImprints or not self.cardImprints[cardId] then
        return {}
    end
    return self.cardImprints[cardId]
end

-- Get all cards that can be imprinted (have less than 2 imprints)
function CampaignState:getImprintableCards()
    local result = {}
    for i, card in ipairs(self.masterDeck) do
        local imprintCount = #self:getCardImprints(card.id)
        if imprintCount < 2 then
            table.insert(result, {
                index = i,
                card = card,
                currentImprints = imprintCount
            })
        end
    end
    return result
end

function CampaignState:getCurrentBlind()
    local types = { "small", "big", "boss" }
    local blindType = types[self.currentBlind]
    local bossId = ""

    if self.currentBlind == 3 then
        -- Select boss based on act via BossManager
        -- If activeBoss is nil, select one
        if not BossManager.activeBoss then
            BossManager:selectBossForAct(self.currentAct)
        end

        if BossManager.activeBoss then
            bossId = BossManager.activeBoss.id
        end
    else
        -- Clear active boss if not boss blind
        BossManager:clearBoss()
    end

    return blind.create(self.currentAct, blindType, bossId)
end

function CampaignState:getNextBlind()
    -- Peek at next blind logic without advancing state
    local nextBlindIdx = self.currentBlind + 1
    local nextAct = self.currentAct

    if nextBlindIdx > 3 then
        nextBlindIdx = 1
        nextAct = nextAct + 1
    end

    local types = { "small", "big", "boss" }
    local typeStr = types[nextBlindIdx]
    local bossId = ""

    if nextBlindIdx == 3 then
        -- For preview, we might need to pre-select boss if not set?
        -- Or just show "Boss" if dynamic?
        -- Ideally we reuse BossManager logic
        local BossManager = require("criblage/BossManager")
        if BossManager.activeBoss then
            bossId = BossManager.activeBoss.id
        else
            -- If no boss active yet, we might need a way to predict it
            -- For MVP, just reusing current act logic
            if nextAct == 1 then bossId = "the_counter" end
            if nextAct == 2 then bossId = "the_skunk" end
        end
    end

    return blind.create(nextAct, typeStr, bossId)
end

function CampaignState:advanceBlind()
    self.blindsCleared = self.blindsCleared + 1
    self.currentBlind = self.currentBlind + 1

    if self.currentBlind > 3 then
        self.currentBlind = 1
        self.currentAct = self.currentAct + 1
    end

    -- Reset hands/discards, score, and crib
    self.handsRemaining = 4
    self.discardsRemaining = 3
    self.currentScore = 0
    self.crib = {} -- Clear crib for new blind

    -- Clear first blind hand bonus after blind 1
    if self.currentBlind > 1 then
        self.firstBlindHandBonus = 0
    end

    -- Generate shop
    self.shopIndex = self.shopIndex + 1
    Shop:generateJokers(self.currentAct, true)
end

function CampaignState:playHand(score, playedCards, cutCard)
    print("DEBUG Campaign: playHand score=" .. score)
    self.handsRemaining = self.handsRemaining - 1
    self.currentScore = self.currentScore + score
    print("DEBUG Campaign: new currentScore=" .. self.currentScore)

    local currentBlind = self:getCurrentBlind()
    local required = blind.getRequiredScore(currentBlind, self.difficulty)

    -- GDD BOSS COUNTERS
    local bossEffects = BossManager and BossManager:getEffects() or {}
    for _, effectId in ipairs(bossEffects) do
        -- 1. THE COLLAPSER: Stack Scaling
        if effectId == "stack_scaling" then
            local totalStacks = 0
            for _, joker in ipairs(JokerManager.slots) do
                totalStacks = totalStacks + joker.stack
            end
            -- Increase difficulty based on total stacks
            if totalStacks > 1 then
                local multiplier = 1.0 + (totalStacks * 0.1) -- 10% per stack
                required = math.floor(required * multiplier)
                print("THE COLLAPSER: Required score increased to " .. required .. " (Stacks: " .. totalStacks .. ")")
            end
        end

        -- 2. THE BREAKER: Imprint Shatter
        -- Cards with imprints are destroyed after scoring
        if effectId == "imprint_shatter" and playedCards then
            for _, card in ipairs(playedCards) do
                if card.imprints and #card.imprints > 0 then
                    -- Find and remove from master deck
                    for i, masterCard in ipairs(self.masterDeck) do
                        if masterCard.id == card.id then
                            print("THE BREAKER: Destroying imprinted card " .. card.rank .. card.suit)
                            self:removeCard(i)
                            break
                        end
                    end
                end
            end
        end
    end

    -- Record build tags (Phase 9)
    local triggers = {
        fifteen = 0,
        run = 0,
        pair = 0,
        flush = 0,
        nobs = 0
    }

    local ScoringUtils = require("utils/ScoringUtils")
    local scoreDetails = ScoringUtils.calculateScore(playedCards, cutCard or self.cutCard, true)
    if scoreDetails and scoreDetails.handResult then
        local hr = scoreDetails.handResult
        if hr.fifteens then triggers.fifteen = #hr.fifteens end
        if hr.runs then triggers.run = #hr.runs end
        if hr.pairs then triggers.pair = #hr.pairs end
        if hr.flush then triggers.flush = 1 end
        if hr.nobs then triggers.nobs = 1 end
    end

    table.insert(self.recentTriggers, triggers)
    if #self.recentTriggers > 3 then
        table.remove(self.recentTriggers, 1)
    end

    if self.currentScore >= required then
        -- Win! Calculate reward
        local reward = Economy:calculateReward(currentBlind.type, self.currentScore, required)
        self.playerGoldSpentTotal = self.playerGoldSpentTotal -- Placeholder for tracking total spent?
        -- Actually playerGoldSpentTotal should be updated when spending gold.
        Economy:addGold(reward)
        self:advanceBlind()
        return "win", reward
    elseif self.handsRemaining <= 0 then
        -- Loss!
        return "loss", 0
    end

    return "continue", 0 -- Continue playing
end

function CampaignState:useDiscard()
    if self.discardsRemaining > 0 then
        self.discardsRemaining = self.discardsRemaining - 1
        events.emit("discard_used", { remaining = self.discardsRemaining })
        return true
    end
    return false
end

function CampaignState:isLastHand()
    return self.handsRemaining == 1
end

function CampaignState:getMaxHandSize()
    local baseSize = 6
    local bossEffects = BossManager and BossManager:getEffects() or {}
    for _, effectId in ipairs(bossEffects) do
        if effectId == "hand_size_reduced" then
            baseSize = baseSize - 1
        end
    end
    return baseSize + (self.firstBlindHandBonus or 0)
end

return CampaignState
