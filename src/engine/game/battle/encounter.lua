--- Encounters detail the setup of unique battles in Kristal, from the enemies that appear to the environment and special mechanics. \
--- Encounter files should be placed inside `scripts/battle/encounters/`.
---
---@class Encounter : Class
---
---@field text                  string
---
---@field background            boolean
---@field hide_world            boolean
---
---@field music                 string?
---
---@field default_xactions      boolean
---
---@field no_end_message        boolean
---
---@field queued_enemy_spawns   table
---
---@field defeated_enemies      table
---
---@field reduced_tension       boolean
---
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

    -- Whether tension is reduced for this encounter.
    self.reduced_tension = false
end

-- Callbacks

--- *(Override)* Called in [`Battle:postInit()`](lua://Battle.postInit). \
--- *If this function returns `true`, then the battle will not override any state changes made here.*
---@return boolean?
function Encounter:onBattleInit() end
--- *(Override)* Called when the battle enters the `"INTRO"` state and the characters do their starting animations.
function Encounter:onBattleStart() end
--- *(Override)* Called when the battle is completed and the victory text (if presesnt) is advanced, just before the transition out.
function Encounter:onBattleEnd() end

--- *(Override)* Called at the start of each new turn, just before the player starts choosing actions.
function Encounter:onTurnStart() end
--- *(Override)* Called at the end of each turn, at the same time all waves end.
function Encounter:onTurnEnd() end

--- *(Override)* Called when the party start performing their actions.
function Encounter:onActionsStart() end
--- *(Override)* Called when the party finish performing their actions.
function Encounter:onActionsEnd() end

--- *(Override)* Called when a character's turn selecting actions begins.
---@param battler   PartyBattler    The battler whose turn it is.
---@param undo      boolean         Whether this character's turn was entered by undoing their previously selected action.
function Encounter:onCharacterTurn(battler, undo) end

--- *(Override)* Called when [`Battle:setState()`](lua://Battle.setState) is called. \
--- *Changing the state to something other than `new`, or returning `true` will stop the standard state change code for this state change from occurring.*
---@param old string
---@param new string
---@return boolean?
function Encounter:beforeStateChange(old, new) end
--- *(Override)* Called when [`Battle:setState()`](lua://Battle.setState) is called, after any state change code has run.
---@param old string
---@param new string
function Encounter:onStateChange(old, new) end

--- *(Override)* Called when an [`ActionButton`](lua://ActionButton.init) is selected.
---@param battler   PartyBattler
---@param button    ActionButton
function Encounter:onActionSelect(battler, button) end

--- *(Override)* Called when an item in a menu is selected (confirm key pressed).
---@param state_reason string       The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param item          table       A table of information representing the menu item.
---@param can_select    boolean     Whether the item is actually selectable or is greyed out.
function Encounter:onMenuSelect(state_reason, item, can_select) end
--- *(Override)* Called when the player backs out of a menu.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param item          table   A table of information representing the menu item that was being hovered over.
function Encounter:onMenuCancel(state_reason, item) end

--- *(Override)* Called when the player selects an enemy in battle.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param enemy_index   integer The index of the selected enemy on the menu.
function Encounter:onEnemySelect(state_reason, enemy_index) end
--- *(Override)* Called when the player backs out of an enemyselect menu in battle.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param enemy_index   integer The index of the selected enemy on the menu.
function Encounter:onEnemyCancel(state_reason, enemy_index) end

--- *(Override)* Called when the player selects a party member in a partyselect menu in battle.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param party_index   integer The index of the selected enemy on the menu.
function Encounter:onPartySelect(state_reason, party_index) end
--- *(Override)* Called when the player backs out of a partyselect menu in battle.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param party_index   number  The index of the selected enemy on the menu.
function Encounter:onPartyCancel(state_reason, party_index) end

--- *(Override)* Called just before a Game Over. \
--- *If this function returns `true`, then the Game Over will not occur*
---@return boolean?
function Encounter:onGameOver() end
--- *(Override)* Called just before returning to the world.
---@param events Character  A list of enemy events in the world that are linked to the enemies in battle.
function Encounter:onReturnToWorld(events) end

--- *(Override)* Called whenever dialogue is about to start, if this returns a value, it will be unpacked and passed
--- into [`Battle:startCutscene(...)`](lua://Battle.startCutscene), as an alternative to standard dialogue.
---@return table?
function Encounter:getDialogueCutscene() end

---@param money integer     Current victory money based on normal money calculations
---@return integer? money
function Encounter:getVictoryMoney(money) end
---@param xp integer        Current victory xp based on normal xp calculations
---@return integer? xp
function Encounter:getVictoryXP(xp) end
---@param text  string      Current victory text
---@param money integer     Money earned on victory
---@param xp    integer     XP earned on victory
---@return string? text
function Encounter:getVictoryText(text, money, xp) end

function Encounter:update() end

--- *(Override)* Called before anything has been rendered each frame. Usable to draw custom backgrounds for specific encounters.
---@param fade number   The opacity of the background when fading in/out of the world.
function Encounter:draw(fade) end
--- *(Override)* Called after everything has been rendered each frame. Usable to draw custom effects for specific encounters.
---@param fade number   The opacity of the background when fading in/out of the world.
function Encounter:drawBackground(fade) end

-- Functions

--- Adds an enemy to the encounter.
---@param enemy string|EnemyBattler The id of an `EnemyBattler`, or an `EnemyBattler` instance.
---@param x? number
---@param y? number
---@param ... any   Additional arguments to pass to [`EnemyBattler:init()`](lua://EnemyBattler.init).
---@return EnemyBattler
function Encounter:addEnemy(enemy, x, y, ...)
    local enemy_obj
    if type(enemy) == "string" then
        enemy_obj = Registry.createEnemy(enemy, ...)
    else
        enemy_obj = enemy
    end
    local enemies = self.queued_enemy_spawns
    local enemies_index
    local transition = false
    if Game.battle and Game.state == "BATTLE" then
        enemies = Game.battle.enemies
        enemies_index = Game.battle.enemies_index
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
    if enemies_index then
        table.insert(enemies_index, enemy_obj)
    end
    if Game.battle and Game.state == "BATTLE" then
        Game.battle:addChild(enemy_obj)
    end
    return enemy_obj
end

--- *(Override)* Called to receive the initial encounter text to be displayed on the first turn.
--- (Not called on any other turns unless [`getEncounterText`](lua://Encounter.getEncounterText) can't find any usable text.) \
--- *By default, returns the [encounter `text`](lua://Encounter.text).*
---@return string|string[] text # If a table, you should use [next] to advance the text
---@return string? portrait # The portrait to show
---@return PartyBattler|PartyMember|Actor|string? actor # The actor to use for the text settings (ex. voice, portrait settings)
function Encounter:getInitialEncounterText()
    return self.text
end

--- *(Override)* Called to receive the encounter text to be displayed each turn.
--- (Not called on turn one, [`getInitialEncounterText`](lua://Encounter.getInitialEncounterText) is used instead.) \
--- *By default, gets an encounter text from a random enemy, falling back on the encounter's
--- [encounter text](lua://Encounter.getInitialEncounterText) if none have encounter text.*
---@return string|string[] text # If a table, you should use [next] to advance the text
---@return string? portrait # The portrait to show
---@return PartyBattler|PartyMember|Actor|string? actor # The actor to use for the text settings (ex. voice, portrait settings)
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
        return self:getInitialEncounterText()
    end
end

--- *(Override)* Retrieves the waves to be used for the next defending phase. \
--- *By default, iterates through all active enemies and selects one wave each using [`EnemyBattler:selectWave()`](lua://EnemyBattler.selectWave)*
---@return Wave[]
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

--- *(Override)* Gets the position the party member at `index` should stand at in this battle.
---@param index integer The index of the party member in [`Game.battle.party`](lua://Battle.party).
---@return number x
---@return number y
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
    x = x + (battler.actor:getWidth() / 2 + ox) * 2
    y = y + (battler.actor:getHeight() + oy) * 2
    return x, y
end

---@return integer
---@return integer
---@return integer
---@return integer
function Encounter:getSoulColor()
    return Game:getSoulColor()
end

--- *(Override)* Gets the position that the soul will appear at when starting waves.
---@return integer x
---@return integer y
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

--- *(Override)* Called when enemy dialogue is finished and closed, before the transition into a wave.
function Encounter:onDialogueEnd()
    Game.battle:setState("DEFENDINGBEGIN")
end

--- *(Override)* Called when all the waves of the current turn have finished.
function Encounter:onWavesDone()
    Game.battle:setState("DEFENDINGEND", "WAVEENDED")
end

--- *(Override)* Creates the soul being used this battle (Called at the start of the first wave)
--- *By default, returns the regular (red) soul.*
---@param x         number  The x-coordinate the soul should spawn at.
---@param y         number  The y-coordinate the soul should spawn at.
---@param color?    table   A custom color for the soul, that should override its default.
---@return Soul
function Encounter:createSoul(x, y, color)
    return Soul(x, y, color)
end

---@return boolean
function Encounter:canDeepCopy()
    return false
end

---@return table defeated_enemies A table indicating the enemies defeated in battle.
function Encounter:getDefeatedEnemies()
    return self.defeated_enemies or Game.battle.defeated_enemies
end

---@param flag  string
---@param value any
function Encounter:setFlag(flag, value)
    Game:setFlag("encounter#"..self.id..":"..flag, value)
end

---@param flag      string
---@param default?  any
---@return any
function Encounter:getFlag(flag, default)
    return Game:getFlag("encounter#"..self.id..":"..flag, default)
end

--- Increments a numerical flag by `amount`.
---@param flag      string
---@param amount?   number  (Defaults to `1`)
---@return number
function Encounter:addFlag(flag, amount)
    return Game:addFlag("encounter#"..self.id..":"..flag, amount)
end

--- Checks if the encounter has reduced tension.
--- @return boolean reduced Whether the encounter has reduced tension.
function Encounter:hasReducedTension()
    return self.reduced_tension
end

--- Returns the tension gained from defending.
--- Returns 2% if reduced tension, otherwise 16%.
---@param battler PartyBattler The current battler about to defend.
---@return number tension The tension gained from defending.
function Encounter:getDefendTension(battler)
    if self:hasReducedTension() then
        return 2
    end
    return 16
end

--- *(Override)* Whether automatic healing while downed is enabled in this encounter. \
--- *By default, returns `true`.*
---@param battler PartyBattler The current battler about to auto-heal.
---@return boolean
function Encounter:isAutoHealingEnabled(battler)
    return true
end

--- *(Override)* Whether a party member can get swooned in this encounter or not.
--- *By default, returns `true` for everyone.*
---@param target PartyBattler The current target.
---@return boolean
function Encounter:canSwoon(target)
    return true
end

return Encounter
