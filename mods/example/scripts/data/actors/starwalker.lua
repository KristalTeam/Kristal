return {
    -- ID of the actor (optional, defaults to filepath)
    id = "starwalker",

    -- Width and height of the actor (if unsure, just use sprite size)
    width = 37,
    height = 36,

    -- In-world hitbox, relative to the actor's topleft
    -- (these numbers are based on the actual deltarune hitbox)
    hitbox = {2, 26, 27, 10},

    -- Path to the actor's sprites
    path = "npcs/starwalker",
    -- Default animation or sprite relative to the path
    default = ""
}