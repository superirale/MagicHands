-- UILayer.lua
-- Rendering layer system for proper draw order and coordinate space separation
-- Implements painter's algorithm with z-indexing

local CoordinateSystem = require("UI/CoordinateSystem")

local UILayer = {}

--- Layer types
UILayer.LayerType = {
    World = "World",          -- Game world objects (not used in card game)
    GameUI = "GameUI",        -- Cards, crib, cut card (viewport space)
    HUD = "HUD",              -- Score, buttons, overlays (viewport space)
    Screen = "Screen",        -- Fullscreen overlays (screen space)
    Debug = "Debug"           -- Debug visualizations (screen space)
}

--- Create a new UILayer instance
UILayer.Layer = class()

function UILayer.Layer:init(name, layerType, zIndex)
    self.name = name
    self.layerType = layerType or UILayer.LayerType.GameUI
    self.zIndex = zIndex or 0
    self.visible = true
    self.drawables = {}  -- Array of {draw=function, zIndex=number}
end

--- Add a drawable object to this layer
--- @param drawable table Object with draw() method
--- @param zIndex number|nil Optional z-index within layer (default: 0)
--- @return number id ID for removing drawable
function UILayer.Layer:add(drawable, zIndex)
    table.insert(self.drawables, {
        obj = drawable,
        zIndex = zIndex or 0
    })
    
    -- Sort by z-index
    table.sort(self.drawables, function(a, b)
        return a.zIndex < b.zIndex
    end)
    
    return #self.drawables
end

--- Remove a drawable by ID
--- @param id number ID returned from add()
function UILayer.Layer:remove(id)
    if self.drawables[id] then
        self.drawables[id] = nil
    end
end

--- Clear all drawables
function UILayer.Layer:clear()
    self.drawables = {}
end

--- Draw all objects in this layer
function UILayer.Layer:draw()
    if not self.visible then return end
    
    -- Apply coordinate transform based on layer type
    if self.layerType == UILayer.LayerType.Screen or self.layerType == UILayer.LayerType.Debug then
        -- Screen space: no transform (use physical pixels)
        -- Already in screen space from engine
    elseif self.layerType == UILayer.LayerType.GameUI or self.layerType == UILayer.LayerType.HUD then
        -- Viewport space: render in 1280x720 logical coordinates
        -- Engine handles viewport scaling via graphics.setViewport()
    end
    
    -- Draw all objects in z-order
    for _, item in ipairs(self.drawables) do
        if item and item.obj and item.obj.draw then
            local success, err = pcall(item.obj.draw, item.obj)
            if not success then
                print("[UILayer:" .. self.name .. "] Error drawing object: " .. tostring(err))
            end
        end
    end
end

--- Set layer visibility
--- @param visible boolean
function UILayer.Layer:setVisible(visible)
    self.visible = visible
end

--- Render pipeline manager
UILayer.RenderPipeline = class()

function UILayer.RenderPipeline:init()
    self.layers = {}  -- Sorted array of layers
    self.layersByName = {}  -- Name -> layer lookup
end

--- Add a layer to the pipeline
--- @param name string Layer name
--- @param layerType string Layer type (from UILayer.LayerType)
--- @param zIndex number Layer z-index (draw order)
--- @return UILayer.Layer layer The created layer
function UILayer.RenderPipeline:addLayer(name, layerType, zIndex)
    local layer = UILayer.Layer(name, layerType, zIndex)
    
    table.insert(self.layers, layer)
    self.layersByName[name] = layer
    
    -- Sort layers by z-index
    table.sort(self.layers, function(a, b)
        return a.zIndex < b.zIndex
    end)
    
    print("[RenderPipeline] Added layer: " .. name .. " (zIndex: " .. zIndex .. ")")
    return layer
end

--- Get a layer by name
--- @param name string Layer name
--- @return UILayer.Layer|nil layer The layer, or nil if not found
function UILayer.RenderPipeline:getLayer(name)
    return self.layersByName[name]
end

--- Remove a layer
--- @param name string Layer name
function UILayer.RenderPipeline:removeLayer(name)
    local layer = self.layersByName[name]
    if not layer then return end
    
    -- Remove from array
    for i, l in ipairs(self.layers) do
        if l == layer then
            table.remove(self.layers, i)
            break
        end
    end
    
    self.layersByName[name] = nil
    print("[RenderPipeline] Removed layer: " .. name)
end

--- Draw all layers in order
function UILayer.RenderPipeline:draw()
    for _, layer in ipairs(self.layers) do
        layer:draw()
    end
end

--- Clear all layers
function UILayer.RenderPipeline:clear()
    for _, layer in pairs(self.layers) do
        layer:clear()
    end
end

--- DEBUG: Print layer hierarchy
function UILayer.RenderPipeline:debugPrint()
    print("[RenderPipeline] Layer Hierarchy:")
    for i, layer in ipairs(self.layers) do
        print(string.format("  %d. %s (type: %s, z: %d, drawables: %d, visible: %s)",
            i,
            layer.name,
            layer.layerType,
            layer.zIndex,
            #layer.drawables,
            tostring(layer.visible)
        ))
    end
end

--- Create standard game layers
--- @return UILayer.RenderPipeline pipeline Configured pipeline
function UILayer.createStandardPipeline()
    local pipeline = UILayer.RenderPipeline()
    
    -- Background layer (z=0)
    pipeline:addLayer("Background", UILayer.LayerType.GameUI, 0)
    
    -- Game UI layer (cards, crib, cut card) (z=10)
    pipeline:addLayer("GameUI", UILayer.LayerType.GameUI, 10)
    
    -- HUD layer (score, buttons) (z=20)
    pipeline:addLayer("HUD", UILayer.LayerType.HUD, 20)
    
    -- Overlay layer (shop, previews) (z=30)
    pipeline:addLayer("Overlay", UILayer.LayerType.Screen, 30)
    
    -- Debug layer (always on top) (z=100)
    pipeline:addLayer("Debug", UILayer.LayerType.Debug, 100)
    
    return pipeline
end

return UILayer
