require("src.vars")

Class = require("src.lib.hump.class")
Vector = require("src.lib.hump.vector")

require ("src.classhelper")
require ("src.graphicshelper")

lib = {}

lib.gamestate = require("src.lib.hump.gamestate")
lib.vector = require("src.lib.hump.vector-light")
lib.timer = require("src.lib.hump.timer")
lib.json = require("src.lib.json")

utils = require("src.utils")

kristal = {}

kristal.mods = require("src.mods")
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

kristal.config = {}

Camera = require("src.lib.hump.camera")
Animation = require("src.animation")

Object = require("src.object.object")
Sprite = require("src.object.sprite")

Text = require("src.object.game.text")
DialogueText = require("src.object.game.dialoguetext")
TextChar = require("src.object.game.textchar")
ShadedChar = require("src.object.game.shadedchar")

ModList = require("src.object.menu.modlist")
ModButton = require("src.object.menu.modbutton")
ModMenuChar = require("src.object.menu.modmenuchar")

DarkTransitionLine = require("src.object.darktransition.darktransitionline")
DarkTransitionParticle = require("src.object.darktransition.darktransitionparticle")

local load_in_channel
local load_out_channel
local load_thread

local next_load_key = 0
local load_waiting = 0
local load_end_funcs = {}

function love.load()
    kristal.config = kristal.loadConfig()

    love.graphics.setDefaultFilter("nearest")

    if kristal.config.windowScale ~= 1 then
        love.window.setMode(WIDTH * kristal.config.windowScale, HEIGHT * kristal.config.windowScale)
    end

    -- setup structure
    love.filesystem.createDirectory("mods")

    -- register gamestate calls
    lib.gamestate.registerEvents()

    -- initialize overlay
    kristal.overlay:init()

    -- screen canvas
    SCREEN_CANVAS = love.graphics.newCanvas(WIDTH, HEIGHT)
    SCREEN_CANVAS:setFilter("nearest", "nearest")

    -- setup hooks
    love.update = utils.hook(love.update, function(orig, ...)
        orig(...)
        kristal.overlay:update(...)
    end)
    love.draw = utils.hook(love.draw, function(orig, ...)
        love.graphics.reset()

        love.graphics.setCanvas(SCREEN_CANVAS)
        love.graphics.clear()
        orig(...)
        kristal.overlay:draw()
        love.graphics.setCanvas()

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.scale(kristal.config.windowScale)
        love.graphics.draw(SCREEN_CANVAS)

        kristal.graphics._clearUnusedCanvases()
    end)

    -- start load thread
    load_in_channel = love.thread.getChannel("load_in")
    load_out_channel = love.thread.getChannel("load_out")

    load_thread = love.thread.newThread("src/loadthread.lua")
    load_thread:start()

    -- load menu
    kristal.states.switch(kristal.states.loading)
end

function love.quit()
    kristal.saveConfig()
    if load_thread and load_thread:isRunning() then
        load_in_channel:push("stop")
    end
end

function love.update(dt)
    lib.timer.update(dt)

    if load_waiting > 0 then
        local msg = load_out_channel:pop()
        if msg then
            load_waiting = load_waiting - 1
            
            if load_waiting == 0 then
                kristal.overlay.setLoading(false)
            end

            kristal.assets.loadData(msg.data.assets)
            kristal.data.loadData(msg.data.data)
            kristal.mods.loadData(msg.data.mods)

            if load_end_funcs[msg.key] then
                load_end_funcs[msg.key]()
                load_end_funcs[msg.key] = nil
            end
        end
    end
end

function kristal.clearAssets(include_mods)
    kristal.assets.clear()
    kristal.data.clear()
    if include_mods then
        kristal.mods.clear()
    end
end

function kristal.loadAssets(dir, loader, paths, after)
    kristal.overlay.setLoading(true)
    load_waiting = load_waiting + 1
    if after then
        load_end_funcs[next_load_key] = after
    end
    load_in_channel:push({
        key = next_load_key,
        dir = dir,
        loader = loader,
        paths = paths
    })
    next_load_key = next_load_key + 1
end

function kristal.loadMod(id)
    local mod = kristal.mods.getMod(id)

    if not mod then return end

    MOD = mod

    if love.filesystem.getInfo(mod.full_path.."/lua/mod.lua") then
        local chunk = love.filesystem.load(mod.full_path.."/lua/mod.lua")

        MOD_LOADING = true

        kristal.loadAssets(mod.full_path, "all", "", function()
            MOD_LOADING = false

            mod.lua = kristal.createModEnvironment()

            setfenv(chunk, mod.lua)
            chunk()
        end)
    end
end

function kristal.createModEnvironment()
    local env = setmetatable({}, {__index = _G})
    local function setupGlobals()
        function require(path)
            local chunk
            if love.filesystem.getInfo(MOD.full_path.."/lua/"..path..".lua") then
                chunk = love.filesystem.load(MOD.full_path.."/lua/"..path..".lua")
            elseif love.filesystem.getInfo(MOD.full_path.."/lua/"..path.."/init.lua") then
                chunk = love.filesystem.load(MOD.full_path.."/lua/"..path.."/init.lua")
            end
            setfenv(chunk, getfenv())()
        end
    end
    setfenv(setupGlobals, env)()
    return env
end

function kristal.loadConfig()
    local config = {
        windowScale = 1,
        skipIntro = false
    }
    if love.filesystem.getInfo("settings.json") then
        utils.merge(config, lib.json.decode(love.filesystem.read("settings.json")))
    end
    return config
end

function kristal.saveConfig()
    love.filesystem.write("settings.json", lib.json.encode(kristal.config))
end