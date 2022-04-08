local spell, super = Class(Spell, "heal_prayer")

function spell:init()
    super:init(self)

    -- Display name
    self.name = "Heal Prayer"

    -- Battle description
    self.effect = "Heal\nAlly"
    -- Menu description
    self.description = "Heavenly light restores a little HP to\none party member. Depends on Magic."

    -- TP cost
    self.cost = 32

    -- Target mode (party, enemy, or none/nil)
    self.target = "party"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:onCast(user, target)
    target:heal(user.chara:getStat("magic") * 5)
end

return spell