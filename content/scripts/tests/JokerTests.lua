-- Joker Unit Tests
local tests = {}

function tests.run()
    print("=== RUNNING JOKER UNIT TESTS ===")
    local pass = 0
    local fail = 0

    local function assertEq(name, actual, expected)
        if actual == expected then
            print("[PASS] " .. name .. ": " .. actual)
            pass = pass + 1
        else
            print("[FAIL] " .. name .. ": Expected " .. expected .. ", Got " .. actual)
            fail = fail + 1
        end
    end

    -- Test 1: Lucky Seven (7, 7, 5, 5, Q) -> 2 Sevens
    local hand1 = {
        Card.new("7", "Hearts"),
        Card.new("7", "Spades"),
        Card.new("5", "Hearts"),
        Card.new("5", "Clubs"),
        Card.new("Queen", "Clubs") -- Cut card at index 5
    }
    local res1 = joker.applyEffects({ "content/data/jokers/lucky_seven.json" }, hand1, "on_score")
    -- Expect +14 Mult (2 sevens * 7 mult)
    assertEq("Lucky Seven Mult", res1.addedTempMult, 14.0)

    -- Test 2: Ace in Hole (A, K, Q, J, 10) -> 1 Ace
    local hand2 = {
        Card.new("Ace", "Spades"),
        Card.new("King", "Hearts"),
        Card.new("Queen", "Hearts"),
        Card.new("Jack", "Hearts"),
        Card.new("10", "Hearts")
    }
    local res2 = joker.applyEffects({ "content/data/jokers/ace_in_hole.json" }, hand2, "on_score")
    -- Expect +80 Chips
    assertEq("Ace in Hole Chips", res2.addedChips, 80)

    -- Test 3: Even Stevens (2, 4, 6, 8, 10) -> 5 Evens
    local hand3 = {
        Card.new("2", "Spades"),
        Card.new("4", "Hearts"),
        Card.new("6", "Clubs"),
        Card.new("8", "Diamonds"),
        Card.new("10", "Spades")
    }
    local res3 = joker.applyEffects({ "content/data/jokers/even_stevens.json" }, hand3, "on_score")
    -- Expect 5 * 4 = 20 Chips
    assertEq("Even Stevens Chips", res3.addedChips, 20)

    -- Test 4: Face Card Fan (K, Q, J, 10, 9) -> 3 Faces (K, Q, J)
    local hand4 = {
        Card.new("King", "Hearts"),
        Card.new("Queen", "Spades"),
        Card.new("Jack", "Diamonds"),
        Card.new("10", "Clubs"),
        Card.new("9", "Hearts")
    }
    local res4 = joker.applyEffects({ "content/data/jokers/face_card_fan.json" }, hand4, "on_score")
    -- Expect 3 * 15 = 45 Chips
    assertEq("Face Card Fan Chips", res4.addedChips, 45)

    -- Test 5: Big Hand (5 cards always) -> +20 chips * 5 = +100
    local res5 = joker.applyEffects({ "content/data/jokers/big_hand.json" }, hand4, "on_score")
    assertEq("Big Hand Chips", res5.addedChips, 100)

    -- Test 6: Combo King (Needs 3+ categories)
    -- Hand: 5H, 5C, 5D, 7H, 7C
    -- 15s: 5+5+5=15. (Multiple 15s). Cat 1.
    -- Pairs: 5-5, 7-7. Cat 2.
    -- Runs: No?
    -- Flush: No.
    -- Nobs: No.
    -- Maybe combine pair + run + 15.
    -- Hand: 4, 5, 6, 4, 5.
    -- 15s: 4+5+6=15. Yes.
    -- Run: 4,5,6. Yes.
    -- Pairs: 4-4, 5-5. Yes.
    -- Categories: Fifteens, Pairs, Runs. = 3.
    local hand6 = {
        Card.new("4", "Hearts"),
        Card.new("5", "Clubs"),
        Card.new("6", "Diamonds"),
        Card.new("4", "Spades"),
        Card.new("5", "Hearts")
    }
    local res6 = joker.applyEffects({ "content/data/jokers/combo_king.json" }, hand6, "on_score")
    -- Expect 100 Chips
    assertEq("Combo King Chips", res6.addedChips, 100)

    -- Test 7: The Trio (3 of a kind -> 3 pairs)
    -- Hand6 has pairs 4-4 and 5-5. (2 pairs).
    -- Need 3 of kind. 7, 7, 7, K, A.
    local hand7 = {
        Card.new("7", "Hearts"),
        Card.new("7", "Clubs"),
        Card.new("7", "Diamonds"),
        Card.new("King", "Spades"),
        Card.new("Ace", "Hearts")
    }
    local res7 = joker.applyEffects({ "content/data/jokers/the_trio.json" }, hand7, "on_score")
    assertEq("The Trio Chips", res7.addedChips, 150)

    -- Test 8: Blackjack (Sum 21)
    -- 5, 4, 4, 4, 4 -> 21
    local hand8 = {
        Card.new("5", "Hearts"),
        Card.new("4", "Clubs"),
        Card.new("4", "Diamonds"),
        Card.new("4", "Spades"),
        Card.new("4", "Hearts")
    }
    -- Wait, duplicate cards allowed in test?
    -- C++ HandEvaluator checks pairs by index, doesn't validate uniqueness.
    -- But 4 suits of 4 exist. So valid.
    -- 5+16 = 21.
    local res8 = joker.applyEffects({ "content/data/jokers/blackjack.json" }, hand8, "on_score")
    -- Expect +5 Mult
    assertEq("Blackjack Mult", res8.addedTempMult, 5.0)

    -- Test 9: Boss "The Counter" (15s disabled)
    -- Hand: 7, 8 (15).
    local hand9 = {
        Card.new("7", "Hearts"),
        Card.new("8", "Spades"),
        Card.new("A", "Clubs"),
        Card.new("2", "Diamonds"),
        Card.new("3", "Spades")
    }
    local bossRules = { "fifteens_disabled" }
    -- Use 0 mults
    local score9 = cribbage.score(hand9, 0, 0, bossRules)
    assertEq("Boss 15s Should be 0", score9.fifteenChips, 0)
    -- Verify 15s WOULD exist otherwise (7+8=15)
    local score9_normal = cribbage.score(hand9, 0, 0, {})
    assertEq("Normal 15s Should be 10", score9_normal.fifteenChips, 10) -- 10 chips per 15
    -- Formula: 15s score 2 POINTS. In my engine:
    -- GDD: "Fifteens: 10 chips per combination".
    -- So 7+8 is ONE combination. 10 chips.
    assertEq("Normal 15s Chips", score9_normal.fifteenChips, 10)

    print("=== TESTS COMPLETE: " .. pass .. " PASSED, " .. fail .. " FAILED ===")
end

return tests
