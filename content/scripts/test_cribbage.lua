-- Comprehensive test suite for Cribbage scoring system

print("========================================")
print("=== CRIBBAGE SCORING TEST SUITE ===")
print("========================================")
print()

local function test(name, cards, expectedScore)
    print("Test: " .. name)
    local score = cribbage.score(cards)
    print("  Fifteens: " .. score.fifteenChips .. " chips")
    print("  Pairs: " .. score.pairChips .. " chips")
    print("  Runs: " .. score.runChips .. " chips")
    print("  Flush: " .. score.flushChips .. " chips")
    print("  Nobs: " .. score.nobsChips .. " chips")
    print("  Base chips: " .. score.baseChips)
    print("  Final score: " .. score.finalScore)

    if expectedScore and score.baseChips == expectedScore then
        print("  ✅ PASS")
    elseif expectedScore then
        print("  ❌ FAIL (expected " .. expectedScore .. " base chips)")
    end
    print()
end

-- Test 1: Simple Fifteen
-- Cards: 5, 10, J(=10), 2, 3(cut)
-- Fifteens: 5+10, 5+J, 10+2+3, J+2+3 = 4 fifteens
test("Simple Fifteen (All 15-Combos)", {
    Card.new("5", "Hearts"),
    Card.new("10", "Spades"),
    Card.new("Jack", "Diamonds"),
    Card.new("2", "Clubs"),
    Card.new("3", "Spades") -- cut
}, 40)                      -- 4 fifteens × 10 = 40

-- Test 2: Triple Fives
-- Cards: 5, 5, 5, 10, K(=10)
-- Fifteens: Each 5 with 10 (×3), each 5 with K (×3), 5+5+5 (×1) = 7 fifteens
-- Pairs: 3 pairs (three-of-a-kind)
test("Triple Fives", {
    Card.new("5", "Hearts"),
    Card.new("5", "Spades"),
    Card.new("5", "Diamonds"),
    Card.new("10", "Clubs"),
    Card.new("King", "Spades") -- cut
}, 106)                        -- 70 (fifteens) + 36 (pairs)

-- Test 3: Pair with Multiple 10-Values
-- Cards: 5, 5, 10, J(=10), K(=10)
-- Fifteens: 5+10 (×2), 5+J (×2), 5+K (×2) = 6 fifteens
-- Pairs: 1 pair (5,5)
test("Single Pair + Multiple Fifteens", {
    Card.new("5", "Hearts"),
    Card.new("5", "Spades"),
    Card.new("10", "Diamonds"),
    Card.new("Jack", "Clubs"),
    Card.new("King", "Spades") -- cut
}, 72)                         -- 60 (fifteens) + 12 (pair)

-- Test 4: Three of a Kind (same as Test 2)
test("Three of a Kind", {
    Card.new("5", "Hearts"),
    Card.new("5", "Spades"),
    Card.new("5", "Diamonds"),
    Card.new("10", "Clubs"),
    Card.new("King", "Spades") -- cut
}, 106)                        -- 70 (fifteens) + 36 (pairs)

-- Test 5: Run of 3
-- Cards: 3, 4, 5, 10, K(=10)
-- Fifteens: 5+10, 5+K = 2 fifteens
-- Runs: 3-4-5
test("Run of 3", {
    Card.new("3", "Hearts"),
    Card.new("4", "Spades"),
    Card.new("5", "Diamonds"),
    Card.new("10", "Clubs"),
    Card.new("King", "Spades") -- cut
}, 44)                         -- 20 (fifteens) + 24 (run)

-- Test 6: Run of 4
-- Cards: 3, 4, 5, 6, K(=10)
-- Fifteens: 5+K, 4+5+6 = 2 fifteens
-- Runs: 3-4-5-6
test("Run of 4", {
    Card.new("3", "Hearts"),
    Card.new("4", "Spades"),
    Card.new("5", "Diamonds"),
    Card.new("6", "Clubs"),
    Card.new("King", "Spades") -- cut
}, 52)                         -- 20 (fifteens) + 32 (run)

-- Test 7: Run of 5
-- Cards: 3, 4, 5, 6, 7
-- Fifteens: 4+5+6, 3+5+7 = 2 fifteens
-- Runs: 3-4-5-6-7
test("Run of 5", {
    Card.new("3", "Hearts"),
    Card.new("4", "Spades"),
    Card.new("5", "Diamonds"),
    Card.new("6", "Clubs"),
    Card.new("7", "Spades") -- cut
}, 60)                      -- 20 (fifteens) + 40 (run)

-- Test 8: 4-card Flush + Run
-- Cards: J(=10), 7, 8, 9, 10 (cut different suit)
-- Fifteens: 7+8 = 1 fifteen
-- Runs: 7-8-9-10-J = run of 5
-- Flush: 4 cards same suit
test("4-Card Flush", {
    Card.new("Jack", "Hearts"),
    Card.new("7", "Hearts"),
    Card.new("8", "Hearts"),
    Card.new("9", "Hearts"),
    Card.new("10", "Spades") -- cut (different suit)
}, 70)                       -- 10 (fifteens) + 40 (run) + 20 (flush)

-- Test 9: 5-card Flush + Run
test("5-Card Flush", {
    Card.new("Jack", "Hearts"),
    Card.new("7", "Hearts"),
    Card.new("8", "Hearts"),
    Card.new("9", "Hearts"),
    Card.new("10", "Hearts") -- cut (same suit!)
}, 80)                       -- 10 (fifteens) + 40 (run) + 30 (5-card flush)

-- Test 10: Nobs
test("Nobs", {
    Card.new("Jack", "Hearts"),
    Card.new("5", "Spades"),
    Card.new("6", "Diamonds"),
    Card.new("7", "Clubs"),
    Card.new("King", "Hearts") -- cut (Hearts, matching Jack)
}, 15)                         -- nobs only

-- Test 11: Complex Hand
test("Complex Hand", {
    Card.new("5", "Hearts"),
    Card.new("5", "Spades"),
    Card.new("6", "Diamonds"),
    Card.new("7", "Clubs"),
    Card.new("8", "Spades") -- cut
}, nil)                     -- Expect multiple fifteens + pairs + runs

-- Test 12: "29 Hand" (Max in real cribbage)
test("God Hand (29 in Cribbage)", {
    Card.new("5", "Hearts"),
    Card.new("5", "Spades"),
    Card.new("5", "Diamonds"),
    Card.new("Jack", "Clubs"),
    Card.new("5", "Clubs") -- cut (4th five!)
}, nil)                    -- Should be massive: many fifteens + many pairs + nobs

-- Test 13: Multipliers (temp + perm)
print("Test: Multipliers")
local cards = {
    Card.new("5", "Hearts"),
    Card.new("10", "Spades"),
    Card.new("Jack", "Diamonds"),
    Card.new("2", "Clubs"),
    Card.new("3", "Spades")
}
local score = cribbage.score(cards, 1.0, 0.5) -- 1x temp, 0.5x perm
print("  Base: " .. score.baseChips)
print("  Temp mult: " .. score.tempMultiplier)
print("  Perm mult: " .. score.permMultiplier)
print("  Final: " .. score.finalScore .. " (expected: " .. (score.baseChips * 2.5) .. ")")
print()

-- Test 14: Multiplier Caps
print("Test: Multiplier Caps")
local score = cribbage.score(cards, 15.0, 10.0) -- Over caps
print("  Temp mult (capped at 10): " .. score.tempMultiplier)
print("  Perm mult (capped at 5): " .. score.permMultiplier)
print("  Final: " .. score.finalScore)
print()

print("========================================")
print("=== ALL TESTS COMPLETE ===")
print("========================================")
