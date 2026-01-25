-- Test GDD Compliance
-- Verifies Joker Stacking and new Scoring Pipeline

local JokerManager = require("criblage/JokerManager")
local EnhancementManager = require("criblage/EnhancementManager")

print("=== GDD COMPLIANCE TEST ===")

-- 1. Test Joker Stacking
print("\n[TEST 1] Joker Stacking")
JokerManager:init()
JokerManager:addJoker("fifteen_fever")
print("Added 1st: " .. table.concat(JokerManager:getJokers(), ", "))
JokerManager:addJoker("fifteen_fever")
print("Added 2nd: " .. table.concat(JokerManager:getJokers(), ", "))

local activeJokers = JokerManager:getJokers()
if activeJokers[1] == "fifteen_fever (x2)" then
    print("PASS: Stacking working (x2)")
else
    print("FAIL: Stacking failed: " .. (activeJokers[1] or "nil"))
end

-- 2. Test Enhancement Manager
print("\n[TEST 2] Enhancement Manager")
EnhancementManager:init()
EnhancementManager:addAugment("pairs")
print("Added Pair Augment (Level 1)")

local mockHandResult = {
    pairs = { { 1, 2 } }, -- One pair
    fifteens = {}
}
local bonus = EnhancementManager:resolveAugments(mockHandResult)
if bonus.chips == 5 and bonus.mult == 0.1 then
    print("PASS: Augment bonus correct (+5 chips, +0.1 mult)")
else
    print("FAIL: Augment bonus incorrect: " .. bonus.chips .. ", " .. bonus.mult)
end

print("\n=== TESTS COMPLETE ===")
