return {
    -- Spell ID (optional, defaults to path)
    id = "pacify",
    -- Display name
    name = "Pacify",

    -- Battle description
    effect = "Spare\nTIRED foe",
    -- Menu description
    description = "SPARE a tired enemy by putting them to sleep.",

    -- TP cost (default tp max is 250)
    cost = 40,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",

    -- (Optional) Suggests this spell when sparing a tired enemy
    pacify = true,
}