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

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {1, 0, 1}

    -- Path to this actor's sprites (defaults to "")
    self.path = "party/susie/light"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    if Game.chapter == 1 then
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
    self.animations = {}

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
    }
end

return actor