-- UIScale.lua
-- UI Scaling system for multi-resolution support

UIScale = {}

-- Base resolution (design target)
UIScale.BASE_WIDTH = 1280
UIScale.BASE_HEIGHT = 720

-- Current scale factor (cached)
UIScale._currentScale = 1.0

-- Auto-calculate scale based on current window size
function UIScale.auto()
    local winW, winH = graphics.getWindowSize()
    ui.calculateScaleFactor(winW, winH)
    UIScale._currentScale = ui.getScaleFactor()
    
    log.info(string.format("Auto UI scale: %.2fx (Window: %dx%d, Base: %dx%d)", 
             UIScale._currentScale, winW, winH, UIScale.BASE_WIDTH, UIScale.BASE_HEIGHT))
    
    return UIScale._currentScale
end

-- Set manual scale factor (for user settings)
function UIScale.set(scale)
    ui.setScaleFactor(scale)
    UIScale._currentScale = scale
    log.info(string.format("Manual UI scale set to: %.2fx", scale))
end

-- Get current scale factor
function UIScale.get()
    -- Use cached value to avoid C++ calls every frame
    return UIScale._currentScale
end

-- Scale a value by current scale factor
function UIScale.scale(value)
    return value * UIScale._currentScale
end

-- Scale multiple values at once (returns multiple values)
function UIScale.scaleMultiple(...)
    local values = {...}
    local scaled = {}
    for i, v in ipairs(values) do
        scaled[i] = v * UIScale._currentScale
    end
    return table.unpack(scaled)
end

-- Get scaled window center
function UIScale.getCenter()
    local winW, winH = graphics.getWindowSize()
    return winW / 2, winH / 2
end

-- Common preset scales
UIScale.PRESETS = {
    TINY = 0.5,       -- 50% (very small UI)
    SMALL = 0.75,     -- 75%
    NORMAL = 1.0,     -- 100% (base resolution)
    LARGE = 1.25,     -- 125%
    HUGE = 1.5,       -- 150%
    ULTRA = 2.0       -- 200% (for 4K)
}

-- Apply preset scale
function UIScale.applyPreset(presetName)
    local scale = UIScale.PRESETS[presetName]
    if scale then
        UIScale.set(scale)
        return true
    else
        log.warn("Unknown scale preset: " .. tostring(presetName))
        return false
    end
end

-- Calculate scale factor from resolution (without applying)
function UIScale.calculateForResolution(width, height)
    local scaleW = width / UIScale.BASE_WIDTH
    local scaleH = height / UIScale.BASE_HEIGHT
    return math.min(scaleW, scaleH)
end

-- Check if UI needs rescaling based on window size change
function UIScale.checkWindowChange(lastWidth, lastHeight)
    local winW, winH = graphics.getWindowSize()
    if winW ~= lastWidth or winH ~= lastHeight then
        UIScale.auto()
        return true, winW, winH
    end
    return false, winW, winH
end

-- Helper: Scale position from base resolution to current resolution
function UIScale.scalePosition(baseX, baseY)
    return baseX * UIScale._currentScale, baseY * UIScale._currentScale
end

-- Helper: Scale size from base resolution to current resolution
function UIScale.scaleSize(baseW, baseH)
    return baseW * UIScale._currentScale, baseH * UIScale._currentScale
end

-- Helper: Unscale (convert screen position back to base resolution)
function UIScale.unscale(value)
    return value / UIScale._currentScale
end

function UIScale.unscalePosition(screenX, screenY)
    return screenX / UIScale._currentScale, screenY / UIScale._currentScale
end

-- Initialize scaling system (call on startup)
function UIScale.init()
    UIScale.auto()
    log.info("UIScale system initialized")
end

return UIScale
