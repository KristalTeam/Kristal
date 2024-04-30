local actor, super = Class(Actor, "susie_dark_transition")

function actor:init(style)
    super.init(self)

    -- Width and height for this actor, used to determine its center
    self.width = 25
    self.height = 43

    -- Path to this actor's sprites (defaults to "")
    self.path = "party/susie/dark_transition"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = "run"
end

return actor