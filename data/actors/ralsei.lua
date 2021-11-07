return {
    name = "Ralsei",
    id = "ralsei",

    width = 19,
    height = 40,

    hitbox = {0, 27, 19, 14},

    path = "party/ralsei",
    default = "world/dark",

    animations = {
        ["battle/idle"]         = {"battle/dark/idle", 0.2, true},

        ["battle/attack"]       = {"battle/dark/attack", 1/15, false},
        ["battle/act"]          = {"battle/dark/act", 1/15, false},
        ["battle/spell"]        = {"battle/dark/spell", 1/15, false, next="battle/idle"},
        ["battle/item"]         = {"battle/dark/item", 1/15, false, next="battle/idle"},
        ["battle/spare"]        = {"battle/dark/spell", 1/15, false, next="battle/idle"},

        ["battle/attack_ready"] = {"battle/dark/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/dark/actready", 0.2, true},
        ["battle/spell_ready"]  = {"battle/dark/spellready", 0.2, true},
        ["battle/item_ready"]   = {"battle/dark/itemready", 0.2, true},
        ["battle/defend_ready"] = {"battle/dark/defend", 1/15, false},

        ["battle/act_end"]      = {"battle/dark/actend", 1/15, false, next="battle/idle"},

        ["battle/hurt"]         = {"battle/dark/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/dark/defeat", 1/15, false},

        ["battle/transition"]   = {"world/dark/right_1", 1/15, false},
        ["battle/intro"]        = {"battle/dark/intro", 1/15, false},
        ["battle/victory"]      = {"battle/dark/victory", 1/15, false}
    },

    offsets = {
        ["world/dark/down"] = {1, 0},
        ["world/dark/left"] = {0, 0},
        ["world/dark/right"] = {0, 0},
        ["world/dark/up"] = {1, 0},

        ["battle/dark/idle"] = {2, 6},

        ["battle/dark/attack"] = {10, 6},
        ["battle/dark/attackready"] = {10, 6},
        ["battle/dark/act"] = {2, 6},
        ["battle/dark/actend"] = {2, 6},
        ["battle/dark/actready"] = {2, 6},
        ["battle/dark/spell"] = {11, 6},
        ["battle/dark/spellready"] = {11, 6},
        ["battle/dark/item"] = {7, 14},
        ["battle/dark/itemready"] = {7, 14},
        ["battle/dark/defend"] = {2, 6},

        ["battle/dark/defeat"] = {2, 6},
        ["battle/dark/hurt"] = {13, 2},

        ["battle/dark/intro"] = {2, 6},
        ["battle/dark/victory"] = {0, 6}
    },

    --[[battle_offset = {2, 6},
    battle = {
        idle            = "battle/dark/idle",

        attack          = "battle/dark/attack",
        act             = "battle/dark/act",
        act_end         = "battle/dark/actend",
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
    }]]
}