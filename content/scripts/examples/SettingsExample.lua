-- SettingsExample.lua
-- Example showing how to integrate SettingsUI into your game

local SettingsUI = require("UI.SettingsUI")
local UILayout = require("UI.UILayout")

SettingsExample = {}

-- Global settings instance
local settingsMenu = nil
local font = nil

function SettingsExample.init()
    -- Load font (assuming UI_FONT is already loaded)
    font = "UI_FONT"
    
    -- Create layout system
    local layout = UILayout()
    layout:init()
    
    -- Create settings menu
    settingsMenu = SettingsUI(font, layout)
    
    log.info("Settings menu initialized")
    log.info("Press F1 or Select (controller) to open settings")
end

function SettingsExample.update(dt)
    -- Check if settings should be opened
    if inputmgr.isActionJustPressed("open_settings") then
        if not settingsMenu.active then
            settingsMenu:open()
        else
            settingsMenu:close()
        end
    end
    
    -- Update settings menu
    local mx, my = inputmgr.getCursor()
    local clicked = inputmgr.isActionJustPressed("confirm")
    
    local result = settingsMenu:update(dt, mx, my, clicked)
    if result and result.action == "close" then
        -- Settings closed
        log.info("Settings menu closed by user")
    end
end

function SettingsExample.draw()
    -- Draw settings menu
    settingsMenu:draw()
end

-- Run the test
function SettingsExample.runTest()
    log.info("=== Settings Menu Test ===")
    
    -- Initialize
    SettingsExample.init()
    
    -- Simulate opening settings
    settingsMenu:open()
    
    log.info("Settings menu is now open")
    log.info("You should see:")
    log.info("  - Theme switcher (Default/Colorblind)")
    log.info("  - UI scale selector (75%, 100%, 125%, 150%, Auto)")
    log.info("  - Controller status")
    log.info("  - Close button")
    
    log.info("\nTo test in-game:")
    log.info("1. Add SettingsExample.init() to your game init")
    log.info("2. Add SettingsExample.update(dt) to your game update")
    log.info("3. Add SettingsExample.draw() to your game draw")
    log.info("4. Press F1 to open settings!")
end

-- Example integration into main game loop:
--[[

-- In your main game file:

local SettingsUI = require("UI.SettingsUI")
local UILayout = require("UI.UILayout")

-- Global variable
local settingsMenu = nil

function Game.init()
    -- ... your existing init code ...
    
    -- Initialize settings menu
    local layout = UILayout()
    layout:init()
    settingsMenu = SettingsUI("UI_FONT", layout)
    
    log.info("Press F1 to open Settings")
end

function Game.update(dt)
    -- Check for settings hotkey
    if inputmgr.isActionJustPressed("open_settings") then
        if not settingsMenu.active then
            settingsMenu:open()
        end
    end
    
    -- Update settings if active
    if settingsMenu.active then
        local mx, my = inputmgr.getCursor()
        local clicked = inputmgr.isActionJustPressed("confirm")
        settingsMenu:update(dt, mx, my, clicked)
        return  -- Don't update game while settings are open
    end
    
    -- ... your existing game update code ...
end

function Game.draw()
    -- ... your existing game draw code ...
    
    -- Draw settings menu on top
    settingsMenu:draw()
end

]]--

return SettingsExample
