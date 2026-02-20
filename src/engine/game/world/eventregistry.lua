--- A registry for events. Used to register and retrieve event classes by ID.
---
---@class EventRegistry
---
local EventRegistry = Class()

function EventRegistry:init()
    self.events = {}
end

--- Register a new event with the given ID.
---@param id string                    The ID of the event.
---@param constructor fun(data):Event  A constructor function that takes event data and returns an event instance.
function EventRegistry:register(id, constructor)
    if self.events[id] then
        Kristal.Console:warn("Replacing already-registered event '" .. id .. "'...")
    end

    self.events[id] = constructor
end

--- Check if an event with the given ID is registered.
---@param id string   The ID of the event.
function EventRegistry:has(id)
    return self.events[id] ~= nil
end

--- Get the constructor function registered with the given ID.
---@param id string   The ID of the event.
function EventRegistry:get(id)
    return self.events[id]
end

--- Create a new event instance of the given ID, using the provided data.
---@param id string           The ID of the event.
---@param data table|nil      The data to pass to the event constructor.
---@return Event              The created event instance.
function EventRegistry:create(id, data)
    local event_class = self.events[id]
    if event_class then
        return event_class(data)
    else
        error("Event '" .. id .. "' is not registered!")
    end
end

return EventRegistry
