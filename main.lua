require("src.vars")

Class = require("src.lib.hump.class")

lib = {}

lib.gamestate = require("src.lib.hump.gamestate")
lib.vector = require("src.lib.hump.vector-light")
lib.timer = require("src.lib.hump.timer")

utils = require("src.utils")

kristal = {}

kristal.assets = require("src.assets")
kristal.data = require("src.data")

kristal.states = require("src.states")
kristal.states.loading = require("src.states.loading")
kristal.states.menu = require("src.states.menu")
kristal.states.testing = require("src.states.testing")

Camera = require("src.lib.hump.camera")
Animation = require("src.animation")

function love.load()
    love.graphics.setDefaultFilter("nearest")
    lib.gamestate.registerEvents()
    kristal.states.switch(kristal.states.loading)
end
