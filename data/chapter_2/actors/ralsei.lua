return {
    name = "Ralsei",
    id = "ralsei",

    width = 19,
    height = 40,

    hitbox = {0, 27, 19, 14},

    color = {0, 1, 0},

    path = "party/ralsei/dark",
    default = "",

    text_sound = "ralsei",
    portrait_path = "face/ralsei",
    portrait_offset = {-15, -10},

    animations = {
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

        ["battle/hurt"]         = {"battle/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/defeat", 1/15, false},

        ["battle/transition"]   = {"right_1", 1/15, false},
        ["battle/intro"]        = {"battle/intro", 1/15, false},
        ["battle/victory"]      = {"battle/victory", 1/10, false}
    },

    offsets = {
        ["down"] = {1, 0},
        ["left"] = {0, 0},
        ["right"] = {0, 0},
        ["up"] = {1, 0},

        ["battle/idle"] = {2, 6},

        ["battle/attack"] = {10, 6},
        ["battle/attackready"] = {10, 6},
        ["battle/act"] = {2, 6},
        ["battle/actend"] = {2, 6},
        ["battle/actready"] = {2, 6},
        ["battle/spell"] = {11, 6},
        ["battle/spellready"] = {11, 6},
        ["battle/item"] = {7, 14},
        ["battle/itemready"] = {7, 14},
        ["battle/defend"] = {2, 6},

        ["battle/defeat"] = {2, 6},
        ["battle/hurt"] = {13, 2},

        ["battle/intro"] = {2, 6},
        ["battle/victory"] = {0, 6}
    },
}