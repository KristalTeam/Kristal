return {
    name = "Susie",
    id = "susie_lw",

    width = 25,
    height = 43,

    hitbox = {3, 30, 19, 14},

    color = {1, 0, 1},

    path = "party/susie/light",
    default = "walk",

    text_sound = "susie",
    portrait_path = "face/susie",
    portrait_offset = {-5, 0},

    animations = {},

    offsets = {
        -- Movement offsets
        ["walk/down"] = {0, 2},
        ["walk/left"] = {0, 2},
        ["walk/right"] = {0, 2},
        ["walk/up"] = {0, 2},
    },
}