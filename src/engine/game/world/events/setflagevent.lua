local SetFlagEvent, super = Class(Event)

function SetFlagEvent:init(x, y, width, height, properties)
    super:init(self, x, y, width, height)

    properties = properties or {}

    self.flag = properties["flag"]
    self.value = properties["value"]

    self.once = properties["once"]
end

function SetFlagEvent:onEnter(chara)
    if chara.is_player then
        Game:setFlag(self.flag, (self.value == nil and true) or self.value)

        if self.once then
            self:setFlag("dont_load", true)
            self:remove()
        end

        return true
    end
end

return SetFlagEvent