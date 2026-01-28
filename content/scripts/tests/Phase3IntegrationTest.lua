-- Phase3IntegrationTest.lua
-- Test script to verify Phase 3 systems are properly integrated

local Phase3IntegrationTest = {}

function Phase3IntegrationTest.run()
    print("\n=== Phase 3 Integration Test ===\n")
    
    local passed = 0
    local failed = 0
    
    -- Test 1: Achievement System loaded
    print("Test 1: Achievement System")
    local MagicHandsAchievements = require("Systems/MagicHandsAchievements")
    if MagicHandsAchievements then
        print("✓ MagicHandsAchievements module loaded")
        passed = passed + 1
    else
        print("✗ Failed to load MagicHandsAchievements")
        failed = failed + 1
    end
    
    -- Test 2: Unlock System loaded
    print("\nTest 2: Unlock System")
    local UnlockSystem = require("Systems/UnlockSystem")
    if UnlockSystem then
        print("✓ UnlockSystem module loaded")
        passed = passed + 1
    else
        print("✗ Failed to load UnlockSystem")
        failed = failed + 1
    end
    
    -- Test 3: Undo System loaded
    print("\nTest 3: Undo System")
    local UndoSystem = require("Systems/UndoSystem")
    if UndoSystem then
        print("✓ UndoSystem module loaded")
        passed = passed + 1
    else
        print("✗ Failed to load UndoSystem")
        failed = failed + 1
    end
    
    -- Test 4: Collection UI loaded
    print("\nTest 4: Collection UI")
    local CollectionUI = require("UI/CollectionUI")
    if CollectionUI then
        print("✓ CollectionUI module loaded")
        passed = passed + 1
    else
        print("✗ Failed to load CollectionUI")
        failed = failed + 1
    end
    
    -- Test 5: Tier Indicator loaded
    print("\nTest 5: Tier Indicator")
    local TierIndicator = require("UI/TierIndicator")
    if TierIndicator then
        print("✓ TierIndicator module loaded")
        passed = passed + 1
    else
        print("✗ Failed to load TierIndicator")
        failed = failed + 1
    end
    
    -- Test 6: Score Preview loaded
    print("\nTest 6: Score Preview")
    local ScorePreview = require("UI/ScorePreview")
    if ScorePreview then
        print("✓ ScorePreview module loaded")
        passed = passed + 1
    else
        print("✗ Failed to load ScorePreview")
        failed = failed + 1
    end
    
    -- Test 7: Achievement Notification loaded
    print("\nTest 7: Achievement Notification")
    local AchievementNotification = require("UI/AchievementNotification")
    if AchievementNotification then
        print("✓ AchievementNotification module loaded")
        passed = passed + 1
    else
        print("✗ Failed to load AchievementNotification")
        failed = failed + 1
    end
    
    -- Test 8: Run Stats Panel loaded
    print("\nTest 8: Run Stats Panel")
    local RunStatsPanel = require("UI/RunStatsPanel")
    if RunStatsPanel then
        print("✓ RunStatsPanel module loaded")
        passed = passed + 1
    else
        print("✗ Failed to load RunStatsPanel")
        failed = failed + 1
    end
    
    -- Test 9: Achievements JSON loaded
    print("\nTest 9: Achievements Data")
    local achievementsData = files and files.loadJSON and files.loadJSON("content/data/achievements.json") or nil
    if achievementsData and achievementsData.achievements then
        print("✓ Achievements data loaded (" .. #achievementsData.achievements .. " achievements)")
        passed = passed + 1
    else
        print("✗ Failed to load achievements.json")
        failed = failed + 1
    end
    
    -- Test 10: Event system check
    print("\nTest 10: Event System")
    if events and events.emit and events.on then
        print("✓ Event system available")
        
        -- Test event emission
        local eventReceived = false
        events.on("test_event", function()
            eventReceived = true
        end)
        events.emit("test_event")
        
        if eventReceived then
            print("✓ Event emission working")
            passed = passed + 1
        else
            print("✗ Event emission failed")
            failed = failed + 1
        end
    else
        print("✗ Event system not available")
        failed = failed + 1
    end
    
    -- Summary
    print("\n=== Test Results ===")
    print("Passed: " .. passed)
    print("Failed: " .. failed)
    print("Total:  " .. (passed + failed))
    
    if failed == 0 then
        print("\n✓ All Phase 3 systems integrated successfully!")
    else
        print("\n✗ Some systems failed to integrate")
    end
    
    return failed == 0
end

return Phase3IntegrationTest
