return {
    name = "Kris",
    id = "kris",

    width = 19,
    height = 37,

    hitbox = {0, 25, 19, 14},

    color = {0, 1, 1},

    path = "party/kris",
    default = "world/dark",

    animations = {
        ["battle/idle"]         = {"battle/dark/idle", 0.2, true},

        ["battle/attack"]       = {"battle/dark/attack", 1/15, false},
        ["battle/act"]          = {"battle/dark/act", 1/15, false},
        ["battle/item"]         = {"battle/dark/item", 1/12, false, next="battle/idle"},
        ["battle/spare"]        = {"battle/dark/act", 1/15, false, next="battle/idle"},

        ["battle/attack_ready"] = {"battle/dark/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/dark/actready", 0.2, true},
        ["battle/item_ready"]   = {"battle/dark/itemready", 0.2, true},
        ["battle/defend_ready"] = {"battle/dark/defend", 1/15, false},

        ["battle/act_end"]      = {"battle/dark/actend", 1/15, false, next="battle/idle"},

        ["battle/hurt"]         = {"battle/dark/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/dark/defeat", 1/15, false},

        ["battle/transition"]   = {"battle/dark/sword_jump_down", 0.2, true},
        ["battle/intro"]        = {"battle/dark/attack", 1/15, true},
        ["battle/victory"]      = {"battle/dark/victory", 1/10, false}
    },

    offsets = {
        ["battle/dark/idle"] = {5, 1},

        ["battle/dark/attack"] = {8, 6},
        ["battle/dark/attackready"] = {8, 6},
        ["battle/dark/act"] = {6, 6},
        ["battle/dark/actend"] = {6, 6},
        ["battle/dark/actready"] = {6, 6},
        ["battle/dark/item"] = {6, 6},
        ["battle/dark/itemready"] = {6, 6},
        ["battle/dark/defend"] = {5, 3},

        ["battle/dark/defeat"] = {8, 5},
        ["battle/dark/hurt"] = {5, 6},

        ["battle/dark/sword_jump_down"] = {17, 2},
        ["battle/dark/intro"] = {8, 9},
        ["battle/dark/victory"] = {3, 0},

        ["dark_transition/dark"] = {5, 6},
        ["dark_transition/ball"] = {5, 6},
        ["dark_transition/landed"] = {4, 2}
    },
}