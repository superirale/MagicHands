-- Test GDD Enhancement Shop Integration
-- Verifies Enhancements appear in Shop and can be purchased

local Shop = require("criblage/Shop")
local EnhancementManager = require("criblage/EnhancementManager")
local Economy = require("criblage/Economy")

print("=== ENHANCEMENT SHOP TEST ===")

-- Setup
Shop:init()
EnhancementManager:init()
Economy:init()
Economy:addGold(500) -- Rich test user

-- 1. Test Shop Generation (Probabilistic, but we can inspect manually)
print("\n[TEST 1] Shop Generation")
Shop:generateJokers(1)
print("Shop Contents:")
for i, item in ipairs(Shop.jokers) do
    if item.type == "enhancement" then
        print(i .. ". [Enhancement] " .. item.id .. " (" .. item.price .. "g)")
    else
        print(i .. ". [Joker] " .. item.id .. " (" .. item.price .. "g)")
    end
end

-- 2. Mock Purchase of Enhancement
-- Force insert an enhancement if none generated
if Shop.jokers[1].type ~= "enhancement" then
    Shop.jokers[1] = {
        id = "planet_pair",
        type = "enhancement",
        price = 75,
        rarity = "common"
    }
    print("Forced slot 1 to planet_pair")
end

print("\n[TEST 2] Buying Enhancement")
print("Buying slot 1...")
local success, msg = Shop:buyJoker(1)
print("Result: " .. tostring(success) .. " - " .. msg)

-- Verify Augment Level
if EnhancementManager.augments["pairs"] == 1 then
    print("PASS: Pair augment level increased to 1")
else
    print("FAIL: Pair augment level is " .. (EnhancementManager.augments["pairs"] or "nil"))
end

print("\n=== TESTS COMPLETE ===")
