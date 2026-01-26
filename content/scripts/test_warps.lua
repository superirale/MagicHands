-- Test Rule Warp System
-- Verifies Warp Activation and Scoring Impact

local EnhancementManager = require("criblage/EnhancementManager")
local Shop = require("criblage/Shop")
local Economy = require("criblage/Economy")

print("=== RULE WARP TEST ===")

EnhancementManager:init()
Economy:init()

-- 1. Test Adding a Warp
print("\n[TEST 1] Add Warp")
local success, msg = EnhancementManager:addWarp("spectral_echo")
print("Add Result: " .. msg)
local effects = EnhancementManager:resolveWarps()

if effects.retrigger == 1 then
    print("PASS: Echo warp active (retrigger=1)")
else
    print("FAIL: Echo warp failed, retrigger=" .. effects.retrigger)
end

-- 2. Test Stacking Warps (Max 3)
print("\n[TEST 2] Max Warps")
EnhancementManager:addWarp("spectral_ghost")
EnhancementManager:addWarp("spectral_void")
local s2, m2 = EnhancementManager:addWarp("spectral_dummy") -- Should fail

if not s2 then
    print("PASS: Correctly blocked 4th warp")
else
    print("FAIL: Allowed 4th warp")
end

-- 3. Test Shop Purchase
print("\n[TEST 3] Shop Integration")
Shop:init()
Shop.jokers = { { id = "spectral_ghost", type = "enhancement", price = 75 } }
Economy:addGold(100) -- Rich

-- We already have metrics maxed, so buying ghost again should fail (duplicate check)
-- Wait, we added ghost in TEST 2.
-- Let's clear manager for shop test
EnhancementManager:init()

local success, msg = Shop:buyJoker(1)
print("Purchase result: " .. msg)

local effects2 = EnhancementManager:resolveWarps()
if effects2.cut_bonus == 20 then
    print("PASS: Shop purchase activated Ghost Cut")
else
    print("FAIL: Ghost Cut not active")
end

print("\n=== TESTS COMPLETE ===")
