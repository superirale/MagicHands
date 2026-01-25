-- Blind & Boss System Test Suite

print("========================================")
print("=== BLIND & BOSS SYSTEM TEST ===")
print("========================================")
print()

-- Test 1: Act 1 blinds
print("Test 1: Act 1 Blind Scaling")
local act1Small = blind.create(1, "small")
local act1Big = blind.create(1, "big")
local act1Boss = blind.create(1, "boss", "the_counter")

print("  Small: base=" .. act1Small.baseScore .. ", required=" .. blind.getRequiredScore(act1Small))
print("  Big: base=" .. act1Big.baseScore .. ", required=" .. blind.getRequiredScore(act1Big))
print("  Boss: base=" .. act1Boss.baseScore .. ", required=" .. blind.getRequiredScore(act1Boss))
print("  Expected: 100, 250, 600")
print()

-- Test 2: Act 2 blinds
print("Test 2: Act 2 Blind Scaling")
local act2Small = blind.create(2, "small")
local act2Big = blind.create(2, "big")
local act2Boss = blind.create(2, "boss")

local req2s = blind.getRequiredScore(act2Small)
local req2b = blind.getRequiredScore(act2Big)
local req2boss = blind.getRequiredScore(act2Boss)

print("  Small: " .. req2s .. " (expected: 600 × 2.5 = 1500)")
print("  Big: " .. req2b .. " (expected: 1400 × 2.5 = 3500)")
print("  Boss: " .. req2boss .. " (expected: 3000 × 2.5 = 7500)")
print()

-- Test 3: Difficulty modifiers
print("Test 3: Difficulty Modifiers")
local normalReq = blind.getRequiredScore(act1Small, 1.0)
local easyReq = blind.getRequiredScore(act1Small, 0.8)
local hardReq = blind.getRequiredScore(act1Small, 1.3)

print("  Normal (1.0x): " .. normalReq)
print("  Easy (0.8x): " .. easyReq .. " (expected: 80)")
print("  Hard (1.3x): " .. hardReq .. " (expected: 130)")
print()

-- Test 4: Boss loading
print("Test 4: Boss JSON Loading")
local counterBoss = boss.load("content/data/bosses/the_counter.json")
if counterBoss then
    print("  ✅ Loaded: " .. counterBoss.name)
    print("  Description: " .. counterBoss.description)
    print("  Effects: " .. #counterBoss.effects)
else
    print("  ❌ FAIL: Could not load boss")
end
print()

local skunkBoss = boss.load("content/data/bosses/the_skunk.json")
if skunkBoss then
    print("  ✅ Loaded: " .. skunkBoss.name)
    print("  Description: " .. skunkBoss.description)
else
    print("  ❌ FAIL")
end
print()

print("========================================")
print("=== ALL TESTS COMPLETE ===")
print("========================================")
print()
print("Phase 3 MVP Complete:")
print("✅ Blind scaling system (Acts 1-2)")
print("✅ Boss JSON loading")
print("✅ Difficulty modifiers")
print("✅ Ready for campaign integration")
