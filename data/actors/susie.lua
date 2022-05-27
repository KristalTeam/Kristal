local actor, super = Class(Actor, "susie")

function actor:init(style)
    super:init(self)

    local susie_style = style or Game:getConfig("susieStyle")

    -- Display name (optional)
    self.name = "Susie"

    -- Width and height for this actor, used to determine its center
    self.width = 25
    self.height = 43

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = {3, 31, 19, 14}

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {1, 0, 1}

    -- Path to this actor's sprites (defaults to "")
    self.path = "party/susie/dark"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    if susie_style == 1 then
        self.default = "walk_bangs"
    else
        self.default = "walk"
    end

    -- Sound to play when this actor speaks (optional)
    self.voice = "susie"
    -- Path to this actor's portrait for dialogue (optional)
    if susie_style == 1 then
        self.portrait_path = "face/susie_bangs"
    else
        self.portrait_path = "face/susie"
    end
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = {-5, 0}

    -- Whether this actor as a follower will blush when close to the player
    self.can_blush = false

    -- Table of sprite animations
    self.animations = {
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

        ["battle/transition"]   = {self.default.."/right_1", 1/15, false},
        ["battle/intro"]        = {"battle/attack", 1/15, true},
        ["battle/victory"]      = {"battle/victory", 1/10, false},

        ["battle/rude_buster"]  = {"battle/rudebuster", 1/15, false, next="battle/idle"},

        -- Cutscene animations
        ["jump_fall"]           = {"fall", 1/5, true},
        ["jump_ball"]           = {"ball", 1/15, true},
    }

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {
        -- Movement offsets
        ["walk/down"] = {0, 0},
        ["walk/left"] = {0, 0},
        ["walk/right"] = {0, 0},
        ["walk/up"] = {0, 0},

        ["walk_bangs/down"] = {0, -2},
        ["walk_bangs/left"] = {0, -2},
        ["walk_bangs/right"] = {0, -2},
        ["walk_bangs/up"] = {0, -2},

        ["walk_unhappy/down"] = {0, 0},
        ["walk_unhappy/left"] = {0, 0},
        ["walk_unhappy/right"] = {0, 0},
        ["walk_unhappy/up"] = {0, -2},

        ["walk_back_arm/left"] = {-3, -2},
        ["walk_back_arm/right"] = {0, -2},

        ["slide"] = {-5, -12},

        -- Battle offsets
        ["battle/idle"] = {-22, -1},

        ["battle/attack"] = {-26, -25},
        ["battle/attackready"] = {-26, -25},
        ["battle/act"] = {-24, -25},
        ["battle/actend"] = {-24, -25},
        ["battle/actready"] = {-24, -25},
        ["battle/spell"] = {-22, -30},
        ["battle/spellready"] = {-22, -15},
        ["battle/item"] = {-22, -1},
        ["battle/itemready"] = {-22, -1},
        ["battle/defend"] = {-20, -23},

        ["battle/defeat"] = {-22, -1},
        ["battle/hurt"] = {-22, -1},

        ["battle/victory"] = {-28, -7},

        ["battle/rudebuster"] = {-44, -33},

        -- Cutscene offsets
        ["pose"] = {-1, -1},

        ["fall"] = {0, -4},
        ["ball"] = {1, 7},
        ["landed"] = {-5, -2},

        ["shock_left"] = {0, -4},
        ["shock_right"] = {-16, -4},
        ["shock_down"] = {0, -2},
        ["shock_up"] = {-6, 0},

        ["shock_behind"] = {-15, -3},
        ["shock_down_flip"] = {0, -2},

        ["laugh_left"] = {-8, -2},
        ["laugh_right"] = {-4, -2},

        ["point_laugh_left"] = {-14, 2},
        ["point_laugh_right"] = {0, 2},

        ["point_left"] = {-11, 2},
        ["point_right"] = {0, 2},
        ["point_up"] = {-2, -12},

        ["point_up_turn"] = {-4, -12},

        ["playful_punch"] = {-8, 0},

        ["wall_left"] = {0, -2},
        ["wall_right"] = {0, -2},

        ["exasperated_left"] = {-1, 0},
        ["exasperated_right"] = {-5, 0},

        ["angry_down"] = {-10, 2},
        ["turn_around"] = {-12, 2},

        ["away"] = {-1, -2},
        ["away_turn"] = {-1, -2},
        ["away_hips"] = {-1, -2},
        ["away_hand"] = {-1, -2},
        ["away_scratch"] = {-1, -2},

        ["t_pose"] = {-6, 0},

        ["fell"] = {-18, -2},
    }
end

return actor