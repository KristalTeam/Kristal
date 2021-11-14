local OverworldActionBox, super = Class(Object)

function OverworldActionBox:init(x, y, index, chara)
    super:init(self, x, y)

    self.index = index
    self.chara = chara

    self.head_sprite = Sprite(chara.head_icons.."/head", 13, 12)
    self.name_sprite = Sprite(chara.name_sprite,         51, 16)
    self.hp_sprite   = Sprite("ui/hp", 109, 24)

    self:addChild(self.head_sprite)
    self:addChild(self.name_sprite)
    self:addChild(self.hp_sprite)

    self.font = Assets.getFont("smallnumbers")

    self.usecolor = false
end

function OverworldActionBox:setHeadIcon(icon)
    self.head_sprite:setSprite(self.chara.head_icons.."/"..icon)
end

function OverworldActionBox:draw()
    -- Draw the line at the top
    if self.usecolor then
        love.graphics.setColor(self.chara.color)
    else
        love.graphics.setColor(51/255, 32/255, 51/255, 1)
    end

    love.graphics.setLineWidth(2)
    love.graphics.line(0, 1, 213, 1)


    -- Draw health
    love.graphics.setColor(128/255, 0, 0, 1)
    love.graphics.rectangle("fill", 128, 24, 76, 9)

    local health = (self.chara.health / self.chara.stats.health) * 76

    if health > 0 then
        love.graphics.setColor(self.chara.color)
        love.graphics.rectangle("fill", 128, 24, health, 9)
    end

    if health <= 0 then
        love.graphics.setColor(1, 0, 0, 1)
    elseif (self.chara.health <= (self.chara.stats.health / 4)) then
        love.graphics.setColor(1, 1, 0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end


    local health_offset = 0
    health_offset = (#tostring(self.chara.health) - 1) * 8

    love.graphics.setFont(self.font)
    love.graphics.print(self.chara.health, 152 - health_offset, 11)
    love.graphics.print("/", 161, 11)
    love.graphics.print(self.chara.stats.health, 181, 11)

    super:draw(self)
end

return OverworldActionBox