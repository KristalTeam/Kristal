return {
    name = "Kris",
    id = "kris",

    width = 19,
    height = 37,

    hitbox = {0, 25, 19, 14},

    color = {0, 1, 1},

    path = "party/kris/dark",
    default = "walk",

    animations = {
        -- Movement animations
        ["slide"]               = {"slide", 4/30, true},

        -- Battle animations
        ["battle/idle"]         = {"battle/idle", 0.2, true},

        ["battle/attack"]       = {"battle/attack", 1/15, false},
        ["battle/act"]          = {"battle/act", 1/15, false},
        ["battle/spell"]        = {"battle/act", 1/15, false},
        ["battle/item"]         = {"battle/item", 1/12, false, next="battle/idle"},
        ["battle/spare"]        = {"battle/act", 1/15, false, next="battle/idle"},

        ["battle/attack_ready"] = {"battle/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/actready", 0.2, true},
        ["battle/spell_ready"]  = {"battle/actready", 0.2, true},
        ["battle/item_ready"]   = {"battle/itemready", 0.2, true},
        ["battle/defend_ready"] = {"battle/defend", 1/15, false},

        ["battle/act_end"]      = {"battle/actend", 1/15, false, next="battle/idle"},

        ["battle/hurt"]         = {"battle/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/defeat", 1/15, false},

        ["battle/transition"]   = {"sword_jump_down", 0.2, true},
        ["battle/intro"]        = {"battle/attack", 1/15, true},
        ["battle/victory"]      = {"battle/victory", 1/10, false},

        -- Cutscene animations
        ["jump_fall"]           = {"fall", 1/5, true},
        ["jump_ball"]           = {"ball", 1/15, true},
    },

    offsets = {
        -- Movement offsets
        ["walk/left"] = {0, 0},
        ["walk/right"] = {0, 0},
        ["walk/up"] = {0, 0},
        ["walk/down"] = {0, 0},

        ["walk_blush/down"] = {0, 0},

        ["slide"] = {0, 0},

        -- Battle offsets
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

        ["battle/intro"] = {8, 9},
        ["battle/victory"] = {3, 0},

        -- Cutscene offsets
        ["pose"] = {4, 2},

        ["fall"] = {5, 6},
        ["ball"] = {-1, -8},
        ["landed"] = {4, 2},

        ["fell"] = {14, -1},

        ["sword_jump_down"] = {19, 5}, -- (was 17,3  was this deltarune accurate?)
        ["sword_jump_settle"] = {27, -4},
        ["sword_jump_up"] = {17, -2},

        ["hug_left"] = {4, 1},
        ["hug_right"] = {2, 1},

        ["peace"] = {0, 0},
        ["rude_gesture"] = {0, 0},

        ["reach"] = {3, 1},

        ["sit"] = {3, 0},

        ["t_pose"] = {4, 0},
    },
}