local Encounter = Class()

function Encounter:init()
    -- Text that will be displayed when the battle starts
    self.text = "* A skirmish breaks out!"

    -- Whether the default grid background is drawn
    self.background = true
    -- If enabled, hides the world even if the default background is disabled
    self.hide_world = false

    -- The music used for this encounter
    self.music = "battle"

    -- Whether characters have the X-Action option in their spell menu
    self.default_xactions = true

    -- Should the battle skip the YOU WON! text?
    self.no_end_message = false

    -- Table used to spawn enemies when the battle exists, if this encounter is created before
    self.queued_enemy_spawns = {}
end

function Encounter:onBattleStart() end
function Encounter:onBattleEnd() end

function Encounter:onTurnStart() end
function Encounter:onTurnEnd() end

function Encounter:update(dt) end

function Encounter:draw(fade) end
function Encounter:drawBackground(fade) end

function Encounter:addEnemy(enemy, x, y, ...)
    local enemy_obj
    if type(enemy) == "string" then
        enemy_obj = Registry.createEnemy(enemy, ...)
    else
        enemy_obj = enemy
    end
    local enemies = self.queued_enemy_spawns
    local transition = false
    if Game.battle and Game.state == "BATTLE" then
        enemies = Game.battle.enemies
        transition = Game.battle.state == "TRANSITION"
    end
    if transition then
        enemy_obj:setPosition(SCREEN_WIDTH + 200, y)
    end
    if x and y then
        if not transition then
            enemy_obj:setPosition(x, y)
        else
            enemy_obj.target_x = x
            enemy_obj.target_y = y
        end
    else
        for _,enemy in ipairs(enemies) do
            if not transition then
                enemy.x = enemy.x - 10
                enemy.y = enemy.y - 45
            else
                enemy.target_x = enemy.target_x - 10
                enemy.target_y = enemy.target_y - 45
            end
        end
        local x, y = 550 + (10 * #enemies), 200 + (45 * #enemies)
        if not transition then
            enemy_obj:setPosition(x, y)
        else
            enemy_obj.target_x = x
            enemy_obj.target_y = y
        end
    end
    table.insert(enemies, enemy_obj)
    if Game.battle and Game.state == "BATTLE" then
        Game.battle:addChild(enemy_obj)
    end
    return enemy_obj
end

function Encounter:fetchEncounterText()
    local enemies = Game.battle:getActiveEnemies()
    return enemies[math.random(#enemies)]:fetchEncounterText()
end

function Encounter:getNextWaves()
    local waves = {}
    for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
        local wave = enemy:selectWave()
        if wave then
            table.insert(waves, wave)
        end
    end
    return waves
end

function Encounter:onDialogueEnd()
    Game.battle:setWaves(self:getNextWaves())

    local soul_x, soul_y, soul_offset_x, soul_offset_y
    local arena_x, arena_y, arena_w, arena_h, arena_shape
    for _,wave in ipairs(Game.battle.waves) do
        soul_x = wave.soul_start_x or soul_x
        soul_y = wave.soul_start_y or soul_y
        soul_offset_x = wave.soul_offset_x or soul_offset_x
        soul_offset_y = wave.soul_offset_y or soul_offset_y
        arena_x = wave.arena_x or arena_x
        arena_y = wave.arena_y or arena_y
        arena_w = wave.arena_width and math.max(wave.arena_width, arena_w or 0) or arena_w
        arena_h = wave.arena_height and math.max(wave.arena_height, arena_h or 0) or arena_h
        if wave.arena_shape then
            arena_shape = wave.arena_shape
        end
    end

    if not arena_shape then
        arena_w, arena_h = arena_w or 142, arena_h or 142
        arena_shape = {{0, 0}, {arena_w, 0}, {arena_w, arena_h}, {0, arena_h}}
    end

    local arena = Arena(arena_x or SCREEN_WIDTH/2, arena_y or (SCREEN_HEIGHT - 155)/2 + 10, arena_shape)
    arena.layer = LAYERS["arena"]

    Game.battle.arena = arena
    Game.battle:addChild(arena)

    local center_x, center_y = arena:getCenter()
    soul_x = soul_x or (soul_offset_x and center_x + soul_offset_x)
    soul_y = soul_y or (soul_offset_y and center_y + soul_offset_y)
    Game.battle:spawnSoul(soul_x or center_x, soul_y or center_y)

    Game.battle.timer:after(15/30, function()
        Game.battle:setState("DEFENDING")
    end)
end

function Encounter:onWavesDone()
    Game.battle:setState("DEFENDINGEND")
    Game.battle:returnSoul()

    for _,wave in ipairs(Game.battle.waves) do
        wave:onEnd()
        wave:clear()
        wave:remove()
    end

    if Game.battle.arena then
        Game.battle.arena:remove()
        Game.battle.arena = nil
    end

    Game.battle.waves = {}
    Game.battle.timer:after(15/30, function()
        Game.battle:nextTurn()
    end)
end

function Encounter:createSoul(x, y)
    return Soul(x, y)
end

return Encounter