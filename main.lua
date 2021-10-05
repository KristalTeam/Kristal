Class = require("src.lib.hump.class")
Gamestate = require("src.lib.hump.gamestate")
Vector = require("src.lib.hump.vector-light")
Camera = require("src.lib.hump.camera")
Timer = require("src.lib.hump.timer")

require("src.vars")
Utils = require("src.utils")

Assets = require("src.assets")
Data = require("src.data")

TestState = require("src.state.teststate")
LoadState = require("src.state.loadstate")
ModMenu = require("src.state.modmenu")

Animation = require("src.animation")

function love.load()
    love.graphics.setDefaultFilter("nearest")
    Gamestate.registerEvents()
    --Gamestate.switch({resume = function() Gamestate.switch(TestState) end})
    Gamestate.switch({resume = function() Gamestate.switch(ModMenu) end})
    Gamestate.push(LoadState)
end