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
    return cost - (chara:getFlag("healing_used") or 0)
end

function spell:onCast(user, target)
    user.chara:addFlag("healing_used", 1)
    if user.chara:getFlag("healing_used") > 5 then
        user.chara:addFlag("healing_used", -1)
    end
    local base_heal = math.ceil((user.chara:getStat("magic") * 1.5) + 5 + (1 * (user.chara:getFlag("healing_used") or 0)))
    local heal_amount = Game.battle:applyHealBonuses(base_heal, user.chara)

    target:heal(heal_amount)
end

return spell
