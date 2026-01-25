--- DebugCommands - Built-in debug commands for development
--- Provides common debugging utilities like god mode, teleportation, spawning, etc.

local DebugCommands = {}

function DebugCommands.register()
    -- Scene Management
    Console.register("scene", function(sceneName)
        if not sceneName then
            Console.print("Usage: scene <SceneName>", { 1, 0.5, 0, 1 })
            return
        end

        local scene = _G[sceneName]
        if scene then
            SceneManager.switch(sceneName)
            Console.print("Switched to scene: " .. sceneName, { 0, 1, 0, 1 })
        else
            Console.print("Scene not found: " .. sceneName, { 1, 0, 0, 1 })
        end
    end, "Switch to a scene (e.g., scene SpatialDemoScene)")

    -- Player Commands
    Console.register("god", function()
        if player then
            player.godMode = not (player.godMode or false)
            Console.print("God mode: " .. tostring(player.godMode), { 0, 1, 0, 1 })
        else
            Console.print("No player found", { 1, 0, 0, 1 })
        end
    end, "Toggle god mode (invincibility)")

    Console.register("tp", function(x, y)
        if not player then
            Console.print("No player found", { 1, 0, 0, 1 })
            return
        end

        local px = tonumber(x)
        local py = tonumber(y)

        if px and py then
            player.x = px
            player.y = py
            Console.print(string.format("Teleported to (%.0f, %.0f)", px, py), { 0, 1, 0, 1 })
        else
            Console.print("Usage: tp <x> <y>", { 1, 0.5, 0, 1 })
        end
    end, "Teleport player to position (e.g., tp 500 300)")

    Console.register("heal", function()
        if player and player.health then
            player.health = player.maxHealth or 100
            Console.print("Player healed", { 0, 1, 0, 1 })
        else
            Console.print("No player or health system found", { 1, 0, 0, 1 })
        end
    end, "Heal player to full health")

    Console.register("kill", function()
        if player and player.health then
            player.health = 0
            Console.print("Player killed", { 1, 0, 0, 1 })
        else
            Console.print("No player or health system found", { 1, 0, 0, 1 })
        end
    end, "Kill the player")

    -- Time Control
    Console.register("speed", function(scale)
        local s = tonumber(scale)
        if s then
            -- Note: Requires Engine.timeScale support
            Console.print(string.format("Time scale set to %.2f", s), { 0, 1, 0, 1 })
            Console.print("(Time scale not yet implemented in engine)", { 1, 0.5, 0, 1 })
        else
            Console.print("Usage: speed <scale> (e.g., speed 0.5 for slow-mo)", { 1, 0.5, 0, 1 })
        end
    end, "Set time scale (0.5 = slow-mo, 2.0 = fast)")

    -- Entity Spawning
    Console.register("spawn", function(entityType)
        if not entityType then
            Console.print("Usage: spawn <type>", { 1, 0.5, 0, 1 })
            return
        end

        local mx, my = input.getMousePosition()
        Console.print(string.format("Spawn %s at (%.0f, %.0f)", entityType, mx, my), { 0, 1, 0, 1 })
        Console.print("(Entity spawning not yet implemented)", { 1, 0.5, 0, 1 })
    end, "Spawn entity at mouse position")

    Console.register("clear", function()
        Console.print("Clear all entities", { 0, 1, 0, 1 })
        Console.print("(Entity clearing not yet implemented)", { 1, 0.5, 0, 1 })
    end, "Destroy all entities")

    -- Graphics/Debug
    Console.register("fps", function()
        Console.print("FPS display toggle", { 0, 1, 0, 1 })
        Console.print("(FPS counter not yet implemented)", { 1, 0.5, 0, 1 })
    end, "Toggle FPS counter")

    Console.register("wireframe", function()
        Console.print("Wireframe mode toggle", { 0, 1, 0, 1 })
        Console.print("(Wireframe not yet implemented)", { 1, 0.5, 0, 1 })
    end, "Toggle wireframe rendering")

    -- Save/Load
    Console.register("save", function(slot)
        local s = tonumber(slot) or 1
        Console.print("Quick save to slot " .. s, { 0, 1, 0, 1 })
        Console.print("(Save system not yet implemented)", { 1, 0.5, 0, 1 })
    end, "Quick save (e.g., save 1)")

    Console.register("load", function(slot)
        local s = tonumber(slot) or 1
        Console.print("Quick load from slot " .. s, { 0, 1, 0, 1 })
        Console.print("(Load system not yet implemented)", { 1, 0.5, 0, 1 })
    end, "Quick load (e.g., load 1)")

    -- Utility
    Console.register("echo", function(...)
        local args = { ... }
        Console.print(table.concat(args, " "), { 1, 1, 1, 1 })
    end, "Echo text to console")

    Console.register("lua", function(...)
        local code = table.concat({ ... }, " ")
        local func, err = load("return " .. code)
        if not func then
            func, err = load(code)
        end

        if func then
            local success, result = pcall(func)
            if success then
                if result ~= nil then
                    Console.print(tostring(result), { 0, 1, 1, 1 })
                end
            else
                Console.print("Error: " .. tostring(result), { 1, 0, 0, 1 })
            end
        else
            Console.print("Parse error: " .. tostring(err), { 1, 0, 0, 1 })
        end
    end, "Execute Lua code (e.g., lua print('hello'))")

    -- Start MobDebug
    Console.register("debug_start", function()
        local status, mobdebug = pcall(require, "mobdebug")
        if status then
            Console.print("Attempting to connect to debugger (localhost:8172)...", { 1, 1, 0, 1 })
            mobdebug.start()
            Console.print("Debugger connected!", { 0, 1, 0, 1 })
        else
            Console.print("Failed to load mobdebug: " .. tostring(mobdebug), { 1, 0, 0, 1 })
        end
    end, "Start Lua debugger (connects to IDE)")

    log.info("Debug commands registered")
end

return DebugCommands
