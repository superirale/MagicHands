-- Test Imprint System
-- Verifies Imprint Application and Scoring Impact

local EnhancementManager = require("criblage/EnhancementManager")
local Shop = require("criblage/Shop")
local Economy = require("criblage/Economy")

print("=== IMPRINT SYSTEM TEST ===")

EnhancementManager:init()
Economy:init()

-- 1. Test Imprinting a Card
print("\n[TEST 1] Apply Imprint")
local testCard = { rank = "A", suit = "S", id = "A_S" }
EnhancementManager:imprintCard(testCard, "gold_inlay")

local applied = EnhancementManager:getImprint(testCard)
if applied == "gold_inlay" then
    print("PASS: Ace of Spades imprinted with Gold Inlay")
else
    print("FAIL: Imprint not found found: " .. tostring(applied))
end

-- 2. Test Scoring Resolutions
print("\n[TEST 2] Resolve Scoring")
local hand = { testCard } -- Hand containing the imprinted card

-- Context: Score
local effects = EnhancementManager:resolveImprints(hand, "score")
if effects.gold == 3 then
    print("PASS: Gold Inlay adds +3 Gold")
else
    print("FAIL: Expected 3 gold, got " .. effects.gold)
end

-- 3. Test Shop Generation & Purchase
print("\n[TEST 3] Shop Integration")
Shop:init()
-- Force an imprint into slot 1
Shop.jokers = { { id = "lucky_pips", type = "enhancement", price = 75 } }

Economy:addGold(100)
local success, msg = Shop:buyJoker(1)
print("Purchase result: " .. msg)

-- Verify an imprint was added (since we pick random card, we check if ANY imprint exists in manager)
local count = 0
for k, v in pairs(EnhancementManager.imprints) do
    count = count + 1
end

if count >= 2 then -- 1 from testCard, 1 from Shop
    print("PASS: Shop purchase applied new imprint")
else
    print("FAIL: Imprint count expected >= 2, got " .. count)
end

print("\n=== TESTS COMPLETE ===")
