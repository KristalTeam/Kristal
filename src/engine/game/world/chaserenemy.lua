local ChaserEnemy, super = Class(Character)

function ChaserEnemy:init(actor, x, y, properties)
    super:init(self, actor, x, y)

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
    self.group = properties["group"]

    self.path = properties["path"]
    self.speed = properties["speed"] or 6

    self.progress = (properties["progress"] or 0) % 1
    self.reverse_progress = false

    self.can_chase = properties["chase"]
    self.chase_speed = properties["chasespeed"] or 9
    self.chase_dist = properties["chasedist"] or 200
    self.chasing = false

    self.alert_timer = 0
    self.alert_icon = nil

    self.noclip = true
    self.enemy_collision = true

    self.remove_on_encounter = true
    self.encountered = false

    if properties["aura"] == nil then
        self.sprite.aura = Game:getConfig("enemyAuras")
    else
        self.sprite.aura = properties["aura"]
    end
end

function ChaserEnemy:onCollide(player)
    if self:isActive() and player:includes(Player) then
        self.encountered = true
        local encounter = self.encounter
        if not encounter and Registry.getEnemy(self.actor.id) then
            encounter = Encounter()
            encounter:addEnemy(self.actor.id)
        end
        if encounter then
            self.world.encountering_enemy = true
            self.sprite:setAnimation("hurt")
            self.sprite.aura = false
            Game.lock_input = true
            self.world.timer:script(function(wait)
                Assets.playSound("tensionhorn")
                wait(8/30)
                local src = Assets.playSound("tensionhorn")
                src:setPitch(1.1)
                wait(12/30)
                self.world.encountering_enemy = false
                Game.lock_input = false
                Game:encounter(encounter, true, self)
                for _,enemy in ipairs(self.stage:getObjects(ChaserEnemy)) do
                    if enemy ~= self and self.group and enemy.group == self.group then
                        if enemy.remove_on_encounter then
                            enemy:remove()
                        end
                    end
                end
                if self.remove_on_encounter then
                    self:remove()
                end
            end)
        end
    end
end

function ChaserEnemy:onAdd(parent)
    super:onAdd(self, parent)

    self:snapToPath()
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

            for i = 1, #path.polygon-1 do
                local next_dist = Utils.dist(path.polygon[i].x, path.polygon[i].y, path.polygon[i+1].x, path.polygon[i+1].y)

                if current_dist + next_dist > dist then
                    local x = path.x + Utils.lerp(path.polygon[i].x, path.polygon[i+1].x, (dist - current_dist) / next_dist)
                    local y = path.y + Utils.lerp(path.polygon[i].y, path.polygon[i+1].y, (dist - current_dist) / next_dist)

                    self:moveTo(x, y)
                    break
                else
                    current_dist = current_dist + next_dist
                end
            end
        elseif path.shape == "ellipse" then
            local angle = progress * (math.pi*2)
            self:moveTo(path.x + math.cos(angle) * path.rx, path.y + math.sin(angle) * path.ry)
        end
    end
end

function ChaserEnemy:isActive()
    return not self.encountered and
           not self.world.encountering_enemy and
           not self.world:hasCutscene() and
           self.world.state ~= "MENU"
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

        if self.alert_timer > 0 then
            self.alert_timer = Utils.approach(self.alert_timer, 0, DTMULT)
            if self.alert_timer == 0 then
                self.alert_icon:remove()
                self.alert_icon = nil
                self.chasing = true
                self.noclip = false
                self:setAnimation("chasing")
            end
        elseif self.can_chase and not self.chasing then
            if self.world.player then
                Object.startCache()
                local in_radius = self.world.player:collidesWith(CircleCollider(self.world, self.x, self.y, self.chase_dist))
                if in_radius then
                    local sight = LineCollider(self.world, self.x, self.y, self.world.player.x, self.world.player.y)
                    if not self.world:checkCollision(sight, true) and not self.world:checkCollision(self.collider, true) then
                        Assets.stopAndPlaySound("alert")
                        self.path = nil
                        self.alert_timer = 20
                        self.alert_icon = Sprite("effects/alert", self.width/2)
                        self.alert_icon:setOrigin(0.5, 1)
                        self.alert_icon.layer = 100
                        self:addChild(self.alert_icon)
                        self:setAnimation("alerted")
                    end
                end
                Object.endCache()
            end
        elseif self.chasing then
            if self.world.player then
                local angle = Utils.angle(self.x, self.y, self.world.player.x, self.world.player.y)
                self:move(math.cos(angle), math.sin(angle), self.chase_speed * DTMULT)
            end
        end
    end

    super:update(self)
end

return ChaserEnemy