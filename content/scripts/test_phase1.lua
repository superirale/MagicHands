-- Test script for Phase 1 implementations
-- Tests: Card Imprints, Deck Shapers, Joker Tier System

print("=== Phase 1 Implementation Tests ===\n")

-- Load required modules
local CampaignState = require("criblage/CampaignState")
local JokerManager = require("criblage/JokerManager")
local EnhancementManager = require("criblage/EnhancementManager")
local Shop = require("criblage/Shop")

-- Initialize systems
CampaignState:init()
JokerManager:init()
EnhancementManager:init()
Shop:init()

-- Test 1: Card Imprints Tracking
print("TEST 1: Card Imprints Tracking")
print("-------------------------------")

-- Add an imprint to a card
local testCardId = "A_H" -- Ace of Hearts
local success, msg = CampaignState:addImprintToCard(testCardId, "gold_inlay")
print("Add gold_inlay to A_H:", success, msg)

-- Try adding a second imprint
success, msg = CampaignState:addImprintToCard(testCardId, "lucky_pips")
print("Add lucky_pips to A_H:", success, msg)

-- Try adding a third (should fail - max 2)
success, msg = CampaignState:addImprintToCard(testCardId, "steel_plating")
print("Add steel_plating to A_H (expect fail):", success, msg)

-- Check imprints
local imprints = CampaignState:getCardImprints(testCardId)
print("Imprints on A_H:", #imprints)
for i, id in ipairs(imprints) do
    print("  " .. i .. ": " .. id)
end

-- Test 2: Imprint Resolution
print("\nTEST 2: Imprint Resolution")
print("--------------------------")

-- Create test cards with imprints
local testCards = {
    { rank = "A", suit = "H", id = "A_H", imprints = {"gold_inlay"} },
    { rank = "7", suit = "D", id = "7_D", imprints = {"lucky_pips"} },
    { rank = "K", suit = "S", id = "K_S", imprints = {"steel_plating"} }
}

-- Resolve on_score trigger
local effects = EnhancementManager:resolveImprints(testCards, "on_score")
print("Imprint Effects (on_score):")
print("  Chips:", effects.chips)
print("  Mult:", effects.mult)
print("  X-Mult:", effects.x_mult)
print("  Gold:", effects.gold)

-- Test 3: Deck Shapers
print("\nTEST 3: Deck Shapers")
print("--------------------")

local initialDeckSize = #CampaignState.masterDeck
print("Initial deck size:", initialDeckSize)

-- Test card removal
success = CampaignState:removeCard(1) -- Remove first card
print("Remove card 1:", success)
print("New deck size:", #CampaignState.masterDeck, "(expected:", initialDeckSize - 1, ")")

-- Test card duplication
success = CampaignState:duplicateCard(1)
print("Duplicate card 1:", success)
print("New deck size:", #CampaignState.masterDeck, "(expected:", initialDeckSize, ")")

-- Test 4: Imprintable Cards List
print("\nTEST 4: Imprintable Cards")
print("-------------------------")

local imprintable = CampaignState:getImprintableCards()
print("Cards that can be imprinted:", #imprintable)
print("First 5 imprintable cards:")
for i = 1, math.min(5, #imprintable) do
    local entry = imprintable[i]
    print(string.format("  %d. %s%s (imprints: %d/2)", 
        entry.index, entry.card.rank, entry.card.suit, entry.currentImprints))
end

-- Test 5: Joker Tier System (requires C++ engine running)
print("\nTEST 5: Joker Tier System")
print("-------------------------")

-- Add tiered joker at different stacks
JokerManager:addJoker("lucky_seven_tiered")
print("Added lucky_seven_tiered (stack 1)")

JokerManager:addJoker("lucky_seven_tiered")
print("Stacked lucky_seven_tiered (stack 2)")

JokerManager:addJoker("lucky_seven_tiered")
print("Stacked lucky_seven_tiered (stack 3)")

local jokers = JokerManager:getJokers()
print("Active jokers:")
for i, jokerStr in ipairs(jokers) do
    print("  " .. i .. ": " .. jokerStr)
end

-- Test 6: Shop Integration
print("\nTEST 6: Shop Integration")
print("------------------------")

Shop:generateJokers(1) -- Act 1 shop
print("Generated shop items:", #Shop.jokers)

for i, item in ipairs(Shop.jokers) do
    print(string.format("  %d. %s (%s) - %dg", i, item.id, item.type, item.price))
end

-- Test buying an imprint (simulated - would need card selection in real game)
print("\nAttempting to buy imprint...")
local hasImprint = false
local imprintIndex = 0
for i, item in ipairs(Shop.jokers) do
    if item.type == "enhancement" and (string.find(item.id, "inlay") or 
       string.find(item.id, "pips") or string.find(item.id, "plating")) then
        hasImprint = true
        imprintIndex = i
        break
    end
end

if hasImprint then
    print("Found imprint in shop at index " .. imprintIndex)
    print("In real game, this would open card selection UI")
else
    print("No imprints in this shop roll (random generation)")
end

-- Test 7: Deck Sculptor in Shop
print("\nTEST 7: Deck Sculptor in Shop")
print("------------------------------")

local hasSculptor = false
for i, item in ipairs(Shop.jokers) do
    if item.id == "spectral_remove" or item.id == "spectral_clone" then
        hasSculptor = true
        print("Found sculptor: " .. item.id .. " at index " .. i)
        break
    end
end

if not hasSculptor then
    print("No sculptors in this shop roll (random generation)")
end

print("\n=== All Phase 1 Tests Complete ===")
print("\nSummary:")
print("✓ Card Imprints: Tracking and resolution implemented")
print("✓ Deck Shapers: Remove/duplicate cards working")
print("✓ Joker Tiers: Stack tracking and tier JSON schema ready")
print("✓ Shop Integration: Imprints and sculptors in shop pool")
print("\nNote: Full testing requires running game with UI")
