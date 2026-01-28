-- TestJSONLoading.lua
-- Simple test to verify files.loadJSON works

print("\n=== Testing JSON Loading ===\n")

-- Test 1: Check if files module exists
print("Test 1: Check files module")
if files then
    print("✓ files module exists")
    print("  Type: " .. type(files))
else
    print("✗ files module NOT found")
    return
end

-- Test 2: Check if loadJSON function exists
print("\nTest 2: Check files.loadJSON function")
if files.loadJSON then
    print("✓ files.loadJSON exists")
    print("  Type: " .. type(files.loadJSON))
else
    print("✗ files.loadJSON NOT found")
    return
end

-- Test 3: Try loading achievements.json
print("\nTest 3: Load achievements.json")
local data = files.loadJSON("content/data/achievements.json")
if data then
    print("✓ JSON loaded successfully")
    if data.achievements then
        print("  Found 'achievements' array with " .. #data.achievements .. " items")
        
        -- Show first achievement
        if data.achievements[1] then
            local first = data.achievements[1]
            print("  First achievement:")
            print("    ID: " .. (first.id or "nil"))
            print("    Name: " .. (first.name or "nil"))
            print("    Category: " .. (first.category or "nil"))
        end
    else
        print("✗ No 'achievements' array in JSON")
    end
else
    print("✗ Failed to load JSON")
end

-- Test 4: Try loading a joker JSON
print("\nTest 4: Load a joker JSON (lucky_seven.json)")
local jokerData = files.loadJSON("content/data/jokers/lucky_seven.json")
if jokerData then
    print("✓ Joker JSON loaded")
    print("  Name: " .. (jokerData.name or "nil"))
    print("  Description: " .. (jokerData.description or "nil"))
else
    print("✗ Failed to load joker JSON")
end

print("\n=== JSON Loading Test Complete ===\n")
