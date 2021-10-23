local Virovirokun, super = Class(Encounter)

function Virovirokun:init()
    super:init(self)

    self.text = "* Virovirokun floated in!"

    self:addEnemy("virovirokun", 530, 148)
    self:addEnemy("virovirokun", 560, 262)
    --self:addEnemy("virovirokun")
    --self:addEnemy("virovirokun")

    self.background = true
    self.music = nil

    self.default_xactions = false

    Game.battle:registerXAction("susie", "Snap")
    Game.battle:registerXAction("susie", "Supercharge", "Charge faster", 80)
end

return Virovirokun