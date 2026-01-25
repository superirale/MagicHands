-- Test script for Criblage card system

print("=== Testing Card System ===")

-- Test 1: Create a single card
local card = Card.new("Ace", "Spades")
print("Created card: " .. card:toString())
print("Card value: " .. card:getValue())
print("Card rank: " .. card:getRank())
print("Card suit: " .. card:getSuit())
print()

-- Test 2: Create a deck with seeded RNG
local seed = 12345
local deck = Deck.new(seed)
print("Created deck with seed: " .. seed)
print("Deck size: " .. deck:getSize())
print()

-- Test 3: Shuffle the deck
deck:shuffle()
print("Shuffled deck")
print()

-- Test 4: Draw a hand of 4 cards
print("Drawing 4 cards:")
local hand = deck:drawMultiple(4)
for i, card in ipairs(hand) do
    print("  " .. i .. ": " .. card:toString() .. " (value: " .. card:getValue() .. ")")
end
print("Deck size after draw: " .. deck:getSize())
print()

-- Test 5: Test cribbage values
print("Testing Cribbage values:")
local ace = Card.new("Ace", "Hearts")
local five = Card.new("5", "Diamonds")
local ten = Card.new("10", "Clubs")
local jack = Card.new("Jack", "Spades")
local queen = Card.new("Queen", "Hearts")
local king = Card.new("King", "Diamonds")

print("Ace value: " .. ace:getValue() .. " (expected: 1)")
print("5 value: " .. five:getValue() .. " (expected: 5)")
print("10 value: " .. ten:getValue() .. " (expected: 10)")
print("Jack value: " .. jack:getValue() .. " (expected: 10)")
print("Queen value: " .. queen:getValue() .. " (expected: 10)")
print("King value: " .. king:getValue() .. " (expected: 10)")
print()

print("=== Card System Test Complete ===")
