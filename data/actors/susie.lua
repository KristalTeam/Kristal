return {
    name = "Susie",
    id = "susie",

    width = 25,
    height = 43,

    hitbox = {3, 30, 19, 14},

    path = "party/susie",
    default = "world/dark",
    -- -3, -6
    offsets = {
        ["world/dark/down"] = {0, 2},
        ["world/dark/left"] = {0, 2},
        ["world/dark/right"] = {0, 2},
        ["world/dark/up"] = {0, 2},

        ["battle/dark_bangs/idle"] = {22, 1},

        ["battle/dark_bangs/attack"] = {26, 25},
        ["battle/dark_bangs/attackready"] = {26, 25},
        ["battle/dark_bangs/act"] = {26, 25},
        ["battle/dark_bangs/actend"] = {26, 25},
        ["battle/dark_bangs/actready"] = {26, 25},
        ["battle/dark_bangs/spell"] = {22, 30},
        ["battle/dark_bangs/spellready"] = {22, 30},
        ["battle/dark_bangs/item"] = {22, 1},
        ["battle/dark_bangs/itemready"] = {22, 1},
        ["battle/dark_bangs/defend"] = {20, 23},

        ["battle/dark_bangs/defeat"] = {22, 1},
        ["battle/dark_bangs/hurt"] = {22, 1},

        ["battle/dark_bangs/victory"] = {28, 7},

        ["battle/dark_bangs/rudebuster"] = {44, 33}
    },

    battle_offset = {3, 1},
    battle = {
        idle            = "battle/dark_bangs/idle",

        attack          = "battle/dark_bangs/attack",
        act             = "battle/dark_bangs/act",
        act_end         = "battle/dark_bangs/actend",
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

        transition      = "world/dark/right_1",
        intro           = "battle/dark_bangs/attack",
        victory         = "battle/dark_bangs/victory",

        rude_buster     = "battle/dark_bangs/rudebuster"
    }
}