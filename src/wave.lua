local Wave, super = Class()

function Wave:init()
    -- Seconds the wave will last (-1 for infinite)
    self.time = 5

    -- Whether the wave is done or not
    self.finished = false

    -- Timer for convenience
    self.timer = Timer.new()

    self.bullets = {}
end

function Wave:update(dt)
    self.timer:update(dt)

    for i = 1, #self.bullets do
        if self.bullets[i] and not self.bullets[i].parent then
            table.remove(self.bullets, i)
            i = i - 1
        end
    end
end
function Wave:draw() end

function Wave:start() end
function Wave:clear() end

function Wave:spawnBullet(bullet, x, y, ...)
    if isClass(bullet) and bullet:includes(Bullet) then
        bullet.wave = self
        Game.battle:addChild(bullet)
        table.insert(self.bullets, bullet)
        return bullet
    elseif Registry.getBullet(bullet) then
        local new_bullet = Registry.createBullet(bullet, x, y, ...)
        new_bullet.wave = self
        Game.battle:addChild(new_bullet)
        table.insert(self.bullets, new_bullet)
        return new_bullet
    else
        local new_bullet = Bullet(x, y, bullet, ...)
        new_bullet.wave = self
        Game.battle:addChild(new_bullet)
        table.insert(self.bullets, new_bullet)
        return new_bullet
    end
end

function Wave:getAttackers()
    local result = {}
    for _,enemy in ipairs(Game.battle.enemies) do
        local wave = enemy.selected_wave
        if type(wave) == "table" and wave.id == self.id or wave == self.id then
            table.insert(result, enemy)
        end
    end
    return result
end

function Wave:getEnemyRatio()
    local enemies = #Game.battle.enemies
    if enemies <= 1 then
        return 1
    elseif enemies == 2 then
        return 1.6
    elseif enemies >= 3 then
        return 2.3
    end
end

return Wave