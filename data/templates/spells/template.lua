local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "test_spell",
    -- Display name
    name = "Test Spell",

    -- Battle description
    effect = "Test\neffect",
    -- Menu description
    description = "Example spell.",

    -- TP cost (default tp max is 250)
    cost = 40,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",

    -- (Optional) Suggests this spell when sparing a tired enemy
    pacify = false,
}

function spell:onCast(user, target)
    -- Code the cast effect here
    -- If you return false, you can call Game.battle:finishAction() to finish the spell
end

return spell