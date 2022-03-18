local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "heal_prayer",
    -- Display name
    name = "Heal Prayer",

    -- Battle description
    effect = "Heal\nAlly",
    -- Menu description
    description = "Heavenly light restores a little HP to\none party member. Depends on Magic.",

    -- TP cost
    cost = 32,

    -- Target mode (party, enemy, or none/nil)
    target = "party",

    tags = {"heal"},
}

function spell:onCast(user, target)
    target:heal(user.chara:getStat("magic") * 5)
end

return spell