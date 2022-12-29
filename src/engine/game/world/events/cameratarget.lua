---@class CameraTarget : Event
---@overload fun(...) : CameraTarget
local CameraTarget, super = Class(Event)

function CameraTarget:init(x, y, w, h, properties)
    super.init(self, x, y, w, h)

    self.solid = false

    self.target_x = properties["x"]
    self.target_y = properties["y"]
    self.target_marker = properties["marker"]

    self.lock_x = properties["lockx"] ~= false
    self.lock_y = properties["locky"] ~= false

    self.speed = properties["speed"]
    self.return_speed = properties["returnspeed"]

    self.time = properties["time"]
    self.return_time = properties["returntime"]

    self.entered = false
end

function CameraTarget:getTargetPosition()
    if self.target_marker then
        return self.world.map:getMarker(self.target_marker)
    else
        return self.target_x or (self.x + self.width / 2), self.target_y or (self.y + self.height / 2)
    end
end

function CameraTarget:onEnter(chara)
    if chara.is_player then
        local x, y = self:getTargetPosition()

        local approach_type = self.time and "time" or "speed"

        if self.lock_x then
            self.world.camera:setModifier("x", x, self.time or self.speed, approach_type)
        end
        if self.lock_y then
            self.world.camera:setModifier("y", y, self.time or self.speed, approach_type)
        end
    end
end

function CameraTarget:onExit(chara)
    if chara.is_player then
        self.entered = false

        local approach_speed = self.return_time or self.return_speed or self.time or self.speed
        local approach_type = (self.return_time and "time") or
                              (self.return_speed and "speed") or
                              (self.time and "time") or "speed"

        if self.lock_x then
            self.world.camera:setModifier("x", nil, approach_speed, approach_type)
        end
        if self.lock_y then
            self.world.camera:setModifier("y", nil, approach_speed, approach_type)
        end
    end
end

return CameraTarget