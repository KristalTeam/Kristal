local spell, super = Class(Spell, "ultimate_heal")

function spell:init()
    super:init(self)

    -- Display name
    self.name = "UltimatHeal"

    -- Battle description
    self.effect = "Best\nhealing"
    -- Menu description
    self.description = "Heals 1 party member to the\nbest of Susie's ability."

    -- TP cost
    self.cost = 100

    -- Target mode (party, enemy, or none/nil)
    self.target = "party"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:getCastMessage(user, target)
    return "* "..user.chara.name.." cast ULTIMATEHEAL!"
end

function spell:onCast(user, target)
    target:heal(user.chara:getStat("magic") + 1)
end

return spell
