LOAD_TESTING = false

WIDTH = 640
HEIGHT = 480
SWIDTH = WIDTH/2
SHEIGHT = HEIGHT/2
FRAMERATE = 1/30

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