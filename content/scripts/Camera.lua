-- Camera.lua
-- Stardew Valley-style camera system with smooth following and boundary clamping
-- Displays a 480x320 viewport scaled to fit the screen (2.67x on 1280x720)

Camera = class()

-- Default configuration
Camera.DEFAULT_CONFIG = {
    viewportWidth = 480,
    viewportHeight = 320,
    smoothing = 0.1, -- Lerp factor (lower = smoother, higher = snappier)
    deadZone = 0,    -- Pixels target can move without camera following
}

--- Create a new Camera instance
--- @param config table|nil Configuration options
function Camera:init(config)
    config = config or {}

    -- Viewport dimensions (what the camera "sees")
    self.viewportWidth = config.viewportWidth or Camera.DEFAULT_CONFIG.viewportWidth
    self.viewportHeight = config.viewportHeight or Camera.DEFAULT_CONFIG.viewportHeight

    -- Map bounds (for clamping)
    self.mapWidth = config.mapWidth or 2400
    self.mapHeight = config.mapHeight or 1600

    -- Smoothing factor (0 = instant, 0.5 = medium lag, 0.9 = very slow)
    self.smoothing = config.smoothing or Camera.DEFAULT_CONFIG.smoothing

    -- Current camera position (top-left of viewport in world coords)
    self.x = 0
    self.y = 0

    -- Target position (for smooth following)
    self.targetX = 0
    self.targetY = 0

    -- Initialize C++ viewport scaling
    if config.zoom then
        -- Dynamic viewport mode (fills screen)
        local sw, sh = 1280, 720
        if graphics.getWindowSize then
            sw, sh = graphics.getWindowSize()
        end

        -- If viewport dimensions not explicitly provided, calculate from zoom
        if not config.viewportWidth then
            self.viewportWidth = sw / config.zoom
        end
        if not config.viewportHeight then
            self.viewportHeight = sh / config.zoom
        end

        graphics.resetViewport()
        graphics.setZoom(config.zoom)
    else
        -- Fixed viewport mode (letterboxed)
        graphics.setViewport(self.viewportWidth, self.viewportHeight)
    end
end

--- Set the map bounds for boundary clamping
--- @param width number Map width in pixels
--- @param height number Map height in pixels
function Camera:setMapBounds(width, height)
    self.mapWidth = width
    self.mapHeight = height
end

--- Follow a target position (typically player center)
--- Camera will smoothly move to center the target in the viewport
--- @param targetX number World X coordinate to follow
--- @param targetY number World Y coordinate to follow
function Camera:follow(targetX, targetY)
    -- Calculate where camera should be to center target
    self.targetX = targetX - self.viewportWidth / 2
    self.targetY = targetY - self.viewportHeight / 2
end

--- Update camera position with smoothing and clamping
--- Call this every frame after following the target
--- @param dt number Delta time in seconds
function Camera:update(dt)
    -- Smooth interpolation toward target using frame-rate independent lerp
    -- The pow() formula ensures consistent smoothing regardless of frame rate
    local lerpFactor = 1 - (self.smoothing ^ (dt * 60))

    self.x = self.x + (self.targetX - self.x) * lerpFactor
    self.y = self.y + (self.targetY - self.y) * lerpFactor

    -- Clamp to map boundaries
    self:clampToBounds()

    -- Apply to C++ renderer
    graphics.setCamera(self.x, self.y)
end

--- Clamp camera position so it doesn't show outside the map
function Camera:clampToBounds()
    local minX = 0
    local minY = 0
    local maxX = self.mapWidth - self.viewportWidth
    local maxY = self.mapHeight - self.viewportHeight

    -- Handle maps smaller than viewport (center the map)
    if maxX < 0 then
        self.x = (self.mapWidth - self.viewportWidth) / 2
    else
        self.x = math.max(minX, math.min(maxX, self.x))
    end

    if maxY < 0 then
        self.y = (self.mapHeight - self.viewportHeight) / 2
    else
        self.y = math.max(minY, math.min(maxY, self.y))
    end
end

--- Immediately snap to target (no smoothing)
--- Useful for scene transitions or teleporting
--- @param targetX number World X coordinate to snap to
--- @param targetY number World Y coordinate to snap to
function Camera:snapTo(targetX, targetY)
    self.targetX = targetX - self.viewportWidth / 2
    self.targetY = targetY - self.viewportHeight / 2
    self.x = self.targetX
    self.y = self.targetY
    self:clampToBounds()
    graphics.setCamera(self.x, self.y)
end

--- Get current camera position
--- @return number x Camera X position (top-left of viewport)
--- @return number y Camera Y position (top-left of viewport)
function Camera:getPosition()
    return self.x, self.y
end

--- Convert screen coordinates to world coordinates
--- Useful for mouse/touch input handling
--- @param screenX number Screen X coordinate
--- @param screenY number Screen Y coordinate
--- @return number worldX World X coordinate
--- @return number worldY World Y coordinate
function Camera:screenToWorld(screenX, screenY)
    -- Note: screenX/Y are in viewport space (0-480, 0-320)
    return screenX + self.x, screenY + self.y
end

--- Convert world coordinates to screen coordinates
--- @param worldX number World X coordinate
--- @param worldY number World Y coordinate
--- @return number screenX Screen X coordinate
--- @return number screenY Screen Y coordinate
function Camera:worldToScreen(worldX, worldY)
    return worldX - self.x, worldY - self.y
end

--- Check if a world rectangle is visible in the viewport
--- Useful for culling off-screen objects
--- @param x number World X coordinate of rectangle
--- @param y number World Y coordinate of rectangle
--- @param w number Width of rectangle
--- @param h number Height of rectangle
--- @return boolean visible True if any part of the rectangle is visible
function Camera:isVisible(x, y, w, h)
    return x + w > self.x and x < self.x + self.viewportWidth
        and y + h > self.y and y < self.y + self.viewportHeight
end

--- Get the viewport dimensions
--- @return number width Viewport width
--- @return number height Viewport height
function Camera:getViewportSize()
    return self.viewportWidth, self.viewportHeight
end

--- Get the visible world bounds
--- @return number x Left edge of visible area
--- @return number y Top edge of visible area
--- @return number w Width of visible area
--- @return number h Height of visible area
function Camera:getVisibleBounds()
    return self.x, self.y, self.viewportWidth, self.viewportHeight
end

return Camera
