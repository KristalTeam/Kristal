local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "test_spell",
    -- Display name
    name = "Test Spell",

    -- Battle description
    effect = "Test\neffect",
    -- Menu description
    description = "Example spell.",

    -- TP cost
    cost = 32,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",

    -- Tags that apply to this spell
    tags = {},
}

function spell:onCast(user, target)
    -- Code the cast effect here
    -- If you return false, you can call Game.battle:finishAction() to finish the spell
end

return spell