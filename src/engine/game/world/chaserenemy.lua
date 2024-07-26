--- An enemy that can chase the player and start encounters. \
--- ChaserEnemies are `Event`s and therefore can be added to a map by naming an object `enemy`. \
--- Several properties on ChaserEnemies can be configured. See the `Fields` section for properties that can be configured.
---
---@class ChaserEnemy : Character
---
---@field encounter     string  The encounter ID that will trigger when the player collides with the enemy.
---@field enemy         string  The actor ID to use for this enemy.
---@field group         string  An arbitrary ID that can be be used to group enemies together in a room. When one enemy in a group is defeated, all enemies in the group are defeated as well. 
---
---@field path          string  The name of a path shape in the current map that the enemy will follow.
---@field speed         number  The speed that the enemy will move along the path specified in `path`, if defined.
---
---@field progress      number  The initial progress of the enemy along their path, if defined, as a decimal value between 0 and 1.
---
---@field can_chase     boolean (Named `chase` when setting this value in a map) Whether the enemy will chase after players it catches sight of. Defaults to `true`.
---@field chasing       boolean Whether the enemy is chasing the player when they enter the room. Defaults to `false`.
---@field chase_dist    number  (Named `chasedist` when setting this value in a map) The distance, in pixels, that the enemy can see the player from. Defaults to `200`.
---
---@field chase_type    string  (Naamed `chasetype` when setting this value in a map) The name of the chasetype to use. See CHASETYPE for available types.
---@field chase_speed   number  (Named `chasespeed` when setting this value in a map) The speed the enemy will chase the player at, in pixels per frame at 30FPS. Defaults to `9`.
---@field chase_max     number  (Named `chasemax` when setting this value in a map) The maximum speed the enemy will chase the player at, if `chase_accel` is set.
---@field chase_accel   number  (Named `chaseaccel` when setting this value in a map) The acceleration of the enemy when chasing the player, in change of pixels per frame at 30FPS, or a multiplier of previous speed when in `multiplier` mode.
---
---@field once          boolean Whether this enemy can only be encountered once (Will not respawn when the room reloads). Defaults to `false`.
---
---@field aura          boolean Whether this enemy will have an aura around it as seen with enemies in Deltarune Chapter 2. Overrides the mod-wide config for enemy auras.
---
---@overload fun(...) : ChaserEnemy
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

    self.chase_timer = 0

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
    if self.path        then table.insert(info, "Path: "     .. self.path)     end
    if self.progress    then table.insert(info, "Progress: " .. self.progress) end
    table.insert(info, "Can chase: "           .. (self.can_chase and "True" or "False"))
    if self.can_chase then
        table.insert(info, "Chase type: "          .. self.chase_type)
        table.insert(info, "Chase speed: "         .. self.chase_speed)
        table.insert(info, "Chase distance: "      .. self.chase_dist)
        table.insert(info, "Chasing: "             .. (self.chasing             and "True" or "False"))
        if self.chase_max then table.insert(info, "Maximum chase speed: " ..self.chase_max) end
        if self.chase_accel then table.insert(info, "Chase acceleration: " .. self.chase_accel) end
    end
    table.insert(info, "Remove on encounter: " .. (self.remove_on_encounter and "True" or "False"))
    table.insert(info, "Encountered: "         .. (self.encountered         and "True" or "False"))
    return info
end

function ChaserEnemy:onCollide(player)
    if self:isActive() and player:includes(Player) then
        self.encountered = true
        local encounter = self.encounter
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
                wait(8/30)
                local src = Assets.playSound("tensionhorn")
                src:setPitch(1.1)
                wait(12/30)
                self.world.encountering_enemy = false
                Game.lock_movement = false
                local enemy_target = self
                if self.enemy then
                    enemy_target = {{self.enemy, self}}
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
    for _,enemy in ipairs(self.stage:getObjects(ChaserEnemy)) do
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
        local statue = FrozenEnemy(self.actor, self.x, self.y, {facing = self.sprite.facing})
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

            for i = 1, #path.points-1 do
                local next_dist = Utils.dist(path.points[i].x, path.points[i].y, path.points[i+1].x, path.points[i+1].y)

                if current_dist + next_dist > dist then
                    local x = Utils.lerp(path.points[i].x, path.points[i+1].x, (dist - current_dist) / next_dist)
                    local y = Utils.lerp(path.points[i].y, path.points[i+1].y, (dist - current_dist) / next_dist)

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
            local angle = progress * (math.pi*2)
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
                self.progress = Utils.clamp(self.progress, 0, 1)
                self.reverse_progress = not self.reverse_progress
            end

            self:snapToPath()
        end

        if self.alert_timer == 0 and self.can_chase and not self.chasing then
            if self.world.player then
                Object.startCache()
                local in_radius = self.world.player:collidesWith(CircleCollider(self.world, self.x, self.y, self.chase_dist))
                if in_radius then
                    local sight = LineCollider(self.world, self.x, self.y, self.world.player.x, self.world.player.y)
                    if not self.world:checkCollision(sight, true) and not self.world:checkCollision(self.collider, true) then
                        self.path = nil
                        self:alert(nil, {callback=function()
                            self.chasing = true
                            self.noclip = false
                            self:setAnimation("chasing")
                        end})
                        self:setAnimation("alerted")
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

function ChaserEnemy:chaseMovement()
    if not self.world.player then
        return
    end

    self.chase_timer = self.chase_timer + DTMULT

    local angle = Utils.angle(self.x, self.y, self.world.player.x, self.world.player.y)

    if self.chase_type == "linear" or self.chase_type == "flee" then
        if self.chase_accel and (not self.chase_max or self.chase_speed < self.chase_max) then
            self.chase_speed = self.chase_speed + (DTMULT * self.chase_accel)
        end

    elseif self.chase_type == "multiplier" then
        self.chase_init = self.chase_init ~= nil and self.chase_init or self.chase_speed
        if self.chase_accel and (not self.chase_max or self.chase_speed < self.chase_max) then
            self.chase_speed = self.chase_init * math.pow(self.chase_accel, self.chase_timer)
        end

    elseif self.chase_type == "flee" then
        local center_x = self.x + self.width
        local center_y = self.y + self.height

        if Utils.dist(center_x, center_y, self.world.soul.x + self.world.soul.width, self.world.soul.y + self.world.soul.height) > 50 then
            angle = angle + math.rad(180)
        end
    end
    
    
    self:move(math.cos(angle), math.sin(angle), self.chase_speed * DTMULT)
end

return ChaserEnemy