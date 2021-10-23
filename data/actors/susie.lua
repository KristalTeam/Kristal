return {
    name = "Susie",
    id = "susie",

    width = 25,
    height = 43,

    hitbox = {3, 30, 19, 14},

    path = "party/susie",
    default = "world/dark",

    animations = {
        ["battle/idle"]         = {"battle/dark/idle", 0.2, true},

        ["battle/attack"]       = {"battle/dark/attack", 1/15, false},
        ["battle/act"]          = {"battle/dark/act", 1/15, false},
        ["battle/spell"]        = {"battle/dark/spell", 1/15, false, next="battle/idle"},
        ["battle/item"]         = {"battle/dark/item", 1/15, false, next="battle/idle"},
        ["battle/spare"]        = {"battle/dark/act", 1/15, false, next="battle/idle"},
        ["battle/defend"]       = {"battle/dark/defend", 1/15, false},

        ["battle/attack_ready"] = {"battle/dark/attackready", 0.2, true},
        ["battle/act_ready"]    = {"battle/dark/actready", 0.2, true},
        ["battle/spell_ready"]  = {"battle/dark/spellready", 0.2, true},
        ["battle/item_ready"]   = {"battle/dark/itemready", 0.2, true},

        ["battle/act_end"]      = {"battle/dark/actend", 1/15, false, next="battle/idle"},

        ["battle/hurt"]         = {"battle/dark/hurt", 1/15, false, temp=true, duration=0.5},
        ["battle/defeat"]       = {"battle/dark/defeat", 1/15, false},

        ["battle/transition"]   = {"world/dark/right_1", 1/15, false},
        ["battle/intro"]        = {"battle/dark/attack", 1/15, true},
        ["battle/victory"]      = {"battle/dark/victory", 1/15, false},

        ["battle/rude_buster"]  = {"battle/dark/rude_buster", 1/15, false, next="battle/idle"}
    },

    offsets = {
        ["world/dark/down"] = {0, 2},
        ["world/dark/left"] = {0, 2},
        ["world/dark/right"] = {0, 2},
        ["world/dark/up"] = {0, 2},

        ["battle/dark/idle"] = {22, 1},

        ["battle/dark/attack"] = {26, 25},
        ["battle/dark/attackready"] = {26, 25},
        ["battle/dark/act"] = {26, 25},
        ["battle/dark/actend"] = {26, 25},
        ["battle/dark/actready"] = {26, 25},
        ["battle/dark/spell"] = {22, 30},
        ["battle/dark/spellready"] = {22, 30},
        ["battle/dark/item"] = {22, 1},
        ["battle/dark/itemready"] = {22, 1},
        ["battle/dark/defend"] = {20, 23},

        ["battle/dark/defeat"] = {22, 1},
        ["battle/dark/hurt"] = {22, 1},

        ["battle/dark/victory"] = {28, 7},

        ["battle/dark/rudebuster"] = {44, 33}
    },

    --[[battle_offset = {3, 1},
    battle = {
        idle            = "battle/dark_bangs/idle",

        attack          = "battle/dark_bangs/attack",
        act             = "battle/dark_bangs/act",
        act_end         = "battle/dark_bangs/actend",
        spell           = "battle/dark_bangs/spell",
        item            = "battle/dark_bangs/item",
        spare           = "battle/dark_bangs/spell",
        defend          = "battle/dark_bangs/defend",

        attack_ready    = "battle/dark_bangs/attackready",
        act_ready       = "battle/dark_bangs/actready",
        spell_ready     = "battle/dark_bangs/spellready",
        item_ready      = "battle/dark_bangs/itemready",

        hurt            = "battle/dark_bangs/hurt",
        defeat          = "battle/dark_bangs/defeat",

        transition      = "world/dark/right_1",
        intro           = "battle/dark_bangs/attack",
        victory         = "battle/dark_bangs/victory",

        rude_buster     = "battle/dark_bangs/rudebuster"
    }]]
}