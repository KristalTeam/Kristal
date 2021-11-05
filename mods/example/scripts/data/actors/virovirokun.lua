return {
    id = "virovirokun",

    width = 38,
    height = 51,

    hitbox = {0, 25, 38, 26},

    flip = "right",

    path = "enemies/virovirokun",
    default_anim = "idle",

    animations = {
        ["idle"] = {"idle", 0.25, true},
        ["spared"] = {"spared", 0, false},
        ["hurt"] = {"hurt", 0, false}
    },

    offsets = {
        ["idle"] = {6, 3},
        ["spared"] = {1, 0},
        ["hurt"] = {2, 2},
    },
}