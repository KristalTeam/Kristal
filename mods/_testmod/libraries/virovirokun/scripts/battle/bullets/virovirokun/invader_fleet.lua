local InvaderFleet, super = Class(Bullet, "virovirokun/invader_fleet")

function InvaderFleet:init(x, y, fleet_size, fleet_speed, dir, buffed)
    super.init(self, x, y)

    -- Arguments
    self.fleet_size = fleet_size or 1
    self.fleet_speed = fleet_speed or 1
    self.dir = dir or 1
    self.buffed = buffed or false

    -- Bullet variables
    self.layer = BATTLE_LAYERS["bullets"] + 10
    self.collider = nil
    self.tp = self.buffed and 1.6 or 2

    -- State variables
    self.move_amount = (self.fleet_speed > 1) and 8 or 6
    self.move_interval = (self.fleet_speed ^ 2) * 2
    self.shot_timer = 20 + (love.math.random(30) - 1)
    self.move_timer = 0

    self.firing_speed = self:getRatio()

    self.invaders = {}
end

function InvaderFleet:onAdd(parent)
    super.onAdd(self, parent)

    local fleet_width = (self.fleet_size * 16)

    for i = 1, self.fleet_size do
        local invader = self.wave:spawnBulletTo(self, "virovirokun/invader", (-fleet_width/2) + ((i - 1) * 16) + 8, 0)
        invader:setScale(1, 1)
        --invader.firing_speed = self.firing_speed
        invader.buffed = self.buffed
        invader.tp = self.tp
        table.insert(self.invaders, invader)
    end

    self.shot_timer = self.shot_timer - 10 -- wtf??? why
end

function InvaderFleet:getRatio()
    if self.fleet_size == 1 then
        return
    elseif self.fleet_size == 3 then
        -- I dont think theres a pattern to this so, deltarune accuracy
        return 2.3
    else
        return 1 + (0.6 * (self.fleet_size - 1))
    end
end

function InvaderFleet:getMinX()
    return Game.battle.arena.left + 10 + (self.fleet_size * 16)/2
end

function InvaderFleet:getMaxX()
    return Game.battle.arena.right - 10 - (self.fleet_size * 16)/2
end

function InvaderFleet:nextFrame()
    for _,invader in ipairs(self.invaders) do
        invader:nextFrame()
    end
end

function InvaderFleet:update()
    super.update(self)

    self.move_timer = self.move_timer + DTMULT
    if self.move_timer >= self.move_interval then
        local next_x = self.x + (self.dir * self.move_amount)
        if (next_x > self:getMaxX() and self.dir == 1) or (next_x < self:getMinX() and self.dir == -1) then
            self.y = self.y + 16
            self.dir = -self.dir
            if self.shot_timer < 10 then
                self.shot_timer = 10
            end
        else
            self.x = next_x
        end
        self:nextFrame()
        if self.fleet_speed > 1 then
            self.move_timer = 0
        else
            self.move_timer = self.move_interval - 1
        end
    end

    local force_shot = false
    local force_target = 0
    local temp_move = self.dir * self.move_amount
    if self.shot_timer < (self.fleet_size == 1 and 12 or 16) and self.buffed then
        Object.startCache()
        for i,invader in ipairs(self.invaders) do
            if invader.stage then
                local next_x = invader.x + ((temp_move / self.move_interval) * 16)

                local invader_x, invader_y = invader:getRelativePosFor(Game.battle)
                local soul_x, soul_y = Game.battle.soul:getRelativePosFor(Game.battle)

                if math.abs(invader_x - soul_x) < 4 then
                    force_shot = true
                    force_target = i
                    break
                end
            end
            temp_move = -temp_move
        end
        Object.endCache()
    end

    if (self.shot_timer <= 0 and self.y < Game.battle.arena.top + 50) or force_shot then
        local shooter = love.math.random(self.fleet_size)
        if force_shot then
            shooter = force_target
        end
        if self.invaders[shooter] and self.invaders[shooter].stage then
            self.invaders[shooter].shot_ready = true
            if self.fleet_size == 1 then
                self.shot_timer = 20 + (love.math.random(20) - 1)
            else
                self.shot_timer = 40 + (love.math.random(30) - 1)
            end
        end
    else
        self.shot_timer = self.shot_timer - (self.fleet_size * DTMULT)
    end
end

return InvaderFleet