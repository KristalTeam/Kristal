---@class Character : Object
---@overload fun(...) : Character
local Character, super = Class(Object)

function Character:init(actor, x, y)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end

    super.init(self, x, y, actor:getSize())

    self.is_player = false
    self.is_follower = false

    self.facing = "down"

    self:setActor(actor)

    self:setOrigin(0.5, 1)
    self:setScale(2)

    self.last_collided_x = false
    self.last_collided_y = false

    self.moved = 0

    self.noclip = true

    self.enemy_collision = false

    self.spin_timer = 0
    self.spin_speed = 0
end

function Character:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "Actor: " .. self.actor.name)
    table.insert(info, "Noclip: " .. (self.noclip and "True" or "False"))
    return info
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

    self.sprite = self.actor:createSprite()
    self.sprite.facing = self.facing
    self.sprite.inherit_color = true
    self.sprite.on_footstep = function(s, n) self:onFootstep(n) end
    self:addChild(self.sprite)
end

function Character:setFacing(dir)
    self.facing = dir
    self.sprite:setFacing(dir)
end

function Character:faceTowards(target)
    self:setFacing(Utils.facingFromAngle(Utils.angle(self.x, self.y, target.x, target.y)))
end

function Character:facePlayer()
    if Game.world and Game.world.player then
        self:faceTowards(Game.world.player)
    end
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

        if (not self.noclip) and (not NOCLIP) then
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

function Character:walkTo(x, y, time, facing, keep_facing, ease, after)
    if type(x) == "string" then
        after = ease
        ease = keep_facing
        keep_facing = facing
        facing = time
        time = y
        x, y = self.world.map:getMarker(x)
    end

    if self:slideTo(x, y, time, ease, function()
        if facing then self:setFacing(facing) end
        if after then after(self) end
    end) then
        if facing and keep_facing then
            self:setFacing(facing)
        end
        self.physics.move_target.move_func = function(_, dx, dy) self:doWalkToStep(dx, dy, keep_facing) end
        return true
    elseif facing and self.facing ~= facing then
        self:setFacing(facing)
    end
    return false
end

function Character:walkToSpeed(x, y, speed, facing, keep_facing, after)
    if type(x) == "string" then
        after = keep_facing
        keep_facing = facing
        facing = speed
        speed = y
        x, y = self.world.map:getMarker(x)
    end

    if self:slideToSpeed(x, y, speed, function()
        if facing then self:setFacing(facing) end
        if after then after(self) end
    end) then
        if facing and keep_facing then
            self:setFacing(facing)
        end
        self.physics.move_target.move_func = function(_, dx, dy) self:doWalkToStep(dx, dy, keep_facing) end
        return true
    elseif facing and self.facing ~= facing then
        self:setFacing(facing)
    end
    return false
end

function Character:walkPath(path, options)
    options = options or {}

    if options["facing"] and options["keep_facing"] then
        self:setFacing(options["facing"])
    end

    local old_after = options.after
    options.after = function()
        if options["facing"] then
            self:setFacing(options["facing"])
        end
        if old_after then
            old_after()
        end
    end

    options.move_func = function(_, dx, dy)
        self:doWalkToStep(dx, dy, options["keep_facing"])
    end

    return self:slidePath(path, options)
end

function Character:doWalkToStep(x, y, keep_facing)
    local was_noclip = self.noclip
    self.noclip = true
    self:move(x, y, 1, keep_facing)
    self.noclip = was_noclip
end

function Character:shakeSelf(x, y, friction, delay)
    super.shake(self, x, y, friction, delay)
end

function Character:stopShakeSelf()
    super.stopShake(self)
end

function Character:shake(x, y, friction, delay)
    if self.sprite then
        self.sprite:shake(x, y, friction, delay)
    else
        self:shakeSelf(x, y, friction, delay)
    end
end

function Character:stopShake()
    if self.sprite then
        self.sprite:stopShake()
    else
        self:stopShakeSelf()
    end
end

function Character:flash(sprite, offset_x, offset_y, layer)
    local sprite_to_use = sprite or self.sprite
    return sprite_to_use:flash(offset_x, offset_y, layer)
end

function Character:setSprite(sprite)
    self.sprite:setSprite(sprite)
end

function Character:setCustomSprite(sprite, ox, oy)
    self.sprite:setCustomSprite(sprite, ox, oy)
end

function Character:setWalkSprite(sprite)
    self.sprite:setWalkSprite(sprite)
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

function Character:jumpTo(x, y, speed, time, jump_sprite, land_sprite)
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

    self.jumping = true
end

function Character:processJump()
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
        self.jump_sprite_timer = self.jump_sprite_timer + DT
        if (self.jump_sprite_timer >= 5/30) then
            self.sprite:set(self.jump_sprite)
            self.jump_progress = 2
        end
    end
    if (self.jump_progress == 2) then
        self.jump_timer = self.jump_timer + DT
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
            self.jump_sprite_timer = self.jump_sprite_timer + DT
        else
            self.jump_sprite_timer = 10/30
        end
        if (self.jump_sprite_timer >= 5/30) then
            self.sprite:resetSprite()
            self.jumping = false
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

function Character:recruitMessage(type, color)
    local x, y = self:getRelativePos(0, self.height, self.world)

    local message = RecruitMessage(type, x, y - 40, color)
    message.layer = WORLD_LAYERS["below_ui"]
    self.world:addChild(message)

    return message
end

function Character:convertToFollower(index, save)
    local follower = Follower(self.actor, self.x, self.y)
    follower.layer = self.layer
    follower:setFacing(self.facing)
    self.world:spawnFollower(follower, {index = index})
    if save then
        Game:addFollower(follower, index)
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

function Character:convertToCharacter()
    local character = Character(self.actor, self.x, self.y)
    character.layer = self.layer
    character:setFacing(self.facing)
    self.world:addChild(character)
    self:remove()
    return character
end

function Character:convertToEnemy(properties)
    local enemy = ChaserEnemy(self.actor, self.x, self.y, properties)
    enemy.layer = self.layer
    enemy:setFacing(self.facing)
    self.world:addChild(enemy)
    self:remove()
    return enemy
end

function Character:update()
    self.actor:onWorldUpdate(self)

    local party_member = self:getPartyMember()
    if party_member then
        if party_member:getWeapon() then
            party_member:getWeapon():onWorldUpdate(self)
        end
        for i = 1, 2 do
            if party_member:getArmor(i) then
                party_member:getArmor(i):onWorldUpdate(self)
            end
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

    super.update(self)
end

function Character:spin(speed)
    self.spin_speed = speed
end

function Character:draw()
    super.draw(self)

    self.actor:onWorldDraw(self)

    if DEBUG_RENDER then
        self.collider:draw(0, 1, 0)
    end
end

return Character