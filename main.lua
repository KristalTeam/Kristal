require("src.vars")

_Class = require("src.lib.hump.class")
Gamestate = require("src.lib.hump.gamestate")
Vector = require("src.lib.hump.vector-light")
Timer = require("src.lib.hump.timer")
Camera = require("src.lib.hump.camera")
JSON = require("src.lib.json")

Class = require("src.classhelper")
require ("src.graphicshelper")

Utils = require("src.utils")

Kristal = {}
Kristal.Config = {}
Kristal.Mods = require("src.mods")
Kristal.Overlay = require("src.overlay")
Kristal.Shaders = require("src.shaders")
Kristal.States = {
    ["Loading"] = require("src.states.loading"),
    ["Menu"] = require("src.states.menu"),
    ["Testing"] = require("src.states.testing"),
    ["DarkTransition"] = require("src.states.dark_transition")
}

Assets = require("src.assets")
Draw = require("src.draw")

Object = require("src.object.object")
Stage = require("src.object.stage")
Sprite = require("src.object.sprite")
Explosion = require("src.object.explosion")

Text = require("src.object.ui.text")
DialogueText = require("src.object.ui.dialoguetext")
TextChar = require("src.object.ui.textchar")
ShadedChar = require("src.object.ui.shadedchar")

ModList = require("src.object.menu.modlist")
ModButton = require("src.object.menu.modbutton")
ModMenuChar = require("src.object.menu.modmenuchar")

DarkTransitionLine = require("src.object.darktransition.darktransitionline")
DarkTransitionParticle = require("src.object.darktransition.darktransitionparticle")
DarkTransitionSparkle = require("src.object.darktransition.darktransitionsparkle")
FlashFade = require("src.object.darktransition.flashfade")
HeadObject = require("src.object.darktransition.head_object")

Collider = require("src.collider.collider")
Hitbox = require("src.collider.hitbox")
LineCollider = require("src.collider.linecollider")

World = require("src.object.game.world")
Tileset = require("src.tileset")
TileLayer = require("src.object.game.tilelayer")
Character = require("src.object.game.character")

Event = require("src.object.game.event")
Savepoint = require("src.object.game.savepoint")

local load_in_channel
local load_out_channel
local load_thread

local next_load_key = 0
local load_waiting = 0
local load_end_funcs = {}

function love.load()
    -- load the settings.json
    Kristal.Config = Kristal.LoadConfig()

    -- pixel scaling (the good one)
    love.graphics.setDefaultFilter("nearest")

    -- scale the window if we have to
    local window_scale = Kristal.Config["windowScale"]
    if window_scale ~= 1 then
        love.window.setMode(SCREEN_WIDTH * window_scale, SCREEN_HEIGHT * window_scale)
    end

    -- setup structure
    love.filesystem.createDirectory("mods")

    -- register gamestate calls
    Gamestate.registerEvents()

    -- initialize overlay
    Kristal.Overlay:init()

    -- screen canvas
    SCREEN_CANVAS = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    SCREEN_CANVAS:setFilter("nearest", "nearest")

    -- setup hooks
    love.update = Utils.hook(love.update, function(orig, ...)
        orig(...)
        Kristal.Overlay:update(...)
    end)
    love.draw = Utils.hook(love.draw, function(orig, ...)
        love.graphics.reset()

        love.graphics.setCanvas(SCREEN_CANVAS)
        love.graphics.clear()
        orig(...)
        Kristal.Overlay:draw()
        love.graphics.setCanvas()

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.scale(Kristal.Config["windowScale"])
        love.graphics.draw(SCREEN_CANVAS)

        Draw._clearUnusedCanvases()
    end)

    -- start load thread
    load_in_channel = love.thread.getChannel("load_in")
    load_out_channel = love.thread.getChannel("load_out")

    load_thread = love.thread.newThread("src/loadthread.lua")
    load_thread:start()

    -- load menu
    Gamestate.switch(Kristal.States["Loading"])
end

function love.quit()
    Kristal.SaveConfig()
    if load_thread and load_thread:isRunning() then
        load_in_channel:push("stop")
    end
end

function love.update(dt)
    DT = dt

    Timer.update(dt)

    if load_waiting > 0 then
        local msg = load_out_channel:pop()
        if msg then
            load_waiting = load_waiting - 1
            
            if load_waiting == 0 then
                Kristal.Overlay.setLoading(false)
            end

            Assets.loadData(msg.data.assets)
            Kristal.Mods.loadData(msg.data.mods)

            if load_end_funcs[msg.key] then
                load_end_funcs[msg.key]()
                load_end_funcs[msg.key] = nil
            end
        end
    end
end

function Kristal.ClearAssets(include_mods)
    Assets.clear()
    if include_mods then
        Kristal.Mods.clear()
    end
end

function Kristal.LoadAssets(dir, loader, paths, after)
    Kristal.Overlay.setLoading(true)
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

function Kristal.LoadMod(id)
    local mod = Kristal.Mods.getMod(id)

    if not mod then return end

    MOD = mod

    if mod.script_chunks["scripts/mod"] then
        local chunk = mod.script_chunks["scripts/mod"]

        MOD_LOADING = true

        Kristal.LoadAssets(mod.path, "all", "", function()
            MOD_LOADING = false

            MOD.env = Kristal.CreateModEnvironment()

            setfenv(chunk, MOD.env)
            chunk()
        end)
    end
end

function Kristal.CreateModEnvironment(global)
    local env = setmetatable({}, {__index = global or _G})
    local function setupGlobals()
        function require(path)
            local chunk = MOD.script_chunks["scripts/"..path]
            --[[if love.filesystem.getInfo(MOD.path.."/scripts/"..path..".lua") then
                chunk = love.filesystem.load(MOD.path.."/scripts/"..path..".lua")
            elseif love.filesystem.getInfo(MOD.path.."/scripts/"..path.."/init.lua") then
                chunk = love.filesystem.load(MOD.path.."/scripts/"..path.."/init.lua")
            end]]
            setfenv(chunk, getfenv())()
        end
    end
    setfenv(setupGlobals, env)()
    return env
end

function Kristal.LoadConfig()
    local config = {
        windowScale = 1,
        skipIntro = false
    }
    if love.filesystem.getInfo("settings.json") then
        Utils.merge(config, JSON.decode(love.filesystem.read("settings.json")))
    end
    return config
end

function Kristal.SaveConfig()
    love.filesystem.write("settings.json", JSON.encode(Kristal.Config))
end

function Kristal.modCall(f, ...)
    if MOD and MOD.env and MOD.env[f] then
        return MOD.env[f](...)
    end
end

function Kristal.modGet(k)
    if MOD and MOD.env and MOD.env[k] then
        return MOD.env[k]
    end
end

function Kristal.executeModScript(path, ...)
    if not MOD.script_chunks[path] then
        return false
    else
        return true, MOD.script_chunks[path](...)
    end
end