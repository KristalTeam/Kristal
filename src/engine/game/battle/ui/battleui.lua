local BattleUI, super = Class(Object)

function BattleUI:init()
    super:init(self, 0, 480)

    self.layer = BATTLE_LAYERS["ui"]

    self.current_encounter_text = Game.battle.encounter.text

    self.encounter_text = Textbox(30, 53, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53, "main_mono", nil, true)
    self.encounter_text.text.line_offset = 0
    self.encounter_text:setText(self.current_encounter_text)
    self:addChild(self.encounter_text)

    self.choice_box = Choicebox(56, 49, 529, 103, true)
    self.choice_box.active = false
    self.choice_box.visible = false
    self:addChild(self.choice_box)

    self.short_act_text_1 = DialogueText("", 30, 53, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53)
    self.short_act_text_2 = DialogueText("", 30, 53 + 30, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53)
    self.short_act_text_3 = DialogueText("", 30, 53 + 30 + 30, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53)
    self:addChild(self.short_act_text_1)
    self:addChild(self.short_act_text_2)
    self:addChild(self.short_act_text_3)


    self.action_boxes = {}
    self.attack_boxes = {}

    local size_offset = 0
    if #Game.battle.party == 3 then
        size_offset = 0
    elseif #Game.battle.party == 2 then
        size_offset = 108
    elseif #Game.battle.party == 1 then
        size_offset = 213
    end


    for index,battler in ipairs(Game.battle.party) do
        local action_box = ActionBox(size_offset + (index - 1) * 213, 0, index, battler)
        self:addChild(action_box)
        table.insert(self.action_boxes, action_box)
    end

    self.parallax_x = 0
    self.parallax_y = 0

    self.animation_done = false
    self.animation_timer = 0
    self.animate_out = false

    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow_down")

    self.sparestar = Assets.getTexture("ui/battle/sparestar")
    self.tiredmark = Assets.getTexture("ui/battle/tiredmark")
end

function BattleUI:clearEncounterText()
    self.encounter_text:setActor(nil)
    self.encounter_text:setFace(nil)
    self.encounter_text:setFont()
    self.encounter_text:setSkippable(true)
    self.encounter_text:setAdvance(true)
    self.encounter_text:setAuto(false)
    self.encounter_text:setText("")
end

function BattleUI:beginAttack()
    local attack_order = Utils.pickMultiple(Game.battle.attackers, #Game.battle.attackers)

    local last_offset = -1
    local offset = 0
    for i = 1, #attack_order do
        offset = offset + last_offset

        local battler = attack_order[i]
        local attack_box = AttackBox(battler, 30 + offset, 0, 40 + (38 * (Game.battle:getPartyIndex(battler.chara.id) - 1)))
        self:addChild(attack_box)
        table.insert(self.attack_boxes, attack_box)

        if i < #attack_order and last_offset ~= 0 then
            last_offset = Utils.pick{0, 10, 15}
        else
            last_offset = Utils.pick{10, 15}
        end
    end
end

function BattleUI:endAttack()
    Game.battle.cancel_attack = false
    for _,box in ipairs(self.attack_boxes) do
        box:remove()
    end
    self.attack_boxes = {}
end

function BattleUI:transitionOut()
    -- TODO: Accurate transition-out animation
    self.animate_out = true
    self.animation_timer = 0
    self.animation_done = false
end

function BattleUI:update()
    self.animation_timer = self.animation_timer + DTMULT

    local max_time = self.animate_out and 6 or 12

    if self.animation_timer > max_time + 1 then
        self.animation_done = true
        self.animation_timer = max_time + 1
    end

    local offset
    if not self.animate_out then
        self.y = Ease.outCubic(math.min(max_time, self.animation_timer), 480, 325 - 480, max_time)
        offset = self.y - Ease.outCubic(self.animation_timer - 1, 480, 325 - 480, max_time)
    else
        self.y = Ease.outCubic(math.min(max_time, self.animation_timer), 325, 480 - 325, max_time)
        offset = self.y - Ease.outCubic(math.max(0, self.animation_timer - 1), 325, 480 - 325, max_time)
    end

    for _, box in ipairs(self.action_boxes) do
        box.data_offset = offset
    end

    super:update(self)
end

function BattleUI:draw()
    self:drawActionArena()
    self:drawActionStrip()
    super:draw(self)
end

function BattleUI:drawActionStrip()
    -- Draw the top line of the action strip
    love.graphics.setColor(PALETTE["action_strip"])
    love.graphics.rectangle("fill", 0, 0, 640, 2)
    -- Draw the background of the action strip
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 2, 640, 35)
end

function BattleUI:drawActionArena()
    -- Draw the top line of the action area
    love.graphics.setColor(PALETTE["action_strip"])
    love.graphics.rectangle("fill", 0, 37, 640, 3)
    -- Draw the background of the action area
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 40, 640, 115)
    self:drawState()
end

function BattleUI:drawState()
    if Game.battle.state == "MENUSELECT" then
        local page = math.ceil(Game.battle.current_menu_y / 3) - 1
        local max_page = math.ceil(#Game.battle.menu_items / 6) - 1

        local x = 0
        local y = 0
        love.graphics.setColor(Game:getSoulColor())
        love.graphics.draw(self.heart_sprite, 5 + ((Game.battle.current_menu_x - 1) * 230), 30 + ((Game.battle.current_menu_y - (page*3)) * 30))

        local font = Assets.getFont("main")
        love.graphics.setFont(font)

        local page_offset = page * 6
        for i = page_offset+1, math.min(page_offset+6, #Game.battle.menu_items) do
            local item = Game.battle.menu_items[i]

            love.graphics.setColor(1, 1, 1, 1)
            local text_offset = 0
            -- Are we able to select this?
            local able = Game.battle:canSelectMenuItem(item)
            if item.party then
                if not able then
                    -- We're not able to select this, so make the heads gray.
                    love.graphics.setColor(COLORS.gray)
                end

                for index, party_id in ipairs(item.party) do
                    local chara = Game:getPartyMember(party_id)

                    -- Draw head only if it isn't the currently selected character
                    if Game.battle:getPartyIndex(party_id) ~= Game.battle.current_selecting then
                        local ox, oy = chara:getHeadIconOffset()
                        love.graphics.draw(Assets.getTexture(chara:getHeadIcons() .. "/head"), text_offset + 30 + (x * 230) + ox, 50 + (y * 30) + oy)
                        text_offset = text_offset + 30
                    end
                end
            end

            if able then
                love.graphics.setColor(item.color or {1, 1, 1, 1})
            else
                love.graphics.setColor(COLORS.gray)
            end
            love.graphics.print(item.name, text_offset + 30 + (x * 230), 50 + (y * 30))
            if x == 0 then
                x = 1
            else
                x = 0
                y = y + 1
            end
        end

        -- Print information about currently selected item
        local tp_offset = 0
        local current_item = Game.battle.menu_items[Game.battle:getItemIndex()]
        if current_item.description then
            love.graphics.setColor(COLORS.gray)
            love.graphics.print(current_item.description, 260 + 240, 50)
            love.graphics.setColor(1, 1, 1, 1)
            _, tp_offset = current_item.description:gsub('\n', '\n')
            tp_offset = tp_offset + 1
        end

        if current_item.tp and current_item.tp ~= 0 then
            love.graphics.setColor(255/255, 160/255, 64/255)
            love.graphics.print(math.floor((current_item.tp / Game.battle.tension_bar:getMaxTension()) * 100) .. "% TP", 260 + 240, 50 + (tp_offset * 32))
            Game.battle.tension_bar:setTensionPreview(current_item.tp)
        else
            Game.battle.tension_bar:setTensionPreview(0)
        end

        love.graphics.setColor(1, 1, 1, 1)
        if page < max_page then
            love.graphics.draw(self.arrow_sprite, 470, 120 + (math.sin(love.timer.getTime()*6) * 2))
        end
        if page > 0 then
            love.graphics.draw(self.arrow_sprite, 470, 70 - (math.sin(love.timer.getTime()*6) * 2), 0, 1, -1)
        end

    elseif Game.battle.state == "ENEMYSELECT" or Game.battle.state == "XACTENEMYSELECT" then
        local enemies = Game.battle:getActiveEnemies()

        local page = math.ceil(Game.battle.current_menu_y / 3) - 1
        local max_page = math.ceil(#enemies / 3) - 1
        local page_offset = page * 3

        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(self.heart_sprite, 55, 30 + ((Game.battle.current_menu_y - page_offset) * 30))

        local font = Assets.getFont("main")
        love.graphics.setFont(font)

        love.graphics.setColor(1, 1, 1, 1)
        if Game.battle.state == "ENEMYSELECT" then
            love.graphics.print("HP", 424, 39, 0, 1, 0.5)
        end
        love.graphics.print("MERCY", 524, 39, 0, 1, 0.5)

        for index = page_offset+1, math.min(page_offset+3, #enemies) do
            local enemy = enemies[index]
            local y_off = (index - page_offset - 1) * 30
            local spare_icon = false
            local tired_icon = false
            if enemy.tired and (enemy.mercy >= 100) then
                love.graphics.setColor(1, 1, 1, 1)

                -- Draw the enemy name to a canvas first
                local canvas = Draw.pushCanvas(font:getWidth(enemy.name), font:getHeight())
                love.graphics.print(enemy.name)
                Draw.popCanvas()

                -- Use the horizontal gradient shader for the spare/tired color
                local shader = Kristal.Shaders["GradientH"]
                love.graphics.setShader(shader)
                shader:send("from", {1, 1, 0, 1}) -- Left color: Spare
                shader:send("to", {0, 0.7, 1, 1}) -- Right color: Tired
                -- Draw the canvas from before to apply the gradient over it
                love.graphics.draw(canvas, 80, 50 + y_off)
                -- Disable the shader
                love.graphics.setShader()

                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(self.sparestar, 80 + font:getWidth(enemy.name) + 20, 60 + y_off)
                love.graphics.draw(self.tiredmark, 80 + font:getWidth(enemy.name) + 40, 60 + y_off)
                spare_icon = true
                tired_icon = true
            elseif enemy.tired then
                love.graphics.setColor(0, 178/255, 1, 1)
                love.graphics.print(enemy.name, 80, 50 + y_off)

                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(self.tiredmark, 80 + font:getWidth(enemy.name) + 40, 60 + y_off)
                tired_icon = true
            elseif enemy.mercy >= 100 then
                love.graphics.setColor(1, 1, 0, 1)
                love.graphics.print(enemy.name, 80, 50 + y_off)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(self.sparestar, 80 + font:getWidth(enemy.name) + 20, 60 + y_off)
                spare_icon = true
            else
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(enemy.name, 80, 50 + y_off)
            end

            for i = 1, #enemy.icons do
                if enemy.icons[i] then
                    if (spare_icon and (i == 1)) or (tired_icon and (i == 2)) then
                        -- Skip the custom icons if we're already drawing spare/tired ones
                    else
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.draw(enemy.icons[i], 80 + font:getWidth(enemy.name) + (i * 20), 60 + y_off)
                    end
                end
            end

            if Game.battle.state == "XACTENEMYSELECT" then
                love.graphics.setColor(Game.battle.party[Game.battle.current_selecting].chara:getXActColor())
                if Game.battle.selected_xaction.id == 0 then
                    love.graphics.print(enemy:getXAction(Game.battle.party[Game.battle.current_selecting]), 282, 50 + y_off)
                else
                    love.graphics.print(Game.battle.selected_xaction.name, 282, 50 + y_off)
                end
            end

            if Game.battle.state == "ENEMYSELECT" then
                local namewidth = font:getWidth(enemy.name)

                love.graphics.setColor(128/255, 128/255, 128/255, 1)

                if ((80 + namewidth + 60 + (font:getWidth(enemy.comment) / 2)) < 415) then
                    love.graphics.print(enemy.comment, 80 + namewidth + 60, 50 + y_off)
                else
                    love.graphics.print(enemy.comment, 80 + namewidth + 60, 50 + y_off, 0, 0.5, 1)
                end


                local hp_percent = enemy.health / enemy.max_health

                -- Draw the enemy's HP
                love.graphics.setColor(128/255, 0, 0, 1)
                love.graphics.rectangle("fill", 420, 55 + y_off, 81, 16)

                love.graphics.setColor(0, 1, 0, 1)
                love.graphics.rectangle("fill", 420, 55 + y_off, (hp_percent * 81), 16)

                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(math.floor(hp_percent * 100) .. "%", 424, 55 + y_off, 0, 1, 0.5)
            end

            -- Draw the enemy's MERCY
            love.graphics.setColor(255/255, 80/255, 32/255, 1)
            love.graphics.rectangle("fill", 520, 55 + y_off, 81, 16)

            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.rectangle("fill", 520, 55 + y_off, ((enemy.mercy / 100) * 81), 16)

            love.graphics.setColor(128/255, 0, 0, 1)
            love.graphics.print(math.floor(enemy.mercy) .. "%", 524, 55 + y_off, 0, 1, 0.5)
        end

        love.graphics.setColor(1, 1, 1, 1)
        if page < max_page then
            love.graphics.draw(self.arrow_sprite, 20, 120 + (math.sin(love.timer.getTime()*6) * 2))
        end
        if page > 0 then
            love.graphics.draw(self.arrow_sprite, 20, 70 - (math.sin(love.timer.getTime()*6) * 2), 0, 1, -1)
        end
    elseif Game.battle.state == "PARTYSELECT" then
        local page = math.ceil(Game.battle.current_menu_y / 3) - 1
        local max_page = math.ceil(#Game.battle.party / 3) - 1
        local page_offset = page * 3

        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(self.heart_sprite, 55, 30 + ((Game.battle.current_menu_y - page_offset) * 30))

        local font = Assets.getFont("main")
        love.graphics.setFont(font)

        for index = page_offset+1, math.min(page_offset+3, #Game.battle.party) do
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(Game.battle.party[index].chara:getName(), 80, 50 + ((index - page_offset - 1) * 30))

            love.graphics.setColor(128 / 255, 0, 0, 1)
            love.graphics.rectangle("fill", 400, 55 + ((index - page_offset - 1) * 30), 101, 16)

            local percentage = Game.battle.party[index].chara.health / Game.battle.party[index].chara:getStat("health")
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle("fill", 400, 55 + ((index - page_offset - 1) * 30), percentage * 101, 16)
        end

        love.graphics.setColor(1, 1, 1, 1)
        if page < max_page then
            love.graphics.draw(self.arrow_sprite, 20, 120 + (math.sin(love.timer.getTime()*6) * 2))
        end
        if page > 0 then
            love.graphics.draw(self.arrow_sprite, 20, 70 - (math.sin(love.timer.getTime()*6) * 2), 0, 1, -1)
        end
    end
    if Game.battle.state == "ATTACKING" or #self.attack_boxes > 0 then
        love.graphics.setColor(0, 0, 0.5)
        love.graphics.rectangle("fill", 79, 78, 224, 2)
        love.graphics.rectangle("fill", 79, 116, 224, 2)
    end
end

return BattleUI