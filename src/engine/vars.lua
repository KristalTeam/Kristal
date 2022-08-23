SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480

BORDER_WIDTH = 1920
BORDER_HEIGHT = 1080
BORDER_SCALE = 0.5

BORDER_ALPHA = 0
BORDER_FADING = "OUT"
BORDER_FADE_TIME = 0.5
BORDER_FADE_FROM = nil
BORDER_TRANSITIONING = false
LAST_BORDER = nil

BORDER_TYPES = {
    {"off",     "OFF",     nil},
    {"dynamic", "Dynamic", nil},
    {"simple",  "Simple",  "simple"},
    {"none",    "None",    nil}
}

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

WORLD_LAYERS = {
    [       "bottom"] = -100,
    [ "above_events"] =  100, --┰-- 100
    [   "below_soul"] =  100, --┙
    [         "soul"] =  200,
    [   "above_soul"] =  300, --┰-- 300
    ["below_bullets"] =  300, --┙
    [      "bullets"] =  400,
    ["above_bullets"] =  500, --┰-- 500
    [     "below_ui"] =  500, --┙
    [           "ui"] =  600,
    [     "above_ui"] =  700, --┰-- 700
    ["below_textbox"] =  700, --┙
    [      "textbox"] =  800,
    ["above_textbox"] =  900,
    [          "top"] = 1000
}

SHOP_LAYERS = {
    [      "background"] = -100,
    ["below_shopkeeper"] =  100,
    [      "shopkeeper"] =  200,
    ["above_shopkeeper"] =  300, --┰-- 300
    [     "below_boxes"] =  300, --┙
    [           "cover"] =  400,
    [       "large_box"] =  450,
    [        "left_box"] =  500,
    [        "info_box"] =  550,
    [       "right_box"] =  600,
    [     "above_boxes"] =  700, --┰-- 700
    [  "below_dialogue"] =  700, --┙
    [        "dialogue"] =  800,
    [  "above_dialogue"] =  900,
    [             "top"] = 1000
}

MUSIC_VOLUME = 0.7
MUSIC_VOLUMES = {
    ["battle"] = 0.7
}
MUSIC_PITCHES = {}

-- Colors used by the engine for various things, here for customizability
PALETTE = {
    ["action_strip"] = {51/255, 32/255, 51/255, 1},
    ["tension_back"] = {128/255, 0, 0, 1},
    ["tension_decrease"] = {1, 0, 0, 1},
    ["tension_fill"] = {255/255, 160/255, 64/255, 1},
    ["tension_max"] = {255/255, 208/255, 32/255, 1},
    ["tension_maxtext"] = {1, 1, 0, 1},
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
