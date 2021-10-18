return {
    name = "Susie",
    id = "susie",

    width = 19,
    height = 38,

    hitbox = {0, 24, 19, 14},

    path = "party/susie",
    default = "world/dark",
    offsets = {
        ["world/dark/down"] = {3, 8},
        ["world/dark/left"] = {3, 8},
        ["world/dark/right"] = {3, 8},
        ["world/dark/up"] = {3, 8},

        ["battle/dark_bangs/idle"] = {25, 7},

        ["battle/dark_bangs/attack"] = {29, 31},
        ["battle/dark_bangs/attackready"] = {29, 31},
        ["battle/dark_bangs/act"] = {29, 31},
        ["battle/dark_bangs/actready"] = {29, 31},
        ["battle/dark_bangs/spell"] = {25, 36},
        ["battle/dark_bangs/spellready"] = {25, 36},
        ["battle/dark_bangs/item"] = {25, 7},
        ["battle/dark_bangs/itemready"] = {25, 7},
        ["battle/dark_bangs/defend"] = {22, 29},

        ["battle/dark_bangs/defeat"] = {25, 7},
        ["battle/dark_bangs/hurt"] = {25, 7},

        ["battle/dark_bangs/victory"] = {31, 13},

        ["battle/dark_bangs/rudebuster"] = {47, 39}
    },

    battle_offset = {6, 7},
    battle = {
        idle            = "battle/dark_bangs/idle",

        attack          = "battle/dark_bangs/attack",
        act             = "battle/dark_bangs/act",
        spell           = "battle/dark_bangs/spell",
        item            = "battle/dark_bangs/item",
        spare           = "battle/dark_bangs/spell",
        defend          = "battle/dark_bangs/defend",

        attack_ready    = "battle/dark_bangs/attackready",
        act_ready       = "battle/dark_bangs/actready",
        spell_ready     = "battle/dark_bangs/spellready",
        item_ready      = "battle/dark_bangs/itemready",

        hurt            = "battle/dark_bangs/hurt",
        defeat          = "battle/dark_bangs/defeat",

        intro           = {"world/dark/right_1", "battle/dark_bangs/attack"},
        victory         = "battle/dark_bangs/victory",

        rude_buster     = "battle/dark_bangs/rudebuster"
    }
}