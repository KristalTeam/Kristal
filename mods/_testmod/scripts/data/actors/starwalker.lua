return {
    id = "starwalker",

    width = 37,
    height = 36,

    hitbox = {0, 22, 37, 14},

    path = "npcs/starwalker",
    default = "starwalker",

    animations = {
        ["wings"] = {"starwalker_wings", 0.25, true},
        ["hurt"] = {"starwalker_shoot_1", 0.5, true},
        ["shoot"] = {"starwalker_wings", 0.25, true, next="wings", frames={5,4,3,2}},
    },

    offsets = {
        ["starwalker"] = {0, 0},
        ["starwalker_wings"] = {6, 4},
        ["starwalker_shoot_1"] = {0, 0},
        ["starwalker_shoot_2"] = {5, 0},
    },

    color = {1, 1, 0, 1}
}