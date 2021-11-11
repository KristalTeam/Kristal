return {
    name = "Noelle",
    id = "noelle",

    width = 23,
    height = 46,

    hitbox = {2, 33, 19, 14},

    color = {1, 1, 0},

    path = "party/noelle",
    default = "world/dark",

    text_sound = "noelle",
    portrait_path = "face/noelle",
    portrait_offset = {-12, -10},

    animations = {
        ["battle/idle"]         = {"battle/dark/idle", 0.2, true},

        ["battle/attack"]       = {"battle/dark/attack", 1/15, false},
        ["battle/act"]          = {"battle/dark/act", 1/15, false},
        ["battle/spell"]        = {"battle/dark/spell", 1/15, false, next="battle/idle"},
        ["battle/item"]         = {"battle/dark/item", 1/15, false, next="battle/idle"},
        ["battle/spare"]        = {"battle/dark/spare", 1/15, false, next="battle/idle"},

        ["battle/attack_ready"] = {"battle/dark/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/dark/actready", 0.2, true},
        ["battle/spell_ready"]  = {"battle/dark/spellready", 0.2, true},
        ["battle/item_ready"]   = {"battle/dark/itemready", 0.2, true},
        ["battle/defend_ready"] = {"battle/dark/defend", 1/15, false},

        ["battle/act_end"]      = {"battle/dark/actend", 1/15, false, next="battle/idle"},

        ["battle/hurt"]         = {"battle/dark/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/dark/defeat", 1/15, false},

        ["battle/transition"]   = {"battle/dark/intro", 1/15, false},
        ["battle/victory"]      = {"battle/dark/victory", 1/10, false}
    },

    offsets = {
        ["battle/dark/idle"] = {3, 0},

        ["battle/dark/attack"] = {8, 0},
        ["battle/dark/attackready"] = {0, 0},
        ["battle/dark/act"] = {0, 0},
        ["battle/dark/actend"] = {0, 0},
        ["battle/dark/actready"] = {0, 0},
        ["battle/dark/spell"] = {3, 0},
        ["battle/dark/spellready"] = {0, 0},
        ["battle/dark/item"] = {2, 0},
        ["battle/dark/itemready"] = {2, 0},
        ["battle/dark/defend"] = {9, 0},

        ["battle/dark/defeat"] = {0, 0},
        ["battle/dark/hurt"] = {9, 0},

        ["battle/dark/intro"] = {11, 7},
        ["battle/dark/victory"] = {0, 0},
    },
}