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

    -- Create the player battler
    if Game.world.player then
        local player_x, player_y = Game.world.player:getScreenPos()
        local player_battler = PartyBattler(Game.world.player.info, player_x, player_y)
        player_battler:setBattleSprite("transition")
        self:addChild(player_battler)
        table.insert(self.party,player_battler)
        table.insert(self.party_beginning_positions, {player_x, player_y})

        Game.world.player.visible = false
    end

    for i = 1, 2 do
        local chara = Game.followers[i]
        if chara then
            local chara_x, chara_y = chara:getScreenPos()
            local chara_battler = PartyBattler(chara.info, chara_x, chara_y)
            chara_battler:setBattleSprite("transition")
            self:addChild(chara_battler)
            table.insert(self.party, chara_battler)
            table.insert(self.party_beginning_positions, {chara_x, chara_y})
            chara.visible = false
        end
    end

    self.intro_timer = 0
    self.offset = 0

    -- states: BATTLETEXT, TRANSITION, INTRO, ACTIONSELECT, ACTING, SPARING, USINGITEMS, ATTACKING, ENEMYDIALOGUE, DEFENDING
    -- ENEMYSELECT, MENUSELECT, XACTENEMYSELECT, PARTYSELECT

    self.state = "NONE"

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

    self.state_reason = nil

    self.menu_items = {}

    self.selected_enemy = 1

    self.current_acting = nil
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

            target_x = target_x + (battler.info.width/2 + battler.info.battle_offset[1]) * 2
            target_y = target_y + (battler.info.height  + battler.info.battle_offset[2]) * 2
            table.insert(self.battler_targets, {target_x, target_y})
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
            battler:setBattleSprite("intro", 1/15, true)
        end
    elseif new == "ACTIONSELECT" then
        if (old == "DEFENDING") or (old == "INTRO") or (self.current_selecting < 1) or (self.current_selecting > #self.party) then
            self.hit_count = {}
            self.current_selecting = 1
            self.current_button = 1
            if self.battle_ui then
                for _,box in ipairs(self.battle_ui.action_boxes) do
                    box.selected_button = 1
                end
                self.battle_ui.encounter_text:setText(self.battle_ui.current_encounter_text)
            end
            for _,battler in ipairs(self.party) do
                battler:setBattleSprite("idle", 1/5, true)
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

        --self.music:setLooping(true)
        --self.music:play()

        if not self.battle_ui then
            self.battle_ui = BattleUI()
            self:addChild(self.battle_ui)
        end
        if not self.tension_bar then
            self.tension_bar = TensionBar(-25, 40)
            self:addChild(self.tension_bar)
        end
    elseif new == "ACTING" then
        print("ENTERED ACTING STATE")
        if self.state_reason ~= "DONTPROCESS" then
            self:finishAct()
        end
        --self:BattleText("* You treated Virovirokun with\ncare! It's no longer\ninfectious!")
    elseif new == "ENEMYSELECT" then
        self.battle_ui.encounter_text:setText("")
        self.current_menu_y = 1
        self.selected_enemy = 1
    elseif new == "MENUSELECT" then
        self.battle_ui.encounter_text:setText("")
        self.current_menu_x = 1
        self.current_menu_y = 1
        self.menu_items = {}
    end
end

function Battle:registerXAction(...) print("TODO: implement!") end -- TODO

function Battle:finishAct()
    local battler = self.current_acting

    if battler.sprite.sprite == battler.info.battle.act then
        battler:setBattleSprite("act_end", 1/15, false, (function() battler:setBattleSprite("idle", 1/5, true) end))
    else
        battler:setBattleSprite("idle", 1/5, true)
    end

    self.current_acting = false
    self:processCharacterActions()
end

function Battle:processCharacterActions()
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
    print("ALL ACTIONS DONE, GO TO STATE")
    self:setState("ACTIONSELECT")
end

function Battle:processAction(action)
    local battler = self.party[action.character_id]
    print("PROCESSING " .. battler.info.name .. "'S ACTION " .. action.action)
    local enemy = action.target
    if action.action == "SPARE" then
        battler:setBattleSprite("spare", 1/15, false, (function() battler:setBattleSprite("idle", 1/5, true) end))
        local worked = enemy:onMercy()
        local text
        if worked then
            text = "* " .. battler.info.name .. " spared " .. enemy.name .. "!"
        else
            text = "* " .. battler.info.name .. " spared " .. enemy.name .. "!\n* But its name wasn't [color:yellow]YELLOW[color:reset]..."
            if enemy.tired then
                -- TODO: unhardcode!
                text = {text, "* (Try using Ralsei's [color:blue]PACIFY[color:reset]!)"}
                -- * (Try using Ralsei's [color:blue]PACIFY[color:reset]!)
                -- * (Try using Noelle's [color:blue]SLEEPMIST[color:reset]!)
                -- * (Try using [color:blue]ACT[color:reset]s!)
            end
        end
        self:BattleText(text,
            (function() self:processCharacterActions() end)
        )
    elseif action.action == "ATTACK" then
        battler:setBattleSprite("attack", 1/15, false)
        self:BattleText("* " .. battler.info.name .. " attacked " .. enemy.name .. "!\n* You will regret this",
            (function() self:processCharacterActions() end)
        )
    elseif action.action == "ACT" then
        battler:setBattleSprite("act", 1/15, false)
        self:setState("ACTING", "DONTPROCESS")
        print("LET'S TRY TO ACT!!!")
        print(action.name)
        self.current_acting = battler
        enemy:onAct(battler, action.name)
    elseif action.action == "SKIP" then
        print("skipped!")
        self:processCharacterActions()
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
        if battler.info.id == string_id then
            return index
        end
    end
end

function Battle:hasAction(character_id)
    for _,action in ipairs(self.character_actions) do
        if action.character_id == character_id then
            return true
        end
    end
    return false
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
        self:processCharacterActions()
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
    if self.state == "TRANSITION" then
        self:updateTransition(dt)
    elseif self.state == "INTRO" then
        self:updateIntro(dt)
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

function Battle:draw()
    if self.encounter.background then
        self:drawBackground()
    end

    self:drawChildren()
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

function Battle:keypressed(key)
    print("KEY PRESSED: " .. key .. " IN STATE " .. self.state)
    if self.state == "MENUSELECT" then
        local menu_width = 2
        local menu_height = math.ceil(#self.menu_items / 2)

        if key == "z" then
            self.ui_select:stop()
            self.ui_select:play()
            if self.state_reason == "ACT" then
                local menu_item = self.menu_items[2 * (self.current_menu_y - 1) + self.current_menu_x]
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
                if (self.current_menu_y + menu_width) > #self.menu_items then
                    self.current_menu_x = 1
                end
            end
        elseif key == "right" then
            self.current_menu_x = self.current_menu_x + 1
            if (self.current_menu_x > menu_width) or ((self.current_menu_y + menu_width) > #self.menu_items) then
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
            if (self.current_menu_y > menu_height) or ((self.current_menu_x + menu_height) > #self.menu_items) then
                self.current_menu_y = menu_height -- No wrapping in this menu.
                if (self.current_menu_x + menu_height) > #self.menu_items then
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
                self:setState("MENUSELECT", "ACT")
                local enemy = self.enemies[self.selected_enemy]
                for _,v in ipairs(enemy.acts) do
                    local item = {
                        ["name"] = v.name,
                        ["tp"] = 0,
                        ["party"] = v.party,
                        ["color"] = {1, 1, 1, 1}
                    }
                    table.insert(self.menu_items, item)
                end
            elseif self.state_reason == "ATTACK" then
                self.party[self.current_selecting]:setBattleSprite("attack_ready")
                table.insert(self.character_actions,
                    {
                        ["character_id"] = self.current_selecting,
                        ["action"] = "ATTACK",
                        ["target"] = self.enemies[self.selected_enemy]
                    }
                )
                self:nextParty()
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
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = #self.enemies
            end
        elseif key == "down" then
            self.current_menu_y = self.current_menu_y + 1
            if self.current_menu_y > #self.enemies then
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