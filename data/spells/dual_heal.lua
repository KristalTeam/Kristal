local spell, super = Class(Spell, "dual_heal")

function spell:init()
    super:init(self)

    -- Display name
    self.name = "Dual Heal"

    -- Battle description
    self.effect = "Heal All\n30 HP"
    -- Menu description
    self.description = "Heavenly light restores a little HP to\nall party members. Depends on Magic."

    -- TP cost
    self.cost = 50

    -- Target mode (party, enemy, or none/nil)
    self.target = "none"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:onCast(user, target)
    for _,battler in ipairs(Game.battle.party) do
        battler:heal(user.chara:getStat("magic") * 5.5)
    end
end

return spell