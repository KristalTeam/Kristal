local Character, super = Class(Object)

function Character:init(actor, x, y)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end

    super:init(self, x, y, actor:getSize())

    self.is_player = false

    self.actor = actor
    self.facing = "down"

    self.sprite = ActorSprite(self.actor)
    self.sprite.facing = self.facing
    self.sprite.inherit_color = true
    self.sprite.on_footstep = function(s, n) self:onFootstep(n) end
    self:addChild(self.sprite)

    self:setOrigin(0.5, 1)
    self:setScale(2)

    self.collider = Hitbox(self, self.actor:getHitbox())

    self.last_collided_x = false
    self.last_collided_y = false

    self.moved = 0

    self.noclip = true

    self.enemy_collision = false

    self.spin_timer = 0
    self.spin_speed = 0

    self.move_target = nil
end

function Character:onAdd(parent)
    if parent:includes(World) then
        self.world = parent
    end
end

function Character:getUniqueID()
    if self.unique_id then
        return self.unique_id
    else
        return (self.world or Game.world).map:getUniqueID() .. "#" .. self.object_id
    end
end

function Character:setFlag(flag, value)
    local uid = self:getUniqueID()
    Game:setFlag(uid..":"..flag, value)
end

function Character:getFlag(flag, default)
    local uid = self:getUniqueID()
    return Game:getFlag(uid..":"..flag, default)
end

function Character:getPartyMember()
    for _,party in pairs(Game.party_data) do
        local actor = party:getActor()
        if actor and actor.id == self.actor.id then
            return party
        end
    end
end

function Character:setActor(actor)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end

    self.actor = actor

    self.width = actor:getWidth()
    self.height = actor:getHeight()

    self.collider = Hitbox(self, self.actor:getHitbox())

    if self.sprite then
        self.sprite:remove()
    end

    self.sprite = ActorSprite(self.actor)
    self.sprite.facing = self.facing
    self.sprite.inherit_color = true
    self.sprite.on_footstep = function(s, n) self:onFootstep(n) end
    self:addChild(self.sprite)
end

function Character:setFacing(dir)
    self.facing = dir
    self.sprite.facing = dir
end

function Character:moveTo(x, y, keep_facing)
    if type(x) == "string" then
        keep_facing = y
        x, y = self.world.map:getMarker(x)
    end
    self:move(x - self.x, y - self.y, 1, keep_facing)
end

function Character:move(x, y, speed, keep_facing)
    local movex, movey = x * (speed or 1), y * (speed or 1)

    local moved = false
    moved = self:moveX(movex, movey) or moved
    moved = self:moveY(movey, movex) or moved

    if moved then
        self.moved = math.max(self.moved, math.max(math.abs(movex) / DTMULT, math.abs(movey) / DTMULT))

        self.sprite.walking = true
        self.sprite.walk_speed = self.moved > 0 and math.max(4, self.moved) or 0
    end

    if not keep_facing and (movex ~= 0 or movey ~= 0) then
        local dir = self.facing
        if self.sprite.directional then
            local angle = math.atan2(movey, movex)
            if not Utils.isFacingAngle(self.facing, angle) then
                dir = Utils.facingFromAngle(math.atan2(movey, movex))
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
    return self:doMoveAmount("x", amount, move_y)
end
function Character:moveY(amount, move_x)
    return self:doMoveAmount("y", amount, move_x)
end

function Character:doMoveAmount(type, amount, other_amount)
    other_amount = other_amount or 0

    if amount == 0 then
        self["last_collided_"..type] = false
        return false, false
    end

    local other = type == "x" and "y" or "x"

    local sign = Utils.sign(amount)
    for i = 1, math.ceil(math.abs(amount)) do
        local moved = sign
        if (i > math.abs(amount)) then
            moved = (math.abs(amount) % 1) * sign
        end

        local last_a = self[type]
        local last_b = self[other]

        self[type] = self[type] + moved

        if not self.noclip then
            Object.startCache()
            local collided, target = self.world:checkCollision(self.collider, self.enemy_collision)
            if collided and not (other_amount > 0) then
                for j = 1, 2 do
                    Object.uncache(self)
                    self[other] = self[other] - j
                    collided, target = self.world:checkCollision(self.collider, self.enemy_collision)
                    if not collided then break end
                end
            end
            if collided and not (other_amount < 0) then
                self[other] = last_b
                for j = 1, 2 do
                    Object.uncache(self)
                    self[other] = self[other] + j
                    collided, target = self.world:checkCollision(self.collider, self.enemy_collision)
                    if not collided then break end
                end
            end
            Object.endCache()

            if collided then
                self[type] = last_a
                self[other] = last_b

                if target and target.onCollide then
                    target:onCollide(self)
                end

                self["last_collided_"..type] = true
                return i > 1, target
            end
        end
    end
    self["last_collided_"..type] = false
    return true, false
end

function Character:onFootstep(num)
    if self.world and self.world.map then
        self.world.map:onFootstep(self, num)
    end
    Kristal.callEvent("onFootstep", self, num)
end

function Character:walkTo(x, y, speed, facing, keep_facing)
    if type(x) == "string" then
        keep_facing = facing
        facing = speed
        speed = y
        x, y = self.world.map:getMarker(x)
    end
    if self.x ~= x or self.y ~= y then
        if facing and keep_facing then
            self:setFacing(facing)
        end
        self:setMoveTarget(true, x, y, speed, facing, keep_facing)
        return true
    elseif facing and self.facing ~= facing then
        self:setFacing(facing)
    end
    return false
end

function Character:slideTo(x, y, speed)
    if type(x) == "string" then
        keep_facing = facing
        facing = speed
        speed = y
        x, y = self.world.map:getMarker(x)
    end
    if self.x ~= x or self.y ~= y then
        self:setMoveTarget(false, x, y, speed)
        return true
    end
    return false
end

function Character:setMoveTarget(animate, x, y, speed, facing, keep_facing)
    local angle = Utils.angle(self.x, self.y, x, y)
    self.move_target = {
        animate = animate,
        x = x,
        y = y,
        angle = angle,
        speed = speed or 4,
        facing = facing,
        keep_facing = keep_facing
    }
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

function Character:setAnimation(animation, after)
    self.sprite:setAnimation(animation, after)
end

function Character:play(speed, loop, reset, on_finished)
    self.sprite:play(speed, loop, reset, on_finished)
end

function Character:jumpTo(x, y, speed, time, jump_sprite, land_sprite, ignore_walls)
    if type(x) == "string" then
        land_sprite = jump_sprite
        jump_sprite = time
        time = speed
        speed = y
        x, y = self.world.map:getMarker(x)
    end
    self.jump_start_x = self.x
    self.jump_start_y = self.y
    self.jump_x = x
    self.jump_y = y
    self.jump_speed = speed or 0
    self.jump_time = time or 1
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

    if ignore_walls then
        self.jump_thru_walls = self.collidable
        self.collidable = false
    end

    self.jumping = true
end

function Character:processJump(dt)
    if (not self.init) then
        self.fake_gravity = (self.jump_speed / ((self.jump_time*30) * 0.5))
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
        self.jump_sprite_timer = self.jump_sprite_timer + dt
        if (self.jump_sprite_timer >= 5/30) then
            self.sprite:set(self.jump_sprite) -- TODO: speed should be 0.25
            self.jump_progress = 2
        end
    end
    if (self.jump_progress == 2) then
        self.jump_timer = self.jump_timer + dt
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
            self.jump_sprite_timer = self.jump_sprite_timer +  dt
        else
            self.jump_sprite_timer = 10/30
        end
        if (self.jump_sprite_timer >= 5/30) then
            self.sprite:resetSprite()
            self.jumping = false
            if self.jump_thru_walls then
                self.collidable = true
            end
        end
    end
end

function Character:statusMessage(type, arg, color, kill)
    local x, y = self:getRelativePos(0, self.height, self.world)

    local percent = DamageNumber(type, arg, x, y - 20, color)
    if kill then
        percent.kill_others = true
    end
    percent.layer = WORLD_LAYERS["below_ui"]
    self.world:addChild(percent)

    return percent
end

function Character:convertToFollower(index, save)
    local follower = Follower(self.actor, self.x, self.y)
    follower.layer = self.layer
    follower:setFacing(self.facing)
    self.world:spawnFollower(follower, {index = index})
    if save then
        table.insert(Game.temp_followers, {follower.actor.id, index})
    end
    self:remove()
    return follower
end

function Character:convertToPlayer()
    self.world:spawnPlayer(self.x, self.y, self.actor)
    local player = self.world.player
    player:setLayer(self.layer)
    player:setFacing(self.facing)
    self:remove()
    return player
end

function Character:convertToNPC(properties)
    local npc = NPC(self.actor, self.x, self.y, properties)
    npc.layer = self.layer
    npc:setFacing(self.facing)
    self.world:addChild(npc)
    self:remove()
    return npc
end

function Character:update(dt)
    self.actor:onWorldUpdate(self, dt)

    local party_member = self:getPartyMember()
    if party_member then
        if party_member:getWeapon() then
            party_member:getWeapon():onWorldUpdate(self, dt)
        end
        for i = 1, 2 do
            if party_member:getArmor(i) then
                party_member:getArmor(i):onWorldUpdate(self, dt)
            end
        end
    end

    local target = self.move_target
    if target then
        if self.x == target.x and self.y == target.y then
            self.move_target = nil
            if target.facing then
                self:setFacing(target.facing)
            end
        end
        local tx = Utils.approach(self.x, target.x, math.abs(math.cos(target.angle)) * target.speed * DTMULT)
        local ty = Utils.approach(self.y, target.y, math.abs(math.sin(target.angle)) * target.speed * DTMULT)
        if target.animate then
            self:moveTo(tx, ty, target.keep_facing)
        else
            self:setPosition(tx, ty)
        end
    end

    if self.moved > 0 then
        self.sprite.walking = true
        self.sprite.walk_speed = math.max(4, self.moved)
        self.moved = 0
    else
        self.sprite.walking = false
    end

    if self.jumping then
        self:processJump(dt)
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

    self.actor:onWorldDraw(self)

    if DEBUG_RENDER then
        self.collider:draw(0, 1, 0)
    end
end

return Character