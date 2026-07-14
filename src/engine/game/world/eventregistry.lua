--- A fallback registry for legacy project events which do not define an EditorEvent.
---@class EventRegistry : Class
---@overload fun(): EventRegistry
local EventRegistry = Class()

function EventRegistry:init()
    self.events = {}
end

---@param id string
---@param constructor fun(data: table):Object
function EventRegistry:register(id, constructor)
    assert(type(id) == "string" and id ~= "", "Event registry requires a non-empty id")
    assert(type(constructor) == "function", "Event registry requires a constructor function")
    if self.events[id] then
        Kristal.Console:warn("Replacing already-registered fallback event '" .. id .. "'...")
    end
    self.events[id] = constructor
end

function EventRegistry:has(id)
    return self.events[id] ~= nil
end

function EventRegistry:get(id)
    return self.events[id]
end

function EventRegistry:create(id, data)
    local constructor = self.events[id]
    if not constructor then error("Fallback event '" .. tostring(id) .. "' is not registered!", 2) end
    return constructor(data)
end

return EventRegistry
