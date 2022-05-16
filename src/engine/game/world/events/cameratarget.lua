local CameraTarget, super = Class(Event)

function CameraTarget:init(x, y, w, h, properties)
    super:init(self, x, y, w, h)

    self.solid = false

    self.target_x = properties["x"]
    self.target_y = properties["y"]
    self.target_marker = properties["marker"]

    self.lock_x = properties["lockx"] ~= false
    self.lock_y = properties["locky"] ~= false

    self.time = properties["time"] or 0.25
    self.return_time = properties["returntime"] or 0.25

    self.entered = false
end

function CameraTarget:getTargetPosition()
    if self.target_marker then
        return self.world.map:getMarker(self.target_marker)
    else
        return self.target_x or (self.x + self.width / 2), self.target_y or (self.y + self.height / 2)
    end
end

function CameraTarget:onCollide(chara)
    if chara.is_player then
        local x, y = self:getTargetPosition()

        self.entered = true

        if self.lock_x then
            self.world:setCameraAttachedX(false)
        end
        if self.lock_y then
            self.world:setCameraAttachedY(false)
        end

        if not self.world.camera.pan_target then
            self.world.camera:panTo(self.lock_x and x or nil, self.lock_y and y or nil, self.time)
        end
    end
end

function CameraTarget:onExit(chara)
    if chara.is_player then
        self.entered = false
        self.world:returnCamera(self.return_time)
    end
end

function CameraTarget:onRemove(parent)
    if self.entered and self.world then
        local tx, ty = self.world:getCameraTarget()
        self.world:setCameraAttached(true)
        self.world.camera:setPosition(tx, ty)
    end
    super:onRemove(self, parent)
end

return CameraTarget