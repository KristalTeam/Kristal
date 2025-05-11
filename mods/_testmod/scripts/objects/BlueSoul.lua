local BlueSoul, super = Class(Soul)

function BlueSoul:init(x, y)
    super.init(self, x, y)

    self.color = COLORS.blue
    self.speed = 5

    self.jumpstage = 2
    self.slam_pain = false

    self.speed_x = 0
    self.speed_y = 0

    self.rotation = math.rad(0)
end

function BlueSoul:doMovement()
    local speed = self.speed

    if (Input.down("cancel")) then
        speed = self.speed / 2
    end

    local move_x, move_y = 0, 0

    if (self.rotation >= math.rad(45) and self.rotation < math.rad(135)) or
         (self.rotation >= math.rad(225) and self.rotation < math.rad(315)) then
        if (Input.down("up")) then self:move(0, -speed, DTMULT) move_y = -1 end
        if (Input.down("down")) then self:move(0, speed, DTMULT) move_y =  1 end
    else
        if (Input.down("left")) then self:move(-speed, 0, DTMULT) move_x = -1 end
        if (Input.down("right")) then self:move(speed, 0, DTMULT) move_x =  1 end
    end

    if (Input.down(Utils.facingFromAngle(self.rotation - math.rad(90))) and self.speed_y == 0 and self.jumpstage == 1) then
        self.jumpstage = 2;
        self.speed_y = -6;
    end

    if (self.jumpstage == 2) then
        if ((not Input.down(Utils.facingFromAngle(self.rotation - math.rad(90)))) and self.speed_y <= -1) then
            self.speed_y = -1
        end

        if ((self.speed_y > 0.5) and (self.speed_y < 8)) then
            self.speed_y = self.speed_y + 0.6 * DTMULT
        end
        if ((self.speed_y > -1) and (self.speed_y <= 0.5)) then
            self.speed_y = self.speed_y + 0.2 * DTMULT
        end
        if ((self.speed_y > -4) and (self.speed_y <= -1)) then
            self.speed_y = self.speed_y + 0.5 * DTMULT
        end
        if ((self.speed_y <= -4)) then
            self.speed_y = self.speed_y + 0.2 * DTMULT
        end
    end

    local new_speed_x = math.cos(math.rad(math.deg(self.rotation) + 90))
    local new_speed_y = math.sin(math.rad(math.deg(self.rotation) + 90))

    if (math.abs(new_speed_x) < 0.001) then new_speed_x = 0 end
    if (math.abs(new_speed_y) < 0.001) then new_speed_y = 0 end

    local moved, collided = self:move(new_speed_x, new_speed_y, self.speed_y * DTMULT)
    if (collided) then
        if (self.speed_y > 10) then
		    Assets.stopAndPlaySound("hurt")
		    Assets.stopAndPlaySound("impact")
            Game.battle:shakeCamera(self.speed_y / 3, self.speed_y / 3, 1)
        end

        self.speed_y = 0
        self.jumpstage = 1
    end

    self.moving_x = move_x
    self.moving_y = move_y
end

return BlueSoul
