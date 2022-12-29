local PinkSoul, super = Class(Soul)

function PinkSoul:init(x, y)
    super.init(self, x, y)

    self:setColor(1, 0, 0.75)

    self.rotation = math.pi
end

function PinkSoul:onCollide(bullet)
    self:explode()

    super.onCollide(self, bullet)
end

function PinkSoul:doMovement()
    local speed = self.speed

    -- Do speed calculations here if required.

    if Input.down("cancel") then speed = speed / 2 end -- Focus mode.

    local move_x, move_y = 0, 0

    -- Keyboard input:
    if Input.down("left")  then move_x = move_x - 1 end
    if Input.down("right") then move_x = move_x + 1 end
    if Input.down("up")    then move_y = move_y + 1 end
    if Input.down("down")  then move_y = move_y - 1 end

    if move_x ~= 0 or move_y ~= 0 then
        self:move(move_x, move_y, speed * DTMULT)
    end

    self.moving_x = move_x
    self.moving_y = move_y
end

function PinkSoul:update()
    --[[if not self.transitioning then
        if Input.pressed("menu") then
            self:explode()
        end
    end]]

    super.update(self)
end

return PinkSoul