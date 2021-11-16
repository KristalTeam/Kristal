require("src.engine.vars")

_Class = require("src.lib.hump.class")
Gamestate = require("src.lib.hump.gamestate")
Vector = require("src.lib.hump.vector-light")
LibTimer = require("src.lib.hump.timer")
Camera = require("src.lib.hump.camera")
JSON = require("src.lib.json")
Ease = require("src.lib.easing")

Class = require("src.utils.class")
require ("src.utils.graphics")

Utils = require("src.utils.utils")
CollisionUtil = require("src.utils.collision")
Draw = require("src.utils.draw")

Kristal = {}
Kristal.Config = {}
Kristal.Mods = require("src.engine.mods")
Kristal.Overlay = require("src.engine.overlay")
Kristal.Shaders = require("src.engine.shaders")
Kristal.States = {
    ["Loading"] = require("src.engine.loadstate"),
    ["Menu"] = require("src.engine.menu.menu"),
    ["Game"] = require("src.engine.game.game"),
    ["DarkTransition"] = require("src.engine.game.darktransition.dark_transition"),
    ["Testing"] = require("src.teststate"),
}

-- Ease of access for game variables
Game = Kristal.States["Game"]

Assets = require("src.engine.assets")
Music = require("src.engine.music")
Input = require("src.engine.input")
Registry = require("src.engine.registry")

Object = require("src.engine.object")
Stage = require("src.engine.objects.stage")
Sprite = require("src.engine.objects.sprite")
Text = require("src.engine.objects.text")
DialogueText = require("src.engine.objects.dialoguetext")
Explosion = require("src.engine.objects.explosion")
AfterImage = require("src.engine.objects.afterimage")
FakeClone = require("src.engine.objects.fakeclone")
Rectangle = require("src.engine.objects.rectangle")
Timer = require("src.engine.objects.timer")

ModList = require("src.engine.menu.modlist")
ModButton = require("src.engine.menu.modbutton")

DarkTransitionLine = require("src.engine.game.darktransition.darktransitionline")
DarkTransitionParticle = require("src.engine.game.darktransition.darktransitionparticle")
DarkTransitionSparkle = require("src.engine.game.darktransition.darktransitionsparkle")
HeadObject = require("src.engine.game.darktransition.head_object")

Collider = require("src.engine.colliders.collider")
ColliderGroup = require("src.engine.colliders.collidergroup")
Hitbox = require("src.engine.colliders.hitbox")
LineCollider = require("src.engine.colliders.linecollider")
CircleCollider = require("src.engine.colliders.circlecollider")
PointCollider = require("src.engine.colliders.pointcollider")
PolygonCollider = require("src.engine.colliders.polygoncollider")

PartyMember = require("src.engine.game.scripts.partymember")
Spell = require("src.engine.game.scripts.spell")
Item = require("src.engine.game.scripts.item")
HealItem = require("src.engine.game.scripts.healitem")
Encounter = require("src.engine.game.scripts.encounter")
Wave = require("src.engine.game.scripts.wave")

ActorSprite = require("src.engine.game.actorsprite")

Cutscene = require("src.engine.game.cutscene")
WorldCutscene = require("src.engine.game.world.worldcutscene")
BattleCutscene = require("src.engine.game.battle.battlecutscene")

World = require("src.engine.game.world")
Tileset = require("src.engine.game.world.tileset")
TileLayer = require("src.engine.game.world.tilelayer")
Character = require("src.engine.game.world.character")
Follower = require("src.engine.game.world.follower")
Player = require("src.engine.game.world.player")
OverworldSoul = require("src.engine.game.world.overworldsoul")
ChaserEnemy = require("src.engine.game.world.chaserenemy")

DarkBox = require("src.engine.game.world.ui.darkbox")
Textbox = require("src.engine.game.world.ui.textbox")
Choicebox = require("src.engine.game.world.ui.choicebox")
DarkMenu = require("src.engine.game.world.ui.darkmenu")
HealthBar = require("src.engine.game.world.ui.healthbar")
OverworldActionBox = require("src.engine.game.world.ui.overworldactionbox")

Event = require("src.engine.game.world.event")
Readable = require("src.engine.game.world.events.readable")
Script = require("src.engine.game.world.events.script")
InteractScript = require("src.engine.game.world.events.interactscript")
Savepoint = require("src.engine.game.world.events.savepoint")
Transition = require("src.engine.game.world.events.transition")
NPC = require("src.engine.game.world.events.npc")
Outline = require("src.engine.game.world.events.outline")
Silhouette = require("src.engine.game.world.events.silhouette")
FrozenEnemy = require("src.engine.game.world.frozenenemy")

Battle = require("src.engine.game.battle")
Battler = require("src.engine.game.battle.battler")
PartyBattler = require("src.engine.game.battle.partybattler")
EnemyBattler = require("src.engine.game.battle.enemybattler")
Arena = require("src.engine.game.battle.arena")
Soul = require("src.engine.game.battle.soul")
Bullet = require("src.engine.game.battle.bullet")
GrazeSprite = require("src.engine.game.battle.grazesprite")
ArenaSprite = require("src.engine.game.battle.arenasprite")
ArenaMask = require("src.engine.game.battle.arenamask")

BattleUI = require("src.engine.game.battle.ui.battleui")
ActionBox = require("src.engine.game.battle.ui.actionbox")
AttackBox = require("src.engine.game.battle.ui.attackbox")
AttackBar = require("src.engine.game.battle.ui.attackbar")
TensionBar = require("src.engine.game.battle.ui.tensionbar")
EnemyTextbox = require("src.engine.game.battle.ui.enemytextbox")

FlashFade = require("src.engine.game.effects.flashfade")
DamageNumber = require("src.engine.game.effects.damagenumber")
HeartBurst = require("src.engine.game.effects.heartburst")
HealSparkle = require("src.engine.game.effects.healsparkle")
SpareSparkle = require("src.engine.game.effects.sparesparkle")
SpareZ = require("src.engine.game.effects.sparez")
SleepMistEffect = require("src.engine.game.effects.sleepmisteffect")
IceSpellEffect = require("src.engine.game.effects.icespelleffect")
IceSpellBurst = require("src.engine.game.effects.icespellburst")

_, LibLurker = pcall(require, "lurker")

local load_in_channel
local load_out_channel
local load_thread

local next_load_key = 0
local load_waiting = 0
local load_end_funcs = {}

function love.load(args)
    --[[
        Launch args:
            --wait: Pauses the load screen until a key is pressed
    ]]

    -- read args
    Kristal.Args = {}
    local last_arg
    for _,arg in ipairs(args or {}) do
        if arg:sub(1, 2) == "--" then
            last_arg = {}
            Kristal.Args[arg:sub(3)] = last_arg
        elseif last_arg then
            table.insert(last_arg, arg)
        end
    end

    -- load the settings.json
    Kristal.Config = Kristal.loadConfig()

    -- pixel scaling (the good one)
    love.graphics.setDefaultFilter("nearest")

    -- scale the window if we have to
    local window_scale = Kristal.Config["windowScale"]
    if window_scale ~= 1 then
        love.window.setMode(SCREEN_WIDTH * window_scale, SCREEN_HEIGHT * window_scale)
    end

    -- toggle vsync
    love.window.setVSync(Kristal.Config["vSync"] and 1 or 0)

    -- setup structure
    love.filesystem.createDirectory("mods")

    -- default registry
    Registry.initialize()

    -- register gamestate calls
    Gamestate.registerEvents()

    -- initialize overlay
    Kristal.Overlay:init()

    -- initialize music
    Music.init()

    -- screen canvas
    SCREEN_CANVAS = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    SCREEN_CANVAS:setFilter("nearest", "nearest")

    -- setup hooks
    Utils.hook(love, "update", function(orig, ...)
        if PERFORMANCE_TEST_STAGE == "UPDATE" then
            PERFORMANCE_TEST = {}
            Utils.pushPerformance("Total")
        end
        orig(...)
        Kristal.Overlay:update(...)
        if PERFORMANCE_TEST then
            Utils.popPerformance()
            print("-------- PERFORMANCE --------")
            Utils.printPerformance()
            PERFORMANCE_TEST_STAGE = "DRAW"
            PERFORMANCE_TEST = nil
        end
    end)
    Utils.hook(love, "draw", function(orig, ...)
        if PERFORMANCE_TEST_STAGE == "DRAW" then
            PERFORMANCE_TEST = {}
            Utils.pushPerformance("Total")
        end

        love.graphics.reset()

        Draw.setCanvas(SCREEN_CANVAS)
        love.graphics.clear()
        orig(...)
        Kristal.Overlay:draw()
        Draw.setCanvas()

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.scale(Kristal.Config["windowScale"])
        love.graphics.draw(SCREEN_CANVAS)

        Draw._clearUnusedCanvases()

        if PERFORMANCE_TEST then
            Utils.popPerformance()
            Utils.printPerformance()
            PERFORMANCE_TEST_STAGE = nil
            PERFORMANCE_TEST = nil
        end
    end)

    -- start load thread
    load_in_channel = love.thread.getChannel("load_in")
    load_out_channel = love.thread.getChannel("load_out")

    load_thread = love.thread.newThread("src/engine/loadthread.lua")
    load_thread:start()

    -- load menu
    if Kristal.Args["test"] then
        Gamestate.switch(Kristal.States["Testing"])
    else
        Gamestate.switch(Kristal.States["Loading"])
    end
end

function love.quit()
    Kristal.saveConfig()
    if load_thread and load_thread:isRunning() then
        load_in_channel:push("stop")
    end
end

function love.update(dt)
    DT = dt
    DTMULT = dt * 30

    LibTimer.update(dt)
    Music.update(dt)
    Assets.update(dt)

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

function love.keypressed(key)
    Input.onKeyPressed(key)

    if key == "f1" then
        Kristal.Config["showFPS"] = not Kristal.Config["showFPS"]
    elseif key == "f2" then
        Kristal.Config["vSync"] = not Kristal.Config["vSync"]
        love.window.setVSync(Kristal.Config["vSync"] and 1 or 0)
    elseif key == "f3" then
        PERFORMANCE_TEST_STAGE = "UPDATE"
    elseif key == "f6" then
        DEBUG_RENDER = not DEBUG_RENDER
    elseif key == "f8" then
        if LibLurker then
            print("Hotswapping files...\nNOTE: Might be unstable. If anything goes wrong, it's not our fault :P")
            LibLurker.scan()
        end
    elseif key == "r" and love.keyboard.isDown("lctrl") then
        if Kristal.getModOption("quickReload") then
            Kristal.quickReload()
        else
            love.event.quit("restart")
        end
    end
end

function love.keyreleased(key)
    Input.onKeyReleased(key)
end

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    local errorResult

    local function mainLoop()
        -- Clear input from last frame
        Input.clearPressed()

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

        -- Dt shouldn't exceed 30FPS
        dt = math.min(dt, 1/30)

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
                if result == "quick_reload" then
                    Mod = nil
                    errorResult = nil
                    Kristal.quickReload()
                else
                    if love.quit then
                        love.quit()
                    end
                    return result
                end
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
    local starwalker_error = (math.random(100) <= 5) -- 5% chance for starwalker
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

    local trace = debug.traceback("", 2)

    love.graphics.origin()

    local split = Utils.split(msg, ": ")

    local function draw()
        local pos = 32
        local ypos = pos
        love.graphics.origin()
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.scale(window_scale)

        love.graphics.setFont(font)

        local _,lines = font:getWrap("Error at "..split[#split-1].." - "..split[#split], 640 - pos)

        love.graphics.printf({"Error at ", {0.6, 0.6, 0.6, 1}, split[#split-1], {1, 1, 1, 1}, " - " .. split[#split]}, pos, ypos, 640 - pos)
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

        -- dt shouldnt exceed 30FPS
        DT = math.min(love.timer.getDelta(), 1/30)

        copy_color[1] = copy_color[1] + (DT * 2)
        copy_color[3] = copy_color[3] + (DT * 2)

        love.graphics.setFont(smaller_font)
        if Kristal.getModOption("quickReload") then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("Press R to go back to mod menu (Quick Reload available)", 8, 480 - 40)
        end
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
        if love.graphics.isActive() and love.graphics.getCanvas() then
            love.graphics.setCanvas()
        end

        love.event.pump()

        for e, a, b, c in love.event.poll() do
            if e == "quit" then
                return 1
            elseif e == "keypressed" and a == "escape" then
                return "restart"
            elseif e == "keypressed" and a == "r" and Kristal.getModOption("quickReload") then
                return "quick_reload"
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

function Kristal.quickReload()
    Mod = nil
    Kristal.Mods.clear()
    Kristal.clearModHooks()
    Registry.initialize()
    love.audio.stop()
    Music.clear()
    Gamestate.switch({})
    Kristal.loadAssets("", "mods", "", function()
        Gamestate.switch(Kristal.States["Menu"])
    end)
end

function Kristal.clearAssets(include_mods)
    Assets.clear()
    if include_mods then
        Kristal.Mods.clear()
    end
end

function Kristal.loadAssets(dir, loader, paths, after)
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

function Kristal.preloadMod(id)
    local mod = Kristal.Mods.getMod(id)

    if not mod then return end

    Mod = {info = mod}

    Registry.initialize(true)
end

function Kristal.loadMod(id, after)
    local mod = Kristal.Mods.getMod(id)

    if not mod then return end

    Mod = Mod or {info = mod}

    MOD_LOADING = true

    Kristal.loadAssets(mod.path, "all", "", function()
        MOD_LOADING = false

        if mod.script_chunks["mod"] then
            local chunk = mod.script_chunks["mod"]

            local result = chunk()
            if type(result) == "table" then
                Mod = result
                if not Mod.info then
                    Mod.info = mod
                end
            end
        end

        Registry.initialize()

        after()
    end)
end

function Kristal.loadConfig()
    local config = {
        windowScale = 1,
        skipIntro = false,
        showFPS = false,
        vSync = true
    }
    if love.filesystem.getInfo("settings.json") then
        Utils.merge(config, JSON.decode(love.filesystem.read("settings.json")))
    end
    return config
end

function Kristal.saveConfig()
    love.filesystem.write("settings.json", JSON.encode(Kristal.Config))
end

function Kristal.modCall(f, ...)
    if Mod and Mod[f] and type(Mod[f]) == "function" then
        return Mod[f](Mod, ...)
    end
end

function Kristal.modGet(k)
    if Mod and Mod[k] then
        return Mod[k]
    end
end

function Kristal.getModOption(name)
    return Mod and Mod.info and Mod.info[name]
end

function Kristal.executeModScript(path, ...)
    if not Mod or not Mod.info.script_chunks[path] then
        return false
    else
        return true, Mod.info.script_chunks[path](...)
    end
end

function Kristal.clearModHooks()
    for _,hook in ipairs(Utils.__MOD_HOOKS) do
        hook.target[hook.name] = hook.orig
    end
    Utils.__MOD_HOOKS = {}
end