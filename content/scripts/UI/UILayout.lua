-- UILayout.lua
-- OOP Layout System
-- Manages UI regions and element positioning relative to the screen.

local UILayout = class()

-- Static defaults
UILayout.defaultWidth = 1280
UILayout.defaultHeight = 720
UILayout.edgePadding = 20

function UILayout:init(width, height)
    self.screenWidth = width or UILayout.defaultWidth
    self.screenHeight = height or UILayout.defaultHeight
    self.regions = {}

    -- Defining anchors as methods or closure-lookup
    self.anchors = {
        ["top-left"] = function(w, h) return UILayout.edgePadding, UILayout.edgePadding end,
        ["top-right"] = function(w, h) return self.screenWidth - UILayout.edgePadding - w, UILayout.edgePadding end,
        ["bottom-left"] = function(w, h) return UILayout.edgePadding, self.screenHeight - UILayout.edgePadding - h end,
        ["bottom-right"] = function(w, h) return self.screenWidth - UILayout.edgePadding - w,
                self.screenHeight - UILayout.edgePadding - h end,
        ["center"] = function(w, h) return (self.screenWidth - w) / 2, (self.screenHeight - h) / 2 end,
        ["top-center"] = function(w, h) return (self.screenWidth - w) / 2, UILayout.edgePadding end,
        ["bottom-center"] = function(w, h) return (self.screenWidth - w) / 2,
                self.screenHeight - UILayout.edgePadding - h end
    }
end

function UILayout:updateScreenSize(w, h)
    self.screenWidth = w
    self.screenHeight = h
    self:recalculateRegions()
end

function UILayout:register(name, opts)
    local region = {
        name = name,
        anchor = opts.anchor or "top-left",
        width = opts.width or 100,
        height = opts.height or 100,
        offsetX = opts.offsetX or 0,
        offsetY = opts.offsetY or 0,
        x = 0,
        y = 0
    }

    self.regions[name] = region
    self:calculateRegionPos(region)
    return region
end

function UILayout:calculateRegionPos(region)
    local anchorFn = self.anchors[region.anchor] or self.anchors["top-left"]
    local bx, by = anchorFn(region.width, region.height)
    region.x = bx + region.offsetX
    region.y = by + region.offsetY
end

function UILayout:recalculateRegions()
    for _, region in pairs(self.regions) do
        self:calculateRegionPos(region)
    end
end

function UILayout:getPosition(name)
    local r = self.regions[name]
    if r then return r.x, r.y end
    return 0, 0
end

-- Helper for stacking
function UILayout:below(name, gap)
    local r = self.regions[name]
    if r then return r.x, r.y + r.height + (gap or 10) end
    return 0, 0
end

return UILayout
