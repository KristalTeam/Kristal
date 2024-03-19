local BlueSoul, super = Class(Soul)

function BlueSoul:init(x, y)
    super:init(self, x, y)

    self.color = COLORS.blue
    self.speed = 5

    self.jumpstage = 2
    self.slam_pain = false

    self.speed_x = 0
    self.speed_y = 0
end

function BlueSoul:doMovement()
    local speed = self.speed

    if (Input.down("cancel")) then
        self.speed = self.speed / 2
    end

    local move_x, move_y = 0, 0

    if (Input.down("left")) then self:move(-speed, 0, DTMULT) move_x = -1 end
    if (Input.down("right")) then self:move(speed, 0, DTMULT) move_x =  1 end

    self.speed_x = 0

    if (Input.down("up") and self.speed_y == 0 and self.jumpstage == 1) then
        self.jumpstage = 2;
        self.speed_y = -6;
    end

    if (self.jumpstage == 2) then
        if ((not Input.down("up")) and self.speed_y <= -1) then
            self.speed_y = -1
        end

        if ((self.speed_y > 0.5) and (self.speed_y < 8)) then
            self.speed_y = self.speed_y + 0.6
        end
        if ((self.speed_y > -1) and (self.speed_y <= 0.5)) then
            self.speed_y = self.speed_y + 0.2
        end
        if ((self.speed_y > -4) and (self.speed_y <= -1)) then
            self.speed_y = self.speed_y + 0.5
        end
        if ((self.speed_y <= -4)) then
            self.speed_y = self.speed_y + 0.2
        end
    end

    local moved, collided = self:move(self.speed_x, self.speed_y, DTMULT)
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