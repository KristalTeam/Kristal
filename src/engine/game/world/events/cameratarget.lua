--- A region in the Overworld that causes the camera to target a specific position while the player is inside. \
--- `CameraTarget` is an [`Event`](lua://Event.init) - naming an object `cameratarget` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
--- 
---@class CameraTarget : Event
---
---@field solid boolean
---
---@field target_x number       *[Property `x`]* The x-coordinate that the camera will center on 
---@field target_y number       *[Property `y`]* The y-coordinate that the camera will center on
---@field target_marker string  *[Property `marker`]* The marker that the camera will center on
---
---@field lock_x boolean        *[Property `lockx`]* Whether the camera's x position will be locked (Defaults to `true`)
---@field lock_y boolean        *[Property `locky`]* Whether the camera's y position will be locked (Defaults to `true`)
---
---@field speed number          *[Property `speed`]* The speed at which the camera will move to its target position
---@field return_speed number   *[Property `returnspeed`]* The speed at which the camera will return to its original target
---
---@field time number           *[Property `time`]* The time, in seconds, that the camera will take to move to its target position
---@field return_time number    *[Property `returntime`]* The time, in seconds, that the camera will take to return to its original target
---
---@field entered boolean
---
---@overload fun(...) : CameraTarget
local CameraTarget, super = Class(Event)

function CameraTarget:init(x, y, shape, properties)
    super.init(self, x, y, shape)

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

--- Gets the target position of the camera whilst inside this region. \
--- Priority is Marker > target position properties > center of object
---@return number x
---@return number y
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