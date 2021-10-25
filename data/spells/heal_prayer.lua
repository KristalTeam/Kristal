local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "heal_prayer",
    -- Display name
    name = "Heal Prayer",

    -- Battle description
    effect = "Heal\nAlly",
    -- Menu description
    description = "Heavenly light restores a little HP to\none party member. Depends on Magic.",

    -- TP cost (default tp max is 250)
    cost = 80,

    -- Target mode (party, enemy, or none/nil)
    target = "party",
}

function spell:onCast(user, target)
    target:heal(love.math.random(100))
    Game.battle:finishSpell()
end

return spell