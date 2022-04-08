local Actor = Class()

function Actor:init()
    -- Display name (optional)
    self.name = nil

    -- Width and height for this actor, used to determine its center
    self.width = 0
    self.height = 0

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = nil

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {1, 0, 0}

    -- Whether this actor flips horizontally (optional, values are "right" or "left", indicating the flip direction)
    self.flip = nil

    -- Path to this actor's sprites (defaults to "")
    self.path = ""
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = ""

    -- Sound to play when this actor speaks (optional)
    self.voice = nil
    -- Path to this actor's portrait for dialogue (optional)
    self.portrait_path = nil
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = nil

    -- Table of sprite animations
    self.animations = {}

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {}
end

function Actor:onWorldUpdate(chara, dt) end
function Actor:onWorldDraw(chara) end

return Actor