local ActionBoxDisplay, super = Class(Object)

function ActionBoxDisplay:init(actbox, x, y)
    super:init(self, x, y)

    self.font = Assets.getFont("smallnumbers")

    self.actbox = actbox
end

function ActionBoxDisplay:draw()
    if Game.battle.current_selecting == self.actbox.index then
        love.graphics.setColor(self.actbox.battler.chara.color)
    else
        love.graphics.setColor(51/255, 32/255, 51/255, 1)
    end

    love.graphics.setLineWidth(2)
    love.graphics.line(0  , 1, 213, 1 )

    if Game.battle.current_selecting ~= self.actbox.index then
        love.graphics.setColor(0, 0, 0, 1)
    end

    love.graphics.setLineWidth(2)
    love.graphics.line(1  , 2, 1,   37)
    love.graphics.line(212, 2, 212, 37)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 2, 2, 209, 35)

    love.graphics.setColor(128/255, 0, 0, 1)
    love.graphics.rectangle("fill", 128, 22 - self.actbox.data_offset, 76, 9)

    local health = (self.actbox.battler.chara.health / self.actbox.battler.chara:getStat("health")) * 76

    if health > 0 then
        love.graphics.setColor(self.actbox.battler.chara.color)
        love.graphics.rectangle("fill", 128, 22 - self.actbox.data_offset, health, 9)
    end


    if health <= 0 then
        love.graphics.setColor(1, 0, 0, 1)
    elseif (self.actbox.battler.chara.health <= (self.actbox.battler.chara:getStat("health") / 4)) then
        love.graphics.setColor(1, 1, 0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end


    local health_offset = 0
    health_offset = (#tostring(self.actbox.battler.chara.health) - 1) * 8

    love.graphics.setFont(self.font)
    love.graphics.print(self.actbox.battler.chara.health, 152 - health_offset, 9 - self.actbox.data_offset)
    love.graphics.print("/", 161, 9 - self.actbox.data_offset)
    love.graphics.print(self.actbox.battler.chara:getStat("health"), 181, 9 - self.actbox.data_offset)

    super:draw(self)
end

return ActionBoxDisplay