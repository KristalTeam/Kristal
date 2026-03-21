--- An Overworld region that sets a flag when the player steps into it. \
--- `SetFlagEvent` is an [`Event`](lua://Event.init) - naming an object `setflag` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
---@class SetFlagEvent : Event
---
---@field flag      string      *[Property `flag`]* The name of the flag to set a value on
---@field value     any         *[Property `value`]* The value to set on the flag
---@field once      boolean     *[Property `once`]* Whether the flag can only be set by this region once (Defaults to `false`)
---@field map_flag  boolean     *[Property `mapflag`]* Whether or not the flag is localized to the current map (Defaults to `false`, meaning the flag is global)
---
---@overload fun(...) : SetFlagEvent
local SetFlagEvent, super = Class(Event, "setflag")

function SetFlagEvent:init(x, y, shape, properties)
    super.init(self, x, y, shape)

    properties = properties or {}

    self.flag = properties["flag"]
    self.value = properties["value"]

    self.once = properties["once"]

    self.map_flag = properties["mapflag"]
end

function SetFlagEvent:getDebugInfo()
    local info = super.getDebugInfo(self)
    if self.flag then table.insert(info, "Flag: " .. self.flag) end
    if self.value then table.insert(info, "Value: " .. tostring(self.value)) end
    if self.once then table.insert(info, "Once: " .. (self.once and "True" or "False")) end
    if self.map_flag then table.insert(info, "Map Flag: " .. (self.map_flag and "True" or "False")) end
    return info
end

function SetFlagEvent:onEnter(chara)
    if chara.is_player then
        if self.flag == nil then
            Kristal.Console:warn("SetFlagEvent is missing a flag, ignoring")
            return
        end

        if self.map_flag then
            self.world.map:setFlag(self.flag, (self.value == nil and true) or self.value)
        else
            Game:setFlag(self.flag, (self.value == nil and true) or self.value)
        end

        if self.once then
            self:setFlag("dont_load", true)
            self:remove()
        end

        return true
    end
end

return SetFlagEvent
