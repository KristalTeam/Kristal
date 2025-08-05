--- The `Battle` Object manages everything related to battles in Kristal. \
--- A globally available reference to the in-use `Battle` instance is stored in [`Game.battle`](lua://Game.battle).
---
---@class Battle : Object
---
---@field party                     PartyBattler[]                  A table of all the `PartyBattler`s in the current battle
---
---@field money                     integer                         Current amount of victory money
---@field xp                        number                          Current amount of victory xp
---
---@field used_violence             boolean
---
---@field ui_move                   love.Source                     A sound source for the `ui_move` sfx, should be used for every time this sound plays in battle
---@field ui_select                 love.Source                     A sound source for the `ui_select` sfx, should be used for every time this sound plays in battle
---@field spare_sound               love.Source                     A sound source for the `spare` sfx, should be used for every time this sound plays in battle
---@
---@field party_beginning_positions table<[number, number]>         The position of each `PartyBattler` at the start of the battle transition
---@field enemy_beginning_positions table<[number, number]>         The position of each `EnemyBattler` at the start of the battle transition
---@
---@field party_world_characters    table<string, Character>        A list of mappings between `PartyBattler`s (by id) and their representations as `Character`s in the world, if they exist
---@field enemy_world_characters    table<EnemyBattler, Character>  A list of mappings between `EnemyBattler`s and their representations as `Character`s in the world, if they exist
---@field battler_targets           table<[number, number]>         Target positions for `PartyBattler`s to transition to at the start of battle
---
---@field encounter_context         ChaserEnemy?                    An optional `ChaserEnemy` instance that initiated the battle
---
---@field state                     string                          The current state of the battle - should never be set manually, see [`Battle:setState()`](lua://Battle.setState) instead
---@field substate                  string                          The current substate of the battle - should never be set manually, see [`Battle:setSubState()`](lua://Battle.setSubState) instead
---@field state_reason              string?                         The reason for the current state of the battle - should never be set manually, see [`Battle:setState()`](lua://Battle.setState) instead
---
---@field camera                    Camera
---
---@field cutscene                  BattleCutscene?                 The active battle cutscene, if it exists - see [`Battle:startCutscene()`](lua://Battle.startCutscene) or [`Battle:startActCutscene()`](lua://Battle.startActCutscene) for how to start cutscenes
---
---@field turn_count                integer                         The current turn number
---
---@field battle_ui                 BattleUI
---@field tension_bar               TensionBar
---
---@field arena                     Arena?
---@field soul                      Soul?
---
---@field music                     Music
---
---@field mask                      ArenaMask                       Objects parented to this will be masked to the arena
---@field timer                     Timer
---
---@field attackers                 EnemyBattler[]
---@field normal_attackers          PartyBattler[]
---@field auto_attackers            PartyBattler[]
---
---@field enemies                   EnemyBattler[]
---@field enemies_index             EnemyBattler[]
---@field enemy_dialogue            SpeechBubble[]
---@field enemies_to_remove         EnemyBattler[]
---@field defeated_enemies          EnemyBattler[]
---@field waves                     Wave[]
---
---@field encounter                 Encounter                       The encounter currently being used for this battle *(only set during `postInit()`)*
---@field resume_world_music        boolean                         *(only set during `postInit()`)*
---@field transitioned              boolean                         Whether the battle opened with a transition *(only set during `postInit()`)*
---
---@overload fun(...) : Battle
local Battle, super = Class(Object)

function Battle:init()
    super.init(self)

    self.party = {}

    self.money = 0
    self.xp = 0

    self.used_violence = false

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.spare_sound = Assets.newSound("spare")

    self.party_beginning_positions = {} -- Only used in TRANSITION, but whatever
    self.enemy_beginning_positions = {}

    self.party_world_characters = {}
    self.enemy_world_characters = {}
    self.battler_targets = {}

    self.encounter_context = nil

    self:createPartyBattlers()

    self.intro_timer = 0
    self.offset = 0

    self.transitioned = false
    self.started = false

    self.textbox_timer = 0
    self.use_textbox_timer = true

    -- states: BATTLETEXT, TRANSITION, INTRO, ACTIONSELECT, ACTING, SPARING, USINGITEMS, ATTACKING, ACTIONSDONE, ENEMYDIALOGUE, DIALOGUEEND, DEFENDING, VICTORY, TRANSITIONOUT
    -- ENEMYSELECT, MENUSELECT, XACTENEMYSELECT, PARTYSELECT, DEFENDINGEND, DEFENDINGBEGIN

    self.state = "NONE"
    self.substate = "NONE"

    self.camera = Camera(self, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH, SCREEN_HEIGHT, false)

    self.cutscene = nil

    self.current_selecting = 0

    self.turn_count = 0

    self.battle_ui = nil
    self.tension_bar = nil

    self.arena = nil
    self.soul = nil

    self.music = Music()

    self.resume_world_music = false

    self.mask = ArenaMask()
    self:addChild(self.mask)

    self.timer = Timer()
    self:addChild(self.timer)

    self.character_actions = {}

    self.selected_character_stack = {}
    self.selected_action_stack = {}

    self.current_actions = {}
    self.short_actions = {}
    self.current_action_index = 1
    self.processed_action = {}
    self.processing_action = false

    self.attackers = {}
    self.normal_attackers = {}
    self.auto_attackers = {}

    self.attack_done = false
    self.cancel_attack = false
    self.auto_attack_timer = 0

    self.post_battletext_func = nil
    self.post_battletext_state = "ACTIONSELECT"

    self.battletext_table = nil
    self.battletext_index = 1

    self.current_menu_x = 1
    self.current_menu_y = 1

    self.enemies = {}
    self.enemies_index = {}
    self.enemy_dialogue = {}
    self.enemies_to_remove = {}
    self.defeated_enemies = {}

    self.seen_encounter_text = false

    self.waves = {}
    self.finished_waves = false

    self.state_reason = nil
    self.substate_reason = nil

    self.menu_items = {}

    self.selected_enemy = 1
    self.selected_spell = nil
    self.selected_xaction = nil
    self.selected_item = nil

    self.pacify_glow_timer = 0

    self.spell_delay = 0
    self.spell_finished = false

    self.actions_done_timer = 0

    self.xactions = {}

    self.background_fade_alpha = 0

    self.wave_length = 0
    self.wave_timer = 0

    self.should_finish_action = false
    self.on_finish_keep_animation = nil
    self.on_finish_action = nil

    self.defending_begin_timer = 0

    self.darkify = false
end

function Battle:createPartyBattlers()
    for i = 1, math.min(3, #Game.party) do
        local party_member = Game.party[i]

        if Game.world.player and Game.world.player.visible and Game.world.player.actor.id == party_member:getActor().id then
            -- Create the player battler
            local player_x, player_y = Game.world.player:getScreenPos()
            local player_battler = PartyBattler(party_member, player_x, player_y)
            player_battler:setAnimation("battle/transition")
            self:addChild(player_battler)
            table.insert(self.party,player_battler)
            table.insert(self.party_beginning_positions, {player_x, player_y})
            self.party_world_characters[party_member.id] = Game.world.player

            Game.world.player.visible = false
        else
            local found = false
            for _,follower in ipairs(Game.world.followers) do
                if follower.visible and follower.actor.id == party_member:getActor().id then
                    local chara_x, chara_y = follower:getScreenPos()
                    local chara_battler = PartyBattler(party_member, chara_x, chara_y)
                    chara_battler:setAnimation("battle/transition")
                    self:addChild(chara_battler)
                    table.insert(self.party, chara_battler)
                    table.insert(self.party_beginning_positions, {chara_x, chara_y})
                    self.party_world_characters[party_member.id] = follower

                    follower.visible = false

                    found = true
                    break
                end
            end
            if not found then
                local chara_battler = PartyBattler(party_member, SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
                chara_battler:setAnimation("battle/transition")
                self:addChild(chara_battler)
                table.insert(self.party, chara_battler)
                table.insert(self.party_beginning_positions, {chara_battler.x, chara_battler.y})
            end
        end
    end
end

---@param state string
---@param encounter string|Encounter
function Battle:postInit(state, encounter)
    self.state = state

    if type(encounter) == "string" then
        self.encounter = Registry.createEncounter(encounter)
    else
        self.encounter = encounter
    end

    if Game.world.music:isPlaying() and self.encounter.music then
        self.resume_world_music = true
        Game.world.music:pause()
    end

    if self.encounter.queued_enemy_spawns then
        for _,enemy in ipairs(self.encounter.queued_enemy_spawns) do
            if state == "TRANSITION" then
                enemy.target_x = enemy.x
                enemy.target_y = enemy.y
                enemy.x = SCREEN_WIDTH + 200
            end
            table.insert(self.enemies, enemy)
            table.insert(self.enemies_index, enemy)
            self:addChild(enemy)
        end
    end

    self.battle_ui = BattleUI()
    self:addChild(self.battle_ui)

    self.tension_bar = TensionBar(-25, 40, true)
    self:addChild(self.tension_bar)

    self.battler_targets = {}
    for index, battler in ipairs(self.party) do
        local target_x, target_y = self.encounter:getPartyPosition(index)
        table.insert(self.battler_targets, {target_x, target_y})

        if state ~= "TRANSITION" then
            battler:setPosition(target_x, target_y)
        end
    end

    for _,enemy in ipairs(self.enemies) do
        self.enemy_beginning_positions[enemy] = {enemy.x, enemy.y}
    end
    if Game.encounter_enemies then
        for _,from in ipairs(Game.encounter_enemies) do
            if not isClass(from) then
                local enemy = self:parseEnemyIdentifier(from[1])
                from[2].visible = false
                from[2].battler = enemy
                self.enemy_beginning_positions[enemy] = {from[2]:getScreenPos()}
                self.enemy_world_characters[enemy] = from[2]
                if state == "TRANSITION" then
                    enemy:setPosition(from[2]:getScreenPos())
                end
            else
                for _,enemy in ipairs(self.enemies) do
                    if enemy.actor and from.actor and enemy.actor.id == from.actor.id then
                        from.visible = false
                        from.battler = enemy
                        self.enemy_beginning_positions[enemy] = {from:getScreenPos()}
                        self.enemy_world_characters[enemy] = from
                        if state == "TRANSITION" then
                            enemy:setPosition(from:getScreenPos())
                        end
                        break
                    end
                end
            end
        end
    end

    if self.encounter_context and self.encounter_context:includes(ChaserEnemy) then
        for _,enemy in ipairs(self.encounter_context:getGroupedEnemies(true)) do
            enemy:onEncounterStart(enemy == self.encounter_context, self.encounter)
        end
    end

    if state == "TRANSITION" then
        self.transitioned = true
        self.transition_timer = 0
        self.afterimage_count = 0
    else
        self.transition_timer = 10

        if state ~= "INTRO" then
            self:nextTurn()
        end
    end

    if not self.encounter:onBattleInit() then
        self:setState(state)
    end
end

function Battle:showUI()
    if self.battle_ui then
        self.battle_ui:transitionIn()
    end
    if self.tension_bar then
        self.tension_bar:show()
    end
end

---@param parent Object
function Battle:onRemove(parent)
    super.onRemove(self, parent)

    self.music:remove()
end

--- Changes the state of the battle and calls [onStateChange()](lua://Battle.onStateChange)
---@param state     string
---@param reason    string?
function Battle:setState(state, reason)
    local old = self.state
    self.state = state
    self.state_reason = reason
    self:onStateChange(old, self.state)
end

--- Changes the substate of the battle and calls [onSubStateChange()](lua://Battle.onSubStateChange)
---@param state     string
---@param reason    string?
function Battle:setSubState(state, reason)
    local old = self.substate
    self.substate = state
    self.substate_reason = reason
    self:onSubStateChange(old, self.substate)
end

function Battle:getState()
    return self.state
end

---@param old string
---@param new string
function Battle:onStateChange(old,new)
    local result = self.encounter:beforeStateChange(old,new)
    if result or self.state ~= new then
        return
    end

    if new == "INTRO" then
        self.seen_encounter_text = false
        self.intro_timer = 0
        Assets.playSound("impact", 0.7)
        Assets.playSound("weaponpull_fast", 0.8)

        for _,battler in ipairs(self.party) do
            battler:setAnimation("battle/intro")
        end

        self.encounter:onBattleStart()
    elseif new == "ACTIONSELECT" then
        if self.current_selecting < 1 or self.current_selecting > #self.party then
            self:nextTurn()
            if self.state ~= "ACTIONSELECT" then
                return
            end
        end

        if self.state_reason == "CANCEL" then
            self.battle_ui.encounter_text:setText("[instant]" .. self.battle_ui.current_encounter_text)
        end

        local had_started = self.started
        if not self.started then
            self.started = true

            for _,battler in ipairs(self.party) do
                battler:resetSprite()
            end

            if self.encounter.music then
                self.music:play(self.encounter.music)
            end
        end

        self:showUI()

        local party = self.party[self.current_selecting]
        party.chara:onActionSelect(party, false)
        self.encounter:onCharacterTurn(party, false)
    elseif new == "ACTIONS" then
        self.battle_ui:clearEncounterText()
        if self.state_reason ~= "DONTPROCESS" then
            self:tryProcessNextAction()
        end
    elseif new == "ENEMYSELECT" or new == "XACTENEMYSELECT" then
        self.battle_ui:clearEncounterText()
        self.current_menu_y = 1
        self.selected_enemy = 1
        
        if not (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable) and #self.enemies_index > 0 then
            local give_up = 0
            repeat
                give_up = give_up + 1
                if give_up > 100 then return end
                -- Keep decrementing until there's a selectable enemy.
                self.current_menu_y = self.current_menu_y + 1
                if self.current_menu_y > #self.enemies_index then
                    self.current_menu_y = 1
                end
            until (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable)
        end
    elseif new == "PARTYSELECT" then
        self.battle_ui:clearEncounterText()
        self.current_menu_y = 1
    elseif new == "MENUSELECT" then
        self.battle_ui:clearEncounterText()
        self.current_menu_x = 1
        self.current_menu_y = 1
    elseif new == "ATTACKING" then
        self.battle_ui:clearEncounterText()

        local enemies_left = self:getActiveEnemies()

        if #enemies_left > 0 then
            for i,battler in ipairs(self.party) do
                local action = self.character_actions[i]
                if action and action.action == "ATTACK" then
                    self:beginAction(action)
                    table.insert(self.attackers, battler)
                    table.insert(self.normal_attackers, battler)
                elseif action and action.action == "AUTOATTACK" then
                    table.insert(self.attackers, battler)
                    table.insert(self.auto_attackers, battler)
                end
            end
        end

        self.auto_attack_timer = 0

        if #self.attackers == 0 then
            self.attack_done = true
            self:setState("ACTIONSDONE")
        else
            self.attack_done = false
        end
    elseif new == "ENEMYDIALOGUE" then
        self.battle_ui:clearEncounterText()
        self.textbox_timer = 3 * 30
        self.use_textbox_timer = true
        local active_enemies = self:getActiveEnemies()
        if #active_enemies == 0 then
            self:setState("VICTORY")
        else
            for _,enemy in ipairs(active_enemies) do
                enemy.current_target = enemy:getTarget()
            end
            local cutscene_args = {self.encounter:getDialogueCutscene()}
            if #cutscene_args > 0 then
                self:startCutscene(unpack(cutscene_args)):after(function()
                    self:setState("DIALOGUEEND")
                end)
            else
                local any_dialogue = false
                for _,enemy in ipairs(active_enemies) do
                    local dialogue = enemy:getEnemyDialogue()
                    if dialogue then
                        any_dialogue = true
                        local bubble = enemy:spawnSpeechBubble(dialogue)
                        table.insert(self.enemy_dialogue, bubble)
                    end
                end
                if not any_dialogue then
                    self:setState("DIALOGUEEND")
                end
            end
        end
    elseif new == "DIALOGUEEND" then
        self.battle_ui:clearEncounterText()

        for i,battler in ipairs(self.party) do
            local action = self.character_actions[i]
            if action and action.action == "DEFEND" then
                self:beginAction(action)
                self:processAction(action)
            end
        end

        self.encounter:onDialogueEnd()
    elseif new == "DEFENDING" then
        self.wave_length = 0
        self.wave_timer = 0

        for _,wave in ipairs(self.waves) do
            wave.encounter = self.encounter

            self.wave_length = math.max(self.wave_length, wave.time)

            wave:onStart()

            wave.active = true
        end
    elseif new == "VICTORY" then
        self.current_selecting = 0

        if self.tension_bar then
            self.tension_bar:hide()
        end

        for _,battler in ipairs(self.party) do
            battler:setSleeping(false)
            battler.defending = false
            battler.action = nil

            battler.chara:resetBuffs()

            if battler.chara:getHealth() <= 0 then
                battler:revive()
                battler.chara:setHealth(battler.chara:autoHealAmount())
            end

            battler:setAnimation("battle/victory")

            local box = self.battle_ui.action_boxes[self:getPartyIndex(battler.chara.id)]
            box:resetHeadIcon()
        end

        self.money = self.money + (math.floor(((Game:getTension() * 2.5) / 10)) * Game.chapter)

        for _,battler in ipairs(self.party) do
            for _,equipment in ipairs(battler.chara:getEquipment()) do
                self.money = math.floor(equipment:applyMoneyBonus(self.money) or self.money)
            end
        end

        self.money = math.floor(self.money)

        self.money = self.encounter:getVictoryMoney(self.money) or self.money
        self.xp = self.encounter:getVictoryXP(self.xp) or self.xp
        -- if (in_dojo) then
        --     self.money = 0
        -- end

        Game.money = Game.money + self.money
        Game.xp = Game.xp + self.xp

        if (Game.money < 0) then
            Game.money = 0
        end

        local win_text = "* You won!\n* Got " .. self.xp .. " EXP and " .. self.money .. " "..Game:getConfig("darkCurrencyShort").."."
        -- if (in_dojo) then
        --     win_text == "* You won the battle!"
        -- end
        if self.used_violence and Game:getConfig("growStronger") then
            local stronger = "You"

            local party_to_lvl_up = {}
            for _,battler in ipairs(self.party) do
                table.insert(party_to_lvl_up, battler.chara)
                if Game:getConfig("growStrongerChara") and battler.chara.id == Game:getConfig("growStrongerChara") then
                    stronger = battler.chara:getName()
                end
                for _,id in pairs(battler.chara:getStrongerAbsent()) do
                    table.insert(party_to_lvl_up, Game:getPartyMember(id))
                end
            end
            
            for _,party in ipairs(Utils.removeDuplicates(party_to_lvl_up)) do
                Game.level_up_count = Game.level_up_count + 1
                party:onLevelUp(Game.level_up_count)
            end

            win_text = "* You won!\n* Got " .. self.money .. " "..Game:getConfig("darkCurrencyShort")..".\n* "..stronger.." became stronger."

            Assets.playSound("dtrans_lw", 0.7, 2)
            --scr_levelup()
        end

        win_text = self.encounter:getVictoryText(win_text, self.money, self.xp) or win_text

        if self.encounter.no_end_message then
            self:setState("TRANSITIONOUT")
            self.encounter:onBattleEnd()
        else
            self:battleText(win_text, function()
                self:setState("TRANSITIONOUT")
                self.encounter:onBattleEnd()
                return true
            end)
        end
    elseif new == "TRANSITIONOUT" then
        self.current_selecting = 0

        if self.tension_bar and self.tension_bar.shown then
            self.tension_bar:hide()
        end

        self.battle_ui:transitionOut()
        self.music:fade(0, 20/30)
        for _,battler in ipairs(self.party) do
            local index = self:getPartyIndex(battler.chara.id)
            if index then
                self.battler_targets[index] = {battler:getPosition()}
            end
        end
        if self.encounter_context and self.encounter_context:includes(ChaserEnemy) then
            for _,enemy in ipairs(self.encounter_context:getGroupedEnemies(true)) do
                enemy:onEncounterTransitionOut(enemy == self.encounter_context, self.encounter)
            end
        end
    elseif new == "DEFENDINGBEGIN" then
        if self.state_reason == "CUTSCENE" then
            self:setState("DEFENDING")
            return
        end

        self.current_selecting = 0
        self.battle_ui:clearEncounterText()

        if self.state_reason then
            self:setWaves(self.state_reason)
            local enemy_found = false
            for i,enemy in ipairs(self.enemies) do
                if Utils.containsValue(enemy.waves, self.state_reason[1]) then
                    enemy.selected_wave = self.state_reason[1]
                    enemy_found = true
                end
            end
            if not enemy_found then
                self.enemies[love.math.random(1, #self.enemies)].selected_wave = self.state_reason[1]
            end
        else
            self:setWaves(self.encounter:getNextWaves())
        end

        if self.arena then
            self.arena:remove()
        end

        local soul_x, soul_y, soul_offset_x, soul_offset_y
        local arena_x, arena_y, arena_w, arena_h, arena_shape
        local arena_rotation = 0
        local has_arena = true
        local spawn_soul = true
        for _,wave in ipairs(self.waves) do
            soul_x = wave.soul_start_x or soul_x
            soul_y = wave.soul_start_y or soul_y
            soul_offset_x = wave.soul_offset_x or soul_offset_x
            soul_offset_y = wave.soul_offset_y or soul_offset_y
            arena_x = wave.arena_x or arena_x
            arena_y = wave.arena_y or arena_y
            arena_w = wave.arena_width and math.max(wave.arena_width, arena_w or 0) or arena_w
            arena_h = wave.arena_height and math.max(wave.arena_height, arena_h or 0) or arena_h
            arena_rotation = wave.arena_rotation or arena_rotation
            if wave.arena_shape then
                arena_shape = wave.arena_shape
            end
            if not wave.has_arena then
                has_arena = false
            end
            if not wave.spawn_soul then
                spawn_soul = false
            end
        end

        local center_x, center_y
        if has_arena then
            if not arena_shape then
                arena_w, arena_h = arena_w or 142, arena_h or 142
                arena_shape = {{0, 0}, {arena_w, 0}, {arena_w, arena_h}, {0, arena_h}}
            end

            local arena = Arena(arena_x or SCREEN_WIDTH/2, arena_y or (SCREEN_HEIGHT - 155)/2 + 10, arena_shape)
            arena.rotation = arena_rotation
            arena.layer = BATTLE_LAYERS["arena"]

            self.arena = arena
            self:addChild(arena)
            center_x, center_y = arena:getCenter()
        else
            center_x, center_y = SCREEN_WIDTH/2, (SCREEN_HEIGHT - 155)/2 + 10
        end

        if spawn_soul then
            soul_x = soul_x or (soul_offset_x and center_x + soul_offset_x)
            soul_y = soul_y or (soul_offset_y and center_y + soul_offset_y)
            self:spawnSoul(soul_x or center_x, soul_y or center_y)
        end

        for _,wave in ipairs(Game.battle.waves) do
            if wave:onArenaEnter() then
                wave.active = true
            end
        end

        self.defending_begin_timer = 0
    end

    -- List of states that should remove the arena.
    -- A whitelist is better than a blacklist in case the modder adds more states.
    -- And in case the modder adds more states and wants the arena to be removed, they can remove the arena themselves.
    local remove_arena = {"DEFENDINGEND", "TRANSITIONOUT", "ACTIONSELECT", "VICTORY", "INTRO", "ACTIONS", "ENEMYSELECT", "XACTENEMYSELECT", "PARTYSELECT", "MENUSELECT", "ATTACKING"}

    local should_end = true
    if Utils.containsValue(remove_arena, new) then
        for _,wave in ipairs(self.waves) do
            if wave:beforeEnd() then
                should_end = false
            end
        end
        if should_end then
            self:returnSoul()
            if self.arena then
                self.arena:remove()
                self.arena = nil
            end
            for _,battler in ipairs(self.party) do
                battler.targeted = false
            end
        end
    end

    local ending_wave = self.state_reason == "WAVEENDED"

    if old == "DEFENDING" and new ~= "DEFENDINGBEGIN" and should_end then
        for _,wave in ipairs(self.waves) do
            if not wave:onEnd(false) then
                wave:clear()
                wave:remove()
            end
        end

        local function exitWaves()
            for _,wave in ipairs(self.waves) do
                wave:onArenaExit()
            end
            self.waves = {}
        end

        if self:hasCutscene() then
            self.cutscene:after(function()
                exitWaves()
                if ending_wave then
                    self:nextTurn()
                end
            end)
        else
            self.timer:after(15/30, function()
                exitWaves()
                if ending_wave then
                    self:nextTurn()
                end
            end)
        end
    end

    self.encounter:onStateChange(old,new)
end

--- Gets the location the soul should spawn at when waves start by default
---@param always_origin? boolean
---@return number
---@return number
function Battle:getSoulLocation(always_origin)
    if self.soul and (not always_origin) then
        return self.soul:getPosition()
    else
        return self.encounter:getSoulSpawnLocation()
    end
end

--- Spawns the soul and sets up its transition from the source character to its starting position
---@param x? number
---@param y? number
function Battle:spawnSoul(x, y)
    local bx, by = self:getSoulLocation()
    local color = {self.encounter:getSoulColor()}
    self:addChild(HeartBurst(bx, by, color))
    if not self.soul then
        self.soul = self.encounter:createSoul(bx, by, color)
        self.soul:transitionTo(x or SCREEN_WIDTH/2, y or SCREEN_HEIGHT/2)
        self.soul.target_alpha = self.soul.alpha
        self.soul.alpha = 0
        if Game:getConfig("soulInvBetweenWaves") then
            self.soul.inv_timer = Game.old_soul_inv_timer
        end
        Game.old_soul_inv_timer = 0
        self:addChild(self.soul)
    end

    if self.state == "DEFENDINGBEGIN" or self.state == "DEFENDING" then
        self.soul:onWaveStart()
    end
end

---@param dont_destroy? boolean
function Battle:returnSoul(dont_destroy)
    if dont_destroy == nil then dont_destroy = false end
    local bx, by = self:getSoulLocation(true)
    if self.soul then
        Game.old_soul_inv_timer = self.soul.inv_timer
        self.soul:transitionTo(bx, by, not dont_destroy)
    end
end

--- Replaces the current soul (if it exists) with a different soul instance
---@param object Soul
function Battle:swapSoul(object)
    if self.soul then
        self.soul:remove()
    end
    object:setPosition(self.soul:getPosition())
    object.layer = self.soul.layer
    self.soul = object
    self:addChild(object)
end

function Battle:resetAttackers()
    if #self.attackers > 0 then
        for _,battler in ipairs(self.attackers) do
            if battler.action then
                battler.action.icon = nil
            end

            if not battler:setAnimation("battle/attack_end") then
                battler:resetSprite()
            end
        end
        self.attackers = {}
        self.normal_attackers = {}
        self.auto_attackers = {}
        if self.battle_ui.attacking then
            self.battle_ui:endAttack()
        end
    end
end

---@param old string
---@param new string
function Battle:onSubStateChange(old,new)
    if (old == "ACT") and (new ~= "ACT") then
        for _,battler in ipairs(self.party) do
            if battler.sprite.anim == "battle/act" then
                battler:setAnimation("battle/act_end")
            end
        end
    end
end

--- Registers an additional X-Action for a specific party member
---@param party         string  The id of the party member who will receive this X-Action
---@param name          string  The name of this X-Action
---@param description?  string  The description of this X-Action
---@param tp?           number  The tp cost of this X-Action
function Battle:registerXAction(party, name, description, tp)
    local act = {
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["color"] = {self.party[self:getPartyIndex(party)].chara:getXActColor()},
        ["tp"] = tp or 0,
        ["short"] = false
    }

    table.insert(self.xactions, act)
end

function Battle:getEncounterText()
    return self.encounter:getEncounterText()
end

function Battle:processCharacterActions()
    if self.state ~= "ACTIONS" then
        self:setState("ACTIONS", "DONTPROCESS")
    end

    self.current_action_index = 1

    local order = {"ACT", {"SPELL", "ITEM", "SPARE"}}

    for lib_id,_ in Kristal.iterLibraries() do
        order = Kristal.libCall(lib_id, "getActionOrder", order, self.encounter) or order
    end
    order = Kristal.modCall("getActionOrder", order, self.encounter) or order

    -- Always process SKIP actions at the end
    table.insert(order, "SKIP")

    for _,action_group in ipairs(order) do
        if self:processActionGroup(action_group) then
            self:tryProcessNextAction()
            return
        end
    end

    self:setSubState("NONE")
    self:setState("ATTACKING")
    --[[self.timer:after(4 / 30, function()
        self:setState("ENEMYDIALOGUE")
    end)]]
    --self:setState("ACTIONSELECT")
end

function Battle:processActionGroup(group)
    if type(group) == "string" then
        local found = false
        for i,battler in ipairs(self.party) do
            local action = self.character_actions[i]
            if action and action.action == group then
                found = true
                self:beginAction(action)
            end
        end
        for _,action in ipairs(self.current_actions) do
            self.character_actions[action.character_id] = nil
        end
        return found
    else
        for i,battler in ipairs(self.party) do
            -- If the table contains the action
            -- Ex. if {"SPELL", "ITEM", "SPARE"} contains "SPARE"
            local action = self.character_actions[i]
            if action and Utils.containsValue(group, action.action) then
                self.character_actions[i] = nil
                self:beginAction(action)
                return true
            end
        end
    end
end

function Battle:tryProcessNextAction(force)
    if self.state == "ACTIONS" and not self.processing_action then
        if #self.current_actions == 0 then
            self:processCharacterActions()
        else
            while self.current_action_index <= #self.current_actions do
                local action = self.current_actions[self.current_action_index]
                if not self.processed_action[action] then
                    self.processing_action = action
                    if self:processAction(action) then
                        self:finishAction(action)
                    end
                    return
                end
                self.current_action_index = self.current_action_index + 1
            end
        end
    end
end

function Battle:getCurrentActing()
    local result = {}
    for _,action in ipairs(self.current_actions) do
        if action.action == "ACT" then
            table.insert(result, action)
        end
    end
    return result
end

function Battle:beginAction(action)
    local battler = self.party[action.character_id]
    local enemy = action.target

    -- Add the action to the actions table, for group processing
    table.insert(self.current_actions, action)

    -- Set the state
    if self.state == "ACTIONS" then
        self:setSubState(action.action)
    end

    -- Call mod callbacks for adding new beginAction behaviour
    if Kristal.callEvent(KRISTAL_EVENT.onBattleActionBegin, action, action.action, battler, enemy) then
        return
    end

    if action.action == "ACT" then
        -- Play the ACT animation by default
        battler:setAnimation("battle/act")
        -- Enemies might change the ACT animation, so run onActStart here
        enemy:onActStart(battler, action.name)
    end
end

function Battle:retargetEnemy()
    for _,other in ipairs(self.enemies) do
        if not other.done_state then
            return other
        end
    end
end

function Battle:processAction(action)
    local battler = self.party[action.character_id]
    local party_member = battler.chara
    local enemy = action.target

    self.current_processing_action = action

    local next_enemy = self:retargetEnemy()
    if not next_enemy then
        return true
    end

    if enemy and enemy.done_state then
        enemy = next_enemy
        action.target = next_enemy
    end

    -- Call mod callbacks for onBattleAction to either add new behaviour for an action or override existing behaviour
    -- Note: non-immediate actions require explicit "return false"!
    local callback_result = Kristal.modCall("onBattleAction", action, action.action, battler, enemy)
    if callback_result ~= nil then
        return callback_result
    end
    for lib_id,_ in Kristal.iterLibraries() do
        callback_result = Kristal.libCall(lib_id, "onBattleAction", action, action.action, battler, enemy)
        if callback_result ~= nil then
            return callback_result
        end
    end

    if action.action == "SPARE" then
        local worked = enemy:canSpare()

        local text = enemy:getSpareText(battler, worked)
        if text then
            self:battleText(text)
        end

        battler:setAnimation("battle/spare", function()
            enemy:onMercy(battler)
            if not worked then
                enemy:mercyFlash()
            end
            self:finishAction(action)
        end)

        return false

    elseif action.action == "ATTACK" or action.action == "AUTOATTACK" then
        local attacksound = battler.chara:getWeapon():getAttackSound(battler, enemy, action.points) or battler.chara:getAttackSound()
        local attackpitch  = battler.chara:getWeapon():getAttackPitch(battler, enemy, action.points) or battler.chara:getAttackPitch()
        local src = Assets.stopAndPlaySound(attacksound or "laz_c")
        src:setPitch(attackpitch or 1)

        self.actions_done_timer = 1.2

        local crit = action.points == 150 and action.action ~= "AUTOATTACK"
        if crit then
            Assets.stopAndPlaySound("criticalswing")

            for i = 1, 3 do
                local sx, sy = battler:getRelativePos(battler.width, 0)
                local sparkle = Sprite("effects/criticalswing/sparkle", sx + Utils.random(50), sy + 30 + Utils.random(30))
                sparkle:play(4/30, true)
                sparkle:setScale(2)
                sparkle.layer = BATTLE_LAYERS["above_battlers"]
                sparkle.physics.speed_x = Utils.random(2, 6)
                sparkle.physics.friction = -0.25
                sparkle:fadeOutSpeedAndRemove()
                self:addChild(sparkle)
            end
        end

        battler:setAnimation("battle/attack", function()
            action.icon = nil

            if action.target and action.target.done_state then
                enemy = self:retargetEnemy()
                action.target = enemy
                if not enemy then
                    self.cancel_attack = true
                    self:finishAction(action)
                    return
                end
            end

            local damage = Utils.round(enemy:getAttackDamage(action.damage or 0, battler, action.points or 0))
            if damage < 0 then
                damage = 0
            end

            if damage > 0 then
                Game:giveTension(Utils.round(enemy:getAttackTension(action.points or 100)))

                local attacksprite = battler.chara:getWeapon():getAttackSprite(battler, enemy, action.points) or battler.chara:getAttackSprite()
                local dmg_sprite = Sprite(attacksprite or "effects/attack/cut")
                dmg_sprite:setOrigin(0.5, 0.5)
                if crit then
                    dmg_sprite:setScale(2.5, 2.5)
                else
                    dmg_sprite:setScale(2, 2)
                end
                local relative_pos_x, relative_pos_y = enemy:getRelativePos(enemy.width/2, enemy.height/2)
                dmg_sprite:setPosition(relative_pos_x + enemy.dmg_sprite_offset[1], relative_pos_y + enemy.dmg_sprite_offset[2])
                dmg_sprite.layer = enemy.layer + 0.01
                dmg_sprite.battler_id = action.character_id or nil
                table.insert(enemy.dmg_sprites, dmg_sprite)
                local dmg_anim_speed = 1/15
                if attacksprite == "effects/attack/shard" then
                    -- Ugly hardcoding BlackShard animation speed accuracy for now
                    dmg_anim_speed = 1/10
                end
                dmg_sprite:play(dmg_anim_speed, false, function(s) s:remove(); Utils.removeFromTable(enemy.dmg_sprites, dmg_sprite) end) -- Remove itself and Remove the dmg_sprite from the enemy's dmg_sprite table when its removed
                enemy.parent:addChild(dmg_sprite)

                local sound = enemy:getDamageSound() or "damage"
                if sound and type(sound) == "string" then
                    Assets.stopAndPlaySound(sound)
                end
                enemy:hurt(damage, battler)

                -- TODO: Call this even if damage is 0, will be a breaking change
                battler.chara:onAttackHit(enemy, damage)
            else
                enemy:hurt(0, battler, nil, nil, nil, action.points ~= 0)
            end

            for _,item in ipairs(battler.chara:getEquipment()) do
                item:onAttackHit(battler, enemy, damage)
            end

            self:finishAction(action)

            Utils.removeFromTable(self.normal_attackers, battler)
            Utils.removeFromTable(self.auto_attackers, battler)

            if not self:retargetEnemy() then
                self.cancel_attack = true
            elseif #self.normal_attackers == 0 and #self.auto_attackers > 0 then
                local next_attacker = self.auto_attackers[1]

                local next_action = self:getActionBy(next_attacker, true)
                if next_action then
                    self:beginAction(next_action)
                    self:processAction(next_action)
                end
            end
        end)

        return false

    elseif action.action == "ACT" then
        -- fun fact: this would have only been a single function call
        -- if stupid multi-acts didn't exist

        -- Check for other short acts
        local self_short = false
        self.short_actions = {}
        for _,iaction in ipairs(self.current_actions) do
            if iaction.action == "ACT" then
                local ibattler = self.party[iaction.character_id]
                local ienemy = iaction.target

                if ienemy then
                    local act = ienemy and ienemy:getAct(iaction.name)

                    if (act and act.short) or (ienemy:getXAction(ibattler) == iaction.name and ienemy:isXActionShort(ibattler)) then
                        table.insert(self.short_actions, iaction)
                        if ibattler == battler then
                            self_short = true
                        end
                    end
                end
            end
        end

        if self_short and #self.short_actions > 1 then
            local short_text = {}
            for _,iaction in ipairs(self.short_actions) do
                local ibattler = self.party[iaction.character_id]
                local ienemy = iaction.target

                local act_text = ienemy:onShortAct(ibattler, iaction.name)
                if act_text then
                    table.insert(short_text, act_text)
                end
            end

            self:shortActText(short_text)
        else
            local text = enemy:onAct(battler, action.name)
            if text then
                self:setActText(text)
            end
        end

        return false

    elseif action.action == "SKIP" then
        return true

    elseif action.action == "SPELL" then
        self.battle_ui:clearEncounterText()

        -- The spell itself handles the animation and finishing
        action.data:onStart(battler, action.target)

        return false

    elseif action.action == "ITEM" then
        local item = action.data
        if item.instant then
            self:finishAction(action)
        else
            local text = item:getBattleText(battler, action.target)
            if text then
                self:battleText(text)
            end
            battler:setAnimation("battle/item", function()
                local result = item:onBattleUse(battler, action.target)
                if result or result == nil then
                    self:finishAction(action)
                end
            end)
        end
        return false

    elseif action.action == "DEFEND" then
        battler:setAnimation("battle/defend")
        battler.defending = true
        return false

    else
        -- we don't know how to handle this...
        Kristal.Console:warn("Unhandled battle action: " .. tostring(action.action))
        return true
    end
end

function Battle:getCurrentAction()
    return self.current_actions[self.current_action_index]
end

function Battle:getActionBy(battler, ignore_current)
    for i,party in ipairs(self.party) do
        if party == battler then
            local action = self.character_actions[i]
            if action then
                return action
            end
            break
        end
    end

    if ignore_current then
        return nil
    end

    for _,action in ipairs(self.current_actions) do
        local ibattler = self.party[action.character_id]
        if ibattler == battler then
            return action
        end
    end
end

function Battle:finishActionBy(battler)
    for _,action in ipairs(self.current_actions) do
        local ibattler = self.party[action.character_id]
        if ibattler == battler then
            self:finishAction(action)
        end
    end
end

function Battle:finishAllActions()
    for _,action in ipairs(self.current_actions) do
        self:finishAction(action)
    end
end

function Battle:allActionsDone()
    for _,action in ipairs(self.current_actions) do
        if not self.processed_action[action] then
            return false
        end
    end
    return true
end

function Battle:clearActionIcon(battler)
    local action

    if not battler then
        action = self:getCurrentAction()
    else
        action = self:getActionBy(battler)
    end

    if action then
        action.icon = nil
    end
end

function Battle:markAsFinished(action, keep_animation)
    if self:getState() ~= "BATTLETEXT" then
        self:finishAction(action, keep_animation)
    else
        self.on_finish_keep_animation = keep_animation
        self.on_finish_action = action
        self.should_finish_action = true
    end
end

function Battle:finishAction(action, keep_animation)
    action = action or self.current_actions[self.current_action_index]

    local battler = self.party[action.character_id]

    self.processed_action[action] = true

    if self.processing_action == action then
        self.processing_action = nil
    end

    local all_processed = self:allActionsDone()

    if all_processed then
        for _,iaction in ipairs(Utils.copy(self.current_actions)) do
            local ibattler = self.party[iaction.character_id]

            local party_num = 1
            local callback = function()
                party_num = party_num - 1
                if party_num == 0 then
                    Utils.removeFromTable(self.current_actions, iaction)
                    self:tryProcessNextAction()
                end
            end

            if iaction.party then
                for _,party in ipairs(iaction.party) do
                    local jbattler = self.party[self:getPartyIndex(party)]

                    if jbattler ~= ibattler then
                        party_num = party_num + 1

                        local dont_end = false
                        if (keep_animation) then
                            if Utils.containsValue(keep_animation, party) then
                                dont_end = true
                            end
                        end

                        if not dont_end then
                            self:endActionAnimation(jbattler, iaction, callback)
                        else
                            callback()
                        end
                    end
                end
            end


            local dont_end = false
            if (keep_animation) then
                if Utils.containsValue(keep_animation, ibattler.chara.id) then
                    dont_end = true
                end
            end

            if not dont_end then
                self:endActionAnimation(ibattler, iaction, callback)
            else
                callback()
            end

            if iaction.action == "DEFEND" then
                ibattler.defending = false
            end

            Kristal.callEvent(KRISTAL_EVENT.onBattleActionEnd, iaction, iaction.action, ibattler, iaction.target, dont_end)
        end
    else
        -- Process actions if we can
        self:tryProcessNextAction()
    end
end

function Battle:endActionAnimation(battler, action, callback)
    local _callback = callback
    callback = function()
        -- Remove the battler's action icon
        if battler.action then
            battler.action.icon = nil
        end
        -- Reset the head sprite
        local box = self.battle_ui.action_boxes[self:getPartyIndex(battler.chara.id)]
        --box:setHeadIcon("head")
        box:resetHeadIcon()
        if _callback then
            _callback()
        end
    end
    if Kristal.callEvent(KRISTAL_EVENT.onBattleActionEndAnimation, action, action.action, battler, action.target, callback, _callback) then
        return
    end
    if action.action ~= "ATTACK" and action.action ~= "AUTOATTACK" then
        if battler.sprite.anim == "battle/"..action.action:lower() then
            -- Attempt to play the end animation if the sprite hasn't changed
            if not battler:setAnimation("battle/"..action.action:lower().."_end", callback) then
                battler:resetSprite()
            end
        else
            -- Otherwise, play idle animation
            battler:resetSprite()
            if callback then
                callback()
            end
        end
    else
        callback()
    end
end

--- Turns a party member's turn from an ACT into a SPELL cast \
--- *Should be called from inside [`EnemyBattler:onAct()`](lua://EnemyBattler.onAct)*
---@param spell     string|Spell        The name of the spell that should be casted by `user`
---@param battler   string              The id of the battler that initiates the ACT
---@param user      string              The id of the battler that should cast the spell
---@param target?   Battler[]|Battler   An optional list of battlers that 
function Battle:powerAct(spell, battler, user, target)

    local user_battler = self:getPartyBattler(user)
    local user_index = self:getPartyIndex(user)

    if user_battler == nil then
        Kristal.Console:error("Invalid power act user: " .. tostring(user))
        return
    end

    if type(spell) == "string" then
        spell = Registry.createSpell(spell)
    end

    local menu_item = {
        data = spell,
        tp = 0
    }

    if target == nil then
        if spell.target == "ally" then
            target = user_battler
        elseif spell.target == "party" then
            target = self.party
        elseif spell.target == "enemy" then
            target = self:getActiveEnemies()[1]
        elseif spell.target == "enemies" then
            target = self:getActiveEnemies()
        end
    end

    local name = user_battler.chara:getName()
    if name == "Ralsei" then
        -- deltarune inconsistency lol
        name = "RALSEI"
    end
    self:setActText("* Your soul shined its power on\n" .. name .. "!", true)

    self.timer:after(7/30, function()
        Assets.playSound("boost")
        battler:flash()
        user_battler:flash()
        local bx, by = self:getSoulLocation()
        local soul = Sprite("effects/soulshine", bx, by)
        soul:play(1/30, false, function() soul:remove() end)
        soul:setOrigin(0.25, 0.25)
        soul:setScale(2, 2)
        self:addChild(soul)

        --[[local box = self.battle_ui.action_boxes[user_index]
        box:setHeadIcon("spell")]]

    end)

    self.timer:after(24/30, function()
        self:pushAction("SPELL", target, menu_item, user_index)
        self:markAsFinished(nil, {user})
    end)
end

function Battle:pushForcedAction(battler, action, target, data, extra)
    data = data or {}

    data.cancellable = false

    self:pushAction(action, target, data, self:getPartyIndex(battler.chara.id), extra)
end

function Battle:pushAction(action_type, target, data, character_id, extra)
    character_id = character_id or self.current_selecting

    local battler = self.party[character_id]

    local current_state = self:getState()

    self:commitAction(battler, action_type, target, data, extra)

    if self.current_selecting == character_id then
        if current_state == self:getState() then
            self:nextParty()
        elseif self.cutscene then
            self.cutscene:after(function()
                self:nextParty()
            end)
        end
    end
end

function Battle:commitAction(battler, action_type, target, data, extra)
    data = data or {}
    extra = extra or {}

    local is_xact = action_type:upper() == "XACT"
    if is_xact then
        action_type = "ACT"
    end

    local tp_diff = 0
    if data.tp then
        tp_diff = Utils.clamp(-data.tp, -Game:getTension(), Game:getMaxTension() - Game:getTension())
    end

    local party_id = self:getPartyIndex(battler.chara.id)

    -- Dont commit action for an inactive party member
    if not battler:isActive() then return end

    -- Make sure this action doesn't cancel any uncancellable actions
    if data.party then
        for _,v in ipairs(data.party) do
            local index = self:getPartyIndex(v)

            if index ~= party_id then
                local action = self.character_actions[index]
                if action then
                    if action.cancellable == false then
                        return
                    end
                    if action.act_parent then
                        local parent_action = self.character_actions[action.act_parent]
                        if parent_action.cancellable == false then
                            return
                        end
                    end
                end
            end
        end
    end

    self:commitSingleAction(Utils.merge({
        ["character_id"] = party_id,
        ["action"] = action_type:upper(),
        ["party"] = data.party,
        ["name"] = data.name,
        ["target"] = target,
        ["data"] = data.data,
        ["tp"] = tp_diff,
        ["cancellable"] = data.cancellable,
    }, extra))

    if data.party then
        for _,v in ipairs(data.party) do
            local index = self:getPartyIndex(v)

            if index ~= party_id then
                local action = self.character_actions[index]
                if action then
                    if action.act_parent then
                        self:removeAction(action.act_parent)
                    else
                        self:removeAction(index)
                    end
                end

                self:commitSingleAction(Utils.merge({
                    ["character_id"] = index,
                    ["action"] = "SKIP",
                    ["reason"] = action_type:upper(),
                    ["name"] = data.name,
                    ["target"] = target,
                    ["data"] = data.data,
                    ["act_parent"] = party_id,
                    ["cancellable"] = data.cancellable,
                }, extra))
            end
        end
    end
end

function Battle:removeAction(character_id)
    local action = self.character_actions[character_id]

    if action then
        self:removeSingleAction(action)

        if action.party then
            for _,v in ipairs(action.party) do
                if v ~= character_id then
                    local iaction = self.character_actions[self:getPartyIndex(v)]
                    if iaction then
                        self:removeSingleAction(iaction)
                    end
                end
            end
        end
    end
end

function Battle:commitSingleAction(action)
    local battler = self.party[action.character_id]

    battler.action = action
    self.character_actions[action.character_id] = action

    if Kristal.callEvent(KRISTAL_EVENT.onBattleActionCommit, action, action.action, battler, action.target) then
        return
    end

    if action.action == "ITEM" and action.data then
        local result = action.data:onBattleSelect(battler, action.target)
        if result ~= false then
            local storage, index = Game.inventory:getItemIndex(action.data)
            action.item_storage = storage
            action.item_index = index
            if action.data:hasResultItem() then
                local result_item = action.data:createResultItem()
                Game.inventory:setItem(storage, index, result_item)
                action.result_item = result_item
            else
                Game.inventory:removeItem(action.data)
            end
            action.consumed = true
        else
            action.consumed = false
        end
    end

    local anim = action.action:lower()
    if action.action == "SPELL" and action.data then
        anim = action.data:getSelectAnimation()
        local result = action.data:onSelect(battler, action.target)
        if result ~= false then
            if action.tp then
                if action.tp > 0 then
                    Game:giveTension(action.tp)
                elseif action.tp < 0 then
                    Game:removeTension(-action.tp)
                end
            end
            battler:setAnimation(anim)
            action.icon = action.action:lower()
        end
    else
        if action.tp then
            if action.tp > 0 then
                Game:giveTension(action.tp)
            elseif action.tp < 0 then
                Game:removeTension(-action.tp)
            end
        end

        if action.action == "SKIP" and action.reason then
            anim = action.reason:lower()
        end

        if (action.action == "ITEM" and action.data and (not action.data.instant)) or (action.action ~= "ITEM") then
            battler:setAnimation("battle/"..anim.."_ready")
            action.icon = anim
        end
    end
end

function Battle:removeSingleAction(action)
    local battler = self.party[action.character_id]

    if Kristal.callEvent(KRISTAL_EVENT.onBattleActionUndo, action, action.action, battler, action.target) then
        battler.action = nil
        self.character_actions[action.character_id] = nil
        return
    end

    battler:resetSprite()

    if action.tp then
        if action.tp < 0 then
            Game:giveTension(-action.tp)
        elseif action.tp > 0 then
            Game:removeTension(action.tp)
        end
    end

    if action.action == "ITEM" and action.data then
        if action.item_index and action.consumed then
            if action.result_item then
                Game.inventory:setItem(action.item_storage, action.item_index, action.data)
            else
                Game.inventory:addItemTo(action.item_storage, action.item_index, action.data)
            end
        end
        action.data:onBattleDeselect(battler, action.target)
    elseif action.action == "SPELL" and action.data then
        action.data:onDeselect(battler, action.target)
    end

    battler.action = nil
    self.character_actions[action.character_id] = nil
end

--- Gets the index of a party member with the given id
---@param string_id string
---@return integer?
function Battle:getPartyIndex(string_id)
    for index, battler in ipairs(self.party) do
        if battler.chara.id == string_id then
            return index
        end
    end
    return nil
end

--- Gets a PartyBattler in the current battle from their id
---@param string_id string
---@return PartyBattler?
function Battle:getPartyBattler(string_id)
    for _, battler in ipairs(self.party) do
        if battler.chara.id == string_id then
            return battler
        end
    end
    return nil
end

--- Gets an EnemyBattler in the current battle from their id
---@param string_id string
---@return EnemyBattler?
function Battle:getEnemyBattler(string_id)
    for _, enemy in ipairs(self.enemies) do
        if enemy.id == string_id then
            return enemy
        end
    end
end

--- Gets an enemy in battle from their corresponding world `Character`
---@param chara Character
---@return EnemyBattler?
function Battle:getEnemyFromCharacter(chara)
    for _, enemy in ipairs(self.enemies) do
        if self.enemy_world_characters[enemy] == chara then
            return enemy
        end
    end
    for _, enemy in ipairs(self.defeated_enemies) do
        if self.enemy_world_characters[enemy] == chara then
            return enemy
        end
    end
end

--- Gets whether a specific character has an action lined up
---@param character_id integer
---@return boolean
function Battle:hasAction(character_id)
    return self.character_actions[character_id] ~= nil
end

--- Returns whether `collider` collides with the arena
---@param collider Collider
---@return boolean  collided
---@return Arena?   colliding_arena
function Battle:checkSolidCollision(collider)
    if NOCLIP then return false end
    Object.startCache()
    if self.arena then
        if self.arena:collidesWith(collider) then
            Object.endCache()
            return true, self.arena
        end
    end
    for _,solid in ipairs(Game.stage:getObjects(Solid)) do
        if solid:collidesWith(collider) then
            Object.endCache()
            return true, solid
        end
    end
    Object.endCache()
    return false
end

--- Shakes the camera by the specified `x`, `y`.
---@param x?        number      The amount of shake in the `x` direction. (Defaults to `4`)
---@param y?        number      The amount of shake in the `y` direction. (Defaults to `4`)
---@param friction? number      The amount that the shake should decrease by, per frame at 30FPS. (Defaults to `1`)
function Battle:shakeCamera(x, y, friction)
    self.camera:shake(x, y, friction)
end

---@return "ALL"|PartyBattler
function Battle:randomTargetOld()
    -- This is "scr_randomtarget_old".
    local none_targetable = true
    for _,battler in ipairs(self.party) do
        if battler:canTarget() then
            none_targetable = false
            break
        end
    end

    if none_targetable then
        return "ALL"
    end

    -- Pick random party member
    local target = nil
    while not target do
        local party = Utils.pick(self.party)
        if party:canTarget() then
            target = party
        end
    end

    target.should_darken = false
    target.darken_timer = 0
    target.targeted = true
    return target
end

---@return "ANY"|PartyBattler
function Battle:randomTarget()
    -- This is "scr_randomtarget".
    local target = self:randomTargetOld()

    if (not Game:getConfig("targetSystem")) and (target ~= "ALL") then
        for _,battler in ipairs(self.party) do
            if battler:canTarget() then
                battler.targeted = true
            end
        end
        return "ANY"
    end

    return target
end

---@return "ALL"
function Battle:targetAll()
    for _,battler in ipairs(self.party) do
        if battler:canTarget() then
            battler.targeted = true
        end
    end
    return "ALL"
end

---@return "ANY"
function Battle:targetAny()
    for _,battler in ipairs(self.party) do
        if battler:canTarget() then
            battler.targeted = true
        end
    end
    return "ANY"
end

---@param target PartyBattler|number
---@return "ALL"|"ANY"|PartyBattler
function Battle:target(target)
    if type(target) == "number" then
        target = self.party[target]
    end

    if target and target:canTarget() then
        target.targeted = true
        return target
    end

    return self:targetAny()
end

function Battle:getPartyFromTarget(target)
    if type(target) == "number" then
        return {self.party[target]}
    elseif isClass(target) then
        return {target}
    elseif type(target) == "string" then
        if target == "ANY" then
            return {Utils.pick(self.party)}
        elseif target == "ALL" then
            return Utils.copy(self.party)
        else
            for _,battler in ipairs(self.party) do
                if battler.chara.id == string.lower(target) then
                    return {battler}
                end
            end
        end
    end
end

--- Hurts the `target` party member(s)
---@param amount    number
---@param exact?    boolean
---@param target?   number|"ALL"|"ANY"|PartyBattler The target battler's index, instance, or strings for specific selection logic (defaults to `"ANY"`)
---@return table?
function Battle:hurt(amount, exact, target)
    -- If target is a numberic value, it will hurt the party battler with that index
    -- "ANY" will choose the target randomly
    -- "ALL" will hurt the entire party all at once
    target = target or "ANY"

    -- Alright, first let's try to adjust targets.

    if type(target) == "number" then
        target = self.party[target]
    end

    if isClass(target) and target:includes(PartyBattler) then
        if (not target) or (target.chara:getHealth() <= 0) then -- Why doesn't this look at :canTarget()? Weird.
            target = self:randomTargetOld()
        end
    end

    if target == "ANY" then
        target = self:randomTargetOld()

        -- Calculate the average HP of the party.
        -- This is "scr_party_hpaverage", which gets called multiple times in the original script.
        -- We'll only do it once here, just for the slight optimization. This won't affect accuracy.

        -- Speaking of accuracy, this function doesn't work at all!
        -- It contains a bug which causes it to always return 0, unless all party members are at full health.
        -- This is because of a random floor() call.
        -- I won't bother making the code accurate; all that matters is the output.

        local party_average_hp = 1

        for _,battler in ipairs(self.party) do
            if battler.chara:getHealth() ~= battler.chara:getStat("health") then
                party_average_hp = 0
                break
            end
        end

        -- Retarget... twice.
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end

        -- If we landed on Kris (or, well, the first party member), and their health is low, retarget (plot armor lol)
        if (target == self.party[1]) and ((target.chara:getHealth() / target.chara:getStat("health")) < 0.35) then
            target = self:randomTargetOld()
        end

        -- They got hit, so un-darken them
        target.should_darken = false
        target.targeted = true
    end

    -- Now it's time to actually damage them!
    if isClass(target) and target:includes(PartyBattler) then
        target:hurt(amount, exact)
        return {target}
    end

    if target == "ALL" then
        Assets.playSound("hurt")
        local alive_battlers = Utils.filter(self.party, function(battler) return not battler.is_down end)
        for _,battler in ipairs(alive_battlers) do
            battler:hurt(amount, exact, nil, {all = true})
        end
        -- Return the battlers who aren't down, aka the ones we hit.
        return alive_battlers
    end
end

--- Sets the waves table to what is specified by `waves`
---@param waves table<string|Wave>
---@param allow_duplicates? boolean If true, duplicate waves will coexist with each other
---@return Wave[]
function Battle:setWaves(waves, allow_duplicates)
    for _,wave in ipairs(self.waves) do
        wave:onEnd(false)
        wave:clear()
        wave:remove()
    end
    self.waves = {}
    self.finished_waves = false
    local added_wave = {}
    for _,wave in ipairs(waves) do
        local exists = (type(wave) == "string" and added_wave[wave]) or (isClass(wave) and added_wave[wave.id])
        if allow_duplicates or not exists then
            if type(wave) == "string" then
                wave = Registry.createWave(wave)
            end
            wave.encounter = self.encounter
            self:addChild(wave)
            table.insert(self.waves, wave)
            added_wave[wave.id] = true

            -- Keep wave inactive until it's time to start
            wave.active = false
        end
    end
    return self.waves
end

function Battle:startProcessing()
    self.has_acted = false
    if not self.encounter:onActionsStart() then
        self:setState("ACTIONS")
    end
end

---@param index integer
function Battle:setSelectedParty(index)
    self.current_selecting = index or 0
end

function Battle:nextParty()
    table.insert(self.selected_character_stack, self.current_selecting)
    table.insert(self.selected_action_stack, Utils.copy(self.character_actions))

    local all_done = true
    local last_selected = self.current_selecting
    self.current_selecting = (self.current_selecting % #self.party) + 1
    while self.current_selecting ~= last_selected do
        if not self:hasAction(self.current_selecting) and self.party[self.current_selecting]:isActive() then
            all_done = false
            break
        end
        self.current_selecting = (self.current_selecting % #self.party) + 1
    end

    if all_done then
        self.selected_character_stack = {}
        self.selected_action_stack = {}
        self.current_action_processing = 1
        self.current_selecting = 0
        self:startProcessing()
    else
        if self:getState() ~= "ACTIONSELECT" then
            self:setState("ACTIONSELECT")
            self.battle_ui.encounter_text:setText("[instant]" .. self.battle_ui.current_encounter_text)
        end
        local party = self.party[self.current_selecting]
        party.chara:onActionSelect(party, false)
        self.encounter:onCharacterTurn(party, false)
    end
end

function Battle:previousParty()
    if #self.selected_character_stack == 0 then
        return
    end

    self.current_selecting = self.selected_character_stack[#self.selected_character_stack] or 1
    local new_actions = self.selected_action_stack[#self.selected_action_stack-1] or {}

    for i,battler in ipairs(self.party) do
        local old_action = self.character_actions[i]
        local new_action = new_actions[i]
        if new_action ~= old_action then
            if old_action.cancellable == false then
                new_actions[i] = old_action
            else
                if old_action then
                    self:removeSingleAction(old_action)
                end
                if new_action then
                    self:commitSingleAction(new_action)
                end
            end
        end
    end

    self.selected_action_stack[#self.selected_action_stack-1] = new_actions

    table.remove(self.selected_character_stack, #self.selected_character_stack)
    table.remove(self.selected_action_stack, #self.selected_action_stack)

    local party = self.party[self.current_selecting]
    party.chara:onActionSelect(party, true)
    self.encounter:onCharacterTurn(party, true)
end

--- Advances to the next turn of the battle
function Battle:nextTurn()
    self.turn_count = self.turn_count + 1
    if self.turn_count > 1 then
        if self.encounter:onTurnEnd() then
            return
        end
        for _,enemy in ipairs(self:getActiveEnemies()) do
            if enemy:onTurnEnd() then
                return
            end
        end
    end

    for _,action in ipairs(self.current_actions) do
        if action.action == "DEFEND" then
            self:finishAction(action)
        end
    end

    for _,enemy in ipairs(self.enemies) do
        enemy.selected_wave = nil
        enemy.hit_count = 0
    end

    for _,battler in ipairs(self.party) do
        battler.hit_count = 0
        if (battler.chara:getHealth() <= 0) and battler.chara:canAutoHeal() then
            battler:heal(battler.chara:autoHealAmount(), nil, true)
        end
        battler.action = nil
    end

    self.attackers = {}
    self.normal_attackers = {}
    self.auto_attackers = {}

    self.current_selecting = 1
    while not (self.party[self.current_selecting]:isActive()) do
        self.current_selecting = self.current_selecting + 1
        if self.current_selecting > #self.party then
            Kristal.Console:warn("Nobody up! This shouldn't happen...")
            self.current_selecting = 1
            break
        end
    end

    self.current_button = 1

    self.character_actions = {}
    self.current_actions = {}
    self.processed_action = {}

    if self.battle_ui then
        for _,box in ipairs(self.battle_ui.action_boxes) do
            box.selected_button = 1
            --box:setHeadIcon("head")
            box:resetHeadIcon()
        end
        if self.state == "INTRO" or self.state_reason == "INTRO" or not self.seen_encounter_text then
            self.seen_encounter_text = true
            self.battle_ui.current_encounter_text = self.encounter.text
        else
            self.battle_ui.current_encounter_text = self:getEncounterText()
        end
        self.battle_ui.encounter_text:setText(self.battle_ui.current_encounter_text)
    end

    if self.soul then
        self:returnSoul()
    end

    self.encounter:onTurnStart()

    for _,enemy in ipairs(self:getActiveEnemies()) do
        enemy:onTurnStart()
    end

    if self.battle_ui then
        for _,party in ipairs(self.party) do
            party.chara:onTurnStart(party)
        end
    end

    if self.current_selecting ~= 0 and self.state ~= "ACTIONSELECT" then
        self:setState("ACTIONSELECT")
    end
end

--- Checks to see whether the whole party is downed and starts a [`GameOver`](lua://GameOver.init) if they are
function Battle:checkGameOver()
    for _,battler in ipairs(self.party) do
        if not battler.is_down then
            return
        end
    end
    self.music:stop()
    if self:getState() == "DEFENDING" then
        for _,wave in ipairs(self.waves) do
            wave:onEnd(true)
        end
    end
    if self.encounter:onGameOver() then
        return
    end
    Game:gameOver(self:getSoulLocation())
end

--- Ends the battle and removes itself from `Game.battle`
function Battle:returnToWorld()
    if not Game:getConfig("keepTensionAfterBattle") then
        Game:setTension(0)
    end
    self.encounter:setFlag("done", true)
    if self.used_violence then
        self.encounter:setFlag("violenced", true)
    end
    self.transition_timer = 0
    for _,battler in ipairs(self.party) do
        if self.party_world_characters[battler.chara.id] then
            self.party_world_characters[battler.chara.id].visible = true
        end
    end
    local all_enemies = {}
    Utils.merge(all_enemies, self.defeated_enemies)
    Utils.merge(all_enemies, self.enemies)
    for _,enemy in ipairs(all_enemies) do
        local world_chara = self.enemy_world_characters[enemy]
        if world_chara then
            world_chara.visible = true
        end
        if not enemy.exit_on_defeat and world_chara and world_chara.parent then
            if world_chara.onReturnFromBattle then
                world_chara:onReturnFromBattle(self.encounter, enemy)
            end
        end
    end
    if self.encounter_context and self.encounter_context:includes(ChaserEnemy) then
        for _,enemy in ipairs(self.encounter_context:getGroupedEnemies(true)) do
            enemy:onEncounterEnd(enemy == self.encounter_context, self.encounter)
        end
    end
    self.music:stop()
    if self.resume_world_music then
        Game.world.music:resume()
    end
    self:remove()
    self.encounter.defeated_enemies = self.defeated_enemies
    Game.battle = nil
    Game.state = "OVERWORLD"
end

---@param text          string|string[]
---@param dont_finish?  boolean
function Battle:setActText(text, dont_finish)
    self:battleText(text, function()
        if not dont_finish then
            self:finishAction()
        end
        if self.should_finish_action then
            self:finishAction(self.on_finish_action, self.on_finish_keep_animation)
            self.on_finish_action = nil
            self.on_finish_keep_animation = nil
            self.should_finish_action = false
        end
        self:setState("ACTIONS", "BATTLETEXT")
        return true
    end)
end

---@param text string[]
function Battle:shortActText(text)
    self:setState("SHORTACTTEXT")
    self.battle_ui:clearEncounterText()

    self.battle_ui.short_act_text_1:setText(text[1] or "")
    self.battle_ui.short_act_text_2:setText(text[2] or "")
    self.battle_ui.short_act_text_3:setText(text[3] or "")
end

--- Sets the current message in the battlebox and moves to the `BATTLETEXT` state until it is advanced, where it returns to the previous state by default
---@param text string[]|string              The text to set
---@param post_func? fun():boolean|string   When the text is advanced, the name of the state to move to, or a function to run
function Battle:battleText(text,post_func)
    local target_state = self:getState()

    self.battle_ui.encounter_text:setText(text, function()
        self.battle_ui:clearEncounterText()
        if type(post_func) == "string" then
            target_state = post_func
        elseif type(post_func) == "function" and post_func() then
            return
        end
        self:setState(target_state)
    end)
    self.battle_ui.encounter_text:setAdvance(true)

    self:setState("BATTLETEXT")
end

--- Sets the current message in the battlebox - this text can not be advanced, only overwritten if another text is set
---@param text? string[]    The text to set
function Battle:infoText(text)
    self.battle_ui.encounter_text:setText(text or "")
end

---@return boolean?
function Battle:hasCutscene()
    return self.cutscene and not self.cutscene.ended
end

--- Starts a cutscene in battle \
--- *When setting a cutscene during the `ACTIONS` state, see [`Battle:startActCutscene()](lua://Battle.startActCutscene) instead*
---@overload fun(self: Battle, id: string, ...)
---@param group string  The name of the group the cutscene is a part of
---@param id    string  The id of the cutscene 
---@param ...   any     Additional arguments that will be passed to the cutscene function
---@return BattleCutscene?
function Battle:startCutscene(group, id, ...)
    if self.cutscene then
        local cutscene_name = ""
        if type(group) == "string" then
            cutscene_name = group
            if type(id) == "string" then
                cutscene_name = group.."."..id
            end
        elseif type(group) == "function" then
            cutscene_name = "<function>"
        end
        error("Attempt to start a cutscene "..cutscene_name.." while already in cutscene "..self.cutscene.id)
    end
    self.cutscene = BattleCutscene(group, id, ...)
    return self.cutscene
end

--- Starts a cutscene in battle where the cutscene receives the the currently ACTing character and the ACT's target as additional arguments \
---@overload fun(self: Battle, id: string, dont_finish?: boolean)
---@param group         string  The name of the group the cutscene is a part of
---@param id            string  The id of the cutscene 
---@param dont_finish?  boolean Whether the action should end when the cutscene finishes (defaults to `false`)
---@return Cutscene?
function Battle:startActCutscene(group, id, dont_finish)
    local action = self:getCurrentAction()
    local cutscene
    if type(id) ~= "string" then
        dont_finish = id
        cutscene = self:startCutscene(group, self.party[action.character_id], action.target)
    else
        cutscene = self:startCutscene(group, id, self.party[action.character_id], action.target)
    end
    return cutscene:after(function()
        if not dont_finish then
            self:finishAction(action)
        end
        self:setState("ACTIONS", "CUTSCENE")
    end)
end

--[[function Battle:startCutscene(cutscene, post_func)
    BattleScene.start(cutscene, post_func)
end]]

function Battle:sortChildren()
    -- Sort battlers by Y position
    table.stable_sort(self.children, function(a, b)
        return a.layer < b.layer or (a.layer == b.layer and (a:includes(Battler) and b:includes(Battler)) and a.y < b.y)
    end)
end

function Battle:update()
    for _,enemy in ipairs(self.enemies_to_remove) do
        Utils.removeFromTable(self.enemies, enemy)
        local enemy_y = Utils.getKey(self.enemies_index, enemy)
        if enemy_y then
            self.enemies_index[enemy_y] = false
        end
    end
    self.enemies_to_remove = {}

    if self.cutscene then
        if not self.cutscene.ended then
            self.cutscene:update()
        else
            self.cutscene = nil
        end
    end
    if Game.battle == nil then return end -- cutscene ended the battle

    if self.state == "TRANSITION" then
        self:updateTransition()
    elseif self.state == "INTRO" then
        self:updateIntro()
    elseif self.state == "ATTACKING" then
        self:updateAttacking()
    elseif self.state == "ACTIONSDONE" then
        self.actions_done_timer = Utils.approach(self.actions_done_timer, 0, DT)
        local any_hurt = false
        for _,enemy in ipairs(self.enemies) do
            if enemy.hurt_timer > 0 then
                any_hurt = true
                break
            end
        end
        if self.actions_done_timer == 0 and not any_hurt then
            self:resetAttackers()
            if not self.encounter:onActionsEnd() then
                self:setState("ENEMYDIALOGUE")
            end
        end
    elseif self.state == "DEFENDINGBEGIN" then
        self.defending_begin_timer = self.defending_begin_timer + DTMULT
        if self.defending_begin_timer >= 15 then
            self:setState("DEFENDING")
        end
    elseif self.state == "DEFENDING" then
        self:updateWaves()
    elseif self.state == "ENEMYDIALOGUE" then
        self.textbox_timer = self.textbox_timer - DTMULT
        if (self.textbox_timer <= 0) and self.use_textbox_timer then
            self:advanceBoxes()
        else
            local all_done = true
            for _,textbox in ipairs(self.enemy_dialogue) do
                if not textbox:isDone() then
                    all_done = false
                    break
                end
            end
            if all_done then
                self:setState("DIALOGUEEND")
            end
        end
    elseif self.state == "SHORTACTTEXT" then
        self:updateShortActText()
    end

    if self.state ~= "TRANSITIONOUT" then
        self.encounter:update()
    end
    
    -- prevents the bolts afterimage from continuing till the edge of the screen when all the enemies are defeated but there're still unfinished attacks
    if self.state ~= "ATTACKING" then
        for _,attack in ipairs(self.battle_ui.attack_boxes) do
            if not attack.attacked and attack:getClose() <= -2 then
                attack:miss()
            end
        end
    end

    self.offset = self.offset + 1 * DTMULT

    if self.offset > 100 then
        self.offset = self.offset - 100
    end

    self.pacify_glow_timer = self.pacify_glow_timer + DTMULT

    if (self.state == "ENEMYDIALOGUE") or (self.state == "DEFENDINGBEGIN") or (self.state == "DEFENDING") then
        self.background_fade_alpha = math.min(self.background_fade_alpha + (0.05 * DTMULT), 0.75)
        if not self.darkify then
            self.darkify = true
            for _,battler in ipairs(self.party) do
                battler.should_darken = true
            end
        end
    end

    if Utils.containsValue({"DEFENDINGEND", "ACTIONSELECT", "ACTIONS", "VICTORY", "TRANSITIONOUT", "BATTLETEXT"}, self.state) then
        self.background_fade_alpha = math.max(self.background_fade_alpha - (0.05 * DTMULT), 0)
        if self.darkify then
            self.darkify = false
            for _,battler in ipairs(self.party) do
                battler.should_darken = false
            end
        end
    end

    -- Always sort
    --self.update_child_list = true
    super.update(self)

    if self.state == "TRANSITIONOUT" then
        self:updateTransitionOut()
    end
end

function Battle:updateChildren()
    if self.update_child_list then
        self:updateChildList()
        self.update_child_list = false
    end
    for _,v in ipairs(self.draw_fx) do
        v:update()
    end
    for _,v in ipairs(self.children) do
        -- only update if Game.battle is still a reference to this
        if v.active and v.parent == self and Game.battle == self then
            v:fullUpdate()
        end
    end
end

function Battle:updateIntro()
    self.intro_timer = self.intro_timer + 1 * DTMULT
    if self.intro_timer >= 15 then -- TODO: find out why this is 15 instead of 13
        for _,v in ipairs(self.party) do
            v:setAnimation("battle/idle")
        end
        self:setState("ACTIONSELECT", "INTRO")
        --self:nextTurn()
    end
end

function Battle:updateTransition()
    while self.afterimage_count < math.floor(self.transition_timer) do
        for index, battler in ipairs(self.party) do
            local target_x, target_y = unpack(self.battler_targets[index])

            local battler_x = battler.x
            local battler_y = battler.y

            battler.x = Utils.lerp(self.party_beginning_positions[index][1], target_x, (self.afterimage_count + 1) / 10)
            battler.y = Utils.lerp(self.party_beginning_positions[index][2], target_y, (self.afterimage_count + 1) / 10)

            local afterimage = AfterImage(battler, 0.5)
            self:addChild(afterimage)

            battler.x = battler_x
            battler.y = battler_y
        end
        self.afterimage_count = self.afterimage_count + 1
    end

    self.transition_timer = self.transition_timer + 1 * DTMULT

    if self.transition_timer >= 10 then
        self.transition_timer = 10
        self:setState("INTRO")
    end

    for index, battler in ipairs(self.party) do
        local target_x, target_y = unpack(self.battler_targets[index])

        battler.x = Utils.lerp(self.party_beginning_positions[index][1], target_x, self.transition_timer / 10)
        battler.y = Utils.lerp(self.party_beginning_positions[index][2], target_y, self.transition_timer / 10)
    end
    for _, enemy in ipairs(self.enemies) do
        enemy.x = Utils.lerp(self.enemy_beginning_positions[enemy][1], enemy.target_x, self.transition_timer / 10)
        enemy.y = Utils.lerp(self.enemy_beginning_positions[enemy][2], enemy.target_y, self.transition_timer / 10)
    end
end

function Battle:updateTransitionOut()
    if not self.battle_ui.animation_done then
        return
    end

    local all_enemies = {}
    Utils.merge(all_enemies, self.enemies)
    Utils.merge(all_enemies, self.defeated_enemies)

    self.transition_timer = self.transition_timer - DTMULT

    if self.transition_timer <= 0 then--or not self.transitioned then
        local enemies = {}
        for k,v in pairs(self.enemy_world_characters) do
            table.insert(enemies, v)
        end
        self.encounter:onReturnToWorld(enemies)
        self:returnToWorld()
        return
    end

    for index, battler in ipairs(self.party) do
        local target_x, target_y = unpack(self.battler_targets[index])

        battler.x = Utils.lerp(self.party_beginning_positions[index][1], target_x, self.transition_timer / 10)
        battler.y = Utils.lerp(self.party_beginning_positions[index][2], target_y, self.transition_timer / 10)
    end

    for _, enemy in ipairs(all_enemies) do
        local world_chara = self.enemy_world_characters[enemy]
        if enemy.target_x and enemy.target_y and not enemy.exit_on_defeat and world_chara and world_chara.parent then
            enemy.x = Utils.lerp(self.enemy_beginning_positions[enemy][1], enemy.target_x, self.transition_timer / 10)
            enemy.y = Utils.lerp(self.enemy_beginning_positions[enemy][2], enemy.target_y, self.transition_timer / 10)
        else
            local fade = enemy:getFX("battle_end")
            if not fade then
                fade = enemy:addFX(AlphaFX(1), "battle_end")
            end
            fade.alpha = self.transition_timer / 10
        end
    end
end

function Battle:updateAttacking()
    if self.cancel_attack then
        self:finishAllActions()
        self:setState("ACTIONSDONE")
        return
    end
    if not self.attack_done then
        if not self.battle_ui.attacking then
            self.battle_ui:beginAttack()
        end

        if #self.attackers == #self.auto_attackers and self.auto_attack_timer < 4 then
            self.auto_attack_timer = self.auto_attack_timer + DTMULT

            if self.auto_attack_timer >= 4 then
                local next_attacker = self.auto_attackers[1]

                local next_action = self:getActionBy(next_attacker, true)
                if next_action then
                    self:beginAction(next_action)
                    self:processAction(next_action)
                end
            end
        end

        local all_done = true
        for _,attack in ipairs(self.battle_ui.attack_boxes) do
            if not attack.attacked and attack.fade_rect.alpha < 1 then
                local close = attack:getClose()
                if close <= -2 then
                    attack:miss()

                    local action = self:getActionBy(attack.battler, true)
                    action.points = 0

                    if self:processAction(action) then
                        self:finishAction(action)
                    end
                else
                    all_done = false
                end
            end
        end

        if #self.auto_attackers > 0 then
            all_done = false
        end

        if all_done then
            self.attack_done = true
        end
    else
        if self:allActionsDone() then
            self:setState("ACTIONSDONE")
        end
    end
end

function Battle:updateWaves()
    self.wave_timer = self.wave_timer + DT

    local all_done = true
    for _,wave in ipairs(self.waves) do
        if not wave.finished then
            if wave.time >= 0 and self.wave_timer >= wave.time then
                wave.finished = true
            else
                all_done = false
            end
        end
        if not wave:canEnd() then
            all_done = false
        end
    end

    if all_done and not self.finished_waves then
        self.finished_waves = true
        self.encounter:onWavesDone()
    end
end

function Battle:updateShortActText()
    if Input.pressed("confirm") or Input.down("menu") then
        if (not self.battle_ui.short_act_text_1:isTyping()) and
           (not self.battle_ui.short_act_text_2:isTyping()) and
           (not self.battle_ui.short_act_text_3:isTyping()) then
            self.battle_ui.short_act_text_1:setText("")
            self.battle_ui.short_act_text_2:setText("")
            self.battle_ui.short_act_text_3:setText("")
            for _,iaction in ipairs(self.short_actions) do
                self:finishAction(iaction)
            end
            self.short_actions = {}
            self:setState("ACTIONS", "SHORTACTTEXT")
        end
    end
end

---@param string    string
---@param x         number
---@param y         number
---@param color?    table
function Battle:debugPrintOutline(string, x, y, color)
    color = color or {love.graphics.getColor()}
    Draw.setColor(0, 0, 0, 1)
    love.graphics.print(string, x - 1, y)
    love.graphics.print(string, x + 1, y)
    love.graphics.print(string, x, y - 1)
    love.graphics.print(string, x, y + 1)

    Draw.setColor(color)
    love.graphics.print(string, x, y)
end

function Battle:drawDebug()
    local font = Assets.getFont("main", 16)
    love.graphics.setFont(font)

    Draw.setColor(1, 1, 1, 1)
    self:debugPrintOutline("State: "    .. self.state   , 4, 0)
    self:debugPrintOutline("Substate: " .. self.substate, 4, 0 + 16)
end

function Battle:draw()
    if self.encounter.background then
        self:drawBackground()
    end

    self.encounter:drawBackground(self.transition_timer / 10)

    Draw.setColor(0, 0, 0, self.background_fade_alpha)
    love.graphics.rectangle("fill", -20, -20, SCREEN_WIDTH + 40, SCREEN_HEIGHT + 40)

    super.draw(self)

    self.encounter:draw(self.transition_timer / 10)

    if DEBUG_RENDER then
        self:drawDebug()
    end
end

function Battle:drawBackground()
    Draw.setColor(0, 0, 0, self.transition_timer / 10)
    love.graphics.rectangle("fill", -8, -8, SCREEN_WIDTH+16, SCREEN_HEIGHT+16)

    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(1)

    for i = 2, 16 do
        Draw.setColor(66 / 255, 0, 66 / 255, (self.transition_timer / 10) / 2)
        love.graphics.line(0, -210 + (i * 50) + math.floor(self.offset / 2), 640, -210 + (i * 50) + math.floor(self.offset / 2))
        love.graphics.line(-200 + (i * 50) + math.floor(self.offset / 2), 0, -200 + (i * 50) + math.floor(self.offset / 2), 480)
    end

    for i = 3, 16 do
        Draw.setColor(66 / 255, 0, 66 / 255, self.transition_timer / 10)
        love.graphics.line(0, -100 + (i * 50) - math.floor(self.offset), 640, -100 + (i * 50) - math.floor(self.offset))
        love.graphics.line(-100 + (i * 50) - math.floor(self.offset), 0, -100 + (i * 50) - math.floor(self.offset), 480)
    end
end

function Battle:isWorldHidden()
    return self.state ~= "TRANSITION" and self.state ~= "TRANSITIONOUT" and
           (self.encounter.background or self.encounter.hide_world)
end

---@param menu_item table
---@return boolean
function Battle:canSelectMenuItem(menu_item)
    if menu_item.unusable then
        return false
    end
    if menu_item.tp and (menu_item.tp > Game:getTension()) then
        return false
    end
    if menu_item.party then
        for _,party_id in ipairs(menu_item.party) do
            local party_index = self:getPartyIndex(party_id)
            local battler = self.party[party_index]
            local action = self.character_actions[party_index]
            if (not battler) or (not battler:isActive()) or (action and action.cancellable == false) then
                -- They're either down, asleep, or don't exist. Either way, they're not here to do the action.
                return false
            end
        end
    end
    return true
end

---@param battler Battler
---@return boolean
function Battle:isHighlighted(battler)
    if self.state == "PARTYSELECT" then
        return self.party[self.current_menu_y] == battler
    elseif self.state == "ENEMYSELECT" or self.state == "XACTENEMYSELECT" then
        return self.enemies_index[self.current_menu_y] == battler
    elseif self.state == "MENUSELECT" then
        local current_menu = self.menu_items[self:getItemIndex()]
        if current_menu and current_menu.highlight then
            local highlighted = current_menu.highlight
            if isClass(highlighted) then
                return highlighted == battler
            elseif type(highlighted) == "table" then
                return Utils.containsValue(highlighted, battler)
            end
        end
    end
    return false
end

--- Removes an enemy from the battle
---@param enemy     EnemyBattler    The `EnemyBattler` that should be removed
---@param defeated? boolean         If `true`, the enemy is considered as 'defeated'
function Battle:removeEnemy(enemy, defeated)
    table.insert(self.enemies_to_remove, enemy)
    if defeated then
        table.insert(self.defeated_enemies, enemy)
    end
end

--- Gets a list of all the active (not defeated/spared) enemies
---@return EnemyBattler[]
function Battle:getActiveEnemies()
    return Utils.filter(self.enemies, function(enemy) return not enemy.done_state end)
end

--- Gets a list of all the active (not downed) party members
---@return PartyBattler[]
function Battle:getActiveParty()
    return Utils.filter(self.party, function(party) return not party.is_down end)
end

--- Resets the enemies index table, closing all gaps in the enemy select menu
---@param reset_xact? boolean         Whether to also reset the XACT position
function Battle:resetEnemiesIndex(reset_xact)
    self.enemies_index = Utils.copy(self.enemies, true)
    if reset_xact ~= false then
        self.battle_ui:resetXACTPosition()
    end
end

---@param id string
---@return EnemyBattler
function Battle:parseEnemyIdentifier(id)
    local args = Utils.split(id, ":")
    local enemies = Utils.filter(self.enemies, function(enemy) return enemy.id == args[1] end)
    return enemies[args[2] and tonumber(args[2]) or 1]
end

function Battle:getItemIndex()
    return 2 * (self.current_menu_y - 1) + self.current_menu_x
end

function Battle:isValidMenuLocation()
    if self:getItemIndex() > #self.menu_items then
        return false
    end
    if (self.current_menu_x > 2) or self.current_menu_x < 1 then
        return false
    end
    return true
end

--- Advances all enemy dialogue bubbles
function Battle:advanceBoxes()
    local all_done = true
    local to_remove = {}
    -- Check if any dialogue is typing
    for _,dialogue in ipairs(self.enemy_dialogue) do
        if dialogue:isTyping() then
            all_done = false
            break
        end
    end
    -- Nothing is typing, try to advance
    if all_done then
        self.textbox_timer = 3 * 30
        self.use_textbox_timer = true
        for _,dialogue in ipairs(self.enemy_dialogue) do
            dialogue:advance()
            if not dialogue:isDone() then
                all_done = false
            else
                table.insert(to_remove, dialogue)
            end
        end
    end
    -- Remove leftover dialogue
    for _,dialogue in ipairs(to_remove) do
        Utils.removeFromTable(self.enemy_dialogue, dialogue)
    end
    -- If all dialogue is done, go to DIALOGUEEND state
    if all_done then
        self:setState("DIALOGUEEND")
    end
end

---@param item              table
---@param default_ally?     PartyBattler
---@param default_enemy?    EnemyBattler
---@return PartyBattler[]|EnemyBattler[]|nil
function Battle:getTargetForItem(item, default_ally, default_enemy)
    if not item.target or item.target == "none" then
        return nil
    elseif item.target == "ally" then
        return default_ally or self.party[1]
    elseif item.target == "enemy" then
        return default_enemy or self:getActiveEnemies()[1]
    elseif item.target == "party" then
        return self.party
    elseif item.target == "enemies" then
        return self:getActiveEnemies()
    end
end

function Battle:clearMenuItems()
    self.menu_items = {}
end

---@param tbl table
---@return table
function Battle:addMenuItem(tbl)
    -- Item colors in Ch3+ can be dynamic (e.g. pacify) so we should use functions for item color.
    -- Table colors can still be used, but we'll wrap them into functions.
    local color = tbl.color or {1, 1, 1, 1}
    local fcolor
    if type(color) == "table" then
        fcolor = function () return color end
    else
        fcolor = color
    end
    tbl = {
        ["name"] = tbl.name or "",
        ["tp"] = tbl.tp or 0,
        ["unusable"] = tbl.unusable or false,
        ["description"] = tbl.description or "",
        ["party"] = tbl.party or {},
        ["color"] = fcolor,
        ["data"] = tbl.data or nil,
        ["callback"] = tbl.callback or function() end,
        ["highlight"] = tbl.highlight or nil,
        ["icons"] = tbl.icons or nil
    }
    table.insert(self.menu_items, tbl)
    return tbl
end

---@param key string
function Battle:onKeyPressed(key)
    if Kristal.Config["debug"] and Input.ctrl() then
        if key == "h" then
            for _,party in ipairs(self.party) do
                party:heal(math.huge)
            end
        end
        if key == "y" then
            Input.clear(nil, true)
            self:setState("VICTORY")
        end
        if key == "m" then
            if self.music then
                if self.music:isPlaying() then
                    self.music:pause()
                else
                    self.music:resume()
                end
            end
        end
        if self.state == "DEFENDING" and key == "f" then
            self.encounter:onWavesDone()
        end
        if self.soul and self.soul.visible and key == "j" then
            local x, y = self:getSoulLocation()
            self.soul:shatter(6)

            -- Prevents a crash related to not having a soul in some waves
            self:spawnSoul(x, y)
            for _,heartbrust in ipairs(Game.stage:getObjects(HeartBurst)) do
                heartbrust:remove()
            end
            self.soul.visible = false
            self.soul.collidable = false
        end
        if key == "b" then
            self:hurt(math.huge, true, "ALL")
        end
        if key == "k" then
            Game:setTension(Game:getMaxTension() * 2, true)
        end
        if key == "n" then
            NOCLIP = not NOCLIP
        end
    end

    if self.state == "MENUSELECT" then
        local menu_width = 2
        local menu_height = math.ceil(#self.menu_items / 2)

        if Input.isConfirm(key) then
            local menu_item = self.menu_items[self:getItemIndex()]
            local can_select = self:canSelectMenuItem(menu_item)
            if self.encounter:onMenuSelect(self.state_reason, menu_item, can_select) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleMenuSelect, self.state_reason, menu_item, can_select) then return end
            if can_select then
                self.ui_select:stop()
                self.ui_select:play()
                menu_item["callback"](menu_item)
                return
            end
        elseif Input.isCancel(key) then
            local menu_item = self.menu_items[self:getItemIndex()]
            local can_select = self:canSelectMenuItem(menu_item)
            if self.encounter:onMenuCancel(self.state_reason, menu_item) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleMenuCancel, self.state_reason, menu_item, can_select) then return end
            self.ui_move:stop()
            self.ui_move:play()
            Game:setTensionPreview(0)
            self:setState("ACTIONSELECT", "CANCEL")
            return
        elseif Input.is("left", key) then -- TODO: pagination
            self.current_menu_x = self.current_menu_x - 1
            if self.current_menu_x < 1 then
                self.current_menu_x = menu_width
                if not self:isValidMenuLocation() then
                    self.current_menu_x = 1
                end
            end
        elseif Input.is("right", key) then
            self.current_menu_x = self.current_menu_x + 1
            if not self:isValidMenuLocation() then
                self.current_menu_x = 1
            end
        end
        if Input.is("up", key) then
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = 1 -- No wrapping in this menu.
            end
        elseif Input.is("down", key) then
            if self:getItemIndex() % 6 == 0 and #self.menu_items % 6 == 1 and self.current_menu_y == menu_height - 1 then
                self.current_menu_x = self.current_menu_x - 1
            end
            self.current_menu_y = self.current_menu_y + 1
            if (self.current_menu_y > menu_height) or (not self:isValidMenuLocation()) then
                self.current_menu_y = menu_height -- No wrapping in this menu.
                if not self:isValidMenuLocation() then
                    self.current_menu_y = menu_height - 1
                end
            end
        end
    elseif self.state == "ENEMYSELECT" or self.state == "XACTENEMYSELECT" then
        if Input.isConfirm(key) then
            if self.encounter:onEnemySelect(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemySelect, self.state_reason, self.current_menu_y) then return end
            self.ui_select:stop()
            self.ui_select:play()
            if #self.enemies_index == 0 then return end
            self.selected_enemy = self.current_menu_y
            if self.state == "XACTENEMYSELECT" then
                local xaction = Utils.copy(self.selected_xaction)
                if xaction.default then
                    xaction.name = self.enemies_index[self.selected_enemy]:getXAction(self.party[self.current_selecting])
                end
                self:pushAction("XACT", self.enemies_index[self.selected_enemy], xaction)
            elseif self.state_reason == "SPARE" then
                self:pushAction("SPARE", self.enemies_index[self.selected_enemy])
            elseif self.state_reason == "ACT" then
                self:clearMenuItems()
                local enemy = self.enemies_index[self.selected_enemy]
                for _,v in ipairs(enemy.acts) do
                    local insert = not v.hidden
                    if v.character and self.party[self.current_selecting].chara.id ~= v.character then
                        insert = false
                    end
                    if v.party and (#v.party > 0) then
                        for _,party_id in ipairs(v.party) do
                            if not self:getPartyIndex(party_id) then
                                insert = false
                                break
                            end
                        end
                    end
                    if insert then
                        self:addMenuItem({
                            ["name"] = v.name,
                            ["tp"] = v.tp or 0,
                            ["description"] = v.description,
                            ["party"] = v.party,
                            ["color"] = v.color or {1, 1, 1, 1},
                            ["highlight"] = v.highlight or enemy,
                            ["icons"] = v.icons,
                            ["callback"] = function(menu_item)
                                self:pushAction("ACT", enemy, menu_item)
                            end
                        })
                    end
                end
                self:setState("MENUSELECT", "ACT")
            elseif self.state_reason == "ATTACK" then
                self:pushAction("ATTACK", self.enemies_index[self.selected_enemy])
            elseif self.state_reason == "SPELL" then
                self:pushAction("SPELL", self.enemies_index[self.selected_enemy], self.selected_spell)
            elseif self.state_reason == "ITEM" then
                self:pushAction("ITEM", self.enemies_index[self.selected_enemy], self.selected_item)
            else
                self:nextParty()
            end
            return
        end
        if Input.isCancel(key) then
            if self.encounter:onEnemyCancel(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemyCancel, self.state_reason, self.current_menu_y) then return end
            self.ui_move:stop()
            self.ui_move:play()
            if self.state_reason == "SPELL" then
                self:setState("MENUSELECT", "SPELL")
            elseif self.state_reason == "ITEM" then
                self:setState("MENUSELECT", "ITEM")
            else
                self:setState("ACTIONSELECT", "CANCEL")
            end
            return
        end
        if Input.is("up", key) then
            if #self.enemies_index == 0 then return end
            local old_location = self.current_menu_y
            local give_up = 0
            repeat
                give_up = give_up + 1
                if give_up > 100 then return end
                -- Keep decrementing until there's a selectable enemy.
                self.current_menu_y = self.current_menu_y - 1
                if self.current_menu_y < 1 then
                    self.current_menu_y = #self.enemies_index
                end
            until (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable)

            if self.current_menu_y ~= old_location then
                self.ui_move:stop()
                self.ui_move:play()
            end
        elseif Input.is("down", key) then
            if #self.enemies_index == 0 then return end
            local old_location = self.current_menu_y
            local give_up = 0
            repeat
                give_up = give_up + 1
                if give_up > 100 then return end
                -- Keep decrementing until there's a selectable enemy.
                self.current_menu_y = self.current_menu_y + 1
                if self.current_menu_y > #self.enemies_index then
                    self.current_menu_y = 1
                end
            until (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable)

            if self.current_menu_y ~= old_location then
                self.ui_move:stop()
                self.ui_move:play()
            end
        end
    elseif self.state == "PARTYSELECT" then
        if Input.isConfirm(key) then
            if self.encounter:onPartySelect(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattlePartySelect, self.state_reason, self.current_menu_y) then return end
            self.ui_select:stop()
            self.ui_select:play()
            if self.state_reason == "SPELL" then
                self:pushAction("SPELL", self.party[self.current_menu_y], self.selected_spell)
            elseif self.state_reason == "ITEM" then
                self:pushAction("ITEM", self.party[self.current_menu_y], self.selected_item)
            else
                self:nextParty()
            end
            return
        end
        if Input.isCancel(key) then
            if self.encounter:onPartyCancel(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattlePartyCancel, self.state_reason, self.current_menu_y) then return end
            self.ui_move:stop()
            self.ui_move:play()
            if self.state_reason == "SPELL" then
                self:setState("MENUSELECT", "SPELL")
            elseif self.state_reason == "ITEM" then
                self:setState("MENUSELECT", "ITEM")
            else
                self:setState("ACTIONSELECT", "CANCEL")
            end
            return
        end
        if Input.is("up", key) then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = #self.party
            end
        elseif Input.is("down", key) then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y + 1
            if self.current_menu_y > #self.party then
                self.current_menu_y = 1
            end
        end
    elseif self.state == "BATTLETEXT" then
        -- Nothing here
    elseif self.state == "SHORTACTTEXT" then
        -- Nothing here
    elseif self.state == "ENEMYDIALOGUE" then
        -- Nothing here
    elseif self.state == "ACTIONSELECT" then
        self:handleActionSelectInput(key)
    elseif self.state == "ATTACKING" then
        self:handleAttackingInput(key)
    end
end

--- Checks if the current encounter has reduced tension.
--- By default, this redirects to Encounter
--- @return boolean reduced Whether the encounter has reduced tension.
function Battle:hasReducedTension()
    return self.encounter:hasReducedTension()
end

--- Returns the tension gained from defending.
--- By default, this redirects to Encounter.
---@param battler PartyBattler The current battler about to defend.
---@return number tension The tension gained from defending.
function Battle:getDefendTension(battler)
    return self.encounter:getDefendTension(battler)
end

---@param key string
function Battle:handleActionSelectInput(key)
    local actbox = self.battle_ui.action_boxes[self.current_selecting]
    local old_selected_button = actbox.selected_button

    if Input.isConfirm(key) then
        actbox:select()
        self.ui_select:stop()
        self.ui_select:play()
        return
    elseif Input.isCancel(key) then
        local old_selecting = self.current_selecting

        self:previousParty()

        if self.current_selecting ~= old_selecting then
            self.ui_move:stop()
            self.ui_move:play()
            self.battle_ui.action_boxes[self.current_selecting]:unselect()
        end
        return
    elseif Input.is("left", key) then
        actbox.selected_button = actbox.selected_button - 1
    elseif Input.is("right", key) then
        actbox.selected_button = actbox.selected_button + 1
    end

    if actbox.selected_button < 1 then
        actbox.selected_button = #actbox.buttons
    end

    if actbox.selected_button > #actbox.buttons then
        actbox.selected_button = 1
    end
    
    if old_selected_button ~= actbox.selected_button then
        self.ui_move:stop()
        self.ui_move:play()
    end
end

---@param key string
function Battle:handleAttackingInput(key)
    if Input.isConfirm(key) then
        if not self.attack_done and not self.cancel_attack and #self.battle_ui.attack_boxes > 0 then
            local closest
            local closest_attacks = {}

            for _,attack in ipairs(self.battle_ui.attack_boxes) do
                if not attack.attacked then
                    local close = attack:getClose()
                    if not closest then
                        closest = close
                        table.insert(closest_attacks, attack)
                    elseif close == closest then
                        table.insert(closest_attacks, attack)
                    elseif close < closest then
                        closest = close
                        closest_attacks = {attack}
                    end
                end
            end

            if closest and closest < 14.2 and closest > -2 then
                for _,attack in ipairs(closest_attacks) do
                    local points = attack:hit()

                    local action = self:getActionBy(attack.battler, true)
                    action.points = points

                    if self:processAction(action) then
                        self:finishAction(action)
                    end
                end
            end
        end
    end
end

--- Returns the equipment-modified heal amount from a healing action performed by the specified party member
---@param base_heal number      The heal amount to modify
---@param healer PartyMember    The character performing the heal action
function Battle:applyHealBonuses(base_heal, healer)
    local current_heal = base_heal
    for _,battler in ipairs(self.party) do
        for _,item in ipairs(battler.chara:getEquipment()) do
            current_heal = item:applyHealBonus(current_heal, base_heal, healer)
        end
    end
    return current_heal
end

function Battle:canDeepCopy()
    return false
end

return Battle
