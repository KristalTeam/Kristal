--- An enemy found in the Overworld that can chase the player and start encounters. \
--- `ChaserEnemy` is an `Event`* - naming an object `enemy` on an `objects` layer in a map creates this object. *(Does not inherit the `Event` class, inherits [`Character`](lua://Character.lua)) \
--- See this object's Fields for the configurable properties on this object.
---
---@class ChaserEnemy : Character
---
---@field encounter     string  *[Property `encounter`]* The encounter ID that will trigger when the player collides with the enemy.
---@field enemy         string  *[Property `enemy`]* The actor ID to use for this enemy.
---@field group         string  *[Property `group`]* An arbitrary ID that can be be used to group enemies together in a room. When one enemy in a group is defeated, all enemies in the group are defeated as well. 
---
---@field path          string  *[Property `path`]* The name of a path shape in the current map that the enemy will follow.
---@field speed         number  *[Property `speed`]* The speed that the enemy will move along the path specified in `path`, if defined.
---
---@field progress      number  *[Property `progress`]* The initial progress of the enemy along their path, if defined, as a decimal value between 0 and 1.
---
---@field can_chase     boolean *[Property `chase`]* Whether the enemy will chase after players it catches sight of (Defaults to `true`)
---@field chasing       boolean *[Property `chasing`]* Whether the enemy is chasing the player when they enter the room. (Defaults to `false`)
---@field chase_dist    number  *[Property `chasedist`]* The distance, in pixels, that the enemy can see the player from (Defaults to `200`)
---
---@field chase_type    string  *[Property `chasetype`]* The name of the chasetype to use. See [CHASETYPE](lua://CHASETYPE) for available types.
---@field chase_speed   number  *[Property `chasespeed`]* The speed the enemy will chase the player at, in pixels per frame at 30FPS (Defaults to `9`)
---@field chase_max     number  *[Property `chasemax`]* The maximum speed the enemy will chase the player at, if `chase_accel` is set (Speed is uncapped if unset)
---@field chase_accel   number  *[Property `chaseaccel`]* The acceleration of the enemy when chasing the player, in change of pixels per frame at 30FPS, or a multiplier of speed when in `multiplier` mode.
---
---@field pace_type     string  *[Property `pacetype`]* The type of pacing that the enemy will do while idling. See [PACETYPE](lua://PACETYPE) for available types.
---@field pace_marker   table   *[Property list `marker`]* The name of a marker, or a list of markers that the enemy will pace between when `wander` pacing.
---@field pace_interval number  *[Property `paceinterval`]* The interval between actions when `wander` pacing (Defaults to `24`)
---@field pace_return   boolean *[Property `pacereturn`]* Whether the enemy should return to its spawn point between every point when its `pace_type` is set to `wander` or `randomwander`. (Defaults to `true`)
---@field pace_speed    number  *[Property `pacespeed`]* The speed at which the enemy walks when `wander` pacing (Defaults to `2`)
---@field swing_divisor number  *[Property `swingdiv`]* A divisor for the speed of the swing of this enemy when swing pacing (Higher number = slower) (Defaults to `24`)
---@field swing_length  number  *[Property `swinglength`]* The full length swing covered by this enemy when swing pacing. The enemy placement position is the center of the line (Defaults to `400`)
---
---@field once          boolean *[Property `once`]* Whether this enemy can only be encountered once (Will not respawn when the room reloads) (Defaults to `false`)
---
---@field aura          boolean *[Property `aura`]* Whether this enemy will have an aura around it as seen with enemies in Deltarune Chapter 2. Overrides the mod-wide config for enemy auras.
---
---*[Property `actor`]* Actor to use for this enemy \
---*[Property `sprite` or `animation`]* Default sprite/animation to set on this enemy
---@field sprite        ActorSprite 
---
---@field chase_timer       number
---@field pace_timer        number
---@field chase_init_speed  number
---@field spawn_x           number
---@field spawn_y           number
---@field pace_index        integer
---@field wandering         boolean
---@field return_to_spawn   boolean
---@field noclip            boolean
---@field enemy_collision   boolean
---@field remove_on_encounter   boolean
---@field encountered       boolean
---@field visible           boolean
---@field reverse_progress  boolean
---
---@overload fun(actor: string|Actor, x?: number, y?: number, properties?: table) : ChaserEnemy
local ChaserEnemy, super = Class(Character, "enemy")

function ChaserEnemy:init(actor, x, y, properties)
    super.init(self, actor, x, y)

    properties = properties or {}

    if properties["sprite"] then
        self.sprite:setSprite(properties["sprite"])
    elseif properties["animation"] then
        self.sprite:setAnimation(properties["animation"])
    end

    if properties["facing"] then
        self:setFacing(properties["facing"])
    end

    self.encounter = properties["encounter"]
    self.enemy = properties["enemy"]
    self.group = properties["group"]

    self.path = properties["path"]
    self.speed = properties["speed"] or 6

    self.progress = (properties["progress"] or 0) % 1
    self.reverse_progress = false

    self.can_chase = properties["chase"]
    self.chasing = properties["chasing"] or false
    self.chase_dist = properties["chasedist"] or 200

    self.chase_type = properties["chasetype"] or "linear"
    self.chase_speed = properties["chasespeed"] or 9
    self.chase_max = properties["chasemax"]
    self.chase_accel = properties["chaseaccel"]

    self.pace_type = properties["pacetype"]
    self.pace_marker = TiledUtils.parsePropertyList("marker", properties)
    self.pace_interval = properties["paceinterval"] or 24
    self.pace_return  = properties["pacereturn"] or true
    self.pace_speed = properties["pacespeed"] or 4
    self.swing_divisor = properties["swingdiv"] or 24
    self.swing_length = properties["swinglength"] or 400

    self.chase_timer = 0
    self.pace_timer = 0

    -- Used for multiplier acceleration to keep acceleration consistent across framerates.
    self.chase_init_speed = self.chase_speed
    -- Starting x-coordinate of the enemy for pacing types.
    self.spawn_x = x
    -- Starting y-coordinate of the enemy for pacing types.
    self.spawn_y = y
    self.pace_index = 1
    self.wandering = false
    self.return_to_spawn = false

    self.noclip = true
    self.enemy_collision = true

    self.remove_on_encounter = true
    self.encountered = false
    self.once = properties["once"] or false

    if properties["aura"] == nil then
        self.sprite.aura = Game:getConfig("enemyAuras")
    else
        self.sprite.aura = properties["aura"]
    end
end

function ChaserEnemy:getDebugInfo()
    local info = super.getDebugInfo(self)
    if self.path then table.insert(info, "Path: " .. self.path) end
    if self.progress then table.insert(info, "Progress: " .. self.progress) end
    table.insert(info, "Can chase: " .. (self.can_chase and "True" or "False"))
    if self.can_chase then
        table.insert(info, "Chase type: " .. self.chase_type)
        table.insert(info, "Chase speed: " .. self.chase_speed)
        table.insert(info, "Chase distance: " .. self.chase_dist)
        table.insert(info, "Chasing: " .. (self.chasing and "True" or "False"))
        if self.chase_max then table.insert(info, "Maximum chase speed: " .. self.chase_max) end
        if self.chase_accel then table.insert(info, "Chase acceleration: " .. self.chase_accel) end
    end
    table.insert(info, "Remove on encounter: " .. (self.remove_on_encounter and "True" or "False"))
    table.insert(info, "Encountered: " .. (self.encountered and "True" or "False"))
    return info
end

function ChaserEnemy:onCollide(player)
    if self:isActive() and player:includes(Player) then
        self.encountered = true
        local encounter = self.encounter ---@type string|Encounter
        if not encounter and Registry.getEnemy(self.enemy or self.actor.id) then
            encounter = Encounter()
            encounter:addEnemy(self.actor.id)
        end
        if encounter then
            self.world.encountering_enemy = true
            self.sprite:setAnimation("hurt")
            self.sprite.aura = false
            Game.lock_movement = true
            self.world.timer:script(function(wait)
                Assets.playSound("tensionhorn")
                wait(8 / 30)
                local src = Assets.playSound("tensionhorn")
                src:setPitch(1.1)
                wait(12 / 30)
                self.world.encountering_enemy = false
                Game.lock_movement = false
                local enemy_target = self ---@type ChaserEnemy|table[]
                if self.enemy then
                    enemy_target = { { self.enemy, self } }
                end
                Game:encounter(encounter, true, enemy_target, self)
            end)
        end
    end
end

function ChaserEnemy:onAdd(parent)
    super.onAdd(self, parent)

    self:snapToPath()
end

function ChaserEnemy:getGroupedEnemies(include_self)
    local group = {}
    if include_self then
        table.insert(group, self)
    end
    for _, enemy in ipairs(self.stage:getObjects(ChaserEnemy)) do
        if enemy ~= self and self.group and enemy.group == self.group then
            table.insert(group, enemy)
        end
    end
    return group
end

function ChaserEnemy:onEncounterStart(primary, encounter)
    self.visible = false
end

function ChaserEnemy:onEncounterTransitionOut(primary, encounter)
    local enemy = Game.battle:getEnemyFromCharacter(self)
    if enemy and enemy.done_state == "FROZEN" then
        local statue = FrozenEnemy(self.actor, self.x, self.y, { facing = self.sprite:getFacing() })
        statue.layer = self.layer
        Game.world:addChild(statue)
    end
end

function ChaserEnemy:onEncounterEnd(primary, encounter)
    if self.remove_on_encounter then
        self:remove()
    else
        self.visible = true
    end
    if self.once then
        self:setFlag("dont_load", true)
    end
end

function ChaserEnemy:snapToPath()
    if self.path and self.world.map.paths[self.path] then
        local path = self.world.map.paths[self.path]

        local progress = self.progress
        if not path.closed then
            progress = Ease.inOutSine(progress, 0, 1, 1)
        end

        if path.shape == "line" then
            local dist = progress * path.length
            local current_dist = 0

            for i = 1, #path.points - 1 do
                local next_dist = MathUtils.dist(path.points[i].x, path.points[i].y, path.points[i + 1].x, path.points[i + 1].y)

                if current_dist + next_dist > dist then
                    local x = MathUtils.lerp(path.points[i].x, path.points[i + 1].x, MathUtils.clamp((dist - current_dist) / next_dist, 0, 1))
                    local y = MathUtils.lerp(path.points[i].y, path.points[i + 1].y, MathUtils.clamp((dist - current_dist) / next_dist, 0, 1))

                    if self.debug_x and self.debug_y and Kristal.DebugSystem.last_object == self then
                        x = Utils.ease(self.debug_x, x, Kristal.DebugSystem.release_timer, "outCubic")
                        y = Utils.ease(self.debug_y, y, Kristal.DebugSystem.release_timer, "outCubic")
                        if Kristal.DebugSystem.release_timer >= 1 then
                            self.debug_x = nil
                            self.debug_y = nil
                        end
                    end

                    self:moveTo(x, y)
                    break
                else
                    current_dist = current_dist + next_dist
                end
            end
        elseif path.shape == "ellipse" then
            local angle = progress * (math.pi * 2)
            local x = path.x + math.cos(angle) * path.rx
            local y = path.y + math.sin(angle) * path.ry

            if self.debug_x and self.debug_y and Kristal.DebugSystem.last_object == self then
                x = Utils.ease(self.debug_x, x, Kristal.DebugSystem.release_timer, "outCubic")
                y = Utils.ease(self.debug_y, y, Kristal.DebugSystem.release_timer, "outCubic")
                if Kristal.DebugSystem.release_timer >= 1 then
                    self.debug_x = nil
                    self.debug_y = nil
                end
            end

            self:moveTo(x, y)
        end
    end
end

function ChaserEnemy:isActive()
    return not self.encountered and
        not self.world.encountering_enemy and
        not self.world:hasCutscene() and
        self.world.state ~= "MENU" and
        Game.state == "OVERWORLD"
end

function ChaserEnemy:update()
    if self:isActive() then
        if self.path and self.world.map.paths[self.path] then
            local path = self.world.map.paths[self.path]

            if self.reverse_progress then
                self.progress = self.progress - (self.speed / path.length) * DTMULT
            else
                self.progress = self.progress + (self.speed / path.length) * DTMULT
            end
            if path.closed then
                self.progress = self.progress % 1
            elseif self.progress > 1 or self.progress < 0 then
                self.progress = MathUtils.clamp(self.progress, 0, 1)
                self.reverse_progress = not self.reverse_progress
            end

            self:snapToPath()
        elseif self.pace_type and not self.alert_icon and not self.chasing then
            self:paceMovement()
        end

        if self.alert_timer == 0 and self.can_chase and not self.chasing then
            if self.world.player then
                Object.startCache()
                local in_radius = self.world.player:collidesWith(CircleCollider(self.world, self.x, self.y, self.chase_dist))
                if in_radius then
                    local sight = LineCollider(self.world, self.x, self.y, self.world.player.x, self.world.player.y)
                    if not self.world:checkCollision(sight, true) and not self.world:checkCollision(self.collider, true) then
                        self.path = nil
                        self:alert(nil, { callback = function()
                            self.chasing = true
                            self.noclip = false
                            self:setAnimation("chasing")
                        end })
                        self:setAnimation("alerted")
                        self:onAlerted()
                    end
                end
                Object.endCache()
            end
        elseif self.chasing then
            self:chaseMovement()
        end
    end

    super.update(self)
end

--- *(Override)* Called whenever the enemy is alerted of the player's presence. \
--- *By default, used to cancel any potentially active movement for standard pacetypes.*
function ChaserEnemy:onAlerted()
    if self.physics.move_target and self.physics.move_target.after then
        self.physics.move_target:after()
    end
    self.physics.move_target = nil

    if self.physics.move_path and self.physics.move_path.after then
        self.physics.move_path:after()
    end
    self.physics.move_path = nil
end

--- *(Override)* Responsible for movement of the `ChaserEnemy` when it has been alerted of a player's presence. \
--- This function can be hooked to add custom chase types.
function ChaserEnemy:chaseMovement()
    if not self.world.player then
        return
    end

    self.chase_timer = self.chase_timer + DTMULT

    local angle = Utils.angle(self.x, self.y, self.world.player.x, self.world.player.y)

    if self.chase_type == "flee" then
        angle = angle + math.rad(180)
    end
    if self.chase_type == "linear" or self.chase_type == "flee" then
        if self.chase_accel and (not self.chase_max or self.chase_speed < self.chase_max) then
            self.chase_speed = self.chase_speed + (DTMULT * self.chase_accel)
        end
        self:move(math.cos(angle), math.sin(angle), self.chase_speed * DTMULT)
    end
    if self.chase_type == "multiplier" then
        if self.chase_accel and (not self.chase_max or self.chase_speed < self.chase_max) then
            self.chase_speed = self.chase_init_speed * math.pow(self.chase_accel, self.chase_timer)
        end
        self:move(math.cos(angle), math.sin(angle), self.chase_speed * DTMULT)
    end

end

--- *(Override)* Responsible for movement of the `ChaserEnemy` when idle. Only called if `pace_type` is set. \
--- This function can be hooked to add custom pace types.
function ChaserEnemy:paceMovement()
    self.pace_timer = self.pace_timer + DTMULT
    if self.pace_type == "wander" then
        if self.pace_timer < self.pace_interval or self.wandering then
            return
        end

        if not self.return_to_spawn then
            self.wandering = true
            if self.pace_return or self.pace_index == #self.pace_marker then
                self.return_to_spawn = true
            end
            self:walkToSpeed(self.pace_marker[self.pace_index], self.pace_speed, nil, false, function() self.pace_timer = 0; self.wandering = false end)
            self.pace_index = MathUtils.wrapIndex(self.pace_index + 1, #self.pace_marker)
            return
        end

        self.wandering = true
        self:walkToSpeed(self.spawn_x, self.spawn_y, self.pace_speed, nil, false, function() self.pace_timer = 0; self.wandering = false; self.return_to_spawn = false end)
    elseif self.pace_type == "randomwander" then
        if self.pace_timer < self.pace_interval or self.wandering then
            return
        end

        if not self.return_to_spawn then
            self.wandering = true
            if self.pace_return then
                self.return_to_spawn = true
            end
            self:walkToSpeed(TableUtils.pick(self.pace_marker), self.pace_speed, nil, false, function() self.pace_timer = 0; self.wandering = false end)
            return
        end

        self.wandering = true
        self:walkToSpeed(self.spawn_x, self.spawn_y, self.pace_speed, nil, false, function() self.pace_timer = 0; self.wandering = false; self.return_to_spawn = false end)

    elseif self.pace_type == "verticalswing" then
        local y = Utils.wave(self.pace_timer / self.swing_divisor, self.spawn_y - (self.swing_length / 2), self.spawn_y + (self.swing_length / 2))
        self:moveTo(self.x, y)
    elseif self.pace_type == "horizontalswing" then
        local x = Utils.wave(self.pace_timer / self.swing_divisor, self.spawn_x - (self.swing_length / 2), self.spawn_x + (self.swing_length / 2))
        self:moveTo(x, self.y)
    end
end

return ChaserEnemy
