return {
    id = "starwalker",

    width = 37,
    height = 36,

    hitbox = {0, 22, 37, 14},

    path = "npcs/starwalker",
    default = "starwalker",

    animations = {
        ["wings"] = {"starwalker_wings", 0.25, true},
    },

    offsets = {
        ["starwalker"] = {0, 0},
        ["starwalker_wings"] = {6, 4},
    },

    color = {1, 1, 0, 1}
}