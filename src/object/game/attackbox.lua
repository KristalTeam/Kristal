local AttackBox, super = Class(Object)

function AttackBox:init(battler, x, y)
    super:init(self, x, y)

    self.battler = battler

    self.head_sprite = Sprite(battler.chara.head_icons.."/head", 21, 19)
    self.head_sprite:setOrigin(0.5, 0.5)
    self:addChild(self.head_sprite)

    self.press_sprite = Sprite("ui/battle/press", 42, 0)
    self:addChild(self.press_sprite)
end

function AttackBox:draw()
    local target_color = self.battler.chara.attack_bar_color or self.battle.chara.color
    local box_color = self.battler.chara.attack_box_color or Utils.lerp(target_color, {0, 0, 0}, 0.5)

    love.graphics.setLineWidth(2)
    love.graphics.setLineStyle("rough")

    love.graphics.setColor(box_color)
    love.graphics.rectangle("line", 80, 1, 123, 36)
    love.graphics.setColor(target_color)
    love.graphics.rectangle("line", 83, 1, 8, 36)

    love.graphics.setLineWidth(1)

    super:draw(self)
end

return AttackBox