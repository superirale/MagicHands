-- UI.lua
-- Wrapper for C++ UI System

require "content.scripts.UI.UIData"
require "content.scripts.UI.UILogic"
require "content.scripts.UI.UIDefinitions"

UI = {}

function UI.init()
    -- Build UI from C++ (parses UIDefinitions table)
    ui.build()
end

function UI.update(dt)
    -- Update health bar fill width
    local healthEl = ui.get("HealthBarFill")
    if healthEl then
        local pct = UIData.displayHealth / UIData.maxHealth
        ui.setProp(healthEl, "Width", 196 * pct)
    end
    
    -- Update hunger bar (Phase 2)
    local hungerEl = ui.get("HungerBarFill")
    if hungerEl then
        local pct = UIData.displayHunger / UIData.maxHunger
        ui.setProp(hungerEl, "Width", 196 * pct)
    end
    
    -- Update sanity bar (Phase 2)
    local sanityEl = ui.get("SanityBarFill")
    if sanityEl then
        local pct = UIData.displaySanity / UIData.maxSanity
        ui.setProp(sanityEl, "Width", 196 * pct)
    end
    
    -- Update logic (tweening)
    UILogic.update(dt)
    
    -- Update UI elements (C++)
    ui.update(dt)
    
    -- Debug: Test Damage
    if input.isDown("down") then
        UILogic.onDamage(10 * dt)
    end
end

function UI.draw()
    ui.draw()
end
