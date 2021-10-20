local BattleUI, super = Class(Object)

function BattleUI:init()
    super:init(self, 0, 480)

    self.encounter_text = DialogueText("* Smorgasbord 3.", 30, 53)
    self:addChild(self.encounter_text)

    self.action_boxes = {}

    for index,battler in ipairs(Game.battle.party) do
        local action_box = ActionBox((index - 1) * 213, 0, index, battler)
        self:addChild(action_box)
        table.insert(self.action_boxes, action_box)
    end

    self.animation_timer = 0
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
end

return BattleUI