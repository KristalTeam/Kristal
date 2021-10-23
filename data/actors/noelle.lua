return {
    name = "Noelle",
    id = "noelle",

    width = 23,
    height = 46,

    hitbox = {2, 33, 19, 14},

    path = "party/noelle",
    default = "world/dark",
    offsets = {
        ["battle/dark/idle"] = {3, 0},

        ["battle/dark/attack"] = {8, 0},
        ["battle/dark/attackready"] = {0, 0},
        ["battle/dark/act"] = {0, 0},
        ["battle/dark/actend"] = {0, 0},
        ["battle/dark/actready"] = {0, 0},
        ["battle/dark/spell"] = {3, 0},
        ["battle/dark/spellready"] = {0, 0},
        ["battle/dark/item"] = {2, 0},
        ["battle/dark/itemready"] = {2, 0},
        ["battle/dark/defend"] = {9, 0},

        ["battle/dark/defeat"] = {0, 0},
        ["battle/dark/hurt"] = {9, 0},

        ["battle/dark/intro"] = {11, 7},
        ["battle/dark/victory"] = {0, 0},
    },

    battle_offset = {0, 0},
    battle = {
        idle = "battle/dark/idle",

        attack = "battle/dark/attack",
        act = "battle/dark/act",
        act_end = "battle/dark/actend",
        spell = "battle/dark/spell",
        item = "battle/dark/item",
        spare = "battle/dark/act",
        defend = "battle/dark/defend",

        attack_ready = "battle/dark/attackready",
        act_ready = "battle/dark/actready",
        spell_ready = "battle/dark/spellready",
        item_ready = "battle/dark/itemready",

        hurt = "battle/dark/hurt",
        defeat = "battle/dark/defeat",

        transition = "battle/dark/intro",
        victory = "battle/dark/victory",
    }
}