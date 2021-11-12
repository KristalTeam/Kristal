local Character, super = Class(Object)

function Character:init(chara, x, y)
    if type(chara) == "string" then
        chara = Registry.getActor(chara)
    end

    super:init(self, x, y, chara.width, chara.height)

    self.actor = chara
    self.facing = "down"

    self.sprite = ActorSprite(self.actor)
    self.sprite.facing = self.facing
    self:addChild(self.sprite)

    self:setOrigin(0.5, 1)
    self:setScale(2)

    local hitbox = self.actor.hitbox or {0, 0, chara.width, chara.height}
    self.collider = Hitbox(self, hitbox[1], hitbox[2], hitbox[3], hitbox[4])

    -- 1px movement increments
    self.partial_x = (x % 1)
    self.partial_y = (y % 1)

    self.last_collided_x = false
    self.last_collided_y = false

    self.moved = 0

    self.x = math.floor(self.x)
    self.y = math.floor(self.y)

    self.noclip = false

    self.spin_timer = 0
    self.spin_speed = 0
end

function Character:onAdd(parent)
    if parent:includes(World) then
        self.world = parent
    end
end

function Character:getExactPosition(x, y)
    return self.x + self.partial_x, self.y + self.partial_y
end

function Character:setExactPosition(x, y)
    self.x = math.floor(x)
    self.partial_x = x - self.x
    self.y = math.floor(y)
    self.partial_y = y - self.y
end

function Character:setFacing(dir)
    self.facing = dir
    self.sprite.facing = dir
    if not self.sprite.directional and not self.actor.flip then
        self.sprite:resetSprite()
    end
end

function Character:moveTo(x, y)
    self:move(x - (self.x + self.partial_x), y - (self.y + self.partial_y))
end

function Character:move(x, y, speed)
    local movex, movey = x * (speed or 1), y * (speed or 1)

    local moved = false
    moved = self:moveX(movex, movey) or moved
    moved = self:moveY(movey, movex) or moved

    if moved then
        self.moved = math.max(self.moved, math.max(math.abs(movex) / DTMULT, math.abs(movey) / DTMULT))

        self.sprite.walking = true
        self.sprite.walk_speed = self.moved > 0 and math.max(4, self.moved) or 0
    end

    if movex ~= 0 or movey ~= 0 then
        local dir = self.facing
        if self.sprite.directional then
            if movex > 0 then
                dir = (movey ~= 0 and (dir == "down" or dir == "up")) and dir or "right"
            elseif movex < 0 then
                dir = (movey ~= 0 and (dir == "down" or dir == "up")) and dir or "left"
            end
            if movey > 0 then
                dir = (movex ~= 0 and (dir == "left" or dir == "right")) and dir or "down"
            elseif movey < 0 then
                dir = (movex ~= 0 and (dir == "left" or dir == "right")) and dir or "up"
            end
        else
            if movex > 0 then
                dir = "right"
            elseif movex < 0 then
                dir = "left"
            elseif movey > 0 then
                dir = "down"
            elseif movey < 0 then
                dir = "up"
            end
        end

        self.facing = dir
        self.sprite.facing = self.facing
    end

    return moved
end

function Character:moveX(amount, move_y)
    if amount == 0 then
        return false
    end

    self.partial_x = self.partial_x + amount

    local move = math.floor(self.partial_x)
    self.partial_x = self.partial_x % 1

    if move ~= 0 then
        return self:moveXExact(move, move_y)
    else
        return not self.last_collided_x
    end
end

function Character:moveY(amount, move_x)
    if amount == 0 then
        return false
    end

    self.partial_y = self.partial_y + amount

    local move = math.floor(self.partial_y)
    self.partial_y = self.partial_y % 1

    if move ~= 0 then
        return self:moveYExact(move, move_x)
    else
        return not self.last_collided_y
    end
end

function Character:moveXExact(amount, move_y)
    local sign = Utils.sign(amount)
    for i = sign, amount, sign do
        local last_x = self.x
        local last_y = self.y

        self.x = self.x + sign

        if not self.noclip then
            local collided, target = self.world:checkCollision(self.collider)
            if collided and not (move_y > 0) then
                for i = 1, 3 do
                    self.y = self.y - i
                    collided, target = self.world:checkCollision(self.collider)
                    if not collided then break end
                end
            end
            if collided and not (move_y < 0) then
                self.y = last_y
                for i = 1, 3 do
                    self.y = self.y + i
                    collided, target = self.world:checkCollision(self.collider)
                    if not collided then break end
                end
            end
    
            if collided then
                self.x = last_x
                self.y = last_y
                
                if target and target.onCollide then
                    target:onCollide(self)
                end
    
                self.last_collided_x = true
                return false, target
            end 
        end
    end
    self.last_collided_x = false
    return true
end

function Character:moveYExact(amount, move_x)
    local sign = Utils.sign(amount)
    for i = sign, amount, sign do
        local last_x = self.x
        local last_y = self.y

        self.y = self.y + sign

        if not self.noclip then
            Object.startCache()
            local collided, target = self.world:checkCollision(self.collider)
            if collided and not (move_x > 0) then
                for i = 1, 2 do
                    Object.uncache(self)
                    self.x = self.x - i
                    collided, target = self.world:checkCollision(self.collider)
                    if not collided then break end
                end
            end
            if collided and not (move_x < 0) then
                self.x = last_x
                for i = 1, 2 do
                    Object.uncache(self)
                    self.x = self.x + i
                    collided, target = self.world:checkCollision(self.collider)
                    if not collided then break end
                end
            end
            Object.endCache()
    
            if collided then
                self.x = last_x
                self.y = last_y
                
                if target and target.onCollide then
                    target:onCollide(self)
                end
    
                self.last_collided_y = true
                return i ~= sign, target
            end 
        end
    end
    self.last_collided_y = false
    return true
end

function Character:walk(x, y, run, force_dir)
    self:move(x, y, (run and 8 or 4) * DTMULT)
end

function Character:shake(x, y)
    self.sprite.shake_x = x or 0
    self.sprite.shake_y = y or 0
end

function Character:setSprite(sprite)
    self.sprite:setSprite(sprite)
end

function Character:setCustomSprite(sprite, ox, oy)
    self.sprite:setCustomSprite(sprite, ox, oy)
end

function Character:resetSprite()
    self.sprite:resetSprite()
end

function Character:setAnimation(animation)
    self.sprite:setAnimation(animation)
end

function Character:play(speed, loop, reset, on_finished)
    self.sprite:play(speed, loop, reset, on_finished)
end

function Character:jumpTo(x, y, speed, time, jump_sprite, land_sprite)
    self.jump_start_x = self.x
    self.jump_start_y = self.y
    self.jump_x = x
    self.jump_y = y
    self.jump_speed = speed or 0
    self.jump_time = time or 30
    self.jump_sprite = jump_sprite
    self.land_sprite = land_sprite
    self.fake_gravity = 0
    self.jump_arc_y = 0
    self.jump_timer = 0
    self.real_y = 0
    self.drawshadow = false
    --dark = (global.darkzone + 1)
    self.jump_use_sprites = false
    self.jump_sprite_timer = 0
    self.jump_progress = 0
    self.init = false

    if (jump_sprite ~= nil) then
        self.jump_use_sprites = true
    end
    self.drawshadow = false


    self.jumping = true
end

function Character:processJump()
    if (not self.init) then
        self.fake_gravity = (self.jump_speed / (self.jump_time * 0.5))
        self.init = true

        self.false_end_x = self.jump_x
        self.false_end_y = self.jump_y
        if (self.jump_use_sprites) then
            self.sprite:set(self.land_sprite)

            -- TODO: theres a bunch of offsets here.

            --[[
            if (landsprite == spr_kris_dw_landed) -- If it's the Kris kneeling one,
                {
                    self.x = self.x - 4
                    self.y = self.y + 2
                    self.false_end_x  = self.false_end_x  - 8
                    self.jump_start_x = self.jump_start_x - 8
                    self.jump_start_y = self.jump_start_y - 8
                }
                if (landsprite == spr_susie_dw_landed)
                {
                    self.x = self.x - 8
                    self.false_end_x = self.false_end_x - 8
                    self.jump_start_x = self.jump_start_x + 12
                    self.jump_start_y = self.jump_start_y - 12
                }
                if (landsprite == spr_teacup_ralsei_land)
                {
                    self.y = self.y + 4
                    self.jump_start_y = self.jump_start_y + 8
                    self.jump_start_x = self.jump_start_x -  12
                    self.false_end_x = self.false_end_x - 6
                    self.false_end_y = self.false_end_y + 4
                }
                if (jumpsprite == spr_ralsei_jump)
                {
                    shadowoffx = shadowoffx - 10
                    shadowoffy = shadowoffy - 4
                }
            }]]
            self.jump_progress = 1
        else
            self.jump_progress = 2
        end
    end
    if (self.jump_progress == 1) then
        self.jump_sprite_timer = self.jump_sprite_timer + 1 * DTMULT
        if (self.jump_sprite_timer >= 5) then
            self.sprite:set(self.jump_sprite) -- TODO: speed should be 0.25
            self.jump_progress = 2
        end
    end
    if (self.jump_progress == 2) then
        self.jump_timer = self.jump_timer + DTMULT
        self.jump_speed = self.jump_speed - (self.fake_gravity * DTMULT)
        self.jump_arc_y = self.jump_arc_y - (self.jump_speed * DTMULT)
        self.x = Utils.lerp(self.jump_start_x, self.false_end_x, (self.jump_timer / self.jump_time))
        self.real_y = Utils.lerp(self.jump_start_y, self.false_end_y, (self.jump_timer / self.jump_time))

        self.x = self.x
        self.y = self.real_y + self.jump_arc_y

        if (self.jump_timer >= self.jump_time) then
            self.x = self.jump_x
            self.y = self.jump_y

            self.jump_progress = 3
            self.jump_sprite_timer = 0
        end
    end
    if (self.jump_progress == 3) then
        if (self.jump_use_sprites) then
            self.sprite:set(self.land_sprite)
            self.jump_sprite_timer = self.jump_sprite_timer +  DTMULT
        else
            self.jump_sprite_timer = 10
        end
        if (self.jump_sprite_timer >= 5) then
            self.sprite:resetSprite()
            self.jumping = false
        end
    end
end

function Character:update(dt)
    if self.actor.update then
        self.actor:update(self, dt)
    end

    if self.moved > 0 then
        self.sprite.walking = true
        self.sprite.walk_speed = math.max(4, self.moved)
        self.moved = 0
    else
        self.sprite.walking = false
    end

    if self.jumping then
        self:processJump()
    end

    if (self.spin_speed ~= 0) then
        self.spin_timer = self.spin_timer + (1 / self.spin_speed) * DTMULT
        if (self.spin_timer >= 1) then
            if     (self.facing == "down")  then self:setFacing("left")
            elseif (self.facing == "left")  then self:setFacing("up")
            elseif (self.facing == "up")    then self:setFacing("right")
            elseif (self.facing == "right") then self:setFacing("down")
            end

            self.spin_timer = 0
        end
        if (self.spin_timer <= -1) then
            if     (self.facing == "down")  then self:setFacing("right")
            elseif (self.facing == "left")  then self:setFacing("down")
            elseif (self.facing == "up")    then self:setFacing("left")
            elseif (self.facing == "right") then self:setFacing("up")
            end

            self.spin_timer = 0
        end
    else
        self.spin_timer = 0
    end

    super:update(self, dt)
end

function Character:spin(speed)
    self.spin_speed = speed
end

function Character:draw()
    super:draw(self)

    if self.actor.draw then
        self.actor:draw(self)
    end

    if DEBUG_RENDER then
        self.collider:draw(0, 1, 0)
    end
end

return Character