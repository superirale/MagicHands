-- AutoPlay.lua
-- Main QA Bot Controller

local AutoPlayStrategies = require("Systems/AutoPlayStrategies")
local AutoPlayStats = require("Systems/AutoPlayStats")
local AutoPlayErrors = require("Systems/AutoPlayErrors")

local AutoPlay = {
    enabled = false,
    currentRun = 1,
    totalRuns = 100,
    strategy = nil,
    stats = nil,
    errors = nil,
    outputDir = "qa_results/",
    runStartTime = 0,
    stateTimer = 0,  -- Timer for state transitions
    waitTime = 0.1   -- Time to wait between actions (turbo mode)
}

function AutoPlay:init(totalRuns, strategyName)
    print("=================================================")
    print("===    Magic Hands QA AutoPlay Bot v1.0      ===")
    print("=================================================")
    print("Total Runs: " .. tostring(totalRuns))
    print("Strategy: " .. (strategyName or "Random"))
    print("=================================================")
    
    self.enabled = true
    self.totalRuns = totalRuns or 100
    self.currentRun = 1
    
    -- Initialize subsystems
    self.strategy = AutoPlayStrategies:getStrategy(strategyName or "Random")
    self.stats = AutoPlayStats
    self.errors = AutoPlayErrors
    
    -- Initialize error tracking
    self.errors:init()
    
    -- Subscribe to game events (events is a global C++ binding)
    if events and events.on then
        events.on("hand_scored", function(data)
            self:onHandScored(data)
        end)
        events.on("blind_won", function(data)
            self:onBlindWon(data)
        end)
        events.on("shop_purchase", function(data)
            self:onShopPurchase(data)
        end)
        print("AutoPlay: Subscribed to game events")
    else
        print("WARNING: EventSystem not available, stats may be incomplete")
    end
    
    -- Create output directory (will fail silently if mkdir not available)
    pcall(function()
        if os.execute then
            os.execute("mkdir -p " .. self.outputDir .. "screenshots")
        end
    end)
    
    -- Start first run
    self:startRun()
end

function AutoPlay:startRun()
    print("\n")
    print("╔════════════════════════════════════════════╗")
    print(string.format("║  Starting Run %d / %d", self.currentRun, self.totalRuns))
    print("╚════════════════════════════════════════════╝")
    
    -- Initialize stats for this run
    self.stats:init()
    self.stats.currentRun.runId = string.format("run_%s_%03d", 
        os.date("%Y%m%d_%H%M%S"), self.currentRun)
    self.stats.currentRun.strategy = self.strategy.name
    
    -- Reset errors
    self.errors:reset()
    
    self.runStartTime = os.clock()
    self.stateTimer = 0
    
    print("Run ID: " .. self.stats.currentRun.runId)
    print("Strategy: " .. self.strategy.name)
end

function AutoPlay:update(gameScene, dt)
    if not self.enabled then return end
    
    -- Update cooldowns
    if self.playPhaseCooldown and self.playPhaseCooldown > 0 then
        self.playPhaseCooldown = self.playPhaseCooldown - dt
        if self.playPhaseCooldown < 0 then
            self.playPhaseCooldown = 0
        end
    end
    
    -- Debug: Print state every second
    self.debugTimer = (self.debugTimer or 0) + dt
    if self.debugTimer > 1.0 then
        print("AutoPlay: State = " .. (gameScene.state or "nil"))
        self.debugTimer = 0
    end
    
    -- Update state timer
    self.stateTimer = self.stateTimer + dt
    
    -- Record frame time for performance tracking
    self.stats:recordFrameTime(dt * 1000)
    
    -- Check for performance issues
    self.errors:checkPerformance(dt)
    
    -- Check game state for logic errors
    if gameScene then
        local Economy = require("criblage/Economy")
        local CampaignState = require("criblage/CampaignState")
        
        self.errors:checkGameState({
            gold = Economy.gold or 0,
            handsRemaining = CampaignState.handsRemaining or 0,
            discardsRemaining = CampaignState.discardsRemaining or 0,
            hand = gameScene.hand or {},
            currentScore = CampaignState.currentScore or 0
        })
    end
    
    -- Only make decisions if enough time has passed (turbo mode wait)
    if self.stateTimer < self.waitTime then
        return
    end
    
    -- Reset timer for next action
    self.stateTimer = 0
    
    -- Delegate to state-specific handlers
    if not gameScene then return end
    
    local state = gameScene.state
    
    if state == "DEAL" then
        self:handleDealPhase(gameScene)
    elseif state == "PLAY" then
        self:handlePlayPhase(gameScene)
    elseif state == "SHOP" then
        self:handleShopPhase(gameScene)
    elseif state == "BLIND_PREVIEW" then
        self:handleBlindPreview(gameScene)
    elseif state == "GAME_OVER" then
        self:handleGameOver(gameScene)
    end
end

function AutoPlay:handleDealPhase(gameScene)
    local CampaignState = require("criblage/CampaignState")
    
    -- Check if we need to add cards to crib
    if #CampaignState.crib < 2 then
        -- Strategy: Select cards for crib (2 cards)
        local cribIndices = self.strategy:selectCardsForCrib(gameScene.hand)
        
        if cribIndices and #cribIndices > 0 then
            -- Clear all selections first
            for _, view in ipairs(gameScene.cardViews) do
                view.selected = false
            end
            
            -- Select cards for crib
            for _, idx in ipairs(cribIndices) do
                if idx <= #gameScene.cardViews then
                    gameScene.cardViews[idx].selected = true
                end
            end
            
            self.stats:recordDecision("crib_selection",
                gameScene.hand,
                cribIndices,
                "Discarded to crib")
            
            -- Actually add to crib using GameScene method
            gameScene:addSelectedCardsToCrib()
            
            print("Bot added " .. #cribIndices .. " card(s) to crib")
        end
    else
        -- Crib is full, transition to PLAY
        gameScene.state = "PLAY"
        print("Bot: Crib full, moving to PLAY phase")
    end
end

function AutoPlay:handlePlayPhase(gameScene)
    -- Wait for hand to be ready
    if not gameScene.hand or #gameScene.hand < 4 then
        return
    end
    
    -- Cooldown to prevent spamming (wait 0.5s between plays)
    self.playPhaseCooldown = self.playPhaseCooldown or 0
    if self.playPhaseCooldown > 0 then
        return
    end
    
    -- Strategy: Select 4 cards to play
    local playIndices = self.strategy:selectCardsToPlay(gameScene.hand)
    
    if not playIndices or #playIndices ~= 4 then
        print("ERROR: Strategy must return exactly 4 cards to play!")
        return
    end
    
    -- Clear all selections first
    for _, view in ipairs(gameScene.cardViews) do
        view.selected = false
    end
    
    -- Select the 4 cards to play
    for _, idx in ipairs(playIndices) do
        if idx <= #gameScene.cardViews then
            gameScene.cardViews[idx].selected = true
        end
    end
    
    self.stats:recordDecision("card_selection",
        gameScene.hand,
        playIndices,
        "Strategy: " .. self.strategy.name)
    
    print("Bot playing " .. #playIndices .. " cards")
    
    -- Actually play the hand using GameScene method
    gameScene:playHand()
    
    -- Set cooldown to prevent immediate replay
    self.playPhaseCooldown = 0.5  -- Wait 0.5 seconds
end

function AutoPlay:handleShopPhase(gameScene)
    local Shop = require("criblage/Shop")
    local Economy = require("criblage/Economy")
    
    local shopItems = Shop.jokers or {}
    local gold = Economy.gold or 0
    
    print(string.format("Bot in shop: %d gold, %d items available", gold, #shopItems))
    
    -- Strategy: Decide whether to reroll
    local shouldReroll = self.strategy:shouldReroll(gold, shopItems)
    
    if shouldReroll and gold >= Shop.shopRerollCost then
        self.stats:recordDecision("shop_reroll", {}, true, "Strategy wanted different items")
        self.stats:recordReroll()
        Shop:reroll()
        print("Bot rerolled shop")
        return
    end
    
    -- Strategy: Select item to buy
    local itemIndex = self.strategy:selectShopItem(shopItems, gold)
    
    if itemIndex and shopItems[itemIndex] then
        local item = shopItems[itemIndex]
        
        -- Check if we can afford it
        if gold >= item.price then
            self.stats:recordDecision("shop_purchase", shopItems, itemIndex, 
                "Bought: " .. (item.name or item.id or "unknown"))
            
            -- Actually purchase the item
            local success, msg = Shop:buyJoker(itemIndex)
            
            if success then
                -- Track purchase in stats
                if item.type == "joker" then
                    self.stats:recordJokerAcquired(item.id, item.price)
                elseif item.type == "enhancement" then
                    if string.find(item.id, "planet") then
                        self.stats:recordPlanetAcquired(item.id, item.price)
                    elseif string.find(item.id, "spectral") or string.find(item.id, "warp") then
                        self.stats:recordWarpActivated(item.id)
                    end
                end
                
                print("Bot purchased: " .. (item.id or "unknown") .. " for " .. item.price .. "g")
            else
                print("Bot failed to purchase: " .. tostring(msg))
            end
            
            return
        else
            print("Bot cannot afford item (need " .. item.price .. "g, have " .. gold .. "g)")
        end
    end
    
    -- No purchase or can't afford, exit shop
    self.stats:recordDecision("shop_skip", {}, nil, "Nothing affordable or wanted")
    print("Bot leaving shop")
    
    -- Transition to next blind
    gameScene.state = "BLIND_PREVIEW"
end

function AutoPlay:handleBlindPreview(gameScene)
    -- Auto-advance to next blind
    print("Bot advancing to next blind")
    gameScene.state = "DEAL"
    
    local CampaignState = require("criblage/CampaignState")
    CampaignState:startNewBlind()
end

function AutoPlay:handleGameOver(gameScene)
    local CampaignState = require("criblage/CampaignState")
    
    -- Determine outcome
    local outcome = "loss"
    
    -- Check if won (cleared all acts)
    if CampaignState.currentAct > 3 then
        outcome = "win"
    end
    
    print("\n")
    print("╔════════════════════════════════════════════╗")
    print(string.format("║  Run %d Complete: %s", self.currentRun, string.upper(outcome)))
    print("╚════════════════════════════════════════════╝")
    
    self:finishRun(outcome)
end

function AutoPlay:finishRun(outcome)
    local CampaignState = require("criblage/CampaignState")
    
    -- Finalize stats
    local runData = self.stats:finalize(
        outcome,
        CampaignState.currentAct or 1,
        CampaignState.currentBlind or 1,
        CampaignState.currentScore or 0
    )
    
    -- Merge error data
    local errorSummary = self.errors:getSummary()
    runData.errors = errorSummary.errors
    runData.warnings = errorSummary.warnings
    runData.logicErrors = errorSummary.logicErrors
    
    -- Print summary
    print("\nRun Summary:")
    print("  Outcome: " .. outcome)
    print("  Act Reached: " .. runData.actReached)
    print("  Blind Reached: " .. runData.blindReached)
    print("  Final Score: " .. runData.finalScore)
    print("  Hands Played: " .. runData.handsPlayed)
    print("  Best Hand: " .. runData.bestHandScore)
    print("  Errors: " .. #runData.errors)
    print("  Warnings: " .. #runData.warnings)
    print("  Duration: " .. runData.durationSeconds .. "s")
    
    -- Save run data
    self:saveRunData(runData)
    
    -- Take final screenshot if available
    if graphics and graphics.saveScreenshot then
        local screenshotPath = self.outputDir .. "screenshots/" .. 
                               runData.runId .. "_final.png"
        pcall(function()
            graphics.saveScreenshot(screenshotPath)
            print("  Screenshot: " .. screenshotPath)
        end)
    end
    
    -- Check if more runs needed
    self.currentRun = self.currentRun + 1
    
    if self.currentRun <= self.totalRuns then
        -- Start next run
        self:startRun()
        
        -- Reset game state (this should reload the scene)
        -- Note: GameScene integration will handle this
        print("\nRestarting for next run...")
    else
        -- All runs complete
        self:generateSummary()
        self:shutdown()
    end
end

function AutoPlay:saveRunData(runData)
    local filename = self.outputDir .. runData.runId .. ".json"
    
    -- Convert to JSON string
    local jsonString = self:toJSON(runData)
    
    -- Save to file if files module is available
    if files and files.saveFile then
        local success, err = pcall(function()
            files.saveFile(filename, jsonString)
        end)
        
        if success then
            print("  Saved: " .. filename)
        else
            print("  ERROR saving run data: " .. tostring(err))
        end
    else
        print("  WARNING: files.saveFile not available, run data not saved")
    end
end

-- Simple JSON serializer
function AutoPlay:toJSON(tbl, indent)
    indent = indent or 0
    local padding = string.rep("  ", indent)
    
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then
            return "\"" .. tbl:gsub("\"", "\\\"") .. "\""
        elseif type(tbl) == "number" or type(tbl) == "boolean" then
            return tostring(tbl)
        else
            return "null"
        end
    end
    
    local result = "{\n"
    local first = true
    
    for k, v in pairs(tbl) do
        if not first then result = result .. ",\n" end
        first = false
        
        result = result .. padding .. "  \"" .. tostring(k) .. "\": "
        
        if type(v) == "table" then
            result = result .. self:toJSON(v, indent + 1)
        else
            result = result .. self:toJSON(v, indent)
        end
    end
    
    result = result .. "\n" .. padding .. "}"
    return result
end

function AutoPlay:generateSummary()
    print("\n")
    print("╔════════════════════════════════════════════╗")
    print("║     All Runs Complete - Generating        ║")
    print("║            Summary Report                  ║")
    print("╚════════════════════════════════════════════╝")
    
    print("\nTotal Runs: " .. self.totalRuns)
    print("Results saved to: " .. self.outputDir)
    print("\nUse analysis tools to parse results:")
    print("  python tools/qa_analysis/analyze_runs.py " .. self.outputDir)
end

function AutoPlay:shutdown()
    self.enabled = false
    
    -- Cleanup
    if self.errors then
        self.errors:destroy()
    end
    
    print("\n")
    print("╔════════════════════════════════════════════╗")
    print("║      AutoPlay QA Bot Shutdown Complete    ║")
    print("╚════════════════════════════════════════════╝")
    
    -- Signal to C++ main loop that we're done
    _G.AUTOPLAY_QUIT = true
    
    -- Also try os.exit as fallback
    if os and os.exit then
        os.exit(0)
    end
end

-- Event handlers (called by GameScene)
function AutoPlay:onHandScored(data)
    if not self.enabled then return end
    
    print("AutoPlay: onHandScored called with score=" .. tostring(data.score))
    
    self.stats:recordHandScored(
        data.handNum or self.stats.currentRun.handsPlayed + 1,
        data.score or 0,
        data.breakdown or {}
    )
    
    print(string.format("Hand #%d scored: %d points", 
        self.stats.currentRun.handsPlayed, data.score or 0))
end

function AutoPlay:onBlindWon(data)
    if not self.enabled then return end
    
    print("Blind cleared!")
end

function AutoPlay:onShopPurchase(data)
    if not self.enabled then return end
    
    print(string.format("AutoPlay: Shop purchase detected - %s (%s) for %dg", 
        data.id or "unknown",
        data.type or "unknown",
        data.price or 0))
    
    -- Stats are already recorded in handleShopPhase, this is just for logging
end

function AutoPlay:onError(errorData)
    if not self.enabled then return end
    
    -- Take screenshot on error if available
    if graphics and graphics.saveScreenshot then
        local screenshotPath = self.outputDir .. "screenshots/error_" .. 
                               os.time() .. ".png"
        pcall(function()
            graphics.saveScreenshot(screenshotPath)
        end)
    end
end

return AutoPlay
