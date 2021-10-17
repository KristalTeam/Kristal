return {
    name = "Kris",
    id = "kris",

    width = 19,
    height = 38,

    hitbox = {0, 24, 19, 14},

    path = "party/kris",
    default = "world/dark",
    offsets = {
        ["battle/dark/attack"] = {8, 6},
        ["battle/dark/intro"] = {8, 9},
        ["battle/dark/idle"] = {5, 1},
        ["battle/dark/sword_jump_down"] = {17, 2}
    },

    battle = {
        idle = "battle/dark/idle",

        attack = "battle/dark/attack",
        act = "battle/dark/act",
        item = "battle/dark/item",
        spare = "battle/dark/act",
        defend = "battle/dark/defend",

        attack_ready = "battle/dark/attackready",
        act_ready = "battle/dark/actready",
        item_ready = "battle/dark/itemready",

        intro = {"battle/dark/sword_jump_down", "battle/dark/attack"},
        victory = "battle/dark/victory"
    }
}