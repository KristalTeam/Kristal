local Wave, super = Class()

function Wave:init()
    -- Seconds the wave will last
    self.time = 5

    -- Whether the wave is done or not
    self.finished = false

    -- Timer for convenience
    self.timer = Timer.new()

    self.bullets = {}
end

function Wave:update(dt)
    self.timer:update(dt)
end
function Wave:draw() end

function Wave:start() end
function Wave:clear() end

function Wave:spawnBullet(bullet, x, y)
    if isClass(bullet) and bullet:includes(Bullet) then
        Game.battle:addChild(bullet)
        table.insert(self.bullets, bullet)
        return bullet
    else
        local new_bullet = Bullet(bullet, x, y)
        Game.battle:addChild(new_bullet)
        table.insert(self.bullets, new_bullet)
        return new_bullet
    end
end

return Wave