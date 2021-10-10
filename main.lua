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
kristal.states.dark_transition = require("src.states.dark_transition")
kristal.states.testing = require("src.states.testing")

Camera = require("src.lib.hump.camera")
Animation = require("src.animation")

Object = require("src.object.object")
Sprite = require("src.object.sprite")
Text = require("src.object.game.text")
TextChar = require("src.object.game.textchar")
DialogueText = require("src.object.game.dialoguetext")
DarkTransitionLine = require("src.object.darktransition.darktransitionline")
DarkTransitionParticle = require("src.object.darktransition.darktransitionparticle")

local mod_loading_channel

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

    if MOD_LOADING then
        local data = mod_loading_channel:pop()

        if data ~= nil then
            kristal.assets.loadData(data.assets)
            kristal.data.loadData(data.data)

            local chunk = MOD_LOADING

            MOD_LOADING = nil
            mod_loading_channel = nil
            kristal.overlay.setLoading(false)

            MOD = kristal.createModEnvironment()

            setfenv(chunk, MOD)
            chunk()
        end
    end
end

function kristal.loadMod(path)
    MOD = nil
    MOD_NAME = path
    MOD_PATH = "mods/"..path

    if love.filesystem.getInfo(MOD_PATH.."/mod.json") then
        local info = lib.json.decode(love.filesystem.read(MOD_PATH.."/mod.json"))
        if info.name then
            MOD_NAME = info.name
        end
    end

    if love.filesystem.getInfo(MOD_PATH.."/lua/mod.lua") then
        local chunk = love.filesystem.load(MOD_PATH.."/lua/mod.lua")

        MOD_LOADING = chunk

        love.thread.newThread("src/loadthread.lua"):start(MOD_PATH)
        mod_loading_channel = love.thread.getChannel("assets")
        kristal.overlay.setLoading(true)
    end
end

function kristal.createModEnvironment()
    local env = setmetatable({}, {__index = _G})
    local function setupGlobals()
        function require(path)
            local chunk
            if love.filesystem.getInfo(MOD_PATH.."/lua/"..path..".lua") then
                chunk = love.filesystem.load(MOD_PATH.."/lua/"..path..".lua")
            elseif love.filesystem.getInfo(MOD_PATH.."/lua/"..path.."/init.lua") then
                chunk = love.filesystem.load(MOD_PATH.."/lua/"..path.."/init.lua")
            end
            setfenv(chunk, getfenv())()
        end
    end
    setfenv(setupGlobals, env)()
    return env
end