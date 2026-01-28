-- UILayout.lua
-- Centralized layout system for UI positioning
-- Provides anchor points, registration, and automatic stacking

UILayout = {}

-- Screen dimensions (assume 1280x720, can be updated)
UILayout.screenWidth = UILayout.screenWidth or 1280
UILayout.screenHeight = UILayout.screenHeight or 720

-- Padding from screen edges
UILayout.edgePadding = 20

-- Registered UI regions
UILayout.regions = {}

-- Anchor position calculators
local anchors = {
    ["top-left"] = function(w, h)
        return UILayout.edgePadding, UILayout.edgePadding
    end,
    ["top-right"] = function(w, h)
        return UILayout.screenWidth - UILayout.edgePadding - w, UILayout.edgePadding
    end,
    ["bottom-left"] = function(w, h)
        return UILayout.edgePadding, UILayout.screenHeight - UILayout.edgePadding - h
    end,
    ["bottom-right"] = function(w, h)
        return UILayout.screenWidth - UILayout.edgePadding - w,
            UILayout.screenHeight - UILayout.edgePadding - h
    end,
    ["center"] = function(w, h)
        return (UILayout.screenWidth - w) / 2, (UILayout.screenHeight - h) / 2
    end,
    ["top-center"] = function(w, h)
        return (UILayout.screenWidth - w) / 2, UILayout.edgePadding
    end,
    ["bottom-center"] = function(w, h)
        return (UILayout.screenWidth - w) / 2, UILayout.screenHeight - UILayout.edgePadding - h
    end
}

-- Register a UI region
-- opts: { anchor, width, height, offsetX?, offsetY? }
function UILayout.register(name, opts)
    local anchor = opts.anchor or "top-left"
    local width = opts.width or 100
    local height = opts.height or 100
    local offsetX = opts.offsetX or 0
    local offsetY = opts.offsetY or 0

    -- Calculate base position from anchor
    local anchorFn = anchors[anchor]
    if not anchorFn then
        print("[UILayout] Unknown anchor: " .. anchor .. ", using top-left")
        anchorFn = anchors["top-left"]
    end

    local baseX, baseY = anchorFn(width, height)

    UILayout.regions[name] = {
        name = name,
        anchor = anchor,
        x = baseX + offsetX,
        y = baseY + offsetY,
        width = width,
        height = height,
        offsetX = offsetX,
        offsetY = offsetY
    }

    return UILayout.regions[name]
end

-- Get a registered region's position
function UILayout.getPosition(name)
    local region = UILayout.regions[name]
    if region then
        return region.x, region.y
    end
    return 0, 0
end

-- Get a registered region
function UILayout.get(name)
    return UILayout.regions[name]
end

-- Get position below a registered region (for stacking)
function UILayout.below(name, gap)
    gap = gap or 10
    local region = UILayout.regions[name]
    if region then
        return region.x, region.y + region.height + gap
    end
    return UILayout.edgePadding, UILayout.edgePadding
end

-- Get position to the right of a registered region
function UILayout.rightOf(name, gap)
    gap = gap or 10
    local region = UILayout.regions[name]
    if region then
        return region.x + region.width + gap, region.y
    end
    return UILayout.edgePadding, UILayout.edgePadding
end

-- Get position above a registered region
function UILayout.above(name, gap)
    gap = gap or 10
    local region = UILayout.regions[name]
    if region then
        return region.x, region.y - gap
    end
    return UILayout.edgePadding, UILayout.edgePadding
end

-- Update screen dimensions (call on window resize if needed)
function UILayout.setScreenSize(w, h)
    UILayout.screenWidth = w
    UILayout.screenHeight = h
    -- Recalculate all regions
    for name, region in pairs(UILayout.regions) do
        local anchorFn = anchors[region.anchor] or anchors["top-left"]
        local baseX, baseY = anchorFn(region.width, region.height)
        region.x = baseX + region.offsetX
        region.y = baseY + region.offsetY
    end
end

-- Initialize with default regions
function UILayout.init()

end

-- Count registered regions
function UILayout.count()
    local count = 0
    for _ in pairs(UILayout.regions) do count = count + 1 end
    return count
end

return UILayout
