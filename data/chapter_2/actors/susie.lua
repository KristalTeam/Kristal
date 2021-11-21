return {
    name = "Susie",
    id = "susie",

    width = 25,
    height = 43,

    hitbox = {3, 30, 19, 14},

    color = {1, 0, 1},

    path = "party/susie/dark",
    default = "walk",

    text_sound = "susie",
    portrait_path = "face/susie",
    portrait_offset = {-5, 0},

    animations = {
        -- Movement animations
        ["slide"]               = {"slide", 4/30, true},

        -- Battle animations
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

        ["battle/transition"]   = {"walk/right_1", 1/15, false},
        ["battle/intro"]        = {"battle/attack", 1/15, true},
        ["battle/victory"]      = {"battle/victory", 1/10, false},

        ["battle/rude_buster"]  = {"battle/rudebuster", 1/15, false, next="battle/idle"},

        -- Cutscene animations
        ["jump_fall"]           = {"fall", 1/15, true},
        ["jump_ball"]           = {"ball", 1/15, true},
    },

    offsets = {
        -- Movement sprites
        ["walk/down"] = {0, 2},
        ["walk/left"] = {0, 2},
        ["walk/right"] = {0, 2},
        ["walk/up"] = {0, 2},

        ["walk_unhappy/down"] = {0, 2},
        ["walk_unhappy/left"] = {0, 2},
        ["walk_unhappy/right"] = {0, 2},
        ["walk_unhappy/up"] = {0, 2},

        ["walk_back_arm/left"] = {3, 2},
        ["walk_back_arm/right"] = {0, 2},

        ["slide"] = {5, 12},

        -- Battle sprites
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

        ["battle/rudebuster"] = {44, 33},

        -- Cutscene sprites
        ["pose"] = {1, 1},

        ["fall"] = {0, 4},
        ["ball"] = {-1, 6},
        ["landed"] = {5, 2},

        ["shock_left"] = {0, 4},
        ["shock_right"] = {16, 4},
        ["shock_down"] = {0, 2},
        ["shock_up"] = {6, 0},

        ["shock_behind"] = {15, 3},
        ["shock_down_flip"] = {0, 2},

        ["laugh_left"] = {8, 2},
        ["laugh_right"] = {4, 2},

        ["point_laugh_left"] = {14, -2},
        ["point_laugh_right"] = {0, -2},

        ["point_left"] = {11, -2},
        ["point_right"] = {0, -2},
        ["point_up"] = {2, 0},

        ["point_up_turn"] = {2, 0},

        ["playful_punch"] = {8, 0},

        ["wall_left"] = {0, 2},
        ["wall_right"] = {0, 2},

        ["exasperated_left"] = {1, 0},
        ["exasperated_right"] = {5, 0},

        ["angry_down"] = {10, -2},
        ["turn_around"] = {12, -2},

        ["head_hand_left"] = {3, 2},
        ["head_hand_right"] = {0, 2},

        ["away"] = {1, 2},
        ["away_turn"] = {1, 2},
        ["away_hips"] = {1, 2},
        ["away_hand"] = {1, 2},
        ["away_scratch"] = {1, 2},

        ["t_pose"] = {6, 0},

        ["fell"] = {18, 2},
    },
}