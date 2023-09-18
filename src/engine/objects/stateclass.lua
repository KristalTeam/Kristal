---@class StateClass : Class
---
---@field parent StateManager
---@field registered_events table<string, function>|nil
---
---@overload fun() : StateClass
local StateClass, super = Class()

function StateClass:registerEvents(master) end

--- Register an event for this class.
---@param event string # The name of the event to register.
---@param func? function # The class function to register for the event. If not provided, gets the function with the same name as the event.
function StateClass:registerEvent(event, func)
    if not self.registered_events then
        self.registered_events = {}
    end

    if func then
        if self.parent.master then
            self.registered_events[event] = function(master, ...) return func(self, ...) end
        else
            self.registered_events[event] = function(...) return func(self, ...) end
        end
        return
    end

    local class_func = self[event]

    if class_func then
        if self.parent.master then
            self.registered_events[event] = function(master, ...) return class_func(self, ...) end
        else
            self.registered_events[event] = function(...) return class_func(self, ...) end
        end
        return
    end

    for k, v in Utils.iterClass(self) do
        if type(k) == "string" and type(v) == "function" then
            if k:lower() == event or k:lower() == "on" .. event then
                if self.parent.master then
                    self.registered_events[event] = function(master, ...) return v(self, ...) end
                else
                    self.registered_events[event] = function(...) return v(self, ...) end
                end
                return
            end
        end
    end
end

return StateClass