--- Waves are the bullet patterns that enemies use in battle. \
--- Waves are defined in files in `scripts/battle/waves/` and should extend this class. \
--- Each wave is assigned an id that defaults to their filepath starting from `scripts/battle/waves`, 
--- unless an id is specified as an argument to `Class()`. \
--- Wave ids can be placed into an `EnemyBattler`s [`waves`](lua://EnemyBattler.waves) table, or `Wave`s returned from 
--- [`EnemyBattler:selectWave()`](lua://EnemyBattler.selectWave) or [`Encounter:getNextWaves()`](lua://Encounter.getNextWaves) to to be used in battle. \
--- Multiple waves can run in a single defending turn, but if multiple attackers select the same wave only one instance is created;
--- see [`Wave:getAttackers()`](lua://Wave.getAttackers) for determining how many enemies are using a particular wave.
---
---@class Wave : Object
---
---@field arena_x           number? Wave arena x-coordinate
---@field arena_y           number? Wave arena y-coordinate
---
---@field arena_width       number? Wave arena rectangular width 
---@field arena_height      number? Wave arena rectangular height
---
---@field arena_shape       table?  Wave arena shape (overrides rectangle options)
---
---@field arena_rotation    number  Wave arena rotation
---
---@field has_arena         boolean Whether the wave should spawn the arena
---
---@field soul_start_x      number? x-coordinate the soul will transition to at the start of the wave
---@field soul_start_y      number? y-coordinate the soul will transition to at the start of the wave
---@field soul_offset_x     number? x-offset of the soul position at the start of the wave
---@field soul_offset_y     number? y-offset of the soul position at the start of the wave
---
---@field time              number  The number of seconds the wave will last, or `-1` for an infinite wave (Defaults to 5 seconds)
---
---@field finished          boolean Whether the wave is finished or not
---
---@field encounter         Encounter
---
---@field bullets           Bullet[]
---@field objects           Object[]
---
---@field timer             Timer
---@overload fun(...) : Wave
local Wave, super = Class(Object)

--- This function is called when the wave is initialised. Waves are initialised **before** they are due to start, 
--- so do not use this function to set up wave logic i.e. timers, bullets, objects, only use it for arena setup and setting fields such as `time`. \
--- See [`Wave:onStart()`](lua://Wave.onStart) for a suitable alternative.
function Wave:init()
    super.init(self)

    self.layer = BATTLE_LAYERS["above_bullets"]
    -- Arena position

    self.arena_x = nil
    self.arena_y = nil

    self.arena_width = nil
    self.arena_height = nil

    self.arena_shape = nil
    self.arena_rotation = 0
    self.has_arena = true

    -- Whether the wave should spawn the soul
    -- If this is false, the soul can be manually spawned with Wave:spawnSoul()
    self.spawn_soul = true

    -- Position the soul will transition to at the start of the wave

    self.soul_start_x = nil
    self.soul_start_y = nil
    self.soul_offset_x = nil
    self.soul_offset_y = nil

    self.time = 5

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

--- *(Override)* Called every frame after [`Wave:onStart()`](lua://Wave.onStart) has run
function Wave:update()
    for i = 1, #self.bullets do
        if self.bullets[i] and not self.bullets[i].parent then
            table.remove(self.bullets, i)
            i = i - 1
        end
    end
    super.update(self)
end

--- *(Override)* Called when the arena is created for the wave, before [`Wave:onStart()`](lua://Wave.onStart) has been called or the transition is completed. \
--- *If this function returns true, the wave will start immediately, without waiting for the arena transition*
---@return boolean?
function Wave:onArenaEnter() end
--- *(Override)* Called when the arena finishes transitioning out after the wave
function Wave:onArenaExit() end

--- *(Override)* Called at the start of the wave, when [`Wave:update()`](lua://Wave.update) starts being called.
function Wave:onStart() end
--- *(Override)* Called at the end of the wave
---@param death boolean Whether the wave is ending because the player is about to gameover
function Wave:onEnd(death) end
--- *(Override)* Called when the wave is about to be ended \
--- *If this function returns true, the wave will not end*
---@return boolean?
function Wave:beforeEnd() end

--- *(Override)* Whether the wave is able to be ended
---@return boolean
function Wave:canEnd() return true end

--- Removes all objects spawned by this wave
function Wave:clear()
    for _,object in ipairs(self.objects) do
        object:remove()
    end

    self.bullets = {}
    self.objects = {}
end

--- Spawns a new bullet to this wave and parents it to [`Game.battle`](lua://Game.battle).
---@param bullet    string|Bullet   As a string, this parameter is either a sprite path, which will create a basic bullet with that sprite, or the id of a custom bullet. As a `Bullet`, it will directly spawn that instance to the wave.
---@param ...       any             Additional arguments to be passed to the created bullet's init() function. Basic bullets take an `x` and `y` coordinate here.
---@return Bullet bullet            The newly added bullet instance.
function Wave:spawnBullet(bullet, ...)
    return self:spawnBulletTo(nil, bullet, ...)
end

--- Spawns a bullet and parents it to the `parent` object.
---@param parent    Object?         The object to parent the bullet to. If left as `nil`, will parent it to [`Game.battle`](lua://Game.battle).
---@param bullet    string|Bullet   As a string, this parameter is either a sprite path, which will create a basic bullet with that sprite, or the id of a custom bullet. As a `Bullet`, it will directly spawn that instance to the wave.
---@param ...       any             Additional arguments to be passed to the created bullet's init() function. Basic bullets take an `x` and `y` coordinate here.
---@return Bullet bullet            The newly added bullet instance.
function Wave:spawnBulletTo(parent, bullet, ...)
    local new_bullet
    ---@diagnostic disable: param-type-mismatch
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
    new_bullet:onWaveSpawn(self)
    ---@diagnostic enable: param-type-mismatch
    ---@diagnostic disable-next-line: return-type-mismatch
    return new_bullet
end

--- Spawns a sprite and parents it to [`Game.battle`](lua://Game.battle)
---@param texture   string|love.Image
---@param x         number?
---@param y         number?
---@param layer     number?
---@return Sprite
function Wave:spawnSprite(texture, x, y, layer)
    return self:spawnSpriteTo(Game.battle, texture, x, y, layer)
end

--- Spawns a sprite and parents it to the `parent` object
---@param parent    Object
---@param texture   string|love.Image
---@param x         number?
---@param y         number?
---@param layer     number?
---@return any
function Wave:spawnSpriteTo(parent, texture, x, y, layer)
    local sprite = Sprite(texture, x, y)
    sprite:setOrigin(0.5, 0.5)
    sprite:setScale(2)
    sprite.layer = layer or BATTLE_LAYERS["above_arena"]
    return self:spawnObjectTo(parent, sprite)
end

--- Spawns an object and parents it to [`Game.battle`](lua://Game.battle)
---@param object    Object
---@param x         number?
---@param y         number?
---@return Object
function Wave:spawnObject(object, x, y)
    return self:spawnObjectTo(Game.battle, object, x, y)
end

--- Spawns an object and parents it to the `parent` object
---@param parent    Object
---@param object    Object
---@param x         number?
---@param y         number?
---@return Object
function Wave:spawnObjectTo(parent, object, x, y)
    ---@diagnostic disable: param-type-mismatch
    ---@diagnostic disable: undefined-field
    if x or y then
        object:setPosition(x, y)
    end
    object.wave = self
    parent:addChild(object)
    table.insert(self.objects, object)
    if object.onWaveSpawn then
        object:onWaveSpawn(self)
    end
    return object
    ---@diagnostic enable: param-type-mismatch
    ---@diagnostic enable: undefined-field
end

--- Sets the initial position of the arena, relative to the topleft of the screen
---@param x number
---@param y number
function Wave:setArenaPosition(x, y)
    self.arena_x = x
    self.arena_y = y

    if Game.battle.arena then
        Game.battle.arena:setPosition(x, y)
    end
end

--- Sets the initial position of the arena, relative to its default starting position
---@param x number
---@param y number
function Wave:setArenaOffset(x, y)
    self.arena_x = SCREEN_WIDTH/2 + x
    self.arena_y = (SCREEN_HEIGHT - 155)/2 + 10 + y

    if Game.battle.arena then
        Game.battle.arena:move(x, y)
    end
end

--- Sets the initial size of the rectangular arena (Defaults to `142` by `142` pixels)
--- @param width    number
--- @param height   number
function Wave:setArenaSize(width, height)
    self.arena_width = width
    self.arena_height = height or width

    if Game.battle.arena then
        Game.battle.arena:setSize(width, height or width)
    end
end

--- Sets the initial shape of the arena
---@param ... table<[number, number]>   A list of {`x`, `y`} vertices that form the shape of the arena.
function Wave:setArenaShape(...)
    self.arena_shape = {...}

    if Game.battle.arena then
        Game.battle.arena:setShape({...})
    end
end

--- Sets the rotation of the arena
---@param rotation number
function Wave:setArenaRotation(rotation)
    self.arena_rotation = rotation

    if Game.battle.arena then
        Game.battle.arena.rotation = rotation
    end
end

--- Spawns the soul to the wave.
---@param x? number
---@param y? number
function Wave:spawnSoul(x, y)
    -- Prevents weird shit from going down if this is called in the init function
    -- hopefully
    self.spawn_soul = false

    if self.soul_start_x then
        if not x then x = self.soul_start_x end
        if self.soul_offset_x then
            x = x + self.soul_offset_x
        end
    end
    if self.soul_start_y then
        if not y then y = self.soul_start_y end
        if self.soul_offset_y then
            y = y + self.soul_offset_y
        end
    end

    if not x and not y then
        if Game.battle.arena then
            x, y = Game.battle.arena:getCenter()
        else
            x, y = SCREEN_WIDTH / 2, (SCREEN_HEIGHT - 155) / 2 + 10
        end
    end

    Game.battle:spawnSoul(x, y)
end

--- Sets the soul's starting position, relative to the topleft of the screen.
---@param x number
---@param y number
function Wave:setSoulPosition(x, y)
    self.soul_start_x = x
    self.soul_start_y = y

    if Game.battle.soul then
        Game.battle.soul:setExactPosition(x, y)
    end
end

--- Sets the offset of the soul from its default starting position.
---@param x number
---@param y number
function Wave:setSoulOffset(x, y)
    self.soul_offset_x = x
    self.soul_offset_y = y

    if Game.battle.soul then
        Game.battle.soul:move(x or 0, y or 0)
    end
end

--- Retrieves all the attackers that selected this wave
---@return EnemyBattler[]
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

function Wave:canDeepCopy()
    return false
end

return Wave