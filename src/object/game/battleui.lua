local BattleUI, super = Class(Object)

function BattleUI:init()
    super:init(self, 0, 480)

    self.encounter_text = DialogueText(Game.battle.encounter.text, 30, 53)
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

    self.animation_timer = 0

    self.heart_sprite = Assets.getTexture("player/heart")
end

function BattleUI:update(dt)
    self.animation_timer = self.animation_timer + (dt * 30)
    if self.animation_timer > 12 then
        self.animation_timer = 12
    end

    self.y = Ease.outCubic(self.animation_timer, 480, 325 - 480, 12)

    -- TODO: MAKE THE PLATE SLIDE IN USING THE LAST "30FPS FRAME"'S Y https://owo.whats-th.is/9WZ3uU3.png

    self:updateChildren(dt)
end

function BattleUI:draw()
    self:drawActionArena()
    self:drawActionStrip()
    self:drawChildren()
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
            if item.party then
                for index, party_id in ipairs(item.party) do
                    local party_member = Game.battle.party[Game.battle:getPartyIndex(party_id)]
                    --             love.graphics.draw(Assets.getTexture("party/" .. self.battler.actor.id .. "/icon/head"), 12, 11 - self.box_y_offset)
                    --if party_member then
                    --    love.graphics.draw(party_member.sprite, x + (index - 1) * 30, y)
                    --end
                    love.graphics.draw(Assets.getTexture("party/" .. party_member.actor.id .. "/icon/head"), text_offset + 30 + (x * 230), 50 + (y * 30))
                    text_offset = text_offset + 30
                end
            end

            love.graphics.setColor(item.color)
            love.graphics.print(item.name, text_offset + 30 + (x * 230), 50 + (y * 30))
            if x == 0 then
                x = 1
            else
                x = 0
                y = y + 1
            end
        end
    elseif Game.battle.state == "ENEMYSELECT" then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(self.heart_sprite, 55, 30 + (Game.battle.current_menu_y * 30))

        local font = Assets.getFont("main")
        love.graphics.setFont(font)
        for index, enemy in ipairs(Game.battle.enemies) do
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
                love.graphics.draw(canvas, 80, 50 + ((index - 1) * 30))
                -- Disable the shader
                love.graphics.setShader()
            elseif enemy.tired then
                love.graphics.setColor(0, 178/255, 1, 1)
                love.graphics.print(enemy.name, 80, 50 + ((index - 1) * 30))
            elseif enemy.mercy >= 100 then
                love.graphics.setColor(1, 1, 0, 1)
                love.graphics.print(enemy.name, 80, 50 + ((index - 1) * 30))
            else
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(enemy.name, 80, 50 + ((index - 1) * 30))
            end
        end
    end
end

return BattleUI