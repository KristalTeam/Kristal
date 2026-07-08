local spell, super = Class(Spell, "better_heal")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "BetterHeal"
    -- Name displayed when cast (optional)
    self.cast_name = "BETTERHEAL"

    -- Battle description
    self.effect = "Heal\nally"
    -- Menu description
    self.description = "A healing spell that has grown\nwith practice and confidence."

    -- TP cost
    self.cost = 80

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:getTPCost(chara)
    local cost = super.getTPCost(self, chara)
    local healing_used = chara:getFlag("healing_used")
        if healing_used then
            cost = cost - math.floor(healing_used/3)
        end
    return cost
end

function spell:onCast(user, target)
    user.chara:addFlag("healing_used", 1)
    if user.chara:getFlag("healing_used") > 15 then
        user.chara:addFlag("healing_used", -1)
    end
    local base_heal = math.ceil((user.chara:getStat("magic") * 7) + 15 + (1 * (user.chara:getFlag("healing_used") or 0)))
    local heal_amount = Game.battle:applyHealBonuses(base_heal, user.chara)

    target:heal(heal_amount)
end

return spell
