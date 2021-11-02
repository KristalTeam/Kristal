local Battle, super = Class(Object)

function Battle:init()
    super:init(self)

    self.party = {}

    self.music = nil
    --self.music_file = music

    self.max_tension = 250
    self.tension = 0

    self.ui_move = love.audio.newSource("assets/sounds/ui_move.wav", "static")
    self.ui_select = love.audio.newSource("assets/sounds/ui_select.wav", "static")

    self.party_beginning_positions = {} -- Only used in TRANSITION, but whatever

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

            Game.world.player.visible = false
        else
            local found = false
            for _,follower in ipairs(Game.followers) do
                if follower.visible and follower.actor.id == party_member.id then
                    local chara_x, chara_y = follower:getScreenPos()
                    local chara_battler = PartyBattler(party_member, chara_x, chara_y)
                    chara_battler:setAnimation("battle/transition")
                    self:addChild(chara_battler)
                    table.insert(self.party, chara_battler)
                    table.insert(self.party_beginning_positions, {chara_x, chara_y})
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

    -- states: BATTLETEXT, TRANSITION, INTRO, ACTIONSELECT, ACTING, SPARING, USINGITEMS, ATTACKING, ACTIONSDONE, ENEMYDIALOGUE, DIALOGUEEND, DEFENDING
    -- ENEMYSELECT, MENUSELECT, XACTENEMYSELECT, PARTYSELECT

    self.state = "NONE"
    self.substate = "NONE"

    self.camera = Camera(0, 0)

    self.current_selecting = 1

    self.battle_ui = nil
    self.tension_bar = nil

    self.arena = nil
    self.soul = nil

    self.character_actions = {}

    self.current_actions = {}
    self.current_action_index = 1
    self.processed_action = {}
    self.processing_action = false

    self.hit_count = {}

    self.post_battletext_func = nil
    self.post_battletext_state = "ACTIONSELECT"

    self.battletext_table = nil
    self.battletext_index = 1

    self.current_menu_x = 1
    self.current_menu_y = 1

    self.enemies = {}
    self.enemy_dialogue = {}

    self.state_reason = nil
    self.substate_reason = nil

    self.menu_items = {}

    self.selected_enemy = 1
    self.selected_spell = nil

    self.spell_delay = 0
    self.spell_finished = false

    self.xactiontext = {}

    self.timer = Timer.new()

    self.has_acted = false

    self.background_fade_alpha = 0

    self.wave_length = 0
    self.wave_timer = 0
end

function Battle:postInit(state, encounter)
    self:setState(state)
    self.encounter = encounter()

    --[[for _,enemy in ipairs(self.encounter.enemies) do
        local enemy_obj
        if type(enemy) == "string" then
            enemy_obj = Registry.createEnemy(enemy)
        else
            enemy_obj = enemy
        end
        table.insert(self.enemies, enemy_obj)
        self:addChild(enemy_obj)
    end]]

    if state == "TRANSITION" then
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
    end
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
    if new == "INTRO" then
        local src = love.audio.newSource("assets/sounds/snd_impact.wav", "static")
        src:setVolume(0.7)
        src:play()
        local src2 = love.audio.newSource("assets/sounds/snd_weaponpull_fast.wav", "static")
        src2:setVolume(0.8)
        src2:play()

        for _,battler in ipairs(self.party) do
            battler:setAnimation("battle/intro")
        end
    elseif new == "ACTIONSELECT" then
        if old == "DEFENDING" then
            for _,action in ipairs(self.current_actions) do
                if action.action == "DEFEND" then
                    self:finishAction(action)
                end
            end
        end

        if (old == "DEFENDING") or (old == "INTRO") or (self.current_selecting < 1) or (self.current_selecting > #self.party) then
            self.hit_count = {}
            self.current_selecting = 1
            self.current_button = 1

            self.character_actions = {}
            self.current_actions = {}
            self.processed_action = {}

            if self.battle_ui then
                for _,box in ipairs(self.battle_ui.action_boxes) do
                    box.selected_button = 1
                    if old ~= "DEFENDING" then
                        box.head_sprite:setSprite(box.battler.chara.head_icons.."/head")
                    end
                end
                if (old ~= "INTRO") then
                    self.battle_ui.current_encounter_text = self:fetchEncounterText()
                end
                self.battle_ui.encounter_text:setText(self.battle_ui.current_encounter_text)
            end
            if self.arena then
                self:removeChild(self.arena)
                self.arena = nil
            end
            if self.soul then
                self:removeChild(self.soul)
                self.soul = nil
            end
            if old ~= "DEFENDING" then
                for _,battler in ipairs(self.party) do
                    battler:setAnimation("battle/idle")
                end
            end
        end

        if self.state_reason == "CANCEL" then
            self.battle_ui.encounter_text:setText("[instant]" .. self.battle_ui.current_encounter_text)
        end

        if not self.music then
            if not self.music_file then
                self.music = love.audio.newSource("assets/music/battle.ogg", "stream")
                self.music:setVolume(0.7)
                self.music:setLooping(true)
                self.music:play()
            else
                self.music = love.audio.newSource("assets/music/" .. self.music_file, "stream")
                self.music:setLooping(true)
                self.music:play()
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
        if self.state_reason == "DONTPROCESS" then
            return
        end
        self:tryProcessNextAction()
    elseif new == "ENEMYSELECT" then
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
    elseif new == "ENEMYDIALOGUE" then
        self.battle_ui.encounter_text:setText("")
        for _,enemy in ipairs(self.enemies) do
            local x, y
            if enemy.text_offset then
                x, y = enemy.x + enemy.text_offset[1], enemy.y + enemy.text_offset[2]
            else
                x, y = enemy.sprite:getRelativePos(0, enemy.sprite.height/2, self)
            end
            local dialogue = enemy:getEnemyDialogue()
            if dialogue then
                local textbox = EnemyTextbox(dialogue, x, y)
                table.insert(self.enemy_dialogue, textbox)
                self:addChild(textbox)
            end
        end
    elseif new == "DIALOGUEEND" then
        self.battle_ui.encounter_text:setText("")

        for _,action in ipairs(self.character_actions) do
            if action.action == "DEFEND" then
                self:beginAction(action)
                self:processAction(action)
            end
        end

        self.encounter:onDialogueEnd()
    elseif new == "DEFENDING" then
        self.wave_length = 0
        self.wave_timer = 0

        local waves = self.encounter.current_waves

        for _,wave in ipairs(waves) do
            wave.encounter = self.encounter

            self.wave_length = math.max(self.wave_length, wave.time)

            wave:onStart()
        end
    end
end

function Battle:spawnSoul(x, y)
    local battler = self.party[self:getPartyIndex("kris")] -- TODO: don't hardcode kris, they just need a soul

    local bx, by
    if not battler then
        bx, by = -9, -9
    else
        bx, by = battler:localToScreenPos((battler.sprite.width/2) - 4.5, battler.sprite.height/2)
    end

    self:addChild(HeartBurst(bx, by))
    if not self.soul then
        self.soul = Soul(bx, by)
        self.soul:transitionTo(x or SCREEN_WIDTH/2, y or SCREEN_HEIGHT/2)
        self.soul.layer = 20
        self:addChild(self.soul)
    end
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

function Battle:registerXAction(...) print("TODO: implement!") end -- TODO

function Battle:setXActionText(text)
    table.insert(self.xactiontext, text)
end

function Battle:fetchEncounterText()
    return self.encounter:fetchEncounterText()
end

function Battle:processCharacterActions()
    if self.state ~= "ACTIONS" then
        self:setState("ACTIONS", "DONTPROCESS")
    end

    self.current_action_index = 1

    local order = {"ACT", "XACT", {"SPELL", "ITEM", "SPARE"}, "ATTACK", "SKIP"}
    for _,action_group in ipairs(order) do
        if self:processActionGroup(action_group) then
            self:tryProcessNextAction()
            return
        end
    end

    self:setSubState("NONE")
    self:setState("ACTIONSDONE")
    --[[self.timer:after(4 / 30, function()
        self:setState("ENEMYDIALOGUE")
    end)]]
    --self:setState("ACTIONSELECT")
end

function Battle:processActionGroup(group)
    if type(group) == "string" then
        local found = false
        for _,action in ipairs(self.character_actions) do
            if action.action == group then
                found = true
                self:beginAction(action)
            end
        end
        for _,action in ipairs(self.current_actions) do
            Utils.removeFromTable(self.character_actions, action)
        end
        return found
    else
        for i,action in ipairs(self.character_actions) do
            -- If the table contains the action
            -- Ex. if {"SPELL", "ITEM", "SPARE"} contains "SPARE"
            if Utils.containsValue(group, action.action) then
                table.remove(self.character_actions, i)
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

function Battle:getActionFromCharacterIndex(index)
    for _,action in ipairs(self.character_actions) do
        if action.character_id == index then
            return action
        end
    end
end

function Battle:countActingMembers()
    local count = 0
    for _, action in ipairs(self.character_actions) do
        if action.action == "ACT" then
            count = count + 1
        end
    end
    return count
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

function Battle:processAction(action)
    local battler = self.party[action.character_id]
    local party_member = battler.chara
    local enemy = action.target

    if action.action == "SPARE" then
        local worked = enemy:onMercy()
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
        battler:setAnimation("battle/spare", function() self:finishAction(action) end)
        self:battleText(text)
    elseif action.action == "ATTACK" then
        love.audio.newSource("assets/sounds/snd_laz_c.wav", "static"):play()
        battler:setAnimation("battle/attack", function()
            local box = self.battle_ui.action_boxes[self:getPartyIndex(battler.chara.id)]
            box.head_sprite:setSprite(battler.chara.head_icons.."/head")

            local dmg_sprite = Sprite(battler.chara.dmg_sprite or "effects/attack/cut")
            dmg_sprite:setOrigin(0.5, 0.5)
            dmg_sprite:setScale(2, 2)
            dmg_sprite:setPosition(enemy:getRelativePos(enemy.width/2, enemy.height/2))
            dmg_sprite.layer = enemy.layer + 0.01
            dmg_sprite:play(1/15, false, function(s) s:remove() end)
            enemy.parent:addChild(dmg_sprite)

            enemy:hurt(battler.chara.stats.attack, battler)
            self:finishAction(action)
        end)
        self:battleText("* " .. party_member.name .. " attacked " .. enemy.name .. "!\n* You will regret this")
    elseif action.action == "ACT" then
        -- fun fact: this would have only been a single function call
        -- if stupid multi-acts didn't exist

        -- Check for other short acts
        local self_short = false
        local short_actions = {}
        for _,iaction in ipairs(self.current_actions) do
            if iaction.action == "ACT" then
                local ibattler = self.party[iaction.character_id]
                local ienemy = iaction.target

                if ienemy then
                    local act = ienemy and ienemy:getAct(iaction.name)

                    if (act and act.short) or (ienemy:getXAction(ibattler) == iaction.name and ienemy:isXActionShort(ibattler)) then
                        table.insert(short_actions, iaction)
                        if ibattler == battler then
                            self_short = true
                        end
                    end
                end
            end
        end

        if self_short and #short_actions > 1 then
            local short_text = {}
            for _,iaction in ipairs(short_actions) do
                local ibattler = self.party[iaction.character_id]
                local ienemy = iaction.target

                local act_text = ienemy:onShortAct(ibattler, iaction.name)
                if act_text then
                    table.insert(short_text, act_text)
                end
            end

            local dumb_string_testing = ""
            for _,str in ipairs(short_text) do
                dumb_string_testing = dumb_string_testing .. str .. "\n"
            end
            self:battleText(dumb_string_testing, function()
                for _,iaction in ipairs(short_actions) do
                    self:finishAction(iaction)
                end
                self:setState("ACTIONS", "BATTLETEXT")
            end)
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
    elseif action.action == "DEFEND" then
        battler:setAnimation("battle/defend")
        battler.defending = true
    else
        -- we don't know how to handle this...
        return true
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

function Battle:finishAction(action)
    action = action or self.current_actions[self.current_action_index]

    local battler = self.party[action.character_id]

    self.processed_action[action] = true

    if self.processing_action == action then
        self.processing_action = nil
    end

    local all_processed = true
    for _,iaction in ipairs(self.current_actions) do
        if not self.processed_action[iaction] then
            all_processed = false
            break
        end
    end

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
end

function Battle:commitAction(type, target, data)
    data = data or {}

    self.party[self.current_selecting]:setAnimation("battle/"..type:lower().."_ready")
    local box = self.battle_ui.action_boxes[self.current_selecting]
    box.head_sprite:setSprite(box.battler.chara.head_icons.."/"..type:lower())

    local last_tp = self.tension
    if data.tp then
        if data.tp < 0 then
            self.tension_bar:giveTension(-data.tp)
        else
            self.tension_bar:removeTension(data.tp)
        end
    end

    table.insert(self.character_actions,
    {
        ["character_id"] = self.current_selecting,
        ["action"] = type:upper(),
        ["party"] = data.party,
        ["name"] = data.name,
        ["target"] = target,
        ["data"] = data.data,
        ["tp"] = self.tension - last_tp
    })

    if data.party then
        for _,v in ipairs(data.party) do
            local index = self:getPartyIndex(v)

            self.party[index]:setAnimation("battle/"..type:lower().."_ready")
            local other_box = self.battle_ui.action_boxes[index]
            other_box.head_sprite:setSprite(other_box.battler.chara.head_icons.."/"..type:lower())

            table.insert(self.character_actions,
                {
                    ["character_id"] = self:getPartyIndex(v),
                    ["action"] = "SKIP",
                    ["reason"] = type:upper(),
                    ["name"] = data.name,
                    ["target"] = target,
                    ["data"] = data.data,
                    ["act_parent"] = self.current_selecting
                }
            )
        end
    end

    self:nextParty()
end

function Battle:removeAction(character_id)
    for index, action in ipairs(self.character_actions) do
        if action.character_id == character_id then
            local battler = self.party[character_id]
            battler:setAnimation("battle/idle")

            local box = self.battle_ui.action_boxes[character_id]
            box.head_sprite:setSprite(box.battler.chara.head_icons.."/head")

            if action.tp then
                if action.tp < 0 then
                    self.tension_bar:giveTension(-action.tp)
                elseif action.tp > 0 then
                    self.tension_bar:removeTension(action.tp)
                end
            end

            table.remove(self.character_actions, index)

            if action.party then
                for _,v in ipairs(action.party) do
                    if self:hasAction(self:getPartyIndex(v)) then
                        self:removeAction(self:getPartyIndex(v))
                    end
                end
                return
            end
        end
    end
end

function Battle:getPartyIndex(string_id) -- TODO: this only returns the first one... what if someone has two Susies?
    for index, battler in ipairs(self.party) do
        if battler.chara.id == string_id then
            return index
        end
    end
    return nil
end

function Battle:hasAction(character_id)
    for _,action in ipairs(self.character_actions) do
        if action.character_id == character_id then
            return true
        end
    end
    return false
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

function Battle:startProcessing()
    self.has_acted = false
    self:setState("ACTIONS")
end

function Battle:nextParty()
    self.current_selecting = self.current_selecting + 1
    while (self:hasAction(self.current_selecting)) do
        self.current_selecting = self.current_selecting + 1
    end
    if self.current_selecting > #self.party then
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

function Battle:setActText(text, dont_finish)
    self:battleText(text, function()
        if not dont_finish then
            self:finishAction()
        end
        self:setState("ACTIONS", "BATTLETEXT")
    end)
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

function Battle:createTransform()
    local transform = super:createTransform(self)
    transform:apply(self.camera:getTransform(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT))
    return transform
end

function Battle:update(dt)
    self.timer:update(dt)
    if self.state == "TRANSITION" then
        self:updateTransition(dt)
    elseif self.state == "INTRO" then
        self:updateIntro(dt)
    elseif self.state == "ACTIONSDONE" then
        local any_hurt = false
        for _,enemy in ipairs(self.enemies) do
            if enemy.hurt_timer > 0 then
                any_hurt = true
                break
            end
        end
        if not any_hurt then
            self:setState("ENEMYDIALOGUE")
        end
    elseif self.state == "DEFENDING" then
        self:updateWaves(dt)
    end
    -- Always sort
    --self.update_child_list = true
    super:update(self, dt)
end

function Battle:updateIntro(dt)
    self.intro_timer = self.intro_timer + 1 * (dt * 30)
    if self.intro_timer >= 13 then
        self:setState("ACTIONSELECT")
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
end

function Battle:updateWaves(dt)
    local waves = self.encounter.current_waves

    self.wave_timer = self.wave_timer + dt

    local last_done = true
    local all_done = true
    for _,wave in ipairs(waves) do
        if not wave.finished then
            last_done = false

            if wave.time >= 0 and self.wave_timer >= wave.time then
                wave.finished = true
            end
        end
        wave:update(dt)
        if not wave.finished then
            all_done = false
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

    if (self.state == "ACTIONSELECT") or (self.state == "ACTIONS") then
        self.background_fade_alpha = math.max(self.background_fade_alpha - (0.05 * DTMULT), 0)
    end

    love.graphics.setColor(0, 0, 0, self.background_fade_alpha) -- TODO: make this accurate!!
    -- The "foreground" background boxes have values of (17, 0, 17),
    -- while the "background" background boxes have values of (9, 0, 9).
    -- But in our engine, when we use 0.75, for some reason the foreground boxes are correct,
    -- however the background ones are (8, 0, 8).
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    super:draw(self)

    self:drawDebug()
end

function Battle:drawBackground()
    love.graphics.setColor(0, 0, 0, self.transition_timer / 10)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

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

function Battle:canSelectMenuItem(menu_item)
    if menu_item.tp and menu_item.tp > self.tension then
        return false
    end
    if menu_item.party then
        for _,party_id in ipairs(menu_item.party) do
            local battler = Game.battle.party[Game.battle:getPartyIndex(party_id)]
            if (not battler) or (battler.chara.health <= 0) then
                -- They're either down, or don't exist. Either way, they're not here to do the action.
                return false
            end
        end
    end
    return true
end

function Battle:isEnemySelected(enemy)
    if self.state == "ENEMYSELECT" then
        return self.enemies[self.current_menu_y] == enemy
    elseif self.state == "MENUSELECT" and self.state_reason == "ACT" then
        return self.enemies[self.selected_enemy] == enemy
    end
    return false
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
            if self.music:isPlaying() then
                self.music:pause()
            else
                self.music:play()
            end
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
            elseif self.state_reason == "SPELLS" then
                local menu_item = self.menu_items[self:getItemIndex()]
                self.selected_spell = self.menu_items[self:getItemIndex()]
                if self:canSelectMenuItem(menu_item) then
                    self.ui_select:stop()
                    self.ui_select:play()
                    if not menu_item.data.target then
                        self:commitAction("SPELL", nil, menu_item)
                    elseif menu_item.data.target == "enemy" then
                        Game.battle:setState("ENEMYSELECT", "SPELL")
                    elseif menu_item.data.target == "party" then
                        Game.battle:setState("PARTYSELECT", "SPELL")
                    end
                end
                return
            end
        elseif Input.isCancel(key) then
            self.ui_move:stop()
            self.ui_move:play()
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
    elseif self.state == "ENEMYSELECT" then
        if Input.isConfirm(key) then
            self.ui_select:stop()
            self.ui_select:play()
            self.selected_enemy = self.current_menu_y
            if self.state_reason == "SPARE" then
                self:commitAction("SPARE", self.enemies[self.selected_enemy])
            elseif self.state_reason == "ACT" then
                Game.battle.menu_items = {}
                local enemy = self.enemies[self.selected_enemy]
                for _,v in ipairs(enemy.acts) do
                    local insert = true
                    if v.party and (#v.party > 0) then
                        insert = false
                        for _,party_id in ipairs(v.party) do
                            if self:getPartyIndex(party_id) then
                                insert = true
                            end
                        end
                    end
                    if insert then
                        local item = {
                            ["name"] = v.name,
                            ["tp"] = 0,
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
            if not self.battle_ui.encounter_text.state.typing then
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
        if Input.isConfirm(key) then
            self.battle_ui.action_boxes[self.current_selecting]:select()
            self.ui_select:stop()
            self.ui_select:play()
            return
        elseif Input.isCancel(key) then
            if Game.battle.current_selecting > 1 then
                self.ui_move:stop()
                self.ui_move:play()
                Game.battle.current_selecting = Game.battle.current_selecting - 1
                self.battle_ui.action_boxes[self.current_selecting]:unselect()
            end
            return
        elseif key == "left" then
            self.battle_ui.action_boxes[self.current_selecting].selected_button = self.battle_ui.action_boxes[self.current_selecting].selected_button - 1
            self.ui_move:stop()
            self.ui_move:play()
        elseif key == "right" then
            self.battle_ui.action_boxes[self.current_selecting].selected_button = self.battle_ui.action_boxes[self.current_selecting].selected_button + 1
            self.ui_move:stop()
            self.ui_move:play()
        end

        if self.battle_ui.action_boxes[self.current_selecting].selected_button < 1 then
            self.battle_ui.action_boxes[self.current_selecting].selected_button = 5 -- TODO: unhardcode
        end

        if self.battle_ui.action_boxes[self.current_selecting].selected_button > 5 then -- TODO: unhardcode
            self.battle_ui.action_boxes[self.current_selecting].selected_button = 1
        end
    elseif self.state == "DEFENDING" then
        if Input.isConfirm(key) then
            self:setState("NONE")
            self.encounter:onWavesDone()
        elseif key == "d" then
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