local Virovirokun, super = Class("virovirokun", true)

function Virovirokun:init()
    super:init(self)

    if Game:getPartyMember("susie"):getFlag("auto_attack") then
        self:registerAct("Warning")
    end

    self.susie_warned = false
end

function Virovirokun:onAct(battler, name)
    if name == "Warning" then
        self.susie_warned = true
        self.comment = "(Warned)"
        return "* You told Virovirokun to watch out for Susie's attacks.[wait:5]\n* It went on guard."
    else
        return super:onAct(self, battler, name)
    end
end

function Virovirokun:getAttackDamage(damage, battler)
    if self.susie_warned and battler.chara.id == "susie" then
        return 0
    else
        return super:getAttackDamage(self, damage, battler)
    end
end

return Virovirokun