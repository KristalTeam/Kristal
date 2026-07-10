local spell, super = Class(Spell, "ultra_heal")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "UltraHeal"
    -- Name displayed when cast (optional)
    self.cast_name = "ULTRAHEAL"

    -- Battle description
    self.effect = "Best\nhealing"
    -- Menu description
    self.description = "An awesome healing spell.\n... right?"

    -- TP cost
    self.cost = 90

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:getTPCost(chara)
    local cost = super.getTPCost(self, chara)
    return cost - (chara:getFlag("healing_used", 0))
end

function spell:onCast(user, target)
    local healing_used = user.chara:getFlag("healing_used", 0)

    if healing_used < 5 then
        healing_used = healing_used + 1
        user.chara:setFlag("healing_used", healing_used)
    end

    local base_heal = math.ceil((user.chara:getStat("magic") * 1.5) + 5 + healing_used)
    local heal_amount = Game.battle:applyHealBonuses(base_heal, user.chara, target.chara)

    target:heal(heal_amount)
end

return spell
