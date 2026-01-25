-- Campaign state manager
local Economy = require("criblage/Economy")
local JokerManager = require("criblage/JokerManager")
local Shop = require("criblage/Shop")
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
end

function CampaignState:getCurrentBlind()
    local types = { "small", "big", "boss" }
    local blindType = types[self.currentBlind]
    local bossId = ""

    if self.currentBlind == 3 then
        -- Select boss based on act
        if self.currentAct == 1 then
            bossId = "the_counter"
        elseif self.currentAct == 2 then
            bossId = "the_skunk"
        end
    end

    return blind.create(self.currentAct, blindType, bossId)
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
