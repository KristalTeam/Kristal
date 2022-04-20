local actor, super = Class(Actor, "ralsei_ch1")

function actor:init()
    super:init(self)

    -- Display name (optional)
    self.name = "Ralsei"

    -- Width and height for this actor, used to determine its center
    self.width = 23
    self.height = 43

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = {0, 27, 19, 14}

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

        --["battle/hurt"]         = {"battle/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/defeat", 1/15, false},

        ["battle/transition"]   = {"walk/right_1", 1/15, false},
        ["battle/intro"]        = {"battle/intro", 1/15, false},
        ["battle/victory"]      = {"battle/victory", 1/10, false}
    }

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {
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
        --["battle/hurt"] = {-13, -2}, -- does this exist?

        ["battle/intro"] = {-3, -2},
        ["battle/victory"] = {-3, -2}
    }
end

return actor