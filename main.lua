Class = require("src.lib.hump.class")
Gamestate = require("src.lib.hump.gamestate")
Vector = require("src.lib.hump.vector-light")
Camera = require("src.lib.hump.camera")
Timer = require("src.lib.hump.timer")

require("src.vars")
FileSystem = require("src.utils.filesystem")
StrUtil = require("src.utils.string")

Assets = require("src.assets")

LoadState = require("src.state.loadstate")
ModMenu = require("src.state.modmenu")

function love.load()
    love.graphics.setDefaultFilter("nearest")
    Gamestate.registerEvents()
    Gamestate.switch({resume = function() Gamestate.switch(ModMenu) end})
    Gamestate.push(LoadState)
end