---@class Encounter : Class
---@overload fun(...) : Encounter
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
    self.default_xactions = Game:getConfig("partyActions")

    -- Should the battle skip the YOU WON! text?
    self.no_end_message = false

    -- Table used to spawn enemies when the battle exists, if this encounter is created before
    self.queued_enemy_spawns = {}

    -- A copy of Battle.defeated_enemies, used to determine how an enemy has been defeated.
    self.defeated_enemies = nil
end

-- Callbacks

function Encounter:onBattleInit() end
function Encounter:onBattleStart() end
function Encounter:onBattleEnd() end

function Encounter:onTurnStart() end
function Encounter:onTurnEnd() end

function Encounter:onActionsStart() end
function Encounter:onActionsEnd() end

function Encounter:onCharacterTurn(battler, undo) end

function Encounter:beforeStateChange(old, new) end
function Encounter:onStateChange(old, new) end

function Encounter:onActionSelect(battler, button) end

function Encounter:onMenuSelect(state_reason, item, can_select) end
function Encounter:onMenuCancel(state_reason, item) end

function Encounter:onEnemySelect(state_reason, enemy_index) end
function Encounter:onEnemyCancel(state_reason, enemy_index) end

function Encounter:onPartySelect(state_reason, party_index) end
function Encounter:onPartyCancel(state_reason, party_index) end

function Encounter:onGameOver() end
function Encounter:onReturnToWorld(events) end

function Encounter:getDialogueCutscene() end

function Encounter:getVictoryMoney(money) end
function Encounter:getVictoryXP(xp) end
function Encounter:getVictoryText(text, money, xp) end

function Encounter:update() end

function Encounter:draw(fade) end
function Encounter:drawBackground(fade) end

-- Functions

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
        enemy_obj.target_x = x
        enemy_obj.target_y = y
        if not transition then
            enemy_obj:setPosition(x, y)
        end
    else
        for _,enemy in ipairs(enemies) do
            enemy.target_x = enemy.target_x - 10
            enemy.target_y = enemy.target_y - 45
            if not transition then
                enemy.x = enemy.x - 10
                enemy.y = enemy.y - 45
            end
        end
        local x, y = 550 + (10 * #enemies), 200 + (45 * #enemies)
        enemy_obj.target_x = x
        enemy_obj.target_y = y
        if not transition then
            enemy_obj:setPosition(x, y)
        end
    end
    enemy_obj.encounter = self
    table.insert(enemies, enemy_obj)
    if Game.battle and Game.state == "BATTLE" then
        Game.battle:addChild(enemy_obj)
    end
    return enemy_obj
end

function Encounter:getEncounterText()
    local enemies = Game.battle:getActiveEnemies()
    local enemy = Utils.pick(enemies, function(v)
        if not v.text then
            return true
        else
            return #v.text > 0
        end
    end)
    if enemy then
        return enemy:getEncounterText()
    else
        return self.text
    end
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

function Encounter:getPartyPosition(index)
    local x, y = 0, 0
    if #Game.battle.party == 1 then
        x = 80
        y = 140
    elseif #Game.battle.party == 2 then
        x = 80
        y = 100 + (80 * (index - 1))
    elseif #Game.battle.party == 3 then
        x = 80
        y = 50 + (80 * (index - 1))
    end

    local battler = Game.battle.party[index]
    local ox, oy = battler.chara:getBattleOffset()
    x = x + (battler.actor:getWidth()/2 + ox) * 2
    y = y + (battler.actor:getHeight()  + oy) * 2
    return x, y
end

function Encounter:getSoulColor()
    return Game:getSoulColor()
end

function Encounter:getSoulSpawnLocation()
    local main_chara = Game:getSoulPartyMember()

    if main_chara and main_chara:getSoulPriority() >= 0 then
        local battler = Game.battle.party[Game.battle:getPartyIndex(main_chara.id)]

        if battler then
            if main_chara.soul_offset then
                return battler:localToScreenPos(main_chara.soul_offset[1], main_chara.soul_offset[2])
            else
                return battler:localToScreenPos((battler.sprite.width/2) - 4.5, battler.sprite.height/2)
            end
        end
    end
    return -9, -9
end

function Encounter:onDialogueEnd()
    Game.battle:setState("DEFENDINGBEGIN")
end

function Encounter:onWavesDone()
    Game.battle:setState("DEFENDINGEND", "WAVEENDED")
end

function Encounter:createSoul(x, y, color)
    return Soul(x, y, color)
end

function Encounter:canDeepCopy()
    return false
end

function Encounter:getDefeatedEnemies()
    return self.defeated_enemies or Game.battle.defeated_enemies
end

function Encounter:setFlag(flag, value)
    Game:setFlag("encounter#"..self.id..":"..flag, value)
end

function Encounter:getFlag(flag, default)
    return Game:getFlag("encounter#"..self.id..":"..flag, default)
end

function Encounter:addFlag(flag, amount)
    return Game:addFlag("encounter#"..self.id..":"..flag, amount)
end

return Encounter