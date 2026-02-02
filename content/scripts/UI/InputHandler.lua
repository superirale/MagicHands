-- InputHandler.lua
-- Centralized input handling with event-driven architecture
-- Converts raw input to UI events in correct coordinate space

local UIEvents = require("UI/UIEvents")
local CoordinateSystem = require("UI/CoordinateSystem")

local InputHandler = class()

function InputHandler:init()
    -- Mouse state tracking
    self.lastMouseX = 0
    self.lastMouseY = 0
    self.lastLeftButton = false
    self.lastRightButton = false

    -- Drag state
    self.isDragging = false
    self.dragStartX = 0
    self.dragStartY = 0
    self.dragThreshold = 5 -- Pixels before drag starts

    -- Keyboard state
    self.keysPressed = {}

    -- Touch state (for future mobile support)
    self.touches = {}
end

--- Process input events and emit UI events
--- Call this every frame in update()
--- @param dt number Delta time
function InputHandler:update(dt)
    -- Get raw input from engine
    local screenX, screenY = input.getMousePosition()
    local leftButton = input.isMouseButtonDown("left")
    local rightButton = input.isMouseButtonDown("right")

    -- Convert screen coordinates to viewport coordinates
    local viewportX, viewportY = CoordinateSystem.screenToViewport(screenX, screenY)

    local inViewport = CoordinateSystem.isInViewport(screenX, screenY)

    -- Mouse move event
    if screenX ~= self.lastMouseX or screenY ~= self.lastMouseY then
        UIEvents.emit("input:mouseMove", {
            screenX = screenX,
            screenY = screenY,
            viewportX = viewportX,
            viewportY = viewportY,
            inViewport = inViewport
        })
    end

    -- Left button events
    if leftButton and not self.lastLeftButton then
        -- Mouse down
        if inViewport then
            self.dragStartX = viewportX
            self.dragStartY = viewportY

            UIEvents.emit("input:mouseDown", {
                button = "left",
                viewportX = viewportX,
                viewportY = viewportY
            })
        end
    elseif not leftButton and self.lastLeftButton then
        -- Mouse up
        if self.isDragging then
            UIEvents.emit("input:dragEnd", {
                viewportX = viewportX,
                viewportY = viewportY,
                startX = self.dragStartX,
                startY = self.dragStartY
            })
            self.isDragging = false
        else
            -- It was a click (not a drag)
            if inViewport then
                UIEvents.emit("input:click", {
                    button = "left",
                    viewportX = viewportX,
                    viewportY = viewportY
                })
            end
        end

        UIEvents.emit("input:mouseUp", {
            button = "left",
            viewportX = viewportX,
            viewportY = viewportY
        })
    end

    -- Handle dragging
    if leftButton and not self.isDragging then
        local dist = math.abs(viewportX - self.dragStartX) + math.abs(viewportY - self.dragStartY)
        if dist > self.dragThreshold then
            self.isDragging = true
            UIEvents.emit("input:dragStart", {
                viewportX = self.dragStartX,
                viewportY = self.dragStartY
            })
        end
    end

    if self.isDragging then
        UIEvents.emit("input:drag", {
            viewportX = viewportX,
            viewportY = viewportY,
            deltaX = viewportX - self.lastMouseX,
            deltaY = viewportY - self.lastMouseY
        })
    end

    -- Right button events (for context menu, etc.)
    if rightButton and not self.lastRightButton then
        if inViewport then
            UIEvents.emit("input:rightClick", {
                viewportX = viewportX,
                viewportY = viewportY
            })
        end
    end

    -- Keyboard events
    self:processKeyboard()

    -- Update last state
    self.lastMouseX = viewportX -- Store in viewport space
    self.lastMouseY = viewportY
    self.lastLeftButton = leftButton
    self.lastRightButton = rightButton
end

--- Process keyboard input
function InputHandler:processKeyboard()
    -- Common game keys
    local keys = {
        "return", "backspace", "escape", "space", "tab",
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "up", "down", "left", "right"
    }

    for _, key in ipairs(keys) do
        if input.isPressed(key) then
            UIEvents.emit("input:keyPress", { key = key })

            -- Emit specific key events for common actions
            if key == "return" then
                UIEvents.emit("input:confirm", {})
            elseif key == "escape" then
                UIEvents.emit("input:cancel", {})
            elseif key == "backspace" then
                UIEvents.emit("input:discard", {})
            elseif key == "1" then
                UIEvents.emit("input:sortByRank", {})
            elseif key == "2" then
                UIEvents.emit("input:sortBySuit", {})
            elseif key == "c" then
                UIEvents.emit("input:toggleCollection", {})
            elseif key == "tab" then
                UIEvents.emit("input:toggleStats", {})
            elseif key == "z" then
                UIEvents.emit("input:undo", {})
            end
        end
    end
end

--- Get current mouse position in viewport space
--- @return number viewportX X in viewport coordinates
--- @return number viewportY Y in viewport coordinates
function InputHandler:getMousePosition()
    return self.lastMouseX, self.lastMouseY
end

--- Check if currently dragging
--- @return boolean isDragging True if dragging
function InputHandler:isDragging()
    return self.isDragging
end

--- Get drag start position
--- @return number x Drag start X in viewport space
--- @return number y Drag start Y in viewport space
function InputHandler:getDragStart()
    return self.dragStartX, self.dragStartY
end

--- Reset input state (useful for scene transitions)
function InputHandler:reset()
    self.isDragging = false
    self.lastLeftButton = false
    self.lastRightButton = false
    self.keysPressed = {}
end

return InputHandler
