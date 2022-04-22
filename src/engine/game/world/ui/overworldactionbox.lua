local OverworldActionBox, super = Class(Object)

function OverworldActionBox:init(x, y, index, chara)
    super:init(self, x, y)

    self.index = index
    self.chara = chara

    self.head_sprite = Sprite(chara:getHeadIcons().."/head", 13, 13)
    self.name_sprite = Sprite(chara:getNameSprite(),         51, 16)
    self.hp_sprite   = Sprite("ui/hp", 109, 24)

    local ox, oy = chara:getHeadIconOffset()
    self.head_sprite.x = self.head_sprite.x + ox
    self.head_sprite.y = self.head_sprite.y + oy

    self:addChild(self.head_sprite)
    self:addChild(self.name_sprite)
    self:addChild(self.hp_sprite)

    self.font = Assets.getFont("smallnumbers")
    self.main_font = Assets.getFont("main")

    self.selected = false

    self.reaction_text = ""
    self.reaction_alpha = 0
end

function OverworldActionBox:setHeadIcon(icon)
    self.head_sprite:setSprite(self.chara:getHeadIcons().."/"..icon)
end

function OverworldActionBox:update()
    self.reaction_alpha = self.reaction_alpha - DTMULT
    super:update(self)
end

function OverworldActionBox:draw()
    -- Draw the line at the top
    if self.selected then
        love.graphics.setColor(self.chara:getColor())
    else
        love.graphics.setColor(PALETTE["action_strip"], 1)
    end

    love.graphics.setLineWidth(2)
    love.graphics.line(0, 1, 213, 1)

    -- Draw health
    love.graphics.setColor(128/255, 0, 0, 1)
    love.graphics.rectangle("fill", 128, 24, 76, 9)

    local health = (self.chara.health / self.chara:getStat("health")) * 76

    if health > 0 then
        love.graphics.setColor(self.chara:getColor())
        love.graphics.rectangle("fill", 128, 24, health, 9)
    end

    if health <= 0 then
        love.graphics.setColor(1, 0, 0, 1)
    elseif (self.chara.health <= (self.chara:getStat("health") / 4)) then
        love.graphics.setColor(1, 1, 0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    local health_offset = 0
    health_offset = (#tostring(self.chara.health) - 1) * 8

    love.graphics.setFont(self.font)
    love.graphics.print(self.chara.health, 152 - health_offset, 11)
    love.graphics.print("/", 161, 11)
    love.graphics.print(self.chara:getStat("health"), 181, 11)

    love.graphics.setFont(self.main_font)
    love.graphics.setColor(1, 1, 1, self.reaction_alpha / 6)
    love.graphics.print(self.reaction_text, -1, 43, 0, 0.5, 0.5)

    super:draw(self)
end

return OverworldActionBox