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