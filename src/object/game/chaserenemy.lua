local ChaserEnemy, super = Class(Character)

ChaserEnemy.ENCOUNTERING = false

function ChaserEnemy:init(actor, x, y, data)
    super:init(self, actor, x, y)

    self.layer = 1

    self.encounter = data.properties["encounter"]
    self.path = data.properties["path"]
    self.speed = data.properties["speed"] or 6

    self.progress = (data.properties["progress"] or 0) % 1
    self.reverse_progress = false

    self.noclip = true
    self.sprite.aura = true
end

function ChaserEnemy:onCollide(player)
    if not ChaserEnemy.ENCOUNTERING and player:includes(Player) then
        local encounter = self.encounter
        if not encounter and Registry.getEnemy(self.actor.id) then
            encounter = Encounter()
            encounter:addEnemy(self.actor.id)
        end
        if encounter then
            ChaserEnemy.ENCOUNTERING = true
            self.sprite:setAnimation("hurt")
            self.sprite.aura = false
            Game.lock_input = true
            self.world.timer:script(function(wait)
                love.audio.newSource("assets/sounds/snd_tensionhorn.wav", "static"):play()
                wait(8/30)
                local src = love.audio.newSource("assets/sounds/snd_tensionhorn.wav", "static")
                src:setPitch(1.1)
                src:play()
                wait(12/30)
                ChaserEnemy.ENCOUNTERING = false
                Game:encounter(encounter, true, self)
            end)
        end
    end
end

function ChaserEnemy:onAdd(parent)
    super:onAdd(self, parent)

    self:snapToPath()
end

function ChaserEnemy:snapToPath()
    if self.path and self.world.paths[self.path] then
        local path = self.world.paths[self.path]

        local progress = self.progress
        if not path.closed then
            progress = Ease.inOutSine(progress, 0, 1, 1)
        end

        if path.shape == "line" then
            local dist = progress * path.length
            local current_dist = 0

            for i = 1, #path.polygon-1 do
                local next_dist = Vector.dist(path.polygon[i].x, path.polygon[i].y, path.polygon[i+1].x, path.polygon[i+1].y)

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

function ChaserEnemy:update(dt)
    if self.path and self.world.paths[self.path] and not ChaserEnemy.ENCOUNTERING then
        local path = self.world.paths[self.path]

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

    super:update(self, dt)
end

return ChaserEnemy