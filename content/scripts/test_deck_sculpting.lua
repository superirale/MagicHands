-- Test Deck Sculpting
-- Verifies Master Deck Persistence, Removal, and Duplication

local CampaignState = require("criblage/CampaignState")

print("=== DECK SCULPTING TEST ===")

-- 1. Init Deck
CampaignState:initDeck()
local deck = CampaignState:getDeck()
print("Initial Deck Size: " .. #deck)

if #deck == 52 then
    print("PASS: Deck initialized with 52 cards")
else
    print("FAIL: Deck size " .. #deck)
end

-- 2. Test Removal (The Scythe)
print("\n[TEST 2] Remove Card")
-- Remove the first card
local cardToRemove = deck[1]
print("Removing " .. cardToRemove.id)

CampaignState:removeCard(1)
local deck2 = CampaignState:getDeck()
print("New Deck Size: " .. #deck2)

if #deck2 == 51 then
    print("PASS: Card removed successfully")
else
    print("FAIL: Deck size " .. #deck2)
end

-- Verify card is gone
local found = false
for _, c in ipairs(deck2) do
    if c.id == cardToRemove.id then
        found = true
        break
    end
end
if not found then
    print("PASS: Specific card verified gone")
else
    print("FAIL: Card still in deck")
end

-- 3. Test Duplication (The Mirror)
print("\n[TEST 3] Duplicate Card")
-- Duplicate the new first card (was 2nd)
local cardToCopy = deck2[1]
print("Duplicating " .. cardToCopy.id)

CampaignState:duplicateCard(1)
local deck3 = CampaignState:getDeck()
print("New Deck Size: " .. #deck3)

if #deck3 == 52 then
    print("PASS: Deck back to 52 (51 + 1)")
else
    print("FAIL: Deck size " .. #deck3)
end

-- Verify duplication
local count = 0
for _, c in ipairs(deck3) do
    -- Check rank/suit match
    if c.rank == cardToCopy.rank and c.suit == cardToCopy.suit then
        count = count + 1
    end
end

if count >= 2 then
    print("PASS: Found " .. count .. " copies of " .. cardToCopy.rank .. cardToCopy.suit)
else
    print("FAIL: Only found " .. count .. " copies")
end

print("\n=== TESTS COMPLETE ===")
