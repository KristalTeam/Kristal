return {
    id = "testmod",
    name = "Test Mod",
    subtitle = "For Kristal development, NOT an example mod!",

    version = "v?.?.?",
    engineVer = "v0.9.0-dev",

    chapter = 2,

    map = "alley",
    -- encounter = "virovirokun" -- for testing encounter reloading
    -- Look! the comments don't create furious errors anymore! hooray!

    party = {"kris", "susie", "ralsei"},
    -- party = {"kris", "noelle"} -- for testing snowgrave
    inventory = {
        items = {"darkburger", "darkburger", "darkburger", "darkburger", "dd_burger", "dumburger", "tensionbit", "tensionbit", "counter"},
        key_items = {"cell_phone", "shadowcrystal", "egg"},
        storage = "favwich",
    },
    equipment = {
        kris = {
            weapon = "wood_blade",
            armor = {"dealmaker", "egg"}
        },
        susie = {
            weapon = "devilsknife",
        },
    },

    transition = false,

    quickReload = true,
    hidden = false,

    config = {
        kristal = {
            -- growStrongerChara = "susie",

            -- ralseiStyle = 2,
            keepTensionAfterBattle = true,
            overworldSpells = true,
        },
        virovirokun = {
            enable_cook = true,
            enable_quarantine = true,
        }
    },
}