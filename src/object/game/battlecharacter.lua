local BattleCharacter, super = Class(Object)

function BattleCharacter:init(chara, x, y)
    super:init(self, x, y, chara.width, chara.height)

    self.info = chara

    self.sprite = CharacterSprite(self.info)
    self.sprite.facing = "right"
    self:addChild(self.sprite)

    self:setOrigin(0.5, 1)
    self:setScale(2)

    -- make sure the battle intro is a table with at least 1 sprite
    self.battle_intro = self.info.battle.intro or {self.info.default, self.info.battle.attack}
    if type(self.battle_intro == "string") then
        self.battle_intro = {self.battle_intro}
    end

    -- default to the idle animation, handle the battle intro elsewhere
    self:setBattleSprite("idle", 1/5, true)
end

function BattleCharacter:setBattleSprite(sprite, speed, loop)
    self:setSprite(self.info.battle[sprite], speed, loop)
end

function BattleCharacter:setSprite(sprite, speed, loop)
    self.sprite:setSprite(sprite)
    if not self.sprite.directional then
        self.sprite:play(speed or (1/15), loop)
    end
end

return BattleCharacter