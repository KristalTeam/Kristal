return {
    name = "Kris",
    id = "kris",

    width = 19,
    height = 37,

    hitbox = {0, 25, 19, 14},

    color = {0, 1, 1},

    path = "party/kris/dark",
    default = "",

    animations = {
        ["battle/idle"]         = {"battle/idle", 0.2, true},

        ["battle/attack"]       = {"battle/attack", 1/15, false},
        ["battle/act"]          = {"battle/act", 1/15, false},
        ["battle/item"]         = {"battle/item", 1/12, false, next="battle/idle"},
        ["battle/spare"]        = {"battle/act", 1/15, false, next="battle/idle"},

        ["battle/attack_ready"] = {"battle/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/actready", 0.2, true},
        ["battle/item_ready"]   = {"battle/itemready", 0.2, true},
        ["battle/defend_ready"] = {"battle/defend", 1/15, false},

        ["battle/act_end"]      = {"battle/actend", 1/15, false, next="battle/idle"},

        ["battle/hurt"]         = {"battle/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/defeat", 1/15, false},

        ["battle/transition"]   = {"battle/sword_jump_down", 0.2, true},
        ["battle/intro"]        = {"battle/attack", 1/15, true},
        ["battle/victory"]      = {"battle/victory", 1/10, false}
    },

    offsets = {
        ["battle/idle"] = {5, 1},

        ["battle/attack"] = {8, 6},
        ["battle/attackready"] = {8, 6},
        ["battle/act"] = {6, 6},
        ["battle/actend"] = {6, 6},
        ["battle/actready"] = {6, 6},
        ["battle/item"] = {6, 6},
        ["battle/itemready"] = {6, 6},
        ["battle/defend"] = {5, 3},

        ["battle/defeat"] = {8, 5},
        ["battle/hurt"] = {5, 6},

        ["battle/sword_jump_down"] = {17, 2},
        ["battle/intro"] = {8, 9},
        ["battle/victory"] = {3, 0},

        --["dark_transition/dark"] = {5, 6},
        --["dark_transition/ball"] = {5, 6},
        --["dark_transition/landed"] = {4, 2}
    },
}