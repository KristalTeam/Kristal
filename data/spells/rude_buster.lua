local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "rude_buster",
    -- Display name
    name = "Rude Buster",

    -- Battle description
    effect = "Rude\nDamage",
    -- Menu description
    description = "Deals moderate Rude-elemental damage to\none foe. Depends on Attack & Magic.",

    -- TP cost (default tp max is 250)
    cost = 125,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",
}

return spell