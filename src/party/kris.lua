return {
    name = "Kris",
    id = "kris",

    width = 19,
    height = 38,

    hitbox = {0, 24, 19, 14},

    path = "party/kris",
    default = "world/dark",
    offsets = {
        ["battle/dark/idle"] = {5, 1},

        ["battle/dark/attack"] = {8, 6},
        ["battle/dark/attackready"] = {8, 6},
        ["battle/dark/act"] = {6, 6},
        ["battle/dark/actready"] = {6, 6},
        ["battle/dark/item"] = {6, 6},
        ["battle/dark/itemready"] = {6, 6},
        ["battle/dark/defend"] = {5, 3},

        ["battle/dark/defeat"] = {6, 6},
        ["battle/dark/hurt"] = {5, 6},

        ["battle/dark/sword_jump_down"] = {17, 2},
        ["battle/dark/intro"] = {8, 9},
        ["battle/dark/victory"] = {3, 0},

        ["dark_transition/dark"] = {5, 6},
        ["dark_transition/ball"] = {5, 6},
        ["dark_transition/landed"] = {4, 2}
    },

    battle_offset = {2, 1},
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

        hurt = "battle/dark/hurt",
        defeat = "battle/dark/defeat",

        transition = "battle/dark/sword_jump_down",
        intro = "battle/dark/attack",
        victory = "battle/dark/victory",
    }
}