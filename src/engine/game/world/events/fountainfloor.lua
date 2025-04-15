--- The color-changing floor region usually found in front of a dark fountain (intended for use with [DarkFountain](lua://DarkFountain.init)). \
--- `FountainFloor` is an [`Event`](lua://Event.init) - naming an object `fountainfloor` on an `objects` layer in a map creates this object.
--- 
---@class FountainFloor : Event
---
---@field fountain DarkFountain?    The `DarkFountain` object present in this map, if it exists - prioritises using this for object color.
---@field siner number              Timer for the color-changing effect
---@field stage Stage
---
---@overload fun(...) : FountainFloor
local FountainFloor, super = Class(Event)

function FountainFloor:init(x, y, shape)
    super.init(self, x, y, shape)

    self:setColor(0, 1, 0)

    self.fountain = nil

    self.siner = 0
end

function FountainFloor:postLoad()
    if self.stage and not self.fountain then
        self.fountain = self.stage:getObjects(DarkFountain)[1]
    end
end

function FountainFloor:update()
    super.update(self)

    self.siner = self.siner + DTMULT

    self:setColor(((self.siner / 4) / 255) % 1, 1, (60 + (math.sin(self.siner / 16) * 40) + 60) / 255)
end

function FountainFloor:draw()
    if self.fountain then
        Draw.setColor(self.fountain.bg_color)
    end

    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

return FountainFloor