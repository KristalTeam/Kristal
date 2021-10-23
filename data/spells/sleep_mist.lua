return {
    -- Spell ID (optional, defaults to path)
    id = "sleep_mist",
    -- Display name
    name = "Sleep Mist",

    -- Battle description
    effect = "Spare\nTIRED foes",
    -- Menu description
    description = "A cold mist sweeps through,\nsparing all TIRED enemies.",

    -- TP cost (default tp max is 250)
    cost = 80,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",

    -- (Optional) Suggests this spell when sparing a tired enemy
    pacify = true,
}