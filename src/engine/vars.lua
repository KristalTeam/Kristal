 -- replaces mod list with "Start game", should be a string of the mod id
TARGET_MOD = nil

FRAMERATE = 1/60

SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480

TILE_WIDTH = 40
TILE_HEIGHT = 40

FOLLOW_DELAY = 0.4

BATTLE_LAYERS = {
    [        "bottom"] = -1000,
    ["below_battlers"] =  -200,
    [      "battlers"] =  -100,
    ["above_battlers"] =     0, --┰-- 0
    [      "below_ui"] =     0, --┙
    [            "ui"] =   100,
    ["damage_numbers"] =   150,
    [      "above_ui"] =   200, --┰-- 200
    [   "below_arena"] =   200, --┙
    [         "arena"] =   300,
    [   "above_arena"] =   400, --┰-- 400
    [    "below_soul"] =   400, --┙
    [          "soul"] =   500,
    [    "above_soul"] =   600, --┰-- 600
    [ "below_bullets"] =   600, --┙
    [       "bullets"] =   700,
    [ "above_bullets"] =   800,
    [           "top"] =  1000
}

MUSIC_VOLUME = 0.7
MUSIC_VOLUMES = {
    ["battle"] = 0.7
}
MUSIC_PITCHES = {}

-- Colors used by the engine for various things, here for customizability
PALETTE = {
    ["action_strip"] = {51/255, 32/255, 51/255, 1}
}

COLORS = {
    aqua = {0, 1, 1, 1},
    black = {0, 0, 0, 1},
    blue = {0, 0, 1, 1},
    dkgray = {0.25, 0.25, 0.25, 1},
    fuchsia = {1, 0, 1, 1},
    gray = {0.5, 0.5, 0.5, 1},
    green = {0, 0.5, 0, 1},
    lime = {0, 1, 0, 1},
    ltgray = {0.75, 0.75, 0.75, 1},
    maroon = {0.5, 0, 0, 1},
    navy = {0, 0, 0.5, 1},
    olive = {0.5, 0.5, 0, 1},
    orange = {1, 0.625, 0.25, 1},
    purple = {0.5, 0, 0.5, 1},
    red = {1, 0, 0, 1},
    silver = {0.75, 0.75, 0.75, 1},
    teal = {0, 0.5, 0.5, 1},
    white = {1, 1, 1, 1},
    yellow = {1, 1, 0, 1}
}
for _,v in pairs(COLORS) do
    setmetatable(v, {__call = function(c, a) return {c[1], c[2], c[3], a or 1} end})
end

CHAR_TEXTURES = {
    ["!"] = "exclamation",
    ["\""] = "quote",
    ["#"] = "pound",
    ["$"] = "dollar",
    ["%"] = "percent",
    ["&"] = "ampersand",
    ["'"] = "apostrophe",
    ["("] = "left_paren",
    [")"] = "right_paren",
    ["*"] = "asterisk",
    ["+"] = "plus",
    [","] = "comma",
    ["-"] = "dash",
    ["."] = "period",
    ["/"] = "slash",
    ["0"] = "0",
    ["1"] = "1",
    ["2"] = "2",
    ["3"] = "3",
    ["4"] = "4",
    ["5"] = "5",
    ["6"] = "6",
    ["7"] = "7",
    ["8"] = "8",
    ["9"] = "9",
    [":"] = "colon",
    [";"] = "semicolon",
    ["<"] = "lesser",
    ["="] = "equals",
    [">"] = "greater",
    ["?"] = "question",
    ["@"] = "at",
    ["A"] = "uppercase/A",
    ["B"] = "uppercase/B",
    ["C"] = "uppercase/C",
    ["D"] = "uppercase/D",
    ["E"] = "uppercase/E",
    ["F"] = "uppercase/F",
    ["G"] = "uppercase/G",
    ["H"] = "uppercase/H",
    ["I"] = "uppercase/I",
    ["J"] = "uppercase/J",
    ["K"] = "uppercase/K",
    ["L"] = "uppercase/L",
    ["M"] = "uppercase/M",
    ["N"] = "uppercase/N",
    ["O"] = "uppercase/O",
    ["P"] = "uppercase/P",
    ["Q"] = "uppercase/Q",
    ["R"] = "uppercase/R",
    ["S"] = "uppercase/S",
    ["T"] = "uppercase/T",
    ["U"] = "uppercase/U",
    ["V"] = "uppercase/V",
    ["W"] = "uppercase/W",
    ["X"] = "uppercase/X",
    ["Y"] = "uppercase/Y",
    ["Z"] = "uppercase/Z",
    ["["] = "left_bracket",
    ["\\"] = "backslash",
    ["]"] = "right_bracket",
    ["^"] = "caret",
    ["_"] = "underscore",
    ["`"] = "grave",
    ["a"] = "lowercase/a",
    ["b"] = "lowercase/b",
    ["c"] = "lowercase/c",
    ["d"] = "lowercase/d",
    ["e"] = "lowercase/e",
    ["f"] = "lowercase/f",
    ["g"] = "lowercase/g",
    ["h"] = "lowercase/h",
    ["i"] = "lowercase/i",
    ["j"] = "lowercase/j",
    ["k"] = "lowercase/k",
    ["l"] = "lowercase/l",
    ["m"] = "lowercase/m",
    ["n"] = "lowercase/n",
    ["o"] = "lowercase/o",
    ["p"] = "lowercase/p",
    ["q"] = "lowercase/q",
    ["r"] = "lowercase/r",
    ["s"] = "lowercase/s",
    ["t"] = "lowercase/t",
    ["u"] = "lowercase/u",
    ["v"] = "lowercase/v",
    ["w"] = "lowercase/w",
    ["x"] = "lowercase/x",
    ["y"] = "lowercase/y",
    ["z"] = "lowercase/z",
    ["{"] = "left_curly",
    ["|"] = "pipe",
    ["}"] = "right_curly",
    ["~"] = "tilde",
    [" "] = "space"
}