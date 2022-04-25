local Virovirokun, super = Class("virovirokun", true)

function Virovirokun:init()
    super:init(self)

    if Game:getPartyMember("susie"):getFlag("auto_attack") then
        self:registerAct("Warning")
    end

    self.susie_warned = false

    self.asleep = false

    self:registerAct("Tell Story", "", {"ralsei"})
end

function Virovirokun:onAct(battler, name)
    if name == "Warning" then
        self.susie_warned = true
        self.comment = "(Warned)"
        return "* You told Virovirokun to watch out for Susie's attacks.[wait:5]\n* It went on guard."
    elseif name == "Tell Story" then
        for _,v in ipairs(Game.battle.enemies) do
            v.asleep = true
            v:setTired(true)
            v.comment = "(Sleepy)"
            v:setScale(4, 2)
            v.text_override = "Zzz..."
        end
        self:addMercy(100)
        return "* Ralsei tells Virovirokun a story.[wait:5]\n* The enemies fell asleep!"
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

function Virovirokun:getNextWaves()
    if self.asleep then
        return nil
    end
    self:getNextWaves()
end

return Virovirokun