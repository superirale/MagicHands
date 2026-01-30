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
    
    -- Starting advantage (roguelike blessing)
    startingAdvantage = nil,
    firstBlindHandBonus = 0  -- Extra cards for first blind only
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

    -- Generate shop
    Shop:generateJokers(self.currentAct)
end

function CampaignState:playHand(score)
    print("DEBUG Campaign: playHand score=" .. score)
    self.handsRemaining = self.handsRemaining - 1
    self.currentScore = self.currentScore + score
    print("DEBUG Campaign: new currentScore=" .. self.currentScore)

    local currentBlind = self:getCurrentBlind()
    local required = blind.getRequiredScore(currentBlind, self.difficulty)

    if self.currentScore >= required then
        -- Win! Calculate reward
        local reward = Economy:calculateReward(currentBlind.type, self.currentScore, required)
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

return CampaignState
