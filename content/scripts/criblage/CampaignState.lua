-- Campaign state manager
local Economy = require("criblage/Economy")
local JokerManager = require("criblage/JokerManager")
local Shop = require("criblage/Shop")
local BossManager = require("criblage/BossManager")
-- blind module is typically global or engine provided, but let's assume it's global for now or needed
-- local blind = require("criblage/blind") -- assuming this might be needed later

CampaignState = {
    currentAct = 1,
    currentBlind = 1, -- 1=small, 2=big, 3=boss
    difficulty = 1.0,

    handsRemaining = 4,
    discardsRemaining = 3,
    currentScore = 0,

    blindsCleared = 0
}

function CampaignState:init()
    self.currentAct = 1
    self.currentBlind = 1
    self.difficulty = 1.0
    self.handsRemaining = 4
    self.discardsRemaining = 3
    self.currentScore = 0
    self.blindsCleared = 0

    -- Initialize subsystems
    Economy:init()
    JokerManager:init()
    Shop:init()
    BossManager:init()

    self:initDeck()
end

function CampaignState:initDeck()
    self.masterDeck = {}
    local ranks = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }
    local suits = { "H", "D", "S", "C" }

    -- Standard 52 card deck
    for _, s in ipairs(suits) do
        for _, r in ipairs(ranks) do
            table.insert(self.masterDeck, {
                rank = r,
                suit = s,
                id = r .. "_" .. s -- Initial ID
            })
        end
    end
end

-- Return a COPY of the master deck for the current hand
function CampaignState:getDeck()
    local deckCopy = {}
    for _, card in ipairs(self.masterDeck) do
        -- Deep copy card to prevent reference issues if hand modifies it temporarily
        table.insert(deckCopy, {
            rank = card.rank,
            suit = card.suit,
            id = card.id
        })
    end
    return deckCopy
end

function CampaignState:removeCard(idx)
    if idx > 0 and idx <= #self.masterDeck then
        table.remove(self.masterDeck, idx)
        return true
    end
    return false
end

function CampaignState:duplicateCard(idx)
    if idx > 0 and idx <= #self.masterDeck then
        local original = self.masterDeck[idx]
        local copy = {
            rank = original.rank,
            suit = original.suit,
            id = original.id .. "_copy" .. os.time() -- Unique ID for the copy
        }
        table.insert(self.masterDeck, copy)
        return true
    end
    return false
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

    -- Reset hands/discards and score
    self.handsRemaining = 4
    self.discardsRemaining = 3
    self.currentScore = 0

    -- Generate shop
    Shop:generateJokers(self.currentAct)
end

function CampaignState:playHand(score)
    self.handsRemaining = self.handsRemaining - 1
    self.currentScore = self.currentScore + score

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
        return true
    end
    return false
end

return CampaignState
