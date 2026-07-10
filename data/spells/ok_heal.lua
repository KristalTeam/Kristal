local spell, super = Class(Spell, "ok_heal")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "OKHeal"
    -- Name displayed when cast (optional)
    self.cast_name = "OKHEAL"

    -- Battle description
    self.effect = "OK\nhealing"
    -- Menu description
    self.description = "It's not the best healing spell, but\nit may have its uses."

    -- TP cost
    self.cost = 85

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = { "heal" }
end

function spell:getTPCost(chara)
    local cost = super.getTPCost(self, chara)

    local healing_used = chara:getFlag("healing_used", 0)
    cost = cost - math.floor(healing_used / 3)
    return cost
end

function spell:onCast(user, target)
    local healing_used = user.chara:getFlag("healing_used", 0)

    if healing_used < 15 then
        healing_used = healing_used + 1
        user.chara:setFlag("healing_used", healing_used)
    end

    local base_heal = math.ceil((user.chara:getStat("magic") * 5) + 15 + healing_used)
    local heal_amount = Game.battle:applyHealBonuses(base_heal, user.chara, target.chara)

    target:heal(heal_amount)
end

return spell
