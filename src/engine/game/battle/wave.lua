local Wave, super = Class(Object)

function Wave:init()
    super:init(self)

    self.layer = BATTLE_LAYERS["above_bullets"]

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

    -- Reference to the current encounter
    self.encounter = Game.battle.encounter

    -- Contains bullets added via spawnBullet
    self.bullets = {}
    -- Contains everything added via spawn functions (automatically cleared)
    self.objects = {}

    -- Timer for convenience
    self.timer = Timer()
    self:addChild(self.timer)
end

function Wave:update()
    for i = 1, #self.bullets do
        if self.bullets[i] and not self.bullets[i].parent then
            table.remove(self.bullets, i)
            i = i - 1
        end
    end
    super:update(self)
end

function Wave:onArenaEnter() end
function Wave:onArenaExit() end

function Wave:onStart() end
function Wave:onEnd() end

function Wave:canEnd() return true end

function Wave:clear()
    for _,object in ipairs(self.objects) do
        object:remove()
    end

    self.bullets = {}
    self.objects = {}
end

function Wave:spawnBullet(bullet, ...)
    return self:spawnBulletTo(nil, bullet, ...)
end

function Wave:spawnBulletTo(parent, bullet, ...)
    local new_bullet
    if isClass(bullet) and bullet:includes(Bullet) then
        new_bullet = bullet
    elseif Registry.getBullet(bullet) then
        new_bullet = Registry.createBullet(bullet, ...)
    else
        local x, y = ...
        table.remove(arg, 1)
        table.remove(arg, 1)
        new_bullet = Bullet(x, y, bullet, unpack(arg))
    end
    new_bullet.wave = self
    local attackers = self:getAttackers()
    if #attackers > 0 then
        new_bullet.attacker = Utils.pick(attackers)
    end
    table.insert(self.bullets, new_bullet)
    table.insert(self.objects, new_bullet)
    if parent then
        new_bullet:setParent(parent)
    elseif not new_bullet.parent then
        Game.battle:addChild(new_bullet)
    end
    new_bullet:onWaveSpawn()
    return new_bullet
end

function Wave:spawnSprite(texture, x, y, layer)
    return self:spawnSpriteTo(Game.battle, texture, x, y, layer)
end

function Wave:spawnSpriteTo(parent, texture, x, y, layer)
    local sprite = Sprite(texture, x, y)
    sprite:setOrigin(0.5, 0.5)
    sprite:setScale(2)
    sprite.layer = layer or BATTLE_LAYERS["above_arena"]
    return self:spawnObjectTo(parent, sprite)
end

function Wave:spawnObject(object, x, y)
    return self:spawnObjectTo(Game.battle, object, x, y)
end

function Wave:spawnObjectTo(parent, object, x, y)
    if x or y then
        object:setPosition(x, y)
    end
    object.wave = self
    parent:addChild(object)
    table.insert(self.objects, object)
    if object.onWaveSpawn then
        object:onWaveSpawn()
    end
    return object
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
    self.arena_height = height or width

    if Game.battle.arena then
        Game.battle.arena:setSize(width, height or width)
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
    for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
        local wave = enemy.selected_wave
        if type(wave) == "table" and wave.id == self.id or wave == self.id then
            table.insert(result, enemy)
        end
    end
    return result
end

return Wave