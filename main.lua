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
    ["Game"] = require("src.states.game"),
    ["Testing"] = require("src.states.testing"),
    ["DarkTransition"] = require("src.states.dark_transition")
}

-- Ease of access for game variables
Game = Kristal.States["Game"]

Assets = require("src.assets")
Draw = require("src.draw")

Object = require("src.object.object")
Stage = require("src.object.stage")
Sprite = require("src.object.sprite")
CharacterSprite = require("src.object.charactersprite")
Explosion = require("src.object.explosion")
AfterImage = require("src.object.afterimage")

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

Cutscene = require("src.cutscene")

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
    DTMULT = dt * 30

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

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    local errorResult

    local function mainLoop()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        -- Call update and draw
        if love.update then
            love.update(dt)
        end 

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then love.draw() end

            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.001) end
    end

    -- Main loop time.
    return function()
        if errorResult then
            local result = errorResult()
            if result then
                if love.quit then
                    love.quit()
                end
                return result
            end
        else
            local success, result = xpcall(mainLoop, Kristal.errorHandler)
            if success then
                return result
            else
                errorResult = result
            end
        end
    end
end

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function Kristal.errorHandler(msg)
    local copy_color = {1, 1, 1, 1}
    local anim_index = 1
    math.randomseed(os.time()) -- seed!
    local starwalker_error = (math.random(100) <= 5) -- 10% chance for starwalker
    local font = love.graphics.newFont("assets/fonts/main.ttf", 32, "mono")
    local smaller_font = love.graphics.newFont("assets/fonts/main.ttf", 16, "mono")

    local starwalker, starwalkertext, banana_anim

    if starwalker_error then
        starwalker = love.graphics.newImage("assets/sprites/kristal/starwalker.png")
        starwalkertext = love.graphics.newImage("assets/sprites/kristal/starwalkertext.png")
    else
        banana_anim = {
            love.graphics.newImage("assets/sprites/kristal/banana_1.png"),
            love.graphics.newImage("assets/sprites/kristal/banana_2.png"),
            love.graphics.newImage("assets/sprites/kristal/banana_3.png"),
            love.graphics.newImage("assets/sprites/kristal/banana_4.png"),
            love.graphics.newImage("assets/sprites/kristal/banana_5.png"),
            love.graphics.newImage("assets/sprites/kristal/banana_6.png"),
            love.graphics.newImage("assets/sprites/kristal/banana_7.png")
        }
    end

    msg = tostring(msg)

    error_printer(msg, 2)

    if not love.window or not love.graphics or not love.event then
        return
    end

    local width  = SCREEN_WIDTH
    local height = SCREEN_HEIGHT

    local window_scale = 1

    if Kristal.Config then
        window_scale = Kristal.Config["windowScale"] or 1
        if window_scale ~= 1 then
            local width  = SCREEN_WIDTH  * window_scale
            local height = SCREEN_HEIGHT * window_scale
        end
    end

    if not love.graphics.isCreated() or not love.window.isOpen() then
        local success, status = pcall(love.window.setMode, width, height)
        if not success or not status then
            return
        end
    end

    -- Reset state.
    if love.mouse then
        love.mouse.setVisible(true)
        love.mouse.setGrabbed(false)
        love.mouse.setRelativeMode(false)
        if love.mouse.isCursorSupported() then
            love.mouse.setCursor()
        end
    end
    if love.joystick then
        -- Stop all joystick vibrations.
        for i,v in ipairs(love.joystick.getJoysticks()) do
            v:setVibration()
        end
    end
    if love.audio then love.audio.stop() end

    love.graphics.reset()

    love.graphics.setColor(1, 1, 1, 1)

    local trace = debug.traceback("", 3)

    love.graphics.origin()

    local split = Utils.split(msg, ": ")

    local function draw()
        local pos = 32
        local ypos = pos
        love.graphics.origin()
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.scale(window_scale)

        love.graphics.setFont(font)

        local _,lines = font:getWrap("Error at "..split[1].." - "..split[2], 640 - pos)

        love.graphics.printf({"Error at ", {0.6, 0.6, 0.6, 1}, split[1], {1, 1, 1, 1}, " - " .. split[2]}, pos, ypos, 640 - pos)
        ypos = ypos + (32 * #lines)

        for l in trace:gmatch("(.-)\n") do
            if not l:match("boot.lua") then
                if l:match("stack traceback:") then
                    love.graphics.setFont(font)
                    love.graphics.printf("Traceback:", pos, ypos, 640 - pos)
                    ypos = ypos + 32
                else
                    love.graphics.setFont(smaller_font)
                    love.graphics.printf(l, pos, ypos, 640 - pos)
                    ypos = ypos + 16
                end
            end
        end

        if starwalker_error then
            love.graphics.draw(starwalkertext, 640 - starwalkertext:getWidth() - 20, 480 - starwalkertext:getHeight() - (starwalker:getHeight() * 2))

            love.graphics.push()
            love.graphics.scale(2, 2)
            love.graphics.draw(starwalker, 320 - starwalker:getWidth(), 240 - starwalker:getHeight())
            love.graphics.pop()
        else
            anim_index = anim_index + (DT * 4)
            if anim_index >= 8 then
                anim_index = 1
            end

            local banana = banana_anim[math.floor(anim_index)]

            love.graphics.push()
            love.graphics.scale(2, 2)
            love.graphics.draw(banana, 320 - banana:getWidth(), 240 - banana:getHeight())
            love.graphics.pop()
        end

        DT = love.timer.getDelta()

        copy_color[1] = copy_color[1] + (DT * 2)
        copy_color[3] = copy_color[3] + (DT * 2)

        love.graphics.setFont(smaller_font)
        love.graphics.setColor(copy_color)
        love.graphics.print("Press CTRL+C to copy traceback to clipboard", 8, 480 - 20)
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.present()
    end

    local function copyToClipboard()
        if not love.system then return end
        copy_color = {0, 1, 0, 1}
        love.system.setClipboardText(trace)
        draw()
    end

    return function()
        love.event.pump()

        for e, a, b, c in love.event.poll() do
            if e == "quit" then
                return 1
            elseif e == "keypressed" and a == "escape" then
                return "restart"
            elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
                copyToClipboard()
            elseif e == "touchpressed" then
                local name = love.window.getTitle()
                if #name == 0 or name == "Untitled" then name = "Game" end
                local buttons = {"OK", "Cancel"}
                if love.system then
                    buttons[3] = "Copy to clipboard"
                end
                local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
                if pressed == 1 then
                    return 1
                elseif pressed == 3 then
                    copyToClipboard()
                end
            end
        end

        draw()

        --if love.timer then
        --    love.timer.sleep(0.1)
        --end
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

function Kristal.LoadMod(id, after)
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

            after()
        end)
    else
        after()
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