local actor, super = Class(Actor, "ralsei")

function actor:init(style)
    super.init(self)

    local ralsei_style = style or Game:getConfig("ralseiStyle")

    if ralsei_style == 1 then
        self:initChapter1()
    else
        self:initChapter2()
    end
end

function actor:initChapter1()
    -- Display name (optional)
    self.name = "Ralsei"

    -- Width and height for this actor, used to determine its center
    self.width = 23
    self.height = 43

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = {2, 31, 19, 14}

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {0, 1, 0}

    -- Path to this actor's sprites (defaults to "")
    self.path = "party/ralsei/dark_ch1"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = "walk"

    -- Sound to play when this actor speaks (optional)
    self.voice = "ralsei"
    -- Path to this actor's portrait for dialogue (optional)
    self.portrait_path = "face/ralsei_hat"
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = {-15, -10}

    -- Whether this actor as a follower will blush when close to the player
    self.can_blush = true

    -- Table of sprite animations
    self.animations = {
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

        ["battle/hurt"]         = {"battle/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/defeat", 1/15, false},

        ["battle/transition"]   = {"walk/right_1", 1/15, false},
        ["battle/intro"]        = {"battle/intro", 1/15, false},
        ["battle/victory"]      = {"battle/victory", 1/10, false},

        -- Cutscene animations
        ["hood"]                = {"hood", 0.25, true},
        ["pullhat"]             = {"pullhat", 0.25, true},
        ["removehood"]          = {"removehood", 0.25, false, next="walk/down"},
        ["reveal"]              = {"reveal", 0.3, false},
        ["sing"]                = {"sing", 0.4, true},
        ["sit"]                 = {"sit", 0.1, false},

    }

    -- Tables of sprites to change into in mirrors
    self.mirror_sprites = {
        ["walk/down"] = "walk/up",
        ["walk/up"] = "walk/down",
        ["walk/left"] = "walk/left",
        ["walk/right"] = "walk/right",

        ["walk_blush/down"] = "walk_blush/up",
        ["walk_blush/up"] = "walk_blush/down",
        ["walk_blush/left"] = "walk_blush/left",
        ["walk_blush/right"] = "walk_blush/right",
        
        ["walk_unhappy/down"] = "walk_unhappy/up",
        ["walk_unhappy/up"] = "walk_unhappy/down",
        ["walk_unhappy/left"] = "walk_unhappy/left",
        ["walk_unhappy/right"] = "walk_unhappy/right",
    }

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {
        -- Movement offsets
        ["walk/down"] = {0, 0},
        ["walk/left"] = {0, 0},
        ["walk/right"] = {0, 0},
        ["walk/up"] = {0, 0},

        ["walk_blush/down"] = {0, 0},
        ["walk_blush/left"] = {0, 0},
        ["walk_blush/right"] = {0, 0},
        ["walk_blush/up"] = {0, 0},

        -- Battle offsets
        ["battle/idle"] = {-7, -2},

        ["battle/attack"] = {-11, -3},
        ["battle/attackready"] = {-11, -3},
        ["battle/act"] = {-3, -2},
        ["battle/actend"] = {-3, -2},
        ["battle/actready"] = {-3, -2},
        ["battle/spell"] = {-12, -2},
        ["battle/spellready"] = {-12, -2},
        ["battle/item"] = {-8, -10},
        ["battle/itemready"] = {-8, -10},
        ["battle/defend"] = {-3, -2},

        ["battle/defeat"] = {-3, -2},
        ["battle/hurt"] = {-13, -2}, -- does this exist? Bor's answer: yes, it does.

        ["battle/intro"] = {-3, -2},
        ["battle/victory"] = {-3, -2},

        -- Cutscene offsets
        ["hood"] = {-2, -1},
        ["pullhat"] = {-1, -2},
        ["removehood"] = {-2, -1},
        ["reveal"] = {-2, -2},
        ["sing"] = {-10, -2},
        ["sit"] = {0, 0},
        ["shock"] = {-17, -4},
        ["fallen"] = {-8, 20}
    }
end

function actor:initChapter2()
    -- Display name (optional)
    self.name = "Ralsei"

    -- Width and height for this actor, used to determine its center
    self.width = 21
    self.height = 40

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = {1, 28, 19, 14}
    
    -- A table that defines where the Soul should be placed on this actor if they are a player.
    -- First value is x, second value is y.
    self.soul_offset = {10.5, 24}

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {0, 1, 0}

    -- Path to this actor's sprites (defaults to "")
    self.path = "party/ralsei/dark"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = "walk"

    -- Sound to play when this actor speaks (optional)
    self.voice = "ralsei"
    -- Path to this actor's portrait for dialogue (optional)
    self.portrait_path = "face/ralsei"
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = {-15, -10}

    -- Whether this actor as a follower will blush when close to the player
    self.can_blush = true

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
        ["battle/spare"]        = {"battle/spell", 1/15, false, next="battle/idle"},

        ["battle/attack_ready"] = {"battle/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/actready", 0.2, true},
        ["battle/spell_ready"]  = {"battle/spellready", 0.2, true},
        ["battle/item_ready"]   = {"battle/itemready", 0.2, true},
        ["battle/defend_ready"] = {"battle/defend", 1/15, false},

        ["battle/act_end"]      = {"battle/actend", 1/15, false, next="battle/idle"},

        ["battle/hurt"]         = {"battle/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/defeat", 1/15, false},

        ["battle/transition"]   = {"walk/right_1", 1/15, false},
        ["battle/intro"]        = {"battle/intro", 1/15, false},
        ["battle/victory"]      = {"battle/victory", 1/10, false},

        -- Cutscene animations
        ["jump_fall"]           = {"fall", 1/5, true},
        ["jump_ball"]           = {"ball", 1/15, true},

        ["laugh"]               = {"laugh", 4/30, true},

        ["hug"]                 = {"hug", 2/9, false},
        ["hug_stop"]            = {"hug_stop", 2/9, false},

        ["wave_start"]          = {"wave_start", 5/30, false, next="wave_down"},
        ["wave_down"]           = {"wave_down", 5/30, true}
    }

    -- Tables of sprites to change into in mirrors
    self.mirror_sprites = {
        ["walk/down"] = "walk/up",
        ["walk/up"] = "walk/down",
        ["walk/left"] = "walk/left",
        ["walk/right"] = "walk/right",

        ["walk_unhappy/down"] = "walk_unhappy/up",
        ["walk_unhappy/up"] = "walk_unhappy/down",
        ["walk_unhappy/left"] = "walk_unhappy/left",
        ["walk_unhappy/right"] = "walk_unhappy/right",
        
        ["walk_blush/down"] = "walk_blush/up",
        ["walk_blush/up"] = "walk_blush/down",
        ["walk_blush/left"] = "walk_blush/left",
        ["walk_blush/right"] = "walk_blush/right",
    }

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {
        -- Movement offsets
        ["walk/down"] = {0, 0},
        ["walk/left"] = {0, 0},
        ["walk/right"] = {0, 0},
        ["walk/up"] = {0, 0},

        ["walk_blush/down"] = {0, 0},
        ["walk_blush/left"] = {0, 0},
        ["walk_blush/right"] = {0, 0},
        ["walk_blush/up"] = {0, 0},

        ["walk_unhappy/down"] = {0, 0},
        ["walk_unhappy/left"] = {0, 0},
        ["walk_unhappy/right"] = {0, 0},
        ["walk_unhappy/up"] = {0, 0},

        ["slide"] = {-2, 2},

        -- Battle offsets
        ["battle/idle"] = {-2, -6},

        ["battle/attack"] = {-10, -6},
        ["battle/attackready"] = {-10, -6},
        ["battle/act"] = {-2, -6},
        ["battle/actend"] = {-2, -6},
        ["battle/actready"] = {-2, -6},
        ["battle/spell"] = {-11, -6},
        ["battle/spellready"] = {-11, -6},
        ["battle/item"] = {-7, -14},
        ["battle/itemready"] = {-7, -14},
        ["battle/defend"] = {-2, -6},

        ["battle/defeat"] = {-2, -6},
        ["battle/hurt"] = {-13, -2},

        ["battle/intro"] = {-2, -6},
        ["battle/victory"] = {0, -6},

        -- Cutscene offsets
        ["pose"] = {-1, -1},

        ["fall"] = {-10, 0},
        ["ball"] = {0, 9},
        ["landed"] = {-2, 0},

        ["hug"] = {0, 0},
        ["hug_stop"] = {0, 0},

        ["laugh"] = {-1, 0},

        ["shocked_behind"] = {-9, 3},
        ["surprised_down"] = {-5, -1},

        ["wave_start"] = {0, 0},
        ["wave_down"] = {2, 1},

        ["splat"] = {-15, 21},
        ["stool"] = {-11, 18}
    }
end

return actor