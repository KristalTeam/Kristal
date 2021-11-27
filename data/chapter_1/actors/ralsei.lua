return {
    name = "Ralsei",
    id = "ralsei",

    width = 23,
    height = 43,

    hitbox = {0, 27, 19, 14},

    color = {0, 1, 0},

    path = "party/ralsei/dark_ch1",
    default = "walk",

    text_sound = "ralsei",
    portrait_path = "face/ralsei_hat",
    portrait_offset = {-15, -10},

    animations = {
        -- Battle animations
        ["battle/idle"]         = {"battle/idle", 0.2, true},

        ["battle/attack"]       = {"battle/attack", 1/15, false},
        ["battle/act"]          = {"battle/act", 1/15, false},
        ["battle/spell"]        = {"battle/spell", 1/15, false, next="battle/idle"},
        ["battle/item"]         = {"battle/item", 1/12, false, next="battle/idle"},
        ["battle/spare"]        = {"battle/spell", 1/15, false, next="battle/idle"},

        ["battle/attack_ready"] = {"battle/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/actready", 0.2, true},
        ["battle/spell_ready"]  = {"battle/spellready", 0.2, true},
        ["battle/item_ready"]   = {"battle/itemready", 0.2, true},
        ["battle/defend_ready"] = {"battle/defend", 1/15, false},

        ["battle/act_end"]      = {"battle/actend", 1/15, false, next="battle/idle"},

        --["battle/hurt"]         = {"battle/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/defeat", 1/15, false},

        ["battle/transition"]   = {"walk/right_1", 1/15, false},
        ["battle/intro"]        = {"battle/intro", 1/15, false},
        ["battle/victory"]      = {"battle/victory", 1/10, false}
    },

    offsets = {
        -- Battle offsets
        ["battle/idle"] = {7, 2},

        ["battle/attack"] = {11, 3},
        ["battle/attackready"] = {11, 3},
        ["battle/act"] = {3, 2},
        ["battle/actend"] = {3, 2},
        ["battle/actready"] = {3, 2},
        ["battle/spell"] = {12, 2},
        ["battle/spellready"] = {12, 2},
        ["battle/item"] = {8, 10},
        ["battle/itemready"] = {8, 10},
        ["battle/defend"] = {3, 2},

        ["battle/defeat"] = {3, 2},
        --["battle/hurt"] = {13, 2}, -- does this exist?

        ["battle/intro"] = {3, 2},
        ["battle/victory"] = {3, 2}
    },
}