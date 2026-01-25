--- Console - Developer debug console
--- Press ` (backtick) to toggle
--- Type commands and press Enter to execute

Console = {}
Console.__index = Console

-- State
Console.visible = false
Console.input = ""
Console.cursorPos = 0
Console.history = {}
Console.historyIndex = 0
Console.commands = {}
Console.output = {}
Console.maxOutput = 10

--- Initialize console
function Console.init()
    Console.visible = false
    Console.input = ""
    Console.history = {}
    Console.output = {}

    -- Load console font (use the existing font.ttf)
    Console.font = assets.loadFont("content/fonts/font.ttf", 16)
    if not Console.font then
        log.warn("Console: Failed to load font, text will not render")
    end

    -- Register built-in commands
    Console.register("help", Console.cmd_help, "List all commands")
    Console.register("clear", Console.cmd_clear, "Clear console output")
    Console.register("history", Console.cmd_history, "Show command history")

    log.info("Console initialized (press F1 to toggle)")
end

--- Register a command
---@param name string Command name
---@param func function Command function(args...)
---@param description string Command description
function Console.register(name, func, description)
    Console.commands[name] = {
        func = func,
        desc = description or "No description"
    }
end

--- Toggle console visibility
function Console.toggle()
    Console.visible = not Console.visible
    if Console.visible then
        Console.cursorPos = #Console.input
        log.info("Starting text input...")
        input.startTextInput() -- Enable SDL text input
        log.info("Text input started")
    else
        log.info("Stopping text input...")
        input.stopTextInput() -- Disable SDL text input
        log.info("Text input stopped")
    end
end

--- Add message to output
function Console.print(msg, color)
    table.insert(Console.output, {
        text = tostring(msg),
        color = color or { 1, 1, 1, 1 }
    })

    -- Keep output size manageable
    while #Console.output > Console.maxOutput do
        table.remove(Console.output, 1)
    end
end

--- Execute command
function Console.execute(line)
    if line == "" then return end

    -- Add to history
    table.insert(Console.history, line)
    Console.historyIndex = #Console.history + 1

    -- Echo command
    Console.print("> " .. line, { 0.7, 0.7, 1, 1 })

    -- Parse command
    local parts = {}
    for word in line:gmatch("%S+") do
        table.insert(parts, word)
    end

    if #parts == 0 then return end

    local cmdName = parts[1]
    local args = { table.unpack(parts, 2) }

    -- Execute
    local cmd = Console.commands[cmdName]
    if cmd then
        local success, err = pcall(cmd.func, table.unpack(args))
        if not success then
            Console.print("Error: " .. tostring(err), { 1, 0.3, 0.3, 1 })
        end
    else
        Console.print("Unknown command: " .. cmdName, { 1, 0.5, 0, 1 })
        Console.print("Type 'help' for list of commands", { 0.7, 0.7, 0.7, 1 })
    end
end

--- Update console (handle input)
function Console.update(dt)
    -- Toggle console visibility (F1)
    if input.isPressed("f1") then
        Console.toggle()
        if Console.visible then
            log.info("Console toggled ON")
        else
            log.info("Console toggled OFF")
        end
    end

    if not Console.visible then
        return
    end

    -- Handle text input from SDL
    local text = input.getTextInput()
    if text and text ~= "" then
        log.info("Received text: '" .. text .. "'")
        Console.input = Console.input:sub(1, Console.cursorPos) .. text .. Console.input:sub(Console.cursorPos + 1)
        Console.cursorPos = Console.cursorPos + #text
    end

    -- Handle special keys
    if input.isPressed("return") or input.isPressed("return2") or input.isPressed("kp_enter") then
        Console.execute(Console.input)
        Console.input = ""
        Console.cursorPos = 0
    end

    if input.isPressed("backspace") and Console.cursorPos > 0 then
        Console.input = Console.input:sub(1, Console.cursorPos - 1) .. Console.input:sub(Console.cursorPos + 1)
        Console.cursorPos = Console.cursorPos - 1
    end

    if input.isPressed("delete") and Console.cursorPos < #Console.input then
        Console.input = Console.input:sub(1, Console.cursorPos) .. Console.input:sub(Console.cursorPos + 2)
    end

    if input.isPressed("left") and Console.cursorPos > 0 then
        Console.cursorPos = Console.cursorPos - 1
    end

    if input.isPressed("right") and Console.cursorPos < #Console.input then
        Console.cursorPos = Console.cursorPos + 1
    end

    if input.isPressed("home") then
        Console.cursorPos = 0
    end

    if input.isPressed("end") then
        Console.cursorPos = #Console.input
    end

    -- History navigation
    if input.isPressed("up") and #Console.history > 0 then
        Console.historyIndex = math.max(1, Console.historyIndex - 1)
        Console.input = Console.history[Console.historyIndex] or ""
        Console.cursorPos = #Console.input
    end

    if input.isPressed("down") then
        Console.historyIndex = math.min(#Console.history + 1, Console.historyIndex + 1)
        Console.input = Console.history[Console.historyIndex] or ""
        Console.cursorPos = #Console.input
    end

    -- Close console (escape key)
    if input.isPressed("escape") then
        Console.toggle()
        log.info("Console toggled OFF")
    end
end

--- Draw console
function Console.draw()
    -- Don't draw anything if not visible or no font
    if not Console.visible or not Console.font then return end

    local screenWidth = Window.getWidth()
    local screenHeight = Window.getHeight()
    local consoleHeight = 300

    -- Background (semi-transparent black)
    graphics.drawRect(0, 0, screenWidth, consoleHeight, { r = 0, g = 0, b = 0, a = 0.9 }, true)

    -- Output
    local y = consoleHeight - 60
    for i = #Console.output, math.max(1, #Console.output - 8), -1 do
        local line = Console.output[i]
        local color = line.color
        graphics.print(Console.font, line.text, 10, y, { r = color[1], g = color[2], b = color[3], a = color[4] })
        y = y - 18
    end

    -- Input line
    local prompt = "> "
    graphics.print(Console.font, prompt .. Console.input, 10, consoleHeight - 30)

    -- Cursor (blinking)
    if math.floor(os.clock() * 2) % 2 == 0 then
        -- Simple cursor for now (will need proper text measurement)
        local cursorX = 10 + (#prompt + Console.cursorPos) * 8 -- Approximate width
        graphics.drawRect(cursorX, consoleHeight - 28, 2, 16, { r = 1, g = 1, b = 1, a = 1 }, true)
    end

    -- Help text
    graphics.print(Console.font, "Press F1 or ESC to close | Up/Down for history", 10, consoleHeight - 10,
        { r = 0.5, g = 0.5, b = 0.5, a = 1 })
end

--- Built-in: help command
function Console.cmd_help()
    Console.print("Available commands:", { 1, 1, 0, 1 })
    for name, cmd in pairs(Console.commands) do
        Console.print("  " .. name .. " - " .. cmd.desc, { 0.8, 0.8, 0.8, 1 })
    end
end

--- Built-in: clear command
function Console.cmd_clear()
    Console.output = {}
end

--- Built-in: history command
function Console.cmd_history()
    Console.print("Command history:", { 1, 1, 0, 1 })
    for i, cmd in ipairs(Console.history) do
        Console.print("  " .. i .. ": " .. cmd, { 0.8, 0.8, 0.8, 1 })
    end
end

return Console
