return {
    name = "Ralsei",
    id = "ralsei",

    width = 23,
    height = 43,

    hitbox = {0, 27, 19, 14},

    color = {0, 1, 0},

    path = "party/ralsei",
    default = "world/dark_hat",

    text_sound = "ralsei",
    portrait_path = "face/ralsei_hat",
    portrait_offset = {-15, -10},

    animations = {
        ["battle/idle"]         = {"battle/dark_hat/idle", 0.2, true},

        ["battle/attack"]       = {"battle/dark_hat/attack", 1/15, false},
        ["battle/act"]          = {"battle/dark_hat/act", 1/15, false},
        ["battle/spell"]        = {"battle/dark_hat/spell", 1/15, false, next="battle/idle"},
        ["battle/item"]         = {"battle/dark_hat/item", 1/12, false, next="battle/idle"},
        ["battle/spare"]        = {"battle/dark_hat/spell", 1/15, false, next="battle/idle"},

        ["battle/attack_ready"] = {"battle/dark_hat/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/dark_hat/actready", 0.2, true},
        ["battle/spell_ready"]  = {"battle/dark_hat/spellready", 0.2, true},
        ["battle/item_ready"]   = {"battle/dark_hat/itemready", 0.2, true},
        ["battle/defend_ready"] = {"battle/dark_hat/defend", 1/15, false},

        ["battle/act_end"]      = {"battle/dark_hat/actend", 1/15, false, next="battle/idle"},

        --["battle/hurt"]         = {"battle/dark_hat/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/dark_hat/defeat", 1/15, false},

        ["battle/transition"]   = {"world/dark_hat/right_1", 1/15, false},
        ["battle/intro"]        = {"battle/dark_hat/intro", 1/15, false},
        ["battle/victory"]      = {"battle/dark_hat/victory", 1/10, false}
    },

    offsets = {
        ["battle/dark_hat/idle"] = {7, 2},

        ["battle/dark_hat/attack"] = {11, 3},
        ["battle/dark_hat/attackready"] = {11, 3},
        ["battle/dark_hat/act"] = {3, 2},
        ["battle/dark_hat/actend"] = {3, 2},
        ["battle/dark_hat/actready"] = {3, 2},
        ["battle/dark_hat/spell"] = {12, 2},
        ["battle/dark_hat/spellready"] = {12, 2},
        ["battle/dark_hat/item"] = {8, 10},
        ["battle/dark_hat/itemready"] = {8, 10},
        ["battle/dark_hat/defend"] = {3, 2},

        ["battle/dark_hat/defeat"] = {3, 2},
        --["battle/dark_hat/hurt"] = {13, 2}, -- does this exist?

        ["battle/dark_hat/intro"] = {3, 2},
        ["battle/dark_hat/victory"] = {3, 2}
    },
}