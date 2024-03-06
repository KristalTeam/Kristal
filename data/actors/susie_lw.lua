local actor, super = Class(Actor, "susie_lw")

function actor:init()
    super.init(self)

    -- Display name (optional)
    self.name = "Susie"

    -- Width and height for this actor, used to determine its center
    self.width = 25
    self.height = 43

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = {3, 30, 19, 14}
    
    -- A table that defines where the Soul should be placed on this actor if they are a player.
    -- First value is x, second value is y.
    self.soul_offset = {12.5, 24}

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {1, 0, 1}

    -- Path to this actor's sprites (defaults to "")
    self.path = "party/susie/light"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    if Game:getConfig("susieStyle") == 1 then
        self.default = "walk_bangs"
    else
        self.default = "walk"
    end

    -- Sound to play when this actor speaks (optional)
    self.voice = "susie"
    -- Path to this actor's portrait for dialogue (optional)
    if Game.chapter == 1 then
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
        -- Cutscene animations
        ["look_up_left_walk"] = {"look_up_left_walk", 0.25, true},

        ["kick"] = {"kick", 0.1, false},
        ["slam"] = {"slam", 0.1, false},

        ["sit"] = {"sit", 0.25, true},

        ["eat_chalk"] = {"eat_chalk", 0.15, false},
    }

    -- Tables of sprites to change into in mirrors
    self.mirror_sprites = {
        ["walk/down"] = "walk/up",
        ["walk/up"] = "walk/down",
        ["walk/left"] = "walk/left",
        ["walk/right"] = "walk/right",

        ["walk_bangs/down"] = "walk_bangs/up",
        ["walk_bangs/up"] = "walk_bangs/down",
        ["walk_bangs/left"] = "walk_bangs/left",
        ["walk_bangs/right"] = "walk_bangs/right",
    }

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {
        -- Movement offsets
        ["walk/down"] = {0, -2},
        ["walk/left"] = {0, -2},
        ["walk/right"] = {0, -2},
        ["walk/up"] = {0, -2},

        ["walk_bangs/down"] = {0, -2},
        ["walk_bangs/left"] = {0, -2},
        ["walk_bangs/right"] = {0, -2},
        ["walk_bangs/up"] = {0, -2},

        -- Cutscene offsets
        ["chill"] = {2, -2},

        ["disappointed_chalk_box"] = {0, -2},
        ["hold_chalk_box"] = {0, -2},
        ["blink"] = {0, -2},

        ["look_up"] = {0, -2},

        ["eat_chalk"] = {0, -2},

        ["fall"] = {-2, -2},

        ["shock_down"] = {0, -2},
        ["shock_down_flip"] = {0, -2},

        ["laugh_left"] = {-8, -2},
        ["laugh_right"] = {-4, -2},

        ["playful_punch"] = {-8, 0},
        ["playful_punch_shock"] = {-8, 0},

        ["look_up_left_walk"] = {0, -2},

        ["kick"] = {-5, 0},
        ["slam"] = {-6, -5},

        ["angry_down"] = {-10, 2},
        ["turn_around"] = {-12, 2},

        ["away_scratch"] = {-2, -2},

    }
end

return actor