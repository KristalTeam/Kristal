local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "rude_buster",
    -- Display name
    name = "Rude Buster",

    -- Battle description
    effect = "Rude\nDamage",
    -- Menu description
    description = "Deals moderate Rude-elemental damage to\none foe. Depends on Attack & Magic.",

    -- TP cost
    cost = 50,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",
}

function spell:getCastMessage(user, target)
    return "* "..user.chara.name.." used RUDE BUSTER!"
end

return spell