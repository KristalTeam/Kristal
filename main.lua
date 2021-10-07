require("src.vars")

Class = require("src.lib.hump.class")

lib = {}

lib.gamestate = require("src.lib.hump.gamestate")
lib.vector = require("src.lib.hump.vector-light")
lib.timer = require("src.lib.hump.timer")
lib.json = require("src.lib.json")

utils = require("src.utils")

kristal = {}

kristal.assets = require("src.assets")
kristal.data = require("src.data")
kristal.overlay = require("src.overlay")

kristal.states = require("src.states")
kristal.states.loading = require("src.states.loading")
kristal.states.menu = require("src.states.menu")
kristal.states.testing = require("src.states.testing")

Camera = require("src.lib.hump.camera")
Animation = require("src.animation")

function love.load()
    love.graphics.setDefaultFilter("nearest")

    -- setup structure
    love.filesystem.createDirectory("mods")

    -- register gamestate calls
    lib.gamestate.registerEvents()

    -- setup overlay
    kristal.overlay:init()
    love.update = utils.hook(love.update, function(orig, ...)
        orig(...)
        kristal.overlay:update(...)
    end)
    love.draw = utils.hook(love.draw, function(orig, ...)
        orig(...)
        kristal.overlay:draw()
    end)

    -- load menu
    kristal.states.switch(kristal.states.loading)
end

function love.update(dt)
    lib.timer.update(dt)
end