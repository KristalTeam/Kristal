local spell, super = Class(Spell, "test_spell")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "Test Spell"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    self.effect = "Test\neffect"
    -- Menu description
    self.description = "Example spell."

    -- TP cost
    self.cost = 32

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "enemy"

    -- Tags that apply to this spell
    self.tags = {}
end

function spell:onCast(user, target)
    -- Code the cast effect here
    -- If you return false, you can call Game.battle:finishAction() to finish the spell
end

return spell