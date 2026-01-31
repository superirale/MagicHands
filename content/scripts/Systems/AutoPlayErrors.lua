-- AutoPlayErrors.lua
-- Error detection and capture system for QA bot

local AutoPlayErrors = {
    errors = {},
    warnings = {},
    logicErrors = {},
    performanceIssues = {},
    originalPrint = nil,
    enabled = false
}

function AutoPlayErrors:init()
    print("AutoPlayErrors: Initializing error capture...")
    
    self.errors = {}
    self.warnings = {}
    logicErrors = {}
    self.performanceIssues = {}
    self.enabled = true
    
    -- Store original print function
    self.originalPrint = _G.print
    
    -- TODO: Print wrapping disabled due to recursion issues when GameScene reinitializes
    -- Will rely on Lua error detection from C++ instead
    
    self.originalPrint("AutoPlayErrors: Initialization complete")
end

-- Wrap a function to catch Lua errors
function AutoPlayErrors:wrapFunction(fn, name)
    return function(...)
        local success, result = pcall(fn, ...)
        if not success then
            table.insert(self.errors, {
                time = os.time(),
                type = "lua_error",
                function_name = name or "unknown",
                message = tostring(result),
                stack = debug.traceback()
            })
            print("ERROR: Lua error in " .. (name or "function") .. ": " .. tostring(result))
        end
        return success, result
    end
end

-- Check game state for logic errors
function AutoPlayErrors:checkGameState(gameState)
    if not self.enabled then return end
    
    local issues = {}
    
    -- Check for negative values
    if gameState.gold and gameState.gold < 0 then
        table.insert(issues, "Negative gold: " .. tostring(gameState.gold))
    end
    
    if gameState.handsRemaining and gameState.handsRemaining < 0 then
        table.insert(issues, "Negative hands: " .. tostring(gameState.handsRemaining))
    end
    
    if gameState.discardsRemaining and gameState.discardsRemaining < 0 then
        table.insert(issues, "Negative discards: " .. tostring(gameState.discardsRemaining))
    end
    
    -- Check for invalid hand sizes
    -- Allow up to 9 cards on the very first hand of blind 1 (starting advantage bonus)
    local maxHandSize = 6
    local CampaignState = require("criblage/CampaignState")
    if CampaignState.currentBlind == 1 and CampaignState.handsRemaining == 4 and 
       CampaignState.firstBlindHandBonus > 0 then
        maxHandSize = 6 + CampaignState.firstBlindHandBonus
    end
    
    if gameState.hand and #gameState.hand > maxHandSize then
        table.insert(issues, "Too many cards in hand: " .. tostring(#gameState.hand) .. " (max: " .. maxHandSize .. ")")
    end
    
    if gameState.hand and #gameState.hand < 0 then
        table.insert(issues, "Invalid hand size: " .. tostring(#gameState.hand))
    end
    
    -- Record any issues found
    if #issues > 0 then
        for _, issue in ipairs(issues) do
            table.insert(self.logicErrors, {
                time = os.time(),
                issue = issue,
                gameState = self:captureState(gameState)
            })
            print("ERROR: Logic error detected: " .. issue)
        end
    end
end

-- Capture current game state for error reporting
function AutoPlayErrors:captureState(gameState)
    local state = {}
    
    -- Safely copy game state fields
    if gameState then
        state.gold = gameState.gold
        state.handsRemaining = gameState.handsRemaining
        state.discardsRemaining = gameState.discardsRemaining
        state.currentScore = gameState.currentScore
        state.handSize = gameState.hand and #gameState.hand or 0
    end
    
    return state
end

-- Check for performance issues
function AutoPlayErrors:checkPerformance(frameTime)
    if not self.enabled then return end
    
    -- Frame time in milliseconds
    local frameTimeMs = frameTime * 1000
    
    -- Flag if frame time exceeds 33ms (below 30 FPS)
    if frameTimeMs > 33 then
        table.insert(self.performanceIssues, {
            time = os.time(),
            frameTimeMs = frameTimeMs,
            severity = frameTimeMs > 100 and "critical" or "warning"
        })
    end
end

-- Get summary of all errors
function AutoPlayErrors:getSummary()
    return {
        totalErrors = #self.errors,
        totalWarnings = #self.warnings,
        totalLogicErrors = #self.logicErrors,
        totalPerformanceIssues = #self.performanceIssues,
        errors = self.errors,
        warnings = self.warnings,
        logicErrors = self.logicErrors,
        performanceIssues = self.performanceIssues
    }
end

-- Reset error tracking
function AutoPlayErrors:reset()
    self.errors = {}
    self.warnings = {}
    self.logicErrors = {}
    self.performanceIssues = {}
end

-- Cleanup
function AutoPlayErrors:destroy()
    self.enabled = false
    
    -- Restore original print
    if self.originalPrint then
        print = self.originalPrint
    end
end

return AutoPlayErrors
