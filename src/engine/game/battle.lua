local Battle, super = Class(Object)

function Battle:init()
    super:init(self)

    self.party = {}

    self.max_tension = 250
    self.tension = 0

    self.gold = 0
    self.xp = 0

    self.used_violence = false

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.spare_sound = Assets.newSound("snd_spare")

    self.party_beginning_positions = {} -- Only used in TRANSITION, but whatever
    self.enemy_beginning_positions = {}

    self.party_world_characters = {}

    for i = 1, math.min(3, #Game.party) do
        local party_member = Game.party[i]

        if Game.world.player and Game.world.player.visible and Game.world.player.actor.id == party_member.actor then
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
                if follower.visible and follower.actor.id == party_member.id then
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
                chara_battler:setAnimation("transition")
                self:addChild(chara_battler)
                table.insert(self.party, chara_battler)
                table.insert(self.party_beginning_positions, {chara_battler.x, chara_battler.y})
            end
        end
    end

    self.intro_timer = 0
    self.offset = 0

    self.transitioned = false
    self.started = false

    -- states: BATTLETEXT, TRANSITION, INTRO, ACTIONSELECT, ACTING, SPARING, USINGITEMS, ATTACKING, ACTIONSDONE, ENEMYDIALOGUE, DIALOGUEEND, DEFENDING, VICTORY, TRANSITIONOUT
    -- ENEMYSELECT, MENUSELECT, XACTENEMYSELECT, PARTYSELECT, DEFENDINGEND

    self.state = "NONE"
    self.substate = "NONE"

    self.camera = Camera(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.cutscene = nil

    self.current_selecting = 1

    self.turn_count = 0

    self.battle_ui = nil
    self.tension_bar = nil

    self.arena = nil
    self.soul = nil

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
    self.attack_done = false
    self.cancel_attack = false

    self.post_battletext_func = nil
    self.post_battletext_state = "ACTIONSELECT"

    self.battletext_table = nil
    self.battletext_index = 1

    self.current_menu_x = 1
    self.current_menu_y = 1

    self.enemies = {}
    self.enemy_dialogue = {}
    self.enemies_to_remove = {}
    self.defeated_enemies = {}

    self.waves = {}

    self.state_reason = nil
    self.substate_reason = nil

    self.menu_items = {}

    self.selected_enemy = 1
    self.selected_spell = nil
    self.selected_xaction = nil
    self.selected_item = nil

    self.spell_delay = 0
    self.spell_finished = false

    self.actions_done_timer = 0

    self.xactions = {}

    self.has_acted = false

    self.shake = 0

    self.background_fade_alpha = 0

    self.wave_length = 0
    self.wave_timer = 0
end

function Battle:postInit(state, encounter)
    self.state = state

    if type(encounter) == "string" then
        self.encounter = Registry.createEncounter(encounter)
    else
        self.encounter = encounter
    end

    if self.encounter.music then
        self.music = Music()
        Game.world.music:pause()
    elseif Game.world.music then
        self.music = Game.world.music
    else
        self.music = Music()
    end

    if self.encounter.queued_enemy_spawns then
        for _,enemy in ipairs(self.encounter.queued_enemy_spawns) do
            if state == "TRANSITION" then
                enemy.target_x = enemy.x
                enemy.target_y = enemy.y
                enemy.x = SCREEN_WIDTH + 200
            end
            table.insert(self.enemies, enemy)
            self:addChild(enemy)
        end
    end

    if state == "TRANSITION" then
        self.transitioned = true
        self.transition_timer = 0
        self.afterimage_count = 0
        self.battler_targets = {}
        for index, battler in ipairs(self.party) do
            local target_x, target_y
            if #self.party == 1 then
                target_x = 80
                target_y = 140
            elseif #self.party == 2 then
                target_x = 80
                target_y = 100 + (80 * (index - 1))
            elseif #self.party == 3 then
                target_x = 80
                target_y = 50 + (80 * (index - 1))
            end

            local offset = battler.chara.battle_offset or {0, 0}
            target_x = target_x + (battler.actor.width/2 + offset[1]) * 2
            target_y = target_y + (battler.actor.height  + offset[2]) * 2
            table.insert(self.battler_targets, {target_x, target_y})
        end
        if Game.encounter_enemy then
            for _,enemy in ipairs(self.enemies) do
                if enemy.actor and enemy.actor.id == Game.encounter_enemy.actor.id then
                    Game.encounter_enemy.visible = false
                    enemy:setPosition(Game.encounter_enemy:getScreenPos())
                    break
                end
            end
        end
        for _,enemy in ipairs(self.enemies) do
            self.enemy_beginning_positions[enemy] = {enemy.x, enemy.y}
        end
    else
        self.transition_timer = 10
        for index, battler in ipairs(self.party) do
            if #self.party == 1 then
                battler.x = 80
                battler.y = 140
            elseif #self.party == 2 then
                battler.x = 80
                battler.y = 100 + (80 * (index - 1))
            elseif #self.party == 3 then
                battler.x = 80
                battler.y = 50 + (80 * (index - 1))
            end

            local offset = battler.chara.battle_offset or {0, 0}
            battler.x = battler.x + (battler.actor.width/2 + offset[1]) * 2
            battler.y = battler.y + (battler.actor.height  + offset[2]) * 2
        end

        if state ~= "INTRO" then
            self:nextTurn()
        end
    end

    self:setState(state)
end

function Battle:onRemove(parent)
    super:onRemove(self, parent)

    self.music:remove()
end

function Battle:setState(state, reason)
    local old = self.state
    self.state = state
    self.state_reason = reason
    self:onStateChange(old, self.state)
end

function Battle:setSubState(state, reason)
    local old = self.substate
    self.substate = state
    self.substate_reason = reason
    self:onSubStateChange(old, self.substate)
end

function Battle:getState()
    return self.state
end

function Battle:onStateChange(old,new)
    if self.encounter.beforeStateChange then
        local result = self.encounter:beforeStateChange(old,new)
        if result or self.state ~= new then
            return
        end
    end
    if new == "INTRO" then
        Assets.playSound("snd_impact", 0.7)
        Assets.playSound("snd_weaponpull_fast", 0.8)

        for _,battler in ipairs(self.party) do
            battler:setAnimation("battle/intro")
        end

        self.encounter:onBattleStart()
    elseif new == "ACTIONSELECT" then
        if self.state_reason == "CANCEL" then
            self.battle_ui.encounter_text:setText("[instant]" .. self.battle_ui.current_encounter_text)
        end

        if not self.started then
            self.started = true

            for _,battler in ipairs(self.party) do
                battler:setAnimation("battle/idle")
            end

            if self.encounter.music then
                self.music:play(self.encounter.music)
            end
        end

        if not self.battle_ui then
            self.battle_ui = BattleUI()
            self:addChild(self.battle_ui)
        end
        if not self.tension_bar then
            self.tension_bar = TensionBar(-25, 40)
            self:addChild(self.tension_bar)
        end
    elseif new == "ACTIONS" then
        self.battle_ui.encounter_text:setText("")
        if self.state_reason ~= "DONTPROCESS" then
            self:tryProcessNextAction()
        end
    elseif new == "ENEMYSELECT" or new == "XACTENEMYSELECT" then
        self.battle_ui.encounter_text:setText("")
        self.current_menu_y = 1
        self.selected_enemy = 1
    elseif new == "PARTYSELECT" then
        self.battle_ui.encounter_text:setText("")
        self.current_menu_y = 1
    elseif new == "MENUSELECT" then
        self.battle_ui.encounter_text:setText("")
        self.current_menu_x = 1
        self.current_menu_y = 1
    elseif new == "ATTACKING" then
        self.battle_ui.encounter_text:setText("")

        for i,battler in ipairs(self.party) do
            local action = self.character_actions[i]
            if action and action.action == "ATTACK" then
                self:beginAction(action)
                table.insert(self.attackers, battler)
            end
        end

        if #self.attackers == 0 then
            self.attack_done = true
            self:setState("ACTIONSDONE")
        else
            self.attack_done = false
        end
    elseif new == "ENEMYDIALOGUE" then
        self.battle_ui.encounter_text:setText("")
        local all_done = true
        for _,enemy in ipairs(self.enemies) do
            if not enemy.done_state then
                all_done = false
                local dialogue = enemy:getEnemyDialogue()
                if dialogue then
                    local textbox = self:spawnEnemyTextbox(enemy, dialogue)
                    table.insert(self.enemy_dialogue, textbox)
                end
            end
        end
        if all_done then
            self:setState("VICTORY")
        end
    elseif new == "DIALOGUEEND" then
        self.battle_ui.encounter_text:setText("")

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
        end
    elseif new == "VICTORY" then
        self.tension_bar.animating_in = false
        self.tension_bar.physics.speed_x = -10
        self.tension_bar.physics.friction = -0.4
        for _,battler in ipairs(self.party) do
            battler:setAnimation("battle/victory")

            local box = self.battle_ui.action_boxes[self:getPartyIndex(battler.chara.id)]
            box.head_sprite:setSprite(battler.chara.head_icons.."/head")
        end

        self.gold = self.gold + (math.floor((self.tension / 10)) * Game.chapter)



        -- NOTES:
        -- The Trefoil (unused sword) does the calculation below:
        --     self.gold = self.gold + math.floor(self.gold / 20)

        -- the Silver Card gives you 5% more gold.
        -- the Dealmaker gives you 30% more gold.

        for _,battler in ipairs(self.party) do
            for _,equipment in ipairs(battler.chara:getEquipment()) do
                self.gold = (equipment:applyGoldBonus(self.gold) or self.gold)
            end
        end

        self.gold = math.floor(self.gold)

        -- if (in_dojo) then
        --     self.gold = 0
        -- end

        Game.gold = Game.gold + self.gold
        Game.xp = Game.xp + self.xp

        if (Game.gold < 0) then
            Game.gold = 0
        end

        local win_text = "* You won!\n* Got " .. self.xp .. " EXP and " .. self.gold .. " D$."
        -- if (in_dojo) then
        --     win_text == "* You won the battle!"
        -- end
        if Game.chapter >= 2 and self.used_violence then
            local stronger = "You"

            for _,battler in ipairs(self.party) do
                battler.chara.level = battler.chara.level + 1
                battler.chara:onLevelUp(battler.chara.level)

                if battler.chara.id == "noelle" then
                    -- Hardcoded for now ,??
                    stronger = battler.chara.name
                end
            end

            win_text = "* You won!\n* Got " .. self.gold .. " D$.\n* "..stronger.." became stronger."

            Assets.playSound("snd_dtrans_lw", 0.7, 2)
            --scr_levelup()
        end

        if self.encounter.no_end_message then
            self:setState("TRANSITIONOUT")
            self.encounter:onBattleEnd()
        else
            self:battleText(win_text, function()
                self:setState("TRANSITIONOUT")
                self.encounter:onBattleEnd()
            end)
        end
    elseif new == "TRANSITIONOUT" then
        self.battle_ui:transitionOut()
        if self.music ~= Game.world.music then
            self.music:fade(0, 0.05)
        end
        if Game.encounter_enemy then
            local target = Game.encounter_enemy
            for _,enemy in ipairs(self.defeated_enemies) do
                if enemy.done_state == "FROZEN" then
                    local statue = FrozenEnemy(enemy.actor, target.x, target.y, {facing = target.sprite.facing})
                    statue.layer = target.layer
                    Game.world:addChild(statue)
                    break
                end
            end
        end
    end
    if self.encounter.onStateChange then
        self.encounter:onStateChange(old,new)
    end
end

function Battle:getSoulLocation(always_player)
    if self.soul and (not always_player) then
        return self.soul:getPosition()
    else
        local battler = self.party[self:getPartyIndex("kris")] -- TODO: don't hardcode kris, they just need a soul

        if not battler then
            return -9, -9
        else
            return battler:localToScreenPos((battler.sprite.width/2) - 4.5, battler.sprite.height/2)
        end
    end
end

function Battle:spawnSoul(x, y)
    local bx, by = self:getSoulLocation()
    self:addChild(HeartBurst(bx, by))
    if not self.soul then
        self.soul = self.encounter:createSoul(bx, by)
        self.soul:transitionTo(x or SCREEN_WIDTH/2, y or SCREEN_HEIGHT/2)
        self.soul.target_alpha = self.soul.alpha
        self.soul.alpha = 0
        self:addChild(self.soul)
    end
end

function Battle:returnSoul()
    local bx, by = self:getSoulLocation(true)

    if self.soul then
        self.soul:transitionTo(bx, by, true)
    end
end

function Battle:swapSoul(object)
    if self.soul then
        self.soul:remove()
    end
    object:setPosition(self.soul:getPosition())
    object.layer = self.soul.layer
    self.soul = object
    self:addChild(object)
end

function Battle:onSubStateChange(old,new)
    if (old == "ACT") and (new ~= "ACT") then
        for _,battler in ipairs(self.party) do
            if battler.sprite.anim == "battle/act" then
                battler:setAnimation("battle/act_end")
            end
        end
    end
end

function Battle:registerXAction(party, name, description, tp)
    local act = {
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["color"] = self.party[self:getPartyIndex(party)].chara.xact_color,
        ["tp"] = tp or 0,
        ["short"] = false
    }

    table.insert(self.xactions, act)
end

function Battle:fetchEncounterText()
    return self.encounter:fetchEncounterText()
end

function Battle:processCharacterActions()
    if self.state ~= "ACTIONS" then
        self:setState("ACTIONS", "DONTPROCESS")
    end

    self.current_action_index = 1

    local order = {"ACT", "XACT", {"SPELL", "ITEM", "SPARE"}, "SKIP"}
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

    if action.action == "ACT" then
        -- Play the ACT animation by default
        battler:setAnimation("battle/act")
        -- Enemies might change the ACT animation, so run onActStart here
        enemy:onActStart(battler, action.name)
    else
        -- TODO: Proper beginAction hook for mods
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

    if enemy and enemy.done_state then
        enemy = self:retargetEnemy()
        action.target = enemy
        if not enemy then
            return true
        end
    end

    if action.action == "SPARE" then
        local worked = enemy.mercy >= 100
        local text
        if worked then
            text = "* " .. party_member.name .. " spared " .. enemy.name .. "!"
        else
            text = "* " .. party_member.name .. " spared " .. enemy.name .. "!\n* But its name wasn't [color:yellow]YELLOW[color:reset]..."
            if enemy.tired then
                local found_spell = nil
                for _,party in ipairs(self.party) do
                    for _,spell_id in ipairs(party.chara.spells) do
                        local spell = Registry.getSpell(spell_id)
                        if spell.pacify then
                            found_spell = spell
                            break
                        end
                    end
                    if found_spell then
                        text = {text, "* (Try using "..party.chara.name.."'s [color:blue]"..found_spell.name:upper().."[color:reset]!)"}
                        break
                    end
                end
                if not found_spell then
                    text = {text, "* (Try using [color:blue]ACTs[color:reset]!)"}
                end
            end
        end
        battler:setAnimation("battle/spare", function()
            enemy:onMercy()
            if not worked then
                self.timer:during(8/30, function()
                    enemy.sprite.color = Utils.lerp(enemy.sprite.color, {1, 1, 0}, 0.12 * DTMULT)
                end, function()
                    self.timer:during(8/30, function()
                        enemy.sprite.color = Utils.lerp(enemy.sprite.color, {1, 1, 1}, 0.16 * DTMULT)
                    end, function()
                        enemy.sprite.color = {1, 1, 1}
                    end)
                end)
            end
            self:finishAction(action)
        end)
        self:battleText(text)
    elseif action.action == "ATTACK" then
        local src = Assets.stopAndPlaySound(battler.chara.attack_sound or "snd_laz_c")
        src:setPitch(battler.chara.attack_pitch or 1)

        self.actions_done_timer = 1.2

        local crit = action.points == 150
        if crit then
            Assets.stopAndPlaySound("snd_criticalswing")

            for i = 1, 3 do
                local sx, sy = battler:getRelativePos(battler.width, 0)
                local sparkle = Sprite("effects/criticalswing/sparkle", sx + Utils.random(50), sy + 30 + Utils.random(30))
                sparkle:play(4/30, true)
                sparkle:setScale(2)
                sparkle.layer = LAYERS["above_battlers"]
                sparkle.physics.speed_x = Utils.random(2, 6)
                sparkle.physics.friction = -0.25
                sparkle:fadeOutAndRemove()
                self:addChild(sparkle)
            end
        end

        battler:setAnimation("battle/attack", function()
            local box = self.battle_ui.action_boxes[self:getPartyIndex(battler.chara.id)]
            box.head_sprite:setSprite(battler.chara.head_icons.."/head")

            if action.target and action.target.done_state then
                enemy = self:retargetEnemy()
                action.target = enemy
                if not enemy then
                    self.cancel_attack = true
                    self:finishAction(action)
                    return
                end
            end

            local damage = 0
            if action.points > 0 then
                damage = Utils.round(((battler.chara:getStat("attack") * action.points) / 20) - (action.target.defense * 3))
            end
            if damage < 0 then
                damage = 0
            end

            if damage > 0 then
                -- TODO: JEVIL does (action.points / 15), so make this configurable in some way
                self.tension_bar:giveTensionExact(Utils.round((action.points / 10)))

                local dmg_sprite = Sprite(battler.chara.attack_sprite or "effects/attack/cut")
                dmg_sprite:setOrigin(0.5, 0.5)
                if crit then
                    dmg_sprite:setScale(2.5, 2.5)
                else
                    dmg_sprite:setScale(2, 2)
                end
                dmg_sprite:setPosition(enemy:getRelativePos(enemy.width/2, enemy.height/2))
                dmg_sprite.layer = enemy.layer + 0.01
                dmg_sprite:play(1/15, false, function(s) s:remove() end)
                enemy.parent:addChild(dmg_sprite)

                Assets.stopAndPlaySound("snd_damage")
                enemy:hurt(damage, battler)

                battler.chara:onAttackHit(enemy, damage)
            else
                enemy:statusMessage("msg", "miss", battler.chara.dmg_color or battler.chara.color)
            end

            self:finishAction(action)

            if not self:retargetEnemy() then
                self.cancel_attack = true
            end
        end)
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
    elseif action.action == "SKIP" then
        return true
    elseif action.action == "SPELL" then
        self.battle_ui.encounter_text:setText("")

        -- The spell itself handles the animation and finishing
        action.data:onStart(battler, action.target)
    elseif action.action == "ITEM" then
        local item = action.data.item
        local index = action.data.index
        if item.instant then
            self:finishAction(action)
        else
            self:battleText(item:getBattleText(battler, action.target))
            battler:setAnimation("battle/item", function()
                local result = item:onBattleUse(battler, action.target)
                if result or result == nil then
                    self:finishAction(action)
                end
            end)
        end
    elseif action.action == "DEFEND" then
        battler:setAnimation("battle/defend")
        battler.defending = true
    else
        -- we don't know how to handle this...
        return true
    end
end

function Battle:getCurrentAction()
    return self.current_actions[self.current_action_index]
end

function Battle:getActionBy(battler)
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

function Battle:allActionsDone()
    for _,action in ipairs(self.current_actions) do
        if not self.processed_action[action] then
            return false
        end
    end
    return true
end

function Battle:finishAction(action)
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

                        self:endActionAnimation(jbattler, iaction, callback)
                    end
                end
            end

            self:endActionAnimation(ibattler, iaction, callback)

            -- TODO: Mod hooks !!!
            if iaction.action == "DEFEND" then
                ibattler.defending = false
            end
        end
    else
        -- Process actions if we can
        self:tryProcessNextAction()
    end
end

function Battle:endActionAnimation(battler, action, callback)
    local _callback = callback
    callback = function()
        -- Reset the head sprite
        local box = self.battle_ui.action_boxes[self:getPartyIndex(battler.chara.id)]
        box.head_sprite:setSprite(battler.chara.head_icons.."/head")
        if _callback then
            _callback()
        end
    end
    if action.action ~= "ATTACK" then
        if battler.sprite.anim == "battle/"..action.action:lower() then
            -- Attempt to play the end animation if the sprite hasn't changed
            if not battler:setAnimation("battle/"..action.action:lower().."_end", callback) then
                battler:setAnimation("battle/idle")
            end
        else
            -- Otherwise, play idle animation
            battler:setAnimation("battle/idle")
            if callback then
                callback()
            end
        end
    else
        callback()
    end
end

function Battle:commitAction(type, target, data, character_id)
    data = data or {}

    character_id = character_id or self.current_selecting

    local is_xact = type:upper() == "XACT"
    if is_xact then
        type = "ACT"
    end

    local tp_bar = self.tension_bar
    local tp_diff = 0
    if data.tp then
        tp_diff = Utils.clamp(-data.tp, -tp_bar:getTension(), tp_bar:getMaxTension() - tp_bar:getTension())
    end

    self:commitSingleAction({
        ["character_id"] = character_id,
        ["action"] = type:upper(),
        ["party"] = data.party,
        ["name"] = data.name,
        ["target"] = target,
        ["data"] = data.data,
        ["tp"] = tp_diff
    })

    if data.party then
        for _,v in ipairs(data.party) do
            local index = self:getPartyIndex(v)

            if index ~= character_id then
                local action = self.character_actions[index]
                if action then
                    if action.act_parent then
                        self:removeAction(action.act_parent)
                    else
                        self:removeAction(index)
                    end
                end

                self:commitSingleAction({
                    ["character_id"] = index,
                    ["action"] = "SKIP",
                    ["reason"] = type:upper(),
                    ["name"] = data.name,
                    ["target"] = target,
                    ["data"] = data.data,
                    ["act_parent"] = character_id
                })
            end
        end
    end

    self:nextParty()
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

    local anim = action.action:lower()
    if action.action == "SKIP" then
        anim = action.reason:lower()
    end

    if (action.action == "ITEM" and action.data and action.data.item and (not action.data.item.instant)) or (action.action ~= "ITEM") then
        battler:setAnimation("battle/"..anim.."_ready")
        local box = self.battle_ui.action_boxes[action.character_id]
        box.head_sprite:setSprite(box.battler.chara.head_icons.."/"..anim)
    end

    if action.tp then
        if action.tp > 0 then
            self.tension_bar:giveTension(action.tp)
        elseif action.tp < 0 then
            self.tension_bar:removeTension(-action.tp)
        end
    end

    if action.action == "ITEM" and action.data and action.data.index and action.data.item then
        if action.data.item.result_item then
            Game.inventory:replaceItem("item", action.data.item.result_item, action.data.index)
        else
            Game.inventory:removeItem("item", action.data.index)
        end
        action.data.item:onBattleSelect(battler, action.target)
    end

    self.character_actions[action.character_id] = action
end

function Battle:removeSingleAction(action)
    local battler = self.party[action.character_id]
    battler:setAnimation("battle/idle")

    local box = self.battle_ui.action_boxes[action.character_id]
    box.head_sprite:setSprite(box.battler.chara.head_icons.."/head")

    if action.tp then
        if action.tp < 0 then
            self.tension_bar:giveTension(-action.tp)
        elseif action.tp > 0 then
            self.tension_bar:removeTension(action.tp)
        end
    end

    if action.action == "ITEM" and action.data and action.data.index and action.data.item then
        if action.data.item.result_item then
            Game.inventory:replaceItem("item", action.data.item, action.data.index)
        else
            Game.inventory:addItem(action.data.item, action.data.index)
        end
        action.data.item:onBattleDeselect(battler, action.target)
    end

    self.character_actions[action.character_id] = nil
end

function Battle:getPartyIndex(string_id) -- TODO: this only returns the first one... what if someone has two Susies?
    for index, battler in ipairs(self.party) do
        if battler.chara.id == string_id then
            return index
        end
    end
    return nil
end

function Battle:getPartyBattler(string_id)
    for _, battler in ipairs(self.party) do
        if battler.chara.id == string_id then
            return battler
        end
    end
    return nil
end

function Battle:hasAction(character_id)
    return self.character_actions[character_id] ~= nil
end

function Battle:checkSolidCollision(collider)
    Object.startCache()
    if self.arena then
        if self.arena:collidesWith(collider) then
            Object.endCache()
            return true, self.arena
        end
    end
    Object.endCache()
    return false
end

function Battle:hurt(amount, element)
    element = element or 0

    -- TODO: make this accurate!
    -- See gml_GlobalScript_scr_damage for reference

    -- For now, let's just use a very basic system...

    -- Pick a random party member to take damage from
    local party_member = self.party[math.random(#self.party)]
    while party_member.hp <= 0 do
        party_member = self.party[math.random(#self.party)]
    end

    party_member:hurt(amount, element)

    --self.chara.health = self.chara.health - amount
    --self:statusMessage("max", amount)

    --global.inv = (global.invc * 40)
end

function Battle:setWaves(waves, allow_duplicates)
    for _,wave in ipairs(self.waves) do
        wave:onEnd()
        wave:clear()
        wave:remove()
    end
    self.waves = {}
    local added_wave = {}
    for _,wave in ipairs(waves) do
        local exists = (type(wave) == "string" and added_wave[wave]) or (isClass(wave) and added_wave[wave.id])
        if allow_duplicates or not exists then
            if type(wave) == "string" then
                wave = Registry.createWave(wave)
            end
            self:addChild(wave)
            table.insert(self.waves, wave)
            added_wave[wave.id] = true
        end
    end
    return self.waves
end

function Battle:startProcessing()
    self.has_acted = false
    self:setState("ACTIONS")
end

function Battle:nextParty()
    table.insert(self.selected_character_stack, self.current_selecting)
    table.insert(self.selected_action_stack, Utils.copy(self.character_actions))

    local all_done = true
    local last_selected = self.current_selecting
    self.current_selecting = (self.current_selecting % #self.party) + 1
    while self.current_selecting ~= last_selected do
        if not self:hasAction(self.current_selecting) and not self.party[self.current_selecting].is_down then
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
            if old_action then
                self:removeSingleAction(old_action)
            end
            if new_action then
                self:commitSingleAction(new_action)
            end
        end
    end

    table.remove(self.selected_character_stack, #self.selected_character_stack)
    table.remove(self.selected_action_stack, #self.selected_action_stack)
end

function Battle:nextTurn()
    self.turn_count = self.turn_count + 1
    if self.turn_count > 1 then
        self.encounter:onTurnEnd()
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
        if (battler.chara.health <= 0) then
            battler:heal(math.ceil(battler.chara:getStat("health") / 8))
        end
    end

    self.attackers = {}

    self.current_selecting = 1
    while (self.party[self.current_selecting].is_down) do
        self.current_selecting = self.current_selecting + 1
        if self.current_selecting > #self.party then
            print("WARNING: nobody up! this shouldn't happen...")
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
            box.head_sprite:setSprite(box.battler.chara.head_icons.."/head")
        end
        self.battle_ui.current_encounter_text = self:fetchEncounterText()
        self.battle_ui.encounter_text:setText(self.battle_ui.current_encounter_text)
    end

    if self.soul then
        self.soul:remove()
        self.soul = nil
    end

    self.encounter:onTurnStart()

    self:setState("ACTIONSELECT")
end

function Battle:checkGameOver()
    for _,battler in ipairs(self.party) do
        if not battler.is_down then
            return
        end
    end
    self.music:stop()
    Game:gameOver(self:getSoulLocation())
end

function Battle:returnToWorld()
    self.transition_timer = 0
    for _,battler in ipairs(self.party) do
        if self.party_world_characters[battler.chara.id] then
            self.party_world_characters[battler.chara.id].visible = true
        end
    end
    if self.music ~= Game.world.music then
        self.music:stop()
        Game.world.music:resume()
    end
    self:remove()
    Game.battle = nil
    Game.state = "OVERWORLD"
end

function Battle:setActText(text, dont_finish)
    self:battleText(text, function()
        if not dont_finish then
            self:finishAction()
        end
        self:setState("ACTIONS", "BATTLETEXT")
    end)
end

function Battle:shortActText(text)
    self:setState("SHORTACTTEXT")
    self.battle_ui.encounter_text:setText("")

    self.battle_ui.short_act_text_1:setText(text[1] or "")
    self.battle_ui.short_act_text_2:setText(text[2] or "")
    self.battle_ui.short_act_text_3:setText(text[3] or "")
end

function Battle:battleText(text,post_func)
    self.battletext_index = 1
    if type(text) == "table" then
        self.battletext_table = text
        self.battle_ui.encounter_text:setText(text[1])
    else
        self.battletext_table = nil
        self.battle_ui.encounter_text:setText(text)
    end
    self.post_battletext_func = post_func
    self.post_battletext_state = self:getState()
    self:setState("BATTLETEXT")
end

function Battle:infoText(text)
    self.battle_ui.encounter_text:setText(text or "")
end

function Battle:spawnEnemyTextbox(enemy, text)
    local x, y = enemy.sprite:getRelativePos(0, enemy.sprite.height/2, self)
    if enemy.text_offset then
        x, y = x + enemy.text_offset[1], y + enemy.text_offset[2]
    end
    local textbox = EnemyTextbox(text, x, y, enemy)
    self:addChild(textbox)
    return textbox
end

function Battle:hasCutscene()
    return self.cutscene and not self.cutscene.ended
end

function Battle:startCutscene(group, id, ...)
    if self.cutscene then
        error("Attempt to start a cutscene while already in a cutscene.")
    end
    self.cutscene = BattleCutscene(group, id, ...)
    return self.cutscene
end

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
    table.sort(self.children, function(a, b)
        return a.layer < b.layer or (a.layer == b.layer and (a:includes(Battler) and b:includes(Battler)) and a.y < b.y)
    end)
end

function Battle:createTransform()
    local transform = super:createTransform(self)
    transform:apply(self.camera:getTransform(0, 0))
    return transform
end

function Battle:update(dt)
    for _,enemy in ipairs(self.enemies_to_remove) do
        Utils.removeFromTable(self.enemies, enemy)
    end
    self.enemies_to_remove = {}

    if self.cutscene then
        if not self.cutscene.ended then
            self.cutscene:update(dt)
        end
        if self.cutscene.ended then
            self.cutscene = nil
        end
    end

    if self.state == "TRANSITION" then
        self:updateTransition(dt)
    elseif self.state == "INTRO" then
        self:updateIntro(dt)
    elseif self.state == "ATTACKING" then
        self:updateAttacking(dt)
    elseif self.state == "ACTIONSDONE" then
        self.actions_done_timer = Utils.approach(self.actions_done_timer, 0, dt)
        local any_hurt = false
        for _,enemy in ipairs(self.enemies) do
            if enemy.hurt_timer > 0 then
                any_hurt = true
                break
            end
        end
        if self.actions_done_timer == 0 and not any_hurt then
            for _,battler in ipairs(self.attackers) do
                if not battler:setAnimation("battle/attack_end") then
                    battler:setAnimation("battle/idle")
                end
            end
            self.attackers = {}
            if #self.battle_ui.attack_boxes >= 0 then
                self.battle_ui:endAttack()
            end
            self:setState("ENEMYDIALOGUE")
        end
    elseif self.state == "DEFENDING" then
        self:updateWaves(dt)
    end

    if self.state ~= "TRANSITIONOUT" then
        self.encounter:update(dt)
    end

    if self.shake ~= 0 then
        local last_shake = math.ceil(self.shake)
        self.camera.ox = last_shake
        self.camera.oy = last_shake
        self.shake = Utils.approach(self.shake, 0, DTMULT)
        local new_shake = math.ceil(self.shake)
        if new_shake ~= last_shake then
            self.shake = self.shake * -1
        end
    else
        self.camera.ox = 0
        self.camera.oy = 0
    end

    -- Always sort
    --self.update_child_list = true
    super:update(self, dt)

    if self.state == "TRANSITIONOUT" then
        self:updateTransitionOut(dt)
    end
end

function Battle:updateIntro(dt)
    self.intro_timer = self.intro_timer + 1 * (dt * 30)
    if self.intro_timer >= 13 then
        self:nextTurn()
    end
end

function Battle:updateTransition(dt)
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

    self.transition_timer = self.transition_timer + 1 * (dt * 30)

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

function Battle:updateTransitionOut(dt)
    if not self.battle_ui.animation_done then
        return
    end

    self.transition_timer = self.transition_timer - DTMULT

    if self.transition_timer <= 0 or not self.transitioned then
        self:returnToWorld()
        return
    end

    for index, battler in ipairs(self.party) do
        local target_x, target_y = unpack(self.battler_targets[index])

        battler.x = Utils.lerp(self.party_beginning_positions[index][1], target_x, self.transition_timer / 10)
        battler.y = Utils.lerp(self.party_beginning_positions[index][2], target_y, self.transition_timer / 10)
    end

    for _,battler in ipairs(self.defeated_enemies) do
        battler.alpha = self.transition_timer / 10
    end
    for _,battler in ipairs(self.enemies) do
        battler.alpha = self.transition_timer / 10
    end
end

function Battle:updateAttacking(dt)
    if not self.attack_done then
        if #self.battle_ui.attack_boxes == 0 then
            self.battle_ui:beginAttack()
        end

        local all_done = true
        for _,attack in ipairs(self.battle_ui.attack_boxes) do
            if not attack.attacked and attack.fade_rect.alpha < 1 then
                local close = attack:getClose()
                if close <= -5 then
                    attack:miss()

                    local action = self:getActionBy(attack.battler)
                    action.points = 0

                    if self:processAction(action) then
                        self:finishAction(action)
                    end
                else
                    all_done = false
                end
            end
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

function Battle:updateWaves(dt)
    self.wave_timer = self.wave_timer + dt

    local last_done = true
    local all_done = true
    for _,wave in ipairs(self.waves) do
        if not wave.finished then
            last_done = false

            if wave.time >= 0 and self.wave_timer >= wave.time then
                wave.finished = true
            else
                all_done = false
            end
        end
    end

    if all_done and not last_done then
        self.encounter:onWavesDone()
    end
end

function Battle:debugPrintOutline(string, x, y, color)
    color = color or {love.graphics.getColor()}
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(string, x - 1, y)
    love.graphics.print(string, x + 1, y)
    love.graphics.print(string, x, y - 1)
    love.graphics.print(string, x, y + 1)

    love.graphics.setColor(color)
    love.graphics.print(string, x, y)
end

function Battle:drawDebug()
    local font = Assets.getFont("main", 16)
    love.graphics.setFont(font)

    love.graphics.setColor(1, 1, 1, 1)
    self:debugPrintOutline("State: "    .. self.state   , 4, 0)
    self:debugPrintOutline("Substate: " .. self.substate, 4, 0 + 16)
end

function Battle:draw()
    if self.encounter.background then
        self:drawBackground()
    end

    if (self.state == "ENEMYDIALOGUE") or (self.state == "DEFENDING") then
        self.background_fade_alpha = math.min(self.background_fade_alpha + (0.05 * DTMULT), 0.75)
    end

    if (self.state == "DEFENDINGEND") or (self.state == "ACTIONSELECT") or (self.state == "ACTIONS") then
        self.background_fade_alpha = math.max(self.background_fade_alpha - (0.05 * DTMULT), 0)
    end

    self.encounter:drawBackground(self.transition_timer / 10)

    love.graphics.setColor(0, 0, 0, self.background_fade_alpha) -- TODO: make this accurate!!
    -- The "foreground" background boxes have values of (17, 0, 17),
    -- while the "background" background boxes have values of (9, 0, 9).
    -- But in our engine, when we use 0.75, for some reason the foreground boxes are correct,
    -- however the background ones are (8, 0, 8).
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    super:draw(self)

    self.encounter:draw(self.transition_timer / 10)

    if DEBUG_RENDER then
        self:drawDebug()
    end
end

function Battle:drawBackground()
    love.graphics.setColor(0, 0, 0, self.transition_timer / 10)
    love.graphics.rectangle("fill", -8, -8, SCREEN_WIDTH+16, SCREEN_HEIGHT+16)

    self.offset = self.offset + 1 * (DT * 30)

    if self.offset > 100 then
        self.offset = self.offset - 100
    end

    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(1)

    for i = 2, 16 do
        love.graphics.setColor(66 / 255, 0, 66 / 255, (self.transition_timer / 10) / 2)
        love.graphics.line(0, -210 + (i * 50) + math.floor(self.offset / 2), 640, -210 + (i * 50) + math.floor(self.offset / 2))
        love.graphics.line(-200 + (i * 50) + math.floor(self.offset / 2), 0, -200 + (i * 50) + math.floor(self.offset / 2), 480)
    end

    for i = 3, 16 do
        love.graphics.setColor(66 / 255, 0, 66 / 255, self.transition_timer / 10)
        love.graphics.line(0, -100 + (i * 50) - math.floor(self.offset), 640, -100 + (i * 50) - math.floor(self.offset))
        love.graphics.line(-100 + (i * 50) - math.floor(self.offset), 0, -100 + (i * 50) - math.floor(self.offset), 480)
    end
end

function Battle:isWorldHidden()
    return self.state ~= "TRANSITION" and self.state ~= "TRANSITIONOUT" and
           (self.encounter.background or self.encounter.hide_world)
end

function Battle:canSelectMenuItem(menu_item)
    if menu_item.unusable then
        return false
    end
    if menu_item.tp and (menu_item.tp > self.tension_bar:getTension()) then
        return false
    end
    if menu_item.party then
        for _,party_id in ipairs(menu_item.party) do
            local battler = self.party[self:getPartyIndex(party_id)]
            if (not battler) or (battler.chara.health <= 0) then
                -- They're either down, or don't exist. Either way, they're not here to do the action.
                return false
            end
        end
    end
    return true
end

function Battle:isEnemySelected(enemy)
    if self.state == "ENEMYSELECT" or self.state == "XACTENEMYSELECT" then
        return self.enemies[self.current_menu_y] == enemy
    elseif self.state == "MENUSELECT" and self.state_reason == "ACT" then
        return self.enemies[self.selected_enemy] == enemy
    end
    return false
end

function Battle:removeEnemy(enemy, defeated)
    table.insert(self.enemies_to_remove, enemy)
    if defeated then
        table.insert(self.defeated_enemies, enemy)
    end
end

function Battle:getActiveEnemies()
    return Utils.filter(self.enemies, function(enemy) return not enemy.done_state end)
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

function Battle:keypressed(key)
    if true then -- TODO: DEBUG
        if key == "g" then
            self.party[self.current_selecting]:hurt(1)
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
        if key == "b" then
            for _,battler in ipairs(self.party) do
                battler:hurt(99999)
            end
        end
        if key == "k" then
            self.tension = 250 * 2
        end
    end

    if self.state == "MENUSELECT" then
        local menu_width = 2
        local menu_height = math.ceil(#self.menu_items / 2)

        if Input.isConfirm(key) then
            if self.state_reason == "ACT" then
                local menu_item = self.menu_items[self:getItemIndex()]
                if self:canSelectMenuItem(menu_item) then
                    self.ui_select:stop()
                    self.ui_select:play()

                    self:commitAction("ACT", self.enemies[self.selected_enemy], menu_item)
                end
                return
            elseif self.state_reason == "SPELL" then
                local menu_item = self.menu_items[self:getItemIndex()]
                self.selected_spell = menu_item
                if self:canSelectMenuItem(menu_item) then
                    self.ui_select:stop()
                    self.ui_select:play()

                    if menu_item.data.target == "xact" then
                        self.selected_xaction = menu_item.data
                        self:setState("XACTENEMYSELECT")
                    elseif not menu_item.data.target or menu_item.data.target == "none" then
                        self:commitAction("SPELL", nil, menu_item)
                    elseif menu_item.data.target == "enemy" then
                        self:setState("ENEMYSELECT", "SPELL")
                    elseif menu_item.data.target == "party" then
                        self:setState("PARTYSELECT", "SPELL")
                    end
                end
                return
            elseif self.state_reason == "ITEM" then
                local menu_item = self.menu_items[self:getItemIndex()]
                self.selected_item = menu_item
                if self:canSelectMenuItem(menu_item) then
                    self.ui_select:stop()
                    self.ui_select:play()
                    if not menu_item.data.item.target or menu_item.data.item.target == "none" then
                        self:commitAction("ITEM", nil, menu_item)
                    elseif menu_item.data.item.target == "party" then
                        self:setState("PARTYSELECT", "ITEM")
                    elseif menu_item.data.item.target == "enemy" then
                        self:setState("ENEMYSELECT", "ITEM")
                    end
                end
            end
        elseif Input.isCancel(key) then
            self.ui_move:stop()
            self.ui_move:play()
            self.tension_bar:setTensionPreview(0)
            self:setState("ACTIONSELECT", "CANCEL")
            return
        elseif key == "left" then -- TODO: pagination
            self.current_menu_x = self.current_menu_x - 1
            if self.current_menu_x < 1 then
                self.current_menu_x = menu_width
                if not self:isValidMenuLocation() then
                    self.current_menu_x = 1
                end
            end
        elseif key == "right" then
            self.current_menu_x = self.current_menu_x + 1
            if not self:isValidMenuLocation() then
                self.current_menu_x = 1
            end
        end
        if key == "up" then
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = 1 -- No wrapping in this menu.
            end
        elseif key == "down" then
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
            self.ui_select:stop()
            self.ui_select:play()
            self.selected_enemy = self.current_menu_y
            if self.state == "XACTENEMYSELECT" then
                self:commitAction("XACT", self.enemies[self.selected_enemy], self.selected_xaction)
            elseif self.state_reason == "SPARE" then
                self:commitAction("SPARE", self.enemies[self.selected_enemy])
            elseif self.state_reason == "ACT" then
                self.menu_items = {}
                local enemy = self.enemies[self.selected_enemy]
                for _,v in ipairs(enemy.acts) do
                    local insert = true
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
                        local item = {
                            ["name"] = v.name,
                            ["tp"] = v.tp or 0,
                            ["description"] = v.description,
                            ["party"] = v.party,
                            ["color"] = {1, 1, 1, 1}
                        }
                        table.insert(self.menu_items, item)
                    end
                end
                self:setState("MENUSELECT", "ACT")
            elseif self.state_reason == "ATTACK" then
                self:commitAction("ATTACK", self.enemies[self.selected_enemy])
            elseif self.state_reason == "SPELL" then
                self:commitAction("SPELL", self.enemies[self.selected_enemy], self.selected_spell)
            elseif self.state_reason == "ITEM" then
                self:commitAction("ITEM", self.enemies[self.selected_enemy], self.selected_item)
            else
                self:nextParty()
            end
            return
        end
        if Input.isCancel(key) then
            self.ui_move:stop()
            self.ui_move:play()
            self:setState("ACTIONSELECT", "CANCEL")
            return
        end
        if key == "up" then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = #self.enemies
            end
        elseif key == "down" then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y + 1
            if self.current_menu_y > #self.enemies then
                self.current_menu_y = 1
            end
        end
    elseif self.state == "PARTYSELECT" then
        if Input.isConfirm(key) then
            self.ui_select:stop()
            self.ui_select:play()
            if self.state_reason == "SPELL" then
                self:commitAction("SPELL", self.party[self.current_menu_y], self.selected_spell)
            elseif self.state_reason == "ITEM" then
                self:commitAction("ITEM", self.party[self.current_menu_y], self.selected_item)
            else
                self:nextParty()
            end
            return
        end
        if Input.isCancel(key) then
            self.ui_move:stop()
            self.ui_move:play()
            self:setState("ACTIONSELECT", "CANCEL")
            return
        end
        if key == "up" then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = #self.party
            end
        elseif key == "down" then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y + 1
            if self.current_menu_y > #self.party then
                self.current_menu_y = 1
            end
        end
    elseif self.state == "BATTLETEXT" then
        if Input.isConfirm(key) then
            if not self.battle_ui.encounter_text:isTyping() then
                if self.battletext_table ~= nil then
                    self.battletext_index = self.battletext_index + 1
                    if self.battletext_index <= #self.battletext_table then
                        self.battle_ui.encounter_text:setText(self.battletext_table[self.battletext_index])
                        return
                    end
                end
                self.battle_ui.encounter_text:setText("")
                if self.post_battletext_func then
                    self:post_battletext_func()
                else
                    self:setState(self.post_battletext_state, "BATTLETEXT")
                end
            end
        end
    elseif self.state == "SHORTACTTEXT" then
        if Input.isConfirm(key) then
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
    elseif self.state == "ENEMYDIALOGUE" then
        if Input.isConfirm(key) then
            local any_typing = false
            local all_done = true
            local to_remove = {}
            -- Check if any dialogue is typing
            for _,dialogue in ipairs(self.enemy_dialogue) do
                if dialogue.text.state.typing then
                    all_done = false
                    break
                end
            end
            -- Nothing is typing, try to advance
            if all_done then
                for _,dialogue in ipairs(self.enemy_dialogue) do
                    dialogue:next()
                    if not dialogue.done then
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
    elseif self.state == "ACTIONSELECT" then
        -- TODO: make this less huge!!
        local actbox = self.battle_ui.action_boxes[self.current_selecting]

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
        elseif key == "left" then
            actbox.selected_button = actbox.selected_button - 1
            self.ui_move:stop()
            self.ui_move:play()
        elseif key == "right" then
            actbox.selected_button = actbox.selected_button + 1
            self.ui_move:stop()
            self.ui_move:play()
        end

        if actbox.selected_button < 1 then
            actbox.selected_button = #actbox.buttons
        end

        if actbox.selected_button > #actbox.buttons then
            actbox.selected_button = 1
        end
    elseif self.state == "ATTACKING" then
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

                if closest < 15 and closest > -5 then
                    for _,attack in ipairs(closest_attacks) do
                        local points = attack:hit()

                        local action = self:getActionBy(attack.battler)
                        action.points = points

                        if self:processAction(action) then
                            self:finishAction(action)
                        end
                    end
                end
            end
        end
    elseif self.state == "DEFENDING" then
        if key == "d" then
            local rot = self.arena.rotation + (math.pi/2)
            self.timer:tween(0.33, self.arena, {rotation = rot})
        elseif key == "a" then
            local rot = self.arena.rotation - (math.pi/2)
            self.timer:tween(0.33, self.arena, {rotation = rot})
        elseif key == "w" then
            local sx, sy = self.arena.scale_x * 1.5, self.arena.scale_y * 1.5
            self.timer:tween(0.33, self.arena, {scale_x = sx, scale_y = sy})
        elseif key == "s" then
            local sx, sy = self.arena.scale_x * 0.75, self.arena.scale_y * 0.75
            self.timer:tween(0.33, self.arena, {scale_x = sx, scale_y = sy})
        end
    end
end

return Battle