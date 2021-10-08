require("src.vars")

Class = require("src.lib.hump.class")
Vector = require("src.lib.hump.vector")

require ("src.classhelper")

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
kristal.graphics = require("src.graphics")
kristal.shaders = require("src.shaders")

kristal.states = require("src.states")
kristal.states.loading = require("src.states.loading")
kristal.states.menu = require("src.states.menu")
kristal.states.testing = require("src.states.testing")

Camera = require("src.lib.hump.camera")
Animation = require("src.animation")

Object = require("src.object.object")
DialogueChar = require("src.object.game.dialoguechar")
DialogueText = require("src.object.game.dialoguetext")
TypewriterText = require("src.object.game.typewritertext")

function love.load()
    love.graphics.setDefaultFilter("nearest")

    -- setup structure
    love.filesystem.createDirectory("mods")

    -- register gamestate calls
    lib.gamestate.registerEvents()

    -- initialize overlay
    kristal.overlay:init()

    -- setup hooks
    love.update = utils.hook(love.update, function(orig, ...)
        orig(...)
        kristal.overlay:update(...)
    end)
    love.draw = utils.hook(love.draw, function(orig, ...)
        orig(...)
        kristal.overlay:draw()
        kristal.graphics._clearUnusedCanvases()
    end)

    -- load menu
    kristal.states.switch(kristal.states.loading)
end

function love.update(dt)
    lib.timer.update(dt)
end