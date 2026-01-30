---@meta
--- ObjectPool - Generic object pooling system
--- Reduces garbage collection pressure by reusing objects instead of creating new ones.
---
--- Usage:
--- ```lua
--- ObjectPool = require "ObjectPool"
---
--- -- Create a pool for bullets
--- local bulletPool = ObjectPool.new(
---     function() return { x = 0, y = 0, active = false } end,  -- Constructor
---     function(b) b.x = 0; b.y = 0; b.active = false end,       -- Reset function
---     50  -- Pre-allocate 50 bullets
--- )
---
--- -- Acquire a bullet from the pool
--- local bullet = bulletPool:acquire()
--- bullet.x, bullet.y = player.x, player.y
---
--- -- Release bullet back to pool when done
--- bulletPool:release(bullet)
--- ```
---@module ObjectPool

---@class ObjectPool
---@field pool table Available objects ready for reuse
---@field active table Currently in-use objects
---@field totalCreated number Total objects ever created
---@field totalReused number Total times objects were reused
local ObjectPool = {}
ObjectPool.__index = ObjectPool

--- Create a new object pool.
---@param constructor function Function that creates a new object
---@param reset function|nil Function(obj) that resets an object for reuse (optional)
---@param initialSize number|nil Number of objects to pre-allocate (optional, default 0)
---@return ObjectPool The new pool instance
function ObjectPool.new(constructor, reset, initialSize)
    local self = setmetatable({}, ObjectPool)
    
    self.constructor = constructor
    self.reset = reset or function(obj) end
    self.pool = {}          -- Available objects
    self.active = {}        -- Currently in-use objects
    self.totalCreated = 0   -- Stats tracking
    self.totalReused = 0
    
    -- Pre-allocate initial objects
    initialSize = initialSize or 0
    for i = 1, initialSize do
        local obj = self.constructor()
        obj._pooled = true
        table.insert(self.pool, obj)
        self.totalCreated = self.totalCreated + 1
    end
    
    return self
end

--- Acquire an object from the pool.
--- Returns a recycled object if available, otherwise creates a new one.
--- If the object has an `init` method and arguments are provided, `obj:init(...)` is called.
---@param ... any Arguments to pass to the object's init method
---@return table The acquired object
function ObjectPool:acquire(...)
    local obj
    
    if #self.pool > 0 then
        -- Reuse from pool
        obj = table.remove(self.pool)
        self.totalReused = self.totalReused + 1
    else
        -- Create new
        obj = self.constructor()
        obj._pooled = true
        self.totalCreated = self.totalCreated + 1
    end
    
    -- Mark as active
    obj._active = true
    self.active[obj] = true
    
    -- Initialize with provided arguments if object has init method
    if obj.init and select('#', ...) > 0 then
        obj:init(...)
    end
    
    return obj
end

--- Release an object back to the pool.
--- The reset function is called to clean up the object before returning it to the pool.
---@param obj table The object to release
---@return boolean success True if the object was successfully released
function ObjectPool:release(obj)
    if not obj or not obj._pooled then
        return false
    end
    
    if not obj._active then
        -- Already released
        return false
    end
    
    -- Mark as inactive
    obj._active = false
    self.active[obj] = nil
    
    -- Reset the object
    self.reset(obj)
    
    -- Return to pool
    table.insert(self.pool, obj)
    
    return true
end

--- Release all active objects back to the pool.
--- Useful for scene transitions or level resets.
---@return nil
function ObjectPool:releaseAll()
    for obj, _ in pairs(self.active) do
        self:release(obj)
    end
end

--- Clear the entire pool (for cleanup/destruction).
--- After calling this, the pool is empty and no objects can be reused.
---@return nil
function ObjectPool:clear()
    self.pool = {}
    self.active = {}
end

--- Get pool statistics for monitoring/debugging.
---@return table stats Table with: available, active, totalCreated, totalReused, reuseRate
function ObjectPool:getStats()
    return {
        available = #self.pool,
        active = self:getActiveCount(),
        totalCreated = self.totalCreated,
        totalReused = self.totalReused,
        reuseRate = self.totalCreated > 0 and 
            (self.totalReused / (self.totalCreated + self.totalReused)) or 0
    }
end

--- Get count of currently active (in-use) objects.
---@return number count Number of active objects
function ObjectPool:getActiveCount()
    local count = 0
    for _ in pairs(self.active) do
        count = count + 1
    end
    return count
end

--- Pre-warm the pool by creating additional objects.
--- Useful to avoid allocation during gameplay.
---@param count number Number of objects to add to the pool
---@return nil
function ObjectPool:prewarm(count)
    for i = 1, count do
        local obj = self.constructor()
        obj._pooled = true
        table.insert(self.pool, obj)
        self.totalCreated = self.totalCreated + 1
    end
end

--- Shrink the pool to a maximum size.
--- Removes excess objects from the available pool (does not affect active objects).
---@param maxSize number Maximum number of available objects to keep
---@return nil
function ObjectPool:shrink(maxSize)
    while #self.pool > maxSize do
        table.remove(self.pool)
    end
end

return ObjectPool
