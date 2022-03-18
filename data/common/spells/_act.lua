-- This spell is only used for display in the POWER menu.

local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "_act",
    -- Display name
    name = "ACT",

    -- Battle description
    effect = "",
    -- Menu description
    description = "Do all sorts of things.\nIt isn't magic.",

    -- TP cost
    cost = 0,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",

    tags = {},
}

return spell