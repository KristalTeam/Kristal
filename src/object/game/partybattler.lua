local PartyBattler, super = Class(Object)

function PartyBattler:init(chara, x, y)
    super:init(self, x, y, chara.width, chara.height)

    self.info = chara

    self.layer = -10

    self.sprite = CharacterSprite(self.info)
    self.sprite.facing = "right"

    self.defending = false

    self:addChild(self.sprite)

    self:setOrigin(0.5, 1)
    self:setScale(2)

    -- default to the idle animation, handle the battle intro elsewhere
    self:setBattleSprite("idle", 1/5, true)
end

function PartyBattler:setActSprite(sprite, ox, oy, speed, loop, after)

    self:setCustomSprite(sprite, ox, oy, speed, loop, after)

    local x = self.x - (self.info.width/2 + ox) * 2
    local y = self.y - (self.info.height + oy) * 2
    local flash = FlashFade(sprite, x, y)
    flash:setOrigin(0, 0)
    flash:setScale(self:getScale())
    self.parent:addChild(flash)

    local afterimage1 = AfterImage(self, 0.5)
    local afterimage2 = AfterImage(self, 0.6)
    afterimage1.speed_x = 2.5
    afterimage2.speed_x = 5

    afterimage2.layer = afterimage1.layer - 1

    self:addChild(afterimage1)
    self:addChild(afterimage2)
end

function PartyBattler:setBattleSprite(sprite, speed, loop, after)
    if self.info.battle and self.info.battle[sprite] then
        self:setSprite(self.info.battle[sprite], speed, loop, after)
    end
end

function PartyBattler:setSprite(sprite, speed, loop, after)
    self.sprite:setSprite(sprite)
    if not self.sprite.directional then
        self.sprite:play(speed or (1/15), loop, false, after)
    end
end

function PartyBattler:setCustomSprite(sprite, ox, oy, speed, loop, after)
    self.sprite:setCustomSprite(sprite, ox, oy)
    if not self.sprite.directional then
        self.sprite:play(speed or (1/15), loop, false, after)
    end
end

return PartyBattler