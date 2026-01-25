---@meta
--- SceneManager - Stack-based scene management system
--- Handles scene transitions with proper lifecycle methods (enter, exit, pause, resume).
---
--- Usage:
--- ```lua
--- -- Define a scene
--- TitleScene = class()
--- function TitleScene:enter()
---     print("Entering title scene")
--- end
--- function TitleScene:update(dt)
---     if InputHelper.wasPressed("space") then
---         SceneManager.switch("GameScene")
---     end
--- end
--- function TitleScene:draw()
---     graphics.print(font, "Press Space", 400, 300)
--- end
---
--- -- Switch to it
--- SceneManager.switch("TitleScene")
---
--- -- Push overlay (pause menu)
--- SceneManager.push("PauseMenu")
---
--- -- Pop back to previous
--- SceneManager.pop()
--- ```
---@module SceneManager

---@class SceneManager
---@field current table|nil The currently active scene
---@field stack table Stack of paused scenes
---@field isSwitching boolean Guard against double-switching
SceneManager = {}
SceneManager.current = nil
SceneManager.stack = {}          -- Scene stack for push/pop
SceneManager.isSwitching = false -- Guard against double-switching
SceneManager.sharedState = {}    -- Global state shared between scenes
SceneManager.transition = nil    -- Current active transition

Transition = class()
function Transition:update(dt) end

function Transition:draw() end

-- --- Fade Transition ---

FadeTransition = class()
function FadeTransition:init(duration, color, onHalfway, onComplete)
    self.duration = duration or 0.5
    self.color = color or { r = 0, g = 0, b = 0, a = 1 }
    self.onHalfway = onHalfway
    self.onComplete = onComplete
    self.timer = 0
    self.halfwayCalled = false
end

function FadeTransition:update(dt)
    self.timer = self.timer + dt
    local half = self.duration / 2

    if self.timer >= half and not self.halfwayCalled then
        self.halfwayCalled = true
        if self.onHalfway then self.onHalfway() end
    end

    if self.timer >= self.duration then
        if self.onComplete then self.onComplete() end
        return true -- Done
    end
    return false
end

function FadeTransition:draw()
    local alpha = 0
    local half = self.duration / 2
    if self.timer < half then
        alpha = self.timer / half
    else
        alpha = 1 - ((self.timer - half) / half)
    end

    local drawColor = { r = self.color.r, g = self.color.g, b = self.color.b, a = alpha }
    graphics.drawRect(0, 0, 1280, 720, drawColor, true)
end

-- --- SceneManager Implementation ---

--- Switch to a new scene (replaces current scene, clears stack).
---@param sceneName string The global name of the scene class to switch to
---@param transition table|nil Optional transition config { type="fade", duration=0.5, color={r,g,b,a} }
---@param data table|nil Optional data to pass to the new scene's onInit
---@return nil
function SceneManager.switch(sceneName, transition, data)
    if SceneManager.isSwitching then return end

    local doSwitch = function()
        local sceneClass = _G[sceneName]
        if not sceneClass then
            print("Error: Scene not found: " .. tostring(sceneName))
            return
        end
        print("Switching to scene: " .. sceneName)

        -- Exit current scene
        if SceneManager.current and SceneManager.current.exit then
            SceneManager.current:exit()
        end

        -- Clear stack
        for i = #SceneManager.stack, 1, -1 do
            local scene = SceneManager.stack[i]
            if scene and scene.exit then scene:exit() end
        end
        SceneManager.stack = {}

        -- Create new scene
        print("Creating instance of " .. sceneName)
        SceneManager.current = sceneClass()
        if SceneManager.current.onInit then
            print("Calling onInit for " .. sceneName)
            SceneManager.current:onInit(data)
        else
            print("WARNING: onInit not found for " .. sceneName)
        end
        if SceneManager.current.enter then
            SceneManager.current:enter()
        end
    end

    if transition and transition.type == "fade" then
        SceneManager.isSwitching = true
        SceneManager.transition = FadeTransition(transition.duration, transition.color,
            function() doSwitch() end,
            function()
                SceneManager.transition = nil
                SceneManager.isSwitching = false
            end)
    else
        doSwitch()
    end
end

--- Push a new scene onto the stack (pauses current scene).
---@param sceneName string The global name of the scene class to push
---@param transition table|nil Optional transition
---@param data table|nil Optional data
function SceneManager.push(sceneName, transition, data)
    if SceneManager.isSwitching then return end

    local doPush = function()
        local sceneClass = _G[sceneName]
        if not sceneClass then return end

        if SceneManager.current and SceneManager.current.pause then
            SceneManager.current:pause()
        end

        if SceneManager.current then
            table.insert(SceneManager.stack, SceneManager.current)
        end

        SceneManager.current = sceneClass()
        if SceneManager.current.onInit then SceneManager.current:onInit(data) end
        if SceneManager.current.enter then SceneManager.current:enter() end
    end

    if transition and transition.type == "fade" then
        SceneManager.isSwitching = true
        SceneManager.transition = FadeTransition(transition.duration, transition.color,
            function() doPush() end,
            function()
                SceneManager.transition = nil
                SceneManager.isSwitching = false
            end)
    else
        doPush()
    end
end

--- Pop the current scene and resume the previous one.
function SceneManager.pop(transition)
    if SceneManager.isSwitching then return end
    if #SceneManager.stack == 0 then return end

    local doPop = function()
        if SceneManager.current and SceneManager.current.exit then
            SceneManager.current:exit()
        end

        SceneManager.current = table.remove(SceneManager.stack)

        if SceneManager.current and SceneManager.current.resume then
            SceneManager.current:resume()
        end
    end

    if transition and transition.type == "fade" then
        SceneManager.isSwitching = true
        SceneManager.transition = FadeTransition(transition.duration, transition.color,
            function() doPop() end,
            function()
                SceneManager.transition = nil
                SceneManager.isSwitching = false
            end)
    else
        doPop()
    end
end

function SceneManager.getStackDepth() return #SceneManager.stack end

function SceneManager.canPop() return #SceneManager.stack > 0 end

function SceneManager.update(dt)
    if SceneManager.transition then
        SceneManager.transition:update(dt)
    end

    -- If we are switching, we might want to pause the current scene's update?
    -- For now, let's update ONLY if not in the middle of a blocking transition
    if SceneManager.current and SceneManager.current.update then
        SceneManager.current:update(dt)
    end
end

function SceneManager.draw()
    if SceneManager.current and SceneManager.current.draw then
        SceneManager.current:draw()
    end

    if SceneManager.transition then
        SceneManager.transition:draw()
    end
end

---@class Scene
---@field onInit function Called once when scene is created
---@field enter function Called when scene becomes active
---@field exit function Called when scene is being left
---@field update function Called each frame with delta time
---@field draw function Called each frame for rendering
---@field pause function Called when scene is pushed to stack
---@field resume function Called when scene is popped back from stack

Scene = class()
function Scene:onInit(data) end

function Scene:enter() end

function Scene:exit() end

function Scene:update(dt) end

function Scene:draw() end

function Scene:pause() end

function Scene:resume() end
