local SetFlagEvent, super = Class(Event, "setflag")

function SetFlagEvent:init(x, y, width, height, properties)
    super:init(self, x, y, width, height)

    properties = properties or {}

    self.flag = properties["flag"]
    self.value = properties["value"]

    self.once = properties["once"]

    self.map_flag = properties["mapflag"]
end

function SetFlagEvent:onEnter(chara)
    if chara.is_player then
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