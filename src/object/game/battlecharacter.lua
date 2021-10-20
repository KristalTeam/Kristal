local BattleCharacter, super = Class(Object)

function BattleCharacter:init(chara, x, y)
    super:init(self, x, y, chara.width, chara.height)

    self.info = chara

    self.sprite = CharacterSprite(self.info)
    self.sprite.facing = "right"
    self:addChild(self.sprite)

    self:setOrigin(0.5, 1)
    self:setScale(2)

    -- default to the idle animation, handle the battle intro elsewhere
    self:setBattleSprite("idle", 1/5, true)
end

function BattleCharacter:setBattleSprite(sprite, speed, loop)
    if self.info.battle and self.info.battle[sprite] then
        self:setSprite(self.info.battle[sprite], speed, loop)
    end
end

function BattleCharacter:setSprite(sprite, speed, loop)
    self.sprite:setSprite(sprite)
    if not self.sprite.directional then
        self.sprite:play(speed or (1/15), loop)
    end
end

return BattleCharacter