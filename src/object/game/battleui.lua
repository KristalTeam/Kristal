local BattleUI, super = Class(Object)

function BattleUI:init()
    super:init(self, 0, 480)

    self.encounter_text = DialogueText(Game.battle.encounter.text, 30, 53)
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
    if Game.battle.state == "ENEMYSELECT" then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(self.heart_sprite, 55, 30 + (Game.battle.current_menu_x * 30))

        love.graphics.setFont(Assets.getFont("main"))
        for index, enemy in ipairs(Game.battle.enemies) do
            if enemy.tired and enemy.canspare then
                love.graphics.setColor(1, 0, 0, 1) -- TODO: gradient!
                love.graphics.print("(add gradient) " .. enemy.name, 80, 50 + ((index - 1) * 30))
            elseif enemy.tired then
                love.graphics.setColor(0, 178/255, 1, 1)
                love.graphics.print(enemy.name, 80, 50 + ((index - 1) * 30))
            elseif enemy.canspare then
                love.graphics.setColor(0, 1, 1, 1)
                love.graphics.print(enemy.name, 80, 50 + ((index - 1) * 30))
            else
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(enemy.name, 80, 50 + ((index - 1) * 30))
            end
        end
    end
end

return BattleUI