-- CoordinateSystem.lua
-- Handles coordinate space transformations for UI rendering
-- Separates viewport space (logical 1280x720) from screen space (physical pixels)

local CoordinateSystem = {}

-- Fixed viewport dimensions (design space)
CoordinateSystem.VIEWPORT_WIDTH = 1280
CoordinateSystem.VIEWPORT_HEIGHT = 720

-- Current screen dimensions (physical pixels)
CoordinateSystem.screenWidth = 1280
CoordinateSystem.screenHeight = 720

-- Calculated scale factors
CoordinateSystem.scaleX = 1.0
CoordinateSystem.scaleY = 1.0
CoordinateSystem.scale = 1.0  -- Uniform scale (min of scaleX, scaleY)

-- Letterbox offsets (black bars)
CoordinateSystem.offsetX = 0
CoordinateSystem.offsetY = 0

--- Initialize coordinate system with current screen size
--- @param screenW number Screen width in pixels
--- @param screenH number Screen height in pixels
function CoordinateSystem.init(screenW, screenH)
    CoordinateSystem.updateScreenSize(screenW, screenH)
end

--- Update screen size and recalculate transforms
--- Call this on window resize
--- @param screenW number New screen width in pixels
--- @param screenH number New screen height in pixels
function CoordinateSystem.updateScreenSize(screenW, screenH)
    CoordinateSystem.screenWidth = screenW
    CoordinateSystem.screenHeight = screenH
    
    -- Calculate scale factors
    CoordinateSystem.scaleX = screenW / CoordinateSystem.VIEWPORT_WIDTH
    CoordinateSystem.scaleY = screenH / CoordinateSystem.VIEWPORT_HEIGHT
    
    -- Use uniform scaling (letterboxing) to maintain aspect ratio
    CoordinateSystem.scale = math.min(CoordinateSystem.scaleX, CoordinateSystem.scaleY)
    
    -- Calculate letterbox offsets
    local scaledWidth = CoordinateSystem.VIEWPORT_WIDTH * CoordinateSystem.scale
    local scaledHeight = CoordinateSystem.VIEWPORT_HEIGHT * CoordinateSystem.scale
    
    CoordinateSystem.offsetX = (screenW - scaledWidth) / 2
    CoordinateSystem.offsetY = (screenH - scaledHeight) / 2
    
    print(string.format("[CoordinateSystem] Screen: %dx%d, Scale: %.2f, Offset: (%.0f, %.0f)",
        screenW, screenH, CoordinateSystem.scale, CoordinateSystem.offsetX, CoordinateSystem.offsetY))
end

--- Convert viewport coordinates to screen coordinates
--- Use this when rendering (viewport -> screen)
--- @param viewportX number X in viewport space (0-1280)
--- @param viewportY number Y in viewport space (0-720)
--- @return number screenX X in screen space (pixels)
--- @return number screenY Y in screen space (pixels)
function CoordinateSystem.viewportToScreen(viewportX, viewportY)
    local screenX = viewportX * CoordinateSystem.scale + CoordinateSystem.offsetX
    local screenY = viewportY * CoordinateSystem.scale + CoordinateSystem.offsetY
    return screenX, screenY
end

--- Convert screen coordinates to viewport coordinates
--- Use this for input (mouse/touch) - screen -> viewport
--- @param screenX number X in screen space (pixels)
--- @param screenY number Y in screen space (pixels)
--- @return number viewportX X in viewport space (0-1280)
--- @return number viewportY Y in viewport space (0-720)
function CoordinateSystem.screenToViewport(screenX, screenY)
    local viewportX = (screenX - CoordinateSystem.offsetX) / CoordinateSystem.scale
    local viewportY = (screenY - CoordinateSystem.offsetY) / CoordinateSystem.scale
    return viewportX, viewportY
end

--- Scale a viewport dimension to screen pixels
--- Use for width/height scaling
--- @param viewportSize number Size in viewport space
--- @return number screenSize Size in screen space
function CoordinateSystem.scaleSize(viewportSize)
    return viewportSize * CoordinateSystem.scale
end

--- Check if a screen coordinate is within the viewport (not in letterbox)
--- @param screenX number X in screen space
--- @param screenY number Y in screen space
--- @return boolean isInViewport True if point is inside viewport
function CoordinateSystem.isInViewport(screenX, screenY)
    return screenX >= CoordinateSystem.offsetX and
           screenX <= CoordinateSystem.offsetX + (CoordinateSystem.VIEWPORT_WIDTH * CoordinateSystem.scale) and
           screenY >= CoordinateSystem.offsetY and
           screenY <= CoordinateSystem.offsetY + (CoordinateSystem.VIEWPORT_HEIGHT * CoordinateSystem.scale)
end

--- Get viewport bounds in screen space (for rendering letterbox)
--- @return number x Left edge
--- @return number y Top edge
--- @return number w Width
--- @return number h Height
function CoordinateSystem.getViewportBounds()
    return CoordinateSystem.offsetX,
           CoordinateSystem.offsetY,
           CoordinateSystem.VIEWPORT_WIDTH * CoordinateSystem.scale,
           CoordinateSystem.VIEWPORT_HEIGHT * CoordinateSystem.scale
end

--- Get current scale factor
--- @return number scale Uniform scale factor
function CoordinateSystem.getScale()
    return CoordinateSystem.scale
end

--- Get viewport dimensions
--- @return number width Viewport width (always 1280)
--- @return number height Viewport height (always 720)
function CoordinateSystem.getViewportSize()
    return CoordinateSystem.VIEWPORT_WIDTH, CoordinateSystem.VIEWPORT_HEIGHT
end

--- DEBUG: Draw viewport bounds (for debugging)
function CoordinateSystem.debugDraw()
    local x, y, w, h = CoordinateSystem.getViewportBounds()
    
    -- Draw letterbox areas (black bars)
    if CoordinateSystem.offsetX > 0 then
        graphics.drawRect(0, 0, CoordinateSystem.offsetX, CoordinateSystem.screenHeight,
            {r=0, g=0, b=0, a=1}, true)
        graphics.drawRect(CoordinateSystem.screenWidth - CoordinateSystem.offsetX, 0,
            CoordinateSystem.offsetX, CoordinateSystem.screenHeight, {r=0, g=0, b=0, a=1}, true)
    end
    
    if CoordinateSystem.offsetY > 0 then
        graphics.drawRect(0, 0, CoordinateSystem.screenWidth, CoordinateSystem.offsetY,
            {r=0, g=0, b=0, a=1}, true)
        graphics.drawRect(0, CoordinateSystem.screenHeight - CoordinateSystem.offsetY,
            CoordinateSystem.screenWidth, CoordinateSystem.offsetY, {r=0, g=0, b=0, a=1}, true)
    end
    
    -- Draw viewport border (red)
    graphics.drawRect(x, y, w, h, {r=1, g=0, b=0, a=0.5}, false)
end

return CoordinateSystem
