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

    -- states: BATTLETEXT, TRANSITION, INTRO, ACTIONSELECT, ACTING, SPARING, USINGITEMS, ATTACKING, ENEMYDIALOGUE, DEFENDING
    -- ENEMYSELECT, MENUSELECT, XACTENEMYSELECT, PARTYSELECT

    self.state = "NONE"
    self.substate = "NONE"

    self.camera = Camera(0, 0)

    self.current_selecting = 1

    self.battle_ui = nil
    self.tension_bar = nil

    self.character_actions = {}
    self.current_action_processing = 1

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

    self.current_acting = nil
    self.current_casting = nil

    self.spell_delay = 0
    self.spell_finished = false

    self.xactiontext = {}

    self.timer = Timer.new()

    self.has_acted = false
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
    if reason then
        print("STATE CHANGE: went from " .. old .. " to " .. self.state .. " because of " .. reason)
    else
        print("STATE CHANGE: went from " .. old .. " to " .. self.state)
    end
    self:onStateChange(old, self.state)
end

function Battle:setSubState(state, reason)
    local old = self.substate
    self.substate = state
    self.substate_reason = reason
    if reason then
        print("-> SUBSTATE CHANGE: went from " .. old .. " to " .. self.substate .. " because of " .. reason)
    else
        print("-> SUBSTATE CHANGE: went from " .. old .. " to " .. self.substate)
    end
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
        if (old == "DEFENDING") or (old == "INTRO") or (self.current_selecting < 1) or (self.current_selecting > #self.party) then
            self.hit_count = {}
            self.current_selecting = 1
            self.current_button = 1
            if self.battle_ui then
                for _,box in ipairs(self.battle_ui.action_boxes) do
                    box.selected_button = 1
                    box.head_sprite:setSprite(box.battler.chara.head_icons.."/head")
                end
                if (old ~= "INTRO") then
                    self.battle_ui.current_encounter_text = self:fetchEncounterText()
                end
                self.battle_ui.encounter_text:setText(self.battle_ui.current_encounter_text)
            end
            for _,battler in ipairs(self.party) do
                battler:setAnimation("battle/idle")
            end
        end

        if self.state_reason == "CANCEL" then
            self.battle_ui.encounter_text:setText("[instant]" .. self.battle_ui.current_encounter_text)
        end

        if not self.music then
            if not self.music_file then
                self.music = love.audio.newSource("assets/music/battle.ogg", "stream")
                self.music:setVolume(0.7)
            else
                self.music = love.audio.newSource("assets/music/" .. self.music_file, "stream")
            end
        end

        self.music:setLooping(true)
        self.music:play()

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

        if self.substate == "ACT" then
            self:finishAct()
        elseif self.substate == "SPELL" then
            if self.spell_finished then
                local casting = self.current_casting
                self.current_casting = nil
                casting.spell:onFinish(casting.user, casting.target)
            end
        elseif self.state_reason ~= "BATTLETEXT" then
            self:processCharacterActions()
        end
        print("HI I LIKE IM GAY")
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
                x, y = enemy.sprite:getRelativePos(self, 0, enemy.sprite.height/2)
            end
            local dialogue = enemy:getEnemyDialogue()
            if dialogue then
                local textbox = EnemyTextbox(dialogue, x, y)
                table.insert(self.enemy_dialogue, textbox)
                self:addChild(textbox)
            end
        end
    end
end

function Battle:onSubStateChange(old,new)
    if new == "ACT" then
        print("-> ENTERED ACTING SUBSTATE")
    elseif new == "SPELL" then
        print("-> ENTERED CASTING SUBSTATE")
    end

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

function Battle:finishAct()
    local battler = self.current_acting

    if battler.sprite.anim ~= "battle/act" then
        battler:setAnimation("battle/idle")
        self:setSubState("NONE")
    end

    self.current_acting = false
    self:processCharacterActions()
end

function Battle:finishSpell()
    self.spell_finished = true

    if self.state ~= "BATTLETEXT" then
        local casting = self.current_casting
        self.current_casting = nil
        casting.spell:onFinish(casting.user, casting.target)
        self:setSubState("NONE")
    end
end

function Battle:processCharacterActions()
    if self.state ~= "ACTIONS" then
        self:setState("ACTIONS", "DONTPROCESS")
    end

    local order = {"SKIP", "ACT", "XACT", {"SPELL", "ITEM", "SPARE"}, "ATTACK"}
    for _,action_string in ipairs(order) do
        for i=1, #self.character_actions do
            local character_action = self.character_actions[i]
            if type(action_string) == "string" then
                if character_action.action == action_string then
                    table.remove(self.character_actions,i)
                    i = i - 1
                    self:processAction(character_action)
                    return
                end
            else
                -- If the table contains the action
                -- Ex. if {"SPELL", "ITEM", "SPARE"} contains "SPARE"
                if Utils.containsValue(action_string, character_action.action) then
                    table.remove(self.character_actions,i)
                    i = i - 1
                    self:processAction(character_action)
                    return
                end
            end
        end
    end
    print("ALL ACTIONS DONE, WAITING FOR 4/30 SECONDS")
    self:setSubState("NONE")
    self.timer:after(4 / 30, function()
        self:setState("ENEMYDIALOGUE")
    end)
    --self:setState("ACTIONSELECT")
end

function Battle:getActionFromCharacterIndex(index)
    for _,action in ipairs(self.character_actions) do
        if action.character_id == index then
            return action
        end
    end
end

function Battle:processAction(action)
    local battler = self.party[action.character_id]
    local party_member = battler.chara
    print("PROCESSING " .. party_member.name .. "'S ACTION " .. action.action)
    local enemy = action.target

    self:setSubState(action.action)

    if action.action == "SPARE" then
        battler:setAnimation("battle/spare")
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
        self:BattleText(text,
            (function() self:processCharacterActions() end)
        )
    elseif action.action == "ATTACK" then
        battler:setAnimation("battle/attack")
        self:BattleText("* " .. party_member.name .. " attacked " .. enemy.name .. "!\n* You will regret this",
            (function() self:processCharacterActions() end)
        )
    elseif action.action == "ACT" then
        print("-> It's time to act!")
        if not self.has_acted then
            self.has_acted = true
            enemy:onActStart(battler, action.name)
            for index, value in ipairs(self.party) do
                local chara_action = self:getActionFromCharacterIndex(index)
                if chara_action and chara_action.action == "ACT" then
                    enemy:onActStart(value, chara_action.name)
                end
            end
        end
        --battler:setAnimation("battle/act")
        --print(action.name)
        self.current_acting = battler
        enemy:onAct(battler, action.name)
    elseif action.action == "SKIP" then
        print("skipped!")
        self:processCharacterActions()
    elseif action.action == "SPELL" then
        print("CASTING A SPELL.......")
        self.battle_ui.encounter_text:setText("")
        self.spell_finished = false
        self.current_casting = {
            spell = action.data,
            user = battler,
            target = action.target
        }
        action.data:onStart(battler, action.target)
        if action.data.delay and action.data.delay > 0 then
            self.spell_delay = action.data.delay
        else
            if action.data:onCast(battler, action.target) then
                self:finishSpell()
            end
        end
    else
        -- we don't know how to handle this...
        -- go back!!!
        print("UNKNOWN ACTION " .. action.action .. ", SKIPPING")
        self:processCharacterActions()
    end
end

function Battle:removeAction(character_id)
    for index, action in ipairs(self.character_actions) do
        if action.character_id == character_id then
            table.remove(self.character_actions, index)
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
        print("PROCESSING ACTIONS")
        self:startProcessing()
    else
        if self:getState() ~= "ACTIONSELECT" then
            self:setState("ACTIONSELECT")
            self.battle_ui.encounter_text:setText("[instant]" .. self.battle_ui.current_encounter_text)
        end
    end
end

function Battle:BattleText(text,post_func)
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
    if type(text) == "table" then
        print("BATTLE TEXT: " .. Utils.dump(text))
    else
        print("BATTLE TEXT: " .. text)
    end
end

function Battle:update(dt)
    self.timer:update(dt)
    if self.state == "TRANSITION" then
        self:updateTransition(dt)
    elseif self.state == "INTRO" then
        self:updateIntro(dt)
    end
    if self.current_casting and self.spell_delay > 0 then
        self.spell_delay = self.spell_delay - dt
        if self.spell_delay <= 0 then
            local casting = self.current_casting
            if casting.spell:onCast(casting.user, casting.target) then
                self:finishSpell()
            end
        end
    end
    -- Always sort
    self.update_child_list = true
    self:updateChildren(dt)
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

function Battle:drawDebug()
    local font = Assets.getFont("main")
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("State: "    .. self.state   , 4, -4)
    love.graphics.print("Substate: " .. self.substate, 4, -4 + 32)
end

function Battle:draw()
    if self.encounter.background then
        self:drawBackground()
    end

    self:drawChildren()

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
    if menu_item.tp and menu_item.tp > self.tension_bar.tension then
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

function Battle:commitSpell(menu_item, target)
    self.party[self.current_selecting]:setAnimation("battle/spell_ready")
    local box = self.battle_ui.action_boxes[self.current_selecting]
    box.head_sprite:setSprite(box.battler.chara.head_icons.."/magic")
    self.tension_bar:removeTension(menu_item.tp)
    table.insert(self.character_actions,
    {
        ["character_id"] = self.current_selecting,
        ["action"] = "SPELL",
        ["party"] = menu_item.party,
        ["name"] = menu_item.name,
        ["target"] = target,
        ["data"] = menu_item.data
    })
    if menu_item.party then
        for _,v in ipairs(menu_item.party) do
            table.insert(self.character_actions,
                {
                    ["character_id"] = self:getPartyIndex(v),
                    ["action"] = "SKIP",
                }
            )
        end
    end
    self:nextParty()
end

function Battle:keypressed(key)
    print("KEY PRESSED: " .. key .. " IN STATE " .. self.state)

    if true then -- TODO: DEBUG
        if key == "g" then
            self.party[self.current_selecting]:hurt(1)
        end
    end

    if self.state == "MENUSELECT" then
        local menu_width = 2
        local menu_height = math.ceil(#self.menu_items / 2)

        if key == "z" then
            if self.state_reason == "ACT" then
                local menu_item = self.menu_items[self:getItemIndex()]
                if self:canSelectMenuItem(menu_item) then
                    self.tension_bar:removeTension(menu_item.tp)
                    self.ui_select:stop()
                    self.ui_select:play()

                    table.insert(self.character_actions,
                        {
                            ["character_id"] = self.current_selecting,
                            ["action"] = "ACT",
                            ["party"] = menu_item.party,
                            ["name"] = menu_item.name,
                            ["target"] = self.enemies[self.selected_enemy]
                        }
                    )
                    if menu_item.party then
                        for _,v in ipairs(menu_item.party) do
                            table.insert(self.character_actions,
                                {
                                    ["character_id"] = self:getPartyIndex(v),
                                    ["action"] = "SKIP",
                                }
                            )
                        end
                    end
                    self:nextParty()
                end
                return
            elseif self.state_reason == "SPELLS" then
                local menu_item = self.menu_items[self:getItemIndex()]
                self.selected_spell = self.menu_items[self:getItemIndex()]
                if self:canSelectMenuItem(menu_item) then
                    self.ui_select:stop()
                    self.ui_select:play()
                    if not menu_item.data.target then
                        self:commitSpell(menu_item, nil)
                    elseif menu_item.data.target == "enemy" then
                        Game.battle:setState("ENEMYSELECT", "SPELL")
                    elseif menu_item.data.target == "party" then
                        Game.battle:setState("PARTYSELECT", "SPELL")
                    end
                end
                return
            end
        elseif key == "x" then
            self.ui_move:stop()
            self.ui_move:play()
            self:setState("ACTIONSELECT", "CANCEL")
            return
        elseif key == "left" then -- TODO: pagination... also rewrite this code, im so sorry
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
        if key == "z" then
            self.ui_select:stop()
            self.ui_select:play()
            self.selected_enemy = self.current_menu_y
            if self.state_reason == "SPARE" then
                table.insert(self.character_actions,
                    {
                        ["character_id"] = self.current_selecting,
                        ["action"] = "SPARE",
                        ["target"] = self.enemies[self.selected_enemy]
                    }
                )
                self:nextParty()
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
                self.party[self.current_selecting]:setAnimation("battle/attack_ready")
                self.battle_ui.action_boxes[self.current_selecting].head_sprite:setSprite(self.battle_ui.action_boxes[self.current_selecting].battler.chara.head_icons.."/fight")
                table.insert(self.character_actions,
                    {
                        ["character_id"] = self.current_selecting,
                        ["action"] = "ATTACK",
                        ["target"] = self.enemies[self.selected_enemy]
                    }
                )
                self:nextParty()
            elseif self.state_reason == "SPELL" then
                self:commitSpell(self.selected_spell, self.enemies[self.selected_enemy])
            else
                self:nextParty()
            end
            return
        end
        if key == "x" then
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
        if key == "z" then
            self.ui_select:stop()
            self.ui_select:play()
            if self.state_reason == "SPELL" then
                self:commitSpell(self.selected_spell, self.party[self.current_menu_y])
            else
                self:nextParty()
            end
            return
        end
        if key == "x" then
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
        if key == "z" then
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
        if key == "z" then
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
            -- If all dialogue is done, go to DEFENDING state
            if all_done then
                self:setState("ACTIONSELECT")
            end
        end
    elseif self.state == "ACTIONSELECT" then
        -- TODO: make this less huge!!
        if key == "z" then
            self.battle_ui.action_boxes[self.current_selecting]:select()
            self.ui_select:stop()
            self.ui_select:play()
            return
        elseif key == "x" then
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
    end
end

return Battle