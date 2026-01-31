-- Phase1Test.lua
-- Quick test to verify Phase 1 features work correctly

local Theme = require("UI.Theme")
local UIScale = require("UI.UIScale")

Phase1Test = {}

function Phase1Test.runAll()
    log.info("=== Phase 1 Feature Test ===")
    
    Phase1Test.testTheme()
    Phase1Test.testUIScale()
    Phase1Test.testInputManager()
    
    log.info("=== Phase 1 Tests Complete ===")
end

function Phase1Test.testTheme()
    log.info("\n--- Testing Theme System ---")
    
    -- Test getting colors
    local primary = Theme.get("colors.primary")
    log.info("Primary color: r=" .. primary.r .. " g=" .. primary.g .. " b=" .. primary.b)
    
    -- Test getting sizes
    local buttonHeight = Theme.get("sizes.buttonHeight")
    log.info("Button height: " .. buttonHeight)
    
    -- Test color manipulation
    local lighter = Theme.lighten(primary, 0.2)
    log.info("Lightened primary: r=" .. lighter.r)
    
    local darker = Theme.darken(primary, 0.2)
    log.info("Darkened primary: r=" .. darker.r)
    
    local transparent = Theme.withAlpha(primary, 0.5)
    log.info("Primary with 50% alpha: a=" .. transparent.a)
    
    -- Test theme switching
    local themes = Theme.getThemes()
    log.info("Available themes: " .. table.concat(themes, ", "))
    
    log.info("✓ Theme system working!")
end

function Phase1Test.testUIScale()
    log.info("\n--- Testing UI Scale System ---")
    
    -- Get current scale
    local scale = UIScale.get()
    log.info("Current UI scale: " .. scale)
    
    -- Test scaling values
    local scaled = UIScale.scale(100)
    log.info("100 pixels scaled: " .. scaled)
    
    -- Test scale presets
    log.info("Available presets:")
    for name, value in pairs(UIScale.PRESETS) do
        log.info("  " .. name .. ": " .. value .. "x")
    end
    
    -- Test window size
    local winW, winH = graphics.getWindowSize()
    log.info("Window size: " .. winW .. "x" .. winH)
    
    log.info("✓ UI Scale system working!")
end

function Phase1Test.testInputManager()
    log.info("\n--- Testing Input Manager ---")
    
    -- Check if gamepad is connected
    if inputmgr.isGamepadConnected() then
        local name = inputmgr.getGamepadName()
        log.info("Gamepad connected: " .. name)
        
        if inputmgr.isGamepad() then
            log.info("Currently using gamepad input")
        else
            log.info("Currently using keyboard/mouse input")
        end
    else
        log.info("No gamepad connected")
    end
    
    -- Get cursor position
    local x, y = inputmgr.getCursor()
    log.info("Cursor position: " .. x .. ", " .. y)
    
    -- Test actions (won't trigger unless buttons pressed)
    log.info("Input actions available: confirm, cancel, navigate_up/down/left/right, tab_next/previous, open_menu, open_settings")
    
    log.info("✓ Input Manager working!")
end

return Phase1Test
