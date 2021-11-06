local Wave, super = Class()

function Wave:init()
    -- Wave arena position
    self.arena_x = nil
    self.arena_y = nil
    -- Wave arena rectangle size
    self.arena_width = nil
    self.arena_height = nil
    -- Wave arena shape (overrides all rectangle options)
    self.arena_shape = nil

    -- Position the soul will transition to at the start of the wave
    self.soul_start_x = nil
    self.soul_start_y = nil
    self.soul_offset_x = nil
    self.soul_offset_y = nil

    -- Seconds the wave will last (-1 for infinite)
    self.time = 5

    -- Whether the wave is done or not
    self.finished = false

    -- Timer for convenience
    self.timer = Timer.new()

    -- Contains bullets added via spawnBullet
    self.bullets = {}
    -- Contains everything added via spawn functions (automatically cleared)
    self.objects = {}
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

function Wave:onStart() end
function Wave:onEnd() end

function Wave:clear()
    for _,object in ipairs(self.objects) do
        object:remove()
    end

    self.bullets = {}
    self.objects = {}
end

function Wave:spawnBullet(bullet, x, y, ...)
    return self:spawnBulletTo(nil, bullet, x, y, ...)
end

function Wave:spawnBulletTo(parent, bullet, x, y, ...)
    local new_bullet
    if isClass(bullet) and bullet:includes(Bullet) then
        new_bullet = bullet
    elseif Registry.getBullet(bullet) then
        new_bullet = Registry.createBullet(bullet, x, y, ...)
    else
        new_bullet = Bullet(x, y, bullet, ...)
    end
    new_bullet.wave = self
    table.insert(self.bullets, new_bullet)
    table.insert(self.objects, new_bullet)
    if parent then
        new_bullet:setParent(parent)
    elseif not new_bullet.parent then
        Game.battle:addChild(new_bullet)
    end
    return new_bullet
end

function Wave:spawnSprite(texture, x, y, layer)
    return self:spawnSpriteTo(Game.battle, texture, x, y, layer)
end

function Wave:spawnSpriteTo(parent, texture, x,  y, layer)
    local sprite = Sprite(texture, x, y)
    sprite:setOrigin(0.5, 0.5)
    sprite:setScale(2)
    sprite.layer = layer or LAYERS["above_arena"]
    sprite.wave = self
    parent:addChild(sprite)
    table.insert(self.objects, sprite)
    return sprite
end

function Wave:setArenaPosition(x, y)
    self.arena_x = x
    self.arena_y = y

    if Game.battle.arena then
        Game.battle.arena:setPosition(x, y)
    end
end

function Wave:setArenaOffset(x, y)
    self.arena_x = SCREEN_WIDTH/2 + x
    self.arena_y = (SCREEN_HEIGHT - 155)/2 + 10 + y

    if Game.battle.arena then
        Game.battle.arena:move(x, y)
    end
end

function Wave:setArenaSize(width, height)
    self.arena_width = width
    self.arena_height = height

    if Game.battle.arena then
        Game.battle.arena:setSize(width, height)
    end
end

function Wave:setArenaShape(...)
    self.arena_shape = {...}

    if Game.battle.arena then
        Game.battle.arena:setShape({...})
    end
end

function Wave:setSoulPosition(x, y)
    self.soul_start_x = x
    self.soul_start_y = y

    if Game.battle.soul then
        Game.battle.soul:setExactPosition(x, y)
    end
end

function Wave:setSoulOffset(x, y)
    self.soul_offset_x = x
    self.soul_offset_y = y

    if Game.battle.soul then
        Game.battle.soul:move(x or 0, y or 0)
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