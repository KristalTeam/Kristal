return {
    -- ID of the actor (optional, defaults to filepath)
    id = "dummy",

    -- Width and height of the actor (if unsure, just use sprite size)
    width = 27,
    height = 45,

    -- In-world hitbox, relative to the actor's topleft
    -- (these numbers are based on the actual deltarune hitbox)
    hitbox = {3, 24, 24, 16},

    -- Path to the actor's sprites
    path = "enemies/dummy",
    -- Default animation or sprite relative to the path
    default = "idle",

    animations = {
        -- Looping animation with 0.25 seconds between each frame
        -- (even though there's only 1 idle frame)
        ["idle"] = {"idle", 0.25, true},
    },

    offsets = {
        -- Since the width and height is the idle sprite size, the offset is 0,0
        ["idle"] = {0, 0},
    },
}