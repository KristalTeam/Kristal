return {
    name = "Ralsei",
    id = "ralsei",

    width = 19,
    height = 38,

    hitbox = {0, 24, 19, 14},

    path = "party/ralsei",
    default = "world/dark",
    offsets = {
        ["world/dark/down"] = {1, 3},
        ["world/dark/left"] = {0, 3},
        ["world/dark/right"] = {0, 3},
        ["world/dark/up"] = {1, 3},

        ["battle/dark/idle"] = {2, 9},

        ["battle/dark/attack"] = {10, 9},
        ["battle/dark/attackready"] = {10, 9},
        ["battle/dark/act"] = {2, 9},
        ["battle/dark/actready"] = {2, 9},
        ["battle/dark/spell"] = {11, 9},
        ["battle/dark/spellready"] = {11, 9},
        ["battle/dark/item"] = {7, 17},
        ["battle/dark/itemready"] = {7, 17},
        ["battle/dark/defend"] = {2, 9},

        ["battle/dark/defeat"] = {2, 9},
        ["battle/dark/hurt"] = {13, 5},

        ["battle/dark/intro"] = {2, 9},
        ["battle/dark/victory"] = {0, 9}
    },

    battle_offset = {2, 9},
    battle = {
        idle            = "battle/dark/idle",

        attack          = "battle/dark/attack",
        act             = "battle/dark/act",
        spell           = "battle/dark/spell",
        item            = "battle/dark/item",
        spare           = "battle/dark/spell",
        defend          = "battle/dark/defend",

        attack_ready    = "battle/dark/attackready",
        act_ready       = "battle/dark/actready",
        spell_ready     = "battle/dark/spellready",
        item_ready      = "battle/dark/itemready",

        hurt            = "battle/dark/hurt",
        defeat          = "battle/dark/defeat",

        transition      = "world/dark/right_1",
        intro           = "battle/dark/intro",
        victory         = "battle/dark/victory",
    }
}