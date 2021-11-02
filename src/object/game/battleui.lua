local BattleUI, super = Class(Object)

function BattleUI:init()
    super:init(self, 0, 480)

    self.encounter_text = DialogueText(Game.battle.encounter.text, 30, 53, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53)
    self.current_encounter_text = Game.battle.encounter.text
    self:addChild(self.encounter_text)

    self.action_boxes = {}

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

    self.animation_timer = 0

    self.heart_sprite = Assets.getTexture("player/heart")
end

function BattleUI:update(dt)
    self.animation_timer = self.animation_timer + (dt * 30)

    if self.animation_timer > 13 then
        self.animation_timer = 13
    end

    self.y = Ease.outCubic(math.min(12, self.animation_timer), 480, 325 - 480, 12)

    local offset = self.y - Ease.outCubic(self.animation_timer - 1, 480, 325 - 480, 12)

    for _, box in ipairs(self.action_boxes) do
        box.data_offset = offset
    end

    super:update(self, dt)
end

function BattleUI:draw()
    self:drawActionArena()
    self:drawActionStrip()
    super:draw(self)
end

function BattleUI:drawActionStrip()
    -- Draw the top line of the action strip
    love.graphics.setColor(51/255, 32/255, 51/255, 1)
    love.graphics.rectangle("fill", 0, 0, 640, 2)
    -- Draw the background of the action strip
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 2, 640, 35)
end

function BattleUI:drawActionArena()
    -- Draw the top line of the action area
    love.graphics.setColor(51/255, 32/255, 51/255, 1)
    love.graphics.rectangle("fill", 0, 37, 640, 3)
    -- Draw the background of the action area
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 40, 640, 115)
    self:drawState()
end

function BattleUI:drawState()
    if Game.battle.state == "MENUSELECT" then
        local x = 0
        local y = 0
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(self.heart_sprite, 5 + ((Game.battle.current_menu_x - 1) * 230), 30 + (Game.battle.current_menu_y * 30))

        local font = Assets.getFont("main")
        love.graphics.setFont(font)
        for _, item in ipairs(Game.battle.menu_items) do
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
                    local chara = Registry.getPartyMember(party_id)

                    love.graphics.draw(Assets.getTexture(chara.head_icons .. "/head"), text_offset + 30 + (x * 230), 50 + (y * 30))
                    text_offset = text_offset + 30
                end
            end

            if able then
                love.graphics.setColor(item.color)
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

        if current_item.tp ~= 0 then
            love.graphics.setColor(255/255, 160/255, 64/255)
            love.graphics.print(math.floor((current_item.tp / Game.battle.max_tension) * 100) .. "% TP", 260 + 240, 50 + (tp_offset * 32))
        end

    elseif Game.battle.state == "ENEMYSELECT" then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(self.heart_sprite, 55, 30 + (Game.battle.current_menu_y * 30))

        local font = Assets.getFont("main")
        love.graphics.setFont(font)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("HP", 424, 39, 0, 1, 0.5)
        love.graphics.print("MERCY", 524, 39, 0, 1, 0.5)

        for index, enemy in ipairs(Game.battle.enemies) do
            local y_off = (index - 1) * 30
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
            elseif enemy.tired then
                love.graphics.setColor(0, 178/255, 1, 1)
                love.graphics.print(enemy.name, 80, 50 + y_off)
            elseif enemy.mercy >= 100 then
                love.graphics.setColor(1, 1, 0, 1)
                love.graphics.print(enemy.name, 80, 50 + y_off)
            else
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(enemy.name, 80, 50 + y_off)
            end

            local hp_percent = enemy.health / enemy.max_health

            -- Draw the enemy's HP
            love.graphics.setColor(128/255, 0, 0, 1)
            love.graphics.rectangle("fill", 420, 55 + y_off, 81, 16)

            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle("fill", 420, 55 + y_off, (hp_percent * 81), 16)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(math.floor(hp_percent * 100) .. "%", 424, 55 + y_off, 0, 1, 0.5)

            -- Draw the enemy's MERCY
            love.graphics.setColor(255/255, 80/255, 32/255, 1)
            love.graphics.rectangle("fill", 520, 55 + y_off, 81, 16)

            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.rectangle("fill", 520, 55 + y_off, ((enemy.mercy / 100) * 81), 16)

            love.graphics.setColor(128/255, 0, 0, 1)
            love.graphics.print(math.floor(enemy.mercy) .. "%", 524, 55 + y_off, 0, 1, 0.5)
        end
    elseif Game.battle.state == "PARTYSELECT" then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(self.heart_sprite, 55, 30 + (Game.battle.current_menu_y * 30))

        local font = Assets.getFont("main")
        love.graphics.setFont(font)
        for index, battler in ipairs(Game.battle.party) do
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(battler.chara.name, 80, 50 + ((index - 1) * 30))
        end
    end
end

return BattleUI