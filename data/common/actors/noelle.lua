return {
    name = "Noelle",
    id = "noelle",

    width = 23,
    height = 46,

    hitbox = {2, 33, 19, 14},

    color = {1, 1, 0},

    path = "party/noelle/dark",
    default = "",

    text_sound = "noelle",
    portrait_path = "face/noelle",
    portrait_offset = {-12, -10},

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

        ["battle/transition"]   = {"battle/intro", 1/15, false},
        ["battle/victory"]      = {"battle/victory", 1/10, false}
    },

    offsets = {
        ["battle/idle"] = {3, 0},

        ["battle/attack"] = {8, 0},
        ["battle/attackready"] = {0, 0},
        ["battle/act"] = {0, 0},
        ["battle/actend"] = {0, 0},
        ["battle/actready"] = {0, 0},
        ["battle/spell"] = {3, 0},
        ["battle/spellready"] = {0, 0},
        ["battle/item"] = {2, 0},
        ["battle/itemready"] = {2, 0},
        ["battle/defend"] = {9, 0},

        ["battle/defeat"] = {0, 0},
        ["battle/hurt"] = {9, 0},

        ["battle/intro"] = {11, 7},
        ["battle/victory"] = {0, 0},
    },
}