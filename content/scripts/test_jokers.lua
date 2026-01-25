-- Comprehensive test suite for Joker system

print("========================================")
print("=== JOKER SYSTEM TEST SUITE ===")
print("========================================")
print()

-- Test 1: Load joker from JSON
print("Test 1: Load Joker from JSON")
local jokerDef = joker.load("content/data/jokers/fifteen_fever.json")
if jokerDef then
    print("  ✅ Loaded: " .. jokerDef.name)
    print("  Description: " .. jokerDef.description)
    print("  Rarity: " .. jokerDef.rarity)
else
    print("  ❌ FAIL: Could not load joker")
end
print()

-- Test 2: Apply Fifteen Fever joker
print("Test 2: Fifteen Fever (+0.2x per fifteen)")
local hand = {
    Card.new("5", "Hearts"),
    Card.new("10", "Spades"),
    Card.new("Jack", "Diamonds"),
    Card.new("2", "Clubs"),
    Card.new("3", "Spades") -- cut
}

-- Score without joker
local baseScore = cribbage.score(hand)
print("  Base fifteens: " .. baseScore.fifteenChips .. " chips")
print("  Base total: " .. baseScore.baseChips .. " chips")

-- Apply joker effects
local effects = joker.applyEffects(
    { "content/data/jokers/fifteen_fever.json" },
    hand,
    "on_score"
)
print("  Joker added chips: " .. effects.addedChips)
print("  Joker added mult: " .. effects.addedTempMult .. "x")
print("  Expected: +0.8x (4 fifteens × 0.2)")
if math.abs(effects.addedTempMult - 0.8) < 0.01 then
    print("  ✅ PASS")
else
    print("  ❌ FAIL")
end
print()

-- Test 3: Apply Pair Power joker
print("Test 3: Pair Power (+25 chips per pair)")
local pairHand = {
    Card.new("5", "Hearts"),
    Card.new("5", "Spades"),
    Card.new("10", "Diamonds"),
    Card.new("Jack", "Clubs"),
    Card.new("King", "Spades") -- cut
}

local effects2 = joker.applyEffects(
    { "content/data/jokers/pair_power.json" },
    pairHand,
    "on_score"
)
print("  Joker added chips: " .. effects2.addedChips)
print("  Expected: +25 chips (1 pair × 25)")
if effects2.addedChips == 25 then
    print("  ✅ PASS")
else
    print("  ❌ FAIL")
end
print()

-- Test 4: The Multiplier (cap bypass)
print("Test 4: The Multiplier (legendary +1.0x, ignores caps)")
local effects3 = joker.applyEffects(
    { "content/data/jokers/the_multiplier.json" },
    hand,
    "on_score"
)
print("  Joker added mult: " .. effects3.addedTempMult .. "x")
print("  Ignores caps: " .. tostring(effects3.ignoresCaps))
if effects3.addedTempMult == 1.0 and effects3.ignoresCaps then
    print("  ✅ PASS")
else
    print("  ❌ FAIL")
end
print()

-- Test 5: Multiple jokers stacking
print("Test 5: Multiple Jokers Stacking")
local effects4 = joker.applyEffects(
    {
        "content/data/jokers/fifteen_fever.json",
        "content/data/jokers/the_multiplier.json"
    },
    hand,
    "on_score"
)
print("  Total added mult: " .. effects4.addedTempMult .. "x")
print("  Expected: 1.8x (0.8 from Fifteen Fever + 1.0 from The Multiplier)")
if math.abs(effects4.addedTempMult - 1.8) < 0.01 then
    print("  ✅ PASS")
else
    print("  ❌ FAIL")
end
print()

-- Test 6: Full scoring integration
print("Test 6: Full Scoring with Jokers")
print("Hand: 5♥, 5♠, 10♦, J♣, K♠")
print("Jokers: Pair Power (+25 chips/pair), Fifteen Fever (+0.2x/15)")

local baseScore2 = cribbage.score(pairHand)
local jokerEffects = joker.applyEffects(
    {
        "content/data/jokers/pair_power.json",
        "content/data/jokers/fifteen_fever.json"
    },
    pairHand,
    "on_score"
)

print("  Base chips: " .. baseScore2.baseChips)
print("  Joker chips: +" .. jokerEffects.addedChips)
print("  Total chips: " .. (baseScore2.baseChips + jokerEffects.addedChips))
print("  Base mult: " .. (baseScore2.tempMultiplier + baseScore2.permMultiplier))
print("  Joker mult: +" .. jokerEffects.addedTempMult .. "x")
print("  Total mult: " ..
(1.0 + baseScore2.tempMultiplier + baseScore2.permMultiplier + jokerEffects.addedTempMult) .. "x")

local finalChips = baseScore2.baseChips + jokerEffects.addedChips
local finalMult = 1.0 + baseScore2.tempMultiplier + baseScore2.permMultiplier + jokerEffects.addedTempMult
local finalScore = math.floor(finalChips * finalMult + 0.5)

print("  Final score: " .. finalScore)
print("  Calculation: " .. finalChips .. " × " .. finalMult .. " = " .. finalScore)
print()

print("========================================")
print("=== ALL JOKER TESTS COMPLETE ===")
print("========================================")
