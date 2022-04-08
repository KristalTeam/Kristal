local actor, super = Class(Actor, "virovirokun")

function actor:init()
    super:init(self)

    -- Display name (optional)
    self.name = "Virovirokun"

    -- Width and height for this actor, used to determine its center
    self.width = 38
    self.height = 51

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = {0, 25, 38, 26}

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {1, 0, 0}

    -- Whether this actor flips horizontally (optional, values are "right" or "left", indicating the flip direction)
    self.flip = "right"

    -- Path to this actor's sprites (defaults to "")
    self.path = "enemies/virovirokun"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = "idle"

    -- Sound to play when this actor speaks (optional)
    self.voice = nil
    -- Path to this actor's portrait for dialogue (optional)
    self.portrait_path = nil
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = nil

    -- Table of sprite animations
    self.animations = {
        ["idle"] = {"idle", 0.25, true},
        ["spared"] = {"spared", 0, false},
        ["hurt"] = {"hurt", 0, false}
    }

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {
        ["idle"] = {6, 3},
        ["spared"] = {1, 0},
        ["hurt"] = {2, 2},
    }
end

return actor