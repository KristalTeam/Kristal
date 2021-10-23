return {
    id = "virovirokun",

    width = 38,
    height = 51,

    path = "enemies/virovirokun",
    default_anim = "idle",

    animations = {
        ["idle"] = {"idle", 0.2, true},
        ["spared"] = {"spared", 0, false},
        ["hurt"] = {"hurt", 0, false, temp=true, duration=0.5}
    },

    offsets = {
        ["idle"] = {6, 3},
        ["spared"] = {1, 0},
        ["hurt"] = {2, 2},
    },
}