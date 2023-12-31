local spell, super = Class(Spell, "dual_heal")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "Dual Heal"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    self.effect = "Heal All"
    -- Menu description
    self.description = "Heavenly light restores a little HP to\nall party members. Depends on Magic."

    -- TP cost
    self.cost = 50

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "party"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:onCast(user, target)
    for _,battler in ipairs(target) do
        battler:heal(user.chara:getStat("magic") * 5.5)
    end
end

return spell