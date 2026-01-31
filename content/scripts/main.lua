-- Main.lua
-- Entry point for Criblage testing

package.path = package.path ..
    ";content/scripts/?.lua;content/scripts/scenes/?.lua;content/scripts/entities/?.lua;engine/lua/?.lua;engine/lua/components/?.lua;engine/lua/ui/?.lua"

-- Core library (defines 'class' and 'thread')
require "Core"

-- Scenes.lua requires 'class' library
require "Scenes"

-- Game Scenes
require "scenes/MenuScene"
require "scenes/GameScene"

-- Object Pool & Console
ObjectPool = require "ObjectPool"
Console = require "Console"
DebugCommands = require "DebugCommands"

-- --- Entry Point ---
thread(function()
    -- Initialize console
    Console.init()

    -- Start with Main Menu
    SceneManager.switch("MenuScene")
end)

function update(dt)
    -- Input state is updated by C++ InputSystem

    -- Update console first (handles input)
    Console.update(dt)

    -- Only update scene if console is NOT visible
    if not Console.visible then
        SceneManager.update(dt)
        SceneManager.draw()
    end

    -- Always draw console on top (even when closed, it's just invisible)
    Console.draw()
end
