-- Core.lua
-- Provides Class system and Coroutine Management

Core = {}

-- --- Class System ---
function class(base)
    local c = {}
    if type(base) == 'table' then
        -- Inheritance
        for k,v in pairs(base) do
            c[k] = v
        end
        c._base = base
    end
    c.__index = c

    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj, c)
        if class_tbl.init then
            class_tbl.init(obj, ...)
        end
        return obj
    end
    c.init = function() end -- Default empty init
    setmetatable(c, mt)
    return c
end

-- --- Coroutine Manager ---
-- Similar to Hades 2 'Threads'
local threads = {}

function thread(func, ...)
    local co = coroutine.create(func)
    local args = {...}
    local status, result = coroutine.resume(co, table.unpack(args))
    if not status then
        print("Thread Error: " .. result)
    else
        table.insert(threads, { co = co, waitTime = 0 })
    end
end

function wait(seconds)
    coroutine.yield(seconds)
end

function UpdateCoroutines(dt)
    local activeThreads = {}
    for i, t in ipairs(threads) do
        if t.waitTime > 0 then
            t.waitTime = t.waitTime - dt
            table.insert(activeThreads, t)
        else
            if coroutine.status(t.co) ~= "dead" then
                local status, result = coroutine.resume(t.co)
                if status then
                    if type(result) == "number" then
                        t.waitTime = result
                        table.insert(activeThreads, t)
                    end
                else
                    print("Thread Runtime Error: " .. result)
                end
            end
        end
    end
    threads = activeThreads
end
