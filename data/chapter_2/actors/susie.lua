return {
    name = "Susie",
    id = "susie",

    width = 25,
    height = 43,

    hitbox = {3, 30, 19, 14},

    color = {1, 0, 1},

    path = "party/susie/dark",
    default = "",

    text_sound = "susie",
    portrait_path = "face/susie",
    portrait_offset = {-5, 0},

    animations = {
        ["battle/idle"]         = {"battle/idle", 0.2, true},

        ["battle/attack"]       = {"battle/attack", 1/15, false},
        ["battle/act"]          = {"battle/act", 1/15, false},
        ["battle/spell"]        = {"battle/spell", 1/15, false, next="battle/idle"},
        ["battle/item"]         = {"battle/item", 1/12, false, next="battle/idle"},
        ["battle/spare"]        = {"battle/act", 1/15, false, next="battle/idle"},

        ["battle/attack_ready"] = {"battle/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/actready", 0.2, true},
        ["battle/spell_ready"]  = {"battle/spellready", 0.2, true},
        ["battle/item_ready"]   = {"battle/itemready", 0.2, true},
        ["battle/defend_ready"] = {"battle/defend", 1/15, false},

        ["battle/act_end"]      = {"battle/actend", 1/15, false, next="battle/idle"},

        ["battle/hurt"]         = {"battle/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/defeat", 1/15, false},

        ["battle/transition"]   = {"right_1", 1/15, false},
        ["battle/intro"]        = {"battle/attack", 1/15, true},
        ["battle/victory"]      = {"battle/victory", 1/10, false},

        ["battle/rude_buster"]  = {"battle/rude_buster", 1/15, false, next="battle/idle"}
    },

    offsets = {
        ["down"] = {0, 2},
        ["left"] = {0, 2},
        ["right"] = {0, 2},
        ["up"] = {0, 2},

        ["shock_r"] = {13, 1},

        ["battle/idle"] = {22, 1},

        ["battle/attack"] = {26, 25},
        ["battle/attackready"] = {26, 25},
        ["battle/act"] = {24, 25},
        ["battle/actend"] = {24, 25},
        ["battle/actready"] = {24, 25},
        ["battle/spell"] = {22, 30},
        ["battle/spellready"] = {22, 15},
        ["battle/item"] = {22, 1},
        ["battle/itemready"] = {22, 1},
        ["battle/defend"] = {20, 23},

        ["battle/defeat"] = {22, 1},
        ["battle/hurt"] = {22, 1},

        ["battle/victory"] = {28, 7},

        ["battle/rudebuster"] = {44, 33}
    },
}