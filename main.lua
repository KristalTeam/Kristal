require("src.engine.vars")
require("src.engine.statevars")

_Class = require("src.lib.hump.class")
Gamestate = require("src.lib.hump.gamestate")
Vector = require("src.lib.hump.vector-light")
LibTimer = require("src.lib.hump.timer")
JSON = require("src.lib.json")
Ease = require("src.lib.easing")
SemVer = require("src.lib.semver")

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
    ["Testing"] = require("src.teststate"),
}

-- Ease of access for game variables
Game = Kristal.States["Game"]

Assets = require("src.engine.assets")
Music = require("src.engine.music")
Input = require("src.engine.input")
Registry = require("src.engine.registry")
Camera = require("src.engine.camera")

Object = require("src.engine.object")
Stage = require("src.engine.objects.stage")
Sprite = require("src.engine.objects.sprite")
Text = require("src.engine.objects.text")
DialogueText = require("src.engine.objects.dialoguetext")
Explosion = require("src.engine.objects.explosion")
AfterImage = require("src.engine.objects.afterimage")
FakeClone = require("src.engine.objects.fakeclone")
Rectangle = require("src.engine.objects.rectangle")
Fader = require("src.engine.objects.fader")
HPText = require("src.engine.objects.hptext")
Timer = require("src.engine.objects.timer")
StateManager = require("src.engine.objects.statemanager")
Anchor = require("src.engine.objects.anchor")

ModList = require("src.engine.menu.modlist")
ModButton = require("src.engine.menu.modbutton")
FileList = require("src.engine.menu.filelist")
FileButton = require("src.engine.menu.filebutton")

DarkTransitionLine = require("src.engine.game.darktransition.darktransitionline")
DarkTransitionParticle = require("src.engine.game.darktransition.darktransitionparticle")
DarkTransitionSparkle = require("src.engine.game.darktransition.darktransitionsparkle")
HeadObject = require("src.engine.game.darktransition.head_object")

FXBase = require("src.engine.drawfx.fxbase")
ShaderFX = require("src.engine.drawfx.shaderfx")
ColorMaskFX = require("src.engine.drawfx.colormaskfx")
AlphaFX = require("src.engine.drawfx.alphafx")
RecolorFX = require("src.engine.drawfx.recolorfx")
MaskFX = require("src.engine.drawfx.maskfx")

Collider = require("src.engine.colliders.collider")
ColliderGroup = require("src.engine.colliders.collidergroup")
Hitbox = require("src.engine.colliders.hitbox")
LineCollider = require("src.engine.colliders.linecollider")
CircleCollider = require("src.engine.colliders.circlecollider")
PointCollider = require("src.engine.colliders.pointcollider")
PolygonCollider = require("src.engine.colliders.polygoncollider")

PartyMember = require("src.engine.game.common.data.partymember")
Actor = require("src.engine.game.common.data.actor")
Spell = require("src.engine.game.common.data.spell")
Item = require("src.engine.game.common.data.item")
HealItem = require("src.engine.game.common.data.healitem")
TensionItem = require("src.engine.game.common.data.tensionitem")
LightEquipItem = require("src.engine.game.common.data.lightequipitem")

ActorSprite = require("src.engine.game.common.actorsprite")
Inventory = require("src.engine.game.common.inventory")
DarkInventory = require("src.engine.game.common.darkinventory")
LightInventory = require("src.engine.game.common.lightinventory")

Cutscene = require("src.engine.game.common.cutscene")
WorldCutscene = require("src.engine.game.world.worldcutscene")
BattleCutscene = require("src.engine.game.battle.battlecutscene")

Console = require("src.engine.game.console")

UIBox = require("src.engine.game.common.uibox")
Textbox = require("src.engine.game.common.textbox")
Choicebox = require("src.engine.game.common.choicebox")
SmallFaceText = require("src.engine.game.common.smallfacetext")

World = require("src.engine.game.world")
Map = require("src.engine.game.world.map")
Tileset = require("src.engine.game.world.tileset")
TileLayer = require("src.engine.game.world.tilelayer")
Character = require("src.engine.game.world.character")
Follower = require("src.engine.game.world.follower")
Player = require("src.engine.game.world.player")
OverworldSoul = require("src.engine.game.world.overworldsoul")
WorldBullet = require("src.engine.game.world.worldbullet")
ChaserEnemy = require("src.engine.game.world.chaserenemy")

SaveMenu = require("src.engine.game.world.ui.savemenu")
HealthBar = require("src.engine.game.world.ui.healthbar")
OverworldActionBox = require("src.engine.game.world.ui.overworldactionbox")
Shopbox = require("src.engine.game.world.ui.shopbox")

DarkMenu = require("src.engine.game.world.ui.dark.darkmenu")
DarkItemMenu = require("src.engine.game.world.ui.dark.darkitemmenu")
DarkEquipMenu = require("src.engine.game.world.ui.dark.darkequipmenu")
DarkPowerMenu = require("src.engine.game.world.ui.dark.darkpowermenu")
DarkConfigMenu = require("src.engine.game.world.ui.dark.darkconfigmenu")
DarkMenuPartySelect = require("src.engine.game.world.ui.dark.darkmenupartyselect")
DarkStorageMenu = require("src.engine.game.world.ui.dark.darkstoragemenu")

LightMenu = require("src.engine.game.world.ui.light.lightmenu")
LightItemMenu = require("src.engine.game.world.ui.light.lightitemmenu")
LightStatMenu = require("src.engine.game.world.ui.light.lightstatmenu")
LightCellMenu = require("src.engine.game.world.ui.light.lightcellmenu")

Event = require("src.engine.game.world.event")
Script = require("src.engine.game.world.events.script")
Interactable = require("src.engine.game.world.events.interactable")
Savepoint = require("src.engine.game.world.events.savepoint")
TreasureChest = require("src.engine.game.world.events.treasurechest")
Transition = require("src.engine.game.world.events.transition")
NPC = require("src.engine.game.world.events.npc")
Outline = require("src.engine.game.world.events.outline")
SlideArea = require("src.engine.game.world.events.slidearea")
Silhouette = require("src.engine.game.world.events.silhouette")
CameraTarget = require("src.engine.game.world.events.cameratarget")
FrozenEnemy = require("src.engine.game.world.frozenenemy")

Battle = require("src.engine.game.battle")
Encounter = require("src.engine.game.battle.encounter")
Wave = require("src.engine.game.battle.wave")
Battler = require("src.engine.game.battle.battler")
PartyBattler = require("src.engine.game.battle.partybattler")
EnemyBattler = require("src.engine.game.battle.enemybattler")
Arena = require("src.engine.game.battle.arena")
Soul = require("src.engine.game.battle.soul")
Bullet = require("src.engine.game.battle.bullet")
Solid = require("src.engine.game.battle.solid")
GrazeSprite = require("src.engine.game.battle.grazesprite")
ArenaSprite = require("src.engine.game.battle.arenasprite")
ArenaMask = require("src.engine.game.battle.arenamask")
SnowGraveSpell = require("src.engine.game.battle.snowgravespell")

BattleUI = require("src.engine.game.battle.ui.battleui")
ActionBox = require("src.engine.game.battle.ui.actionbox")
ActionBoxDisplay = require("src.engine.game.battle.ui.actionboxdisplay")
ActionButton = require("src.engine.game.battle.ui.actionbutton")
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
SnowGraveSnowflake = require("src.engine.game.effects.snowgravesnowflake")
FatalEffect = require("src.engine.game.effects.fataleffect")
RudeBusterBeam = require("src.engine.game.effects.rudebusterbeam")
RudeBusterBurst = require("src.engine.game.effects.rudebusterburst")

Shop = require("src.engine.game.shop")
Shopkeeper = require("src.engine.game.shop.shopkeeper")

GameOver = require("src.engine.game.gameover")

DarkTransition = require("src.engine.game.darktransition.darktransition")

Hotswapper = require("src.hotswapper")
utf8 = require("utf8")

-- Register required in the hotswapper
Hotswapper.updateFiles("required")

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

    -- load the version
    Kristal.Version = SemVer(love.filesystem.read("VERSION"))

    -- load the settings.json
    Kristal.Config = Kristal.loadConfig()

    -- load the keybinds
    Input.loadBinds()

    -- pixel scaling (the good one)
    love.graphics.setDefaultFilter("nearest")

    -- set the window size
    local window_scale = Kristal.Config["windowScale"]
    if window_scale ~= 1 or Kristal.Config["fullscreen"] then
        Kristal.resetWindow()
    end

    -- toggle vsync
    love.window.setVSync(Kristal.Config["vSync"] and 1 or 0)

    -- set master volume
    Kristal.setVolume(Kristal.Config["masterVolume"] or 1)

    -- setup structure
    love.filesystem.createDirectory("mods")
    love.filesystem.createDirectory("saves")

    -- default registry
    Registry.initialize()

    -- register gamestate calls
    Gamestate.registerEvents()

    -- initialize overlay
    Kristal.Overlay:init()

    -- global stage
    Kristal.Stage = Stage()

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
        Kristal.Stage:update(...)
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
        Kristal.Stage:draw()
        Kristal.Overlay:draw()
        Draw.setCanvas()

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
        love.graphics.scale(Kristal.getGameScale())
        love.graphics.draw(SCREEN_CANVAS, -SCREEN_WIDTH/2, -SCREEN_HEIGHT/2)

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

    if Kristal.Args["mod"] then
        TARGET_MOD = Kristal.Args["mod"][1]
    end

    -- load menu
    Gamestate.switch(Kristal.States["Loading"])
end

function love.quit()
    Kristal.saveConfig()
    if load_thread and load_thread:isRunning() then
        load_in_channel:push("stop")
    end
end

function love.update(dt)
    BASE_DT = dt
    if FAST_FORWARD then
        dt = dt * FAST_FORWARD_SPEED
    end
    DT = dt
    DTMULT = dt * 30
    RUNTIME = RUNTIME + dt

    LibTimer.update()
    Music.update()
    Assets.update()

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
    elseif key == "f4" or (key == "return" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"))) then
        Kristal.Config["fullscreen"] = not Kristal.Config["fullscreen"]
        love.window.setFullscreen(Kristal.Config["fullscreen"])
    elseif key == "f5" then
        FAST_FORWARD = not FAST_FORWARD
    elseif key == "f6" then
        DEBUG_RENDER = not DEBUG_RENDER
    elseif key == "f8" then
        print("Hotswapping files...\nNOTE: Might be unstable. If anything goes wrong, it's not our fault :P")
        Hotswapper.scan()
    elseif key == "r" and love.keyboard.isDown("lctrl") then
        if Kristal.getModOption("hardReset") then
            love.event.quit("restart")
        else
            if Mod then
                Kristal.quickReload(love.keyboard.isDown("lshift"))
            else
                Kristal.returnToMenu()
            end
        end
    end
end

function love.keyreleased(key)
    Input.onKeyReleased(key)
end

function love.run()
---@diagnostic disable-next-line: undefined-field, redundant-parameter
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's DT to include time taken by love.load.
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
---@diagnostic disable-next-line: undefined-field
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        -- Update DT, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        -- DT shouldn't exceed 30FPS
        dt = math.min(dt, 1/30)

        -- Call update and draw
        if love.update then
            love.update(dt)
        end

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

---@diagnostic disable-next-line: undefined-field
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
                if result == "reload" then
                    Mod = nil
                    errorResult = nil
                    Kristal.returnToMenu()
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

    if not love.window.isOpen() then
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

        -- DT shouldnt exceed 30FPS
        DT = math.min(love.timer.getDelta(), 1/30)

        copy_color[1] = copy_color[1] + (DT * 2)
        copy_color[3] = copy_color[3] + (DT * 2)

        love.graphics.setFont(smaller_font)
        if Kristal.getModOption("hardReset") then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("Press ESC to restart the game", 8, 480 - 40)
        else
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("Press ESC to return to mod menu", 8, 480 - 40)
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
                if Kristal.getModOption("hardReset") then
                    return "restart"
                else
                    return "reload"
                end
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

function Kristal.setVolume(volume)
    Kristal.Config["masterVolume"] = Utils.clamp(volume, 0, 1)
    love.audio.setVolume(volume)
    Kristal.saveConfig()
end

function Kristal.getVolume()
    return Kristal.Config["masterVolume"]
end

function Kristal.clearModState()
    -- Clear disruptive active globals
    Object._clearCache()
    Draw._clearStacks()
    -- End the current mod
    Kristal.callEvent("unload")
    Mod = nil
    Kristal.Mods.clear()
    Kristal.clearModHooks()
    Kristal.clearModSubclasses()
    -- Stop sounds and music
    love.audio.stop()
    Music.clear()
    -- Reset global variables
    Registry.restoreOverridenGlobals()
    package.loaded["src.engine.vars"] = nil
    require("src.engine.vars")
    -- Reset Game state
    package.loaded["src.engine.game.game"] = nil
    Kristal.States["Game"] = require("src.engine.game.game")
    Game = Kristal.States["Game"]
    -- Restore assets and registry
    Assets.restoreData()
    Registry.initialize()
end

function Kristal.returnToMenu()
    -- Go to empty state
    Gamestate.switch({})
    -- Clear the mod
    Kristal.clearModState()
    -- Remove anything on the stage
    for _,object in ipairs(Kristal.Stage.children) do
        object:remove()
    end
    -- Reload mods and return to memu
    Kristal.loadAssets("", "mods", "", function()
        Gamestate.switch(Kristal.States["Menu"])
    end)
end

function Kristal.quickReload(dont_save)
    -- Temporarily save game variables
    local save, save_id, encounter
    if not dont_save then
        save = Game:save()
        save_id = Game.save_id
        encounter = Game.battle and Game.battle.encounter and Game.battle.encounter.id
    end

    -- Temporarily save the current mod id
    local mod_id = Mod.info.id

    -- Go to empty state
    Gamestate.switch({})
    -- Clear the mod
    Kristal.clearModState()
    -- Reload mods
    Kristal.loadAssets("", "mods", "", function()
        -- Reload the current mod directly
        Kristal.loadMod(mod_id, nil, nil, function()
            -- Pre-initialize the current mod
            if Kristal.preInitMod(mod_id) then
                -- Switch to Game and load the temp save
                Gamestate.switch(Game)
                if save then
                    Game:load(save, save_id)

                    -- If we had an encounter, restart the encounter
                    if encounter then
                        Game:encounter(encounter, false)
                    end
                end
            end
        end)
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
    --[[local mod = Kristal.Mods.getAndLoadMod(id)

    if not mod then return end

    Mod = {info = mod, libs = {}}]]

    Registry.initialize(true)
end

function Kristal.loadMod(id, save_id, save_name, after)
    -- Get the mod data (loaded from mod.json)
    local mod = Kristal.Mods.getAndLoadMod(id)

    -- No mod found; nothing to load
    if not mod then return end

    -- Create the Mod table, which is a global table that
    -- can contain a mod's custom variables and functions
    -- with Mod.info referencing the mod data (from the .json)
    Mod = Mod or {info = mod, libs = {}}

    -- Check for mod.lua
    if mod.script_chunks["mod"] then
        -- Execute mod.lua
        local result = mod.script_chunks["mod"]()
        -- If mod.lua returns a table, use that as the global Mod table (optional)
        if type(result) == "table" then
            Mod = result
            if not Mod.info then
                Mod.info = mod
            end
        end
    end

    -- Create the Mod.libs table, which similarly to the
    -- Mod table, can contain a library's custom variables
    -- and functions with lib.info referncing the library data
    Mod.libs = Mod.libs or {}
    for lib_id,lib_info in pairs(mod.libs) do
        local lib = {info = lib_info}

        ACTIVE_LIB = lib

        -- Check for lib.lua
        if lib_info.script_chunks["lib"] then
            -- Execute lib.lua
            local result = lib_info.script_chunks["lib"]()
            -- If lib.lua returns a table, use that as the lib table (optional)
            if type(result) == "table" then
                lib = result
                if not lib.info then
                    lib.info = lib_info
                end
            end
        end

        ACTIVE_LIB = nil

        -- Add the current library to the libs table
        Mod.libs[lib_id] = lib
    end

    if not mod.transition or after then
        Kristal.loadModAssets(mod.id, "all", "", after or function()
            if Kristal.preInitMod(mod.id) then
                Gamestate.switch(Kristal.States["Game"], save_id, save_name)
            end
        end)
    else
        -- Preload assets for the transition
        Registry.initialize(true)

        local final_y = 320

        Kristal.loadModAssets(mod.id, "sprites", DarkTransition.SPRITE_DEPENDENCIES, function()
            local transition = DarkTransition()
            transition.loading_callback = function()
                Kristal.loadModAssets(mod.id, "all", "", function()
                    transition:resumeTransition()
                    if Kristal.preInitMod(mod.id) then
                        Gamestate.switch(Kristal.States["Game"], save_id)
                        local px, py = Game.world.player:getScreenPos()
                        transition.final_y = py
                    end
                end)
            end
            transition.land_callback = function()
                if Game and Game.world and Game.world.player then
                    local kx, ky = transition.kris_sprite:localToScreenPos(transition.kris_width / 2, 0)
                    -- Hardcoded offsets for now...
                    Game.world.player:setScreenPos(kx - 2, transition.final_y - 2)
                    Game.world.player.visible = false
                    Game.world.player:setFacing("down")

                    if not transition.kris_only and Game.world.followers[1] then
                        local sx, sy = transition.susie_sprite:localToScreenPos(transition.susie_width / 2, 0)
                        Game.world.followers[1]:setScreenPos(sx - 2, transition.final_y - 2)
                        Game.world.followers[1].visible = true
                        Game.world.followers[1]:interpolateHistory()
                        Game.world.followers[1]:setFacing("down")
                    end
                end
            end
            transition.end_callback = function()
                if Game and Game.world and Game.world.player then
                    Game.world.player.visible = true
                    if not transition.kris_only and Game.world.followers[1] then
                        Game.world.followers[1].visible = true
                    end
                end
            end

            transition.layer = 1000
            Kristal.Stage:addChild(transition)
        end)
    end
end

function Kristal.loadModAssets(id, asset_type, asset_paths, after)
    -- Get the mod data (loaded from mod.json)
    local mod = Kristal.Mods.getAndLoadMod(id)

    -- No mod found; nothing to load
    if not mod then return end

    -- How many assets we need to load (1 for the mod, 1 for each library)
    local load_count = 1

    -- Count each library for loading
    for _,_ in pairs(mod.libs) do
        load_count = load_count + 1
    end

    -- Begin mod loading
    MOD_LOADING = true

    local function finishLoadStep()
        -- Finish one load process
        load_count = load_count - 1
        -- Check if all load processes are done (mod and libraries)
        if load_count == 0 then
            -- Finish mod loading
            MOD_LOADING = false
            
            -- Call the after function
            after()
        end
    end

    -- Finally load all assets (libraries first)
    for _,lib in pairs(mod.libs) do
        Kristal.loadAssets(lib.path, asset_type or "all", asset_paths or "", finishLoadStep)
    end
    Kristal.loadAssets(mod.path, asset_type or "all", asset_paths or "", finishLoadStep)
end

function Kristal.preInitMod(id)
    -- Get the mod data (loaded from mod.json)
    local mod = Kristal.Mods.getAndLoadMod(id)

    -- No mod found; nothing to load
    if not mod then return end

    -- Whether to call the "after" function
    local use_callback = true

    -- Call preInit on all libraries
    for lib_id,_ in pairs(mod.libs) do
        local lib_result = Kristal.libCall(lib_id, "preInit")
        use_callback = use_callback and lib_result ~= false
    end

    -- Call Mod:preInit
    local mod_result = Kristal.modCall("preInit")
    use_callback = use_callback and mod_result ~= false

    -- Initialize registry
    Registry.initialize()

    -- Return true if no "preInit" explicitly returns false
    return use_callback
end

function Kristal.resetWindow()
    local window_scale = Kristal.Config["windowScale"]
    love.window.setMode(SCREEN_WIDTH * window_scale, SCREEN_HEIGHT * window_scale, {
        fullscreen = Kristal.Config["fullscreen"],
        vsync = Kristal.Config["vSync"] and 1 or 0
    })
end

function Kristal.getGameScale()
    return math.min(love.graphics.getWidth() / SCREEN_WIDTH, love.graphics.getHeight() / SCREEN_HEIGHT)
end

function Kristal.loadConfig()
    local config = {
        windowScale = 1,
        skipIntro = false,
        showFPS = false,
        vSync = false,
        debug = false,
        fullscreen = false,
        simplifyVFX = false,
        autoRun = false,
        masterVolume = 1,
        favorites = {},
    }
    if love.filesystem.getInfo("settings.json") then
        Utils.merge(config, JSON.decode(love.filesystem.read("settings.json")))
    end
    return config
end

function Kristal.saveConfig()
    love.filesystem.write("settings.json", JSON.encode(Kristal.Config))
end

function Kristal.saveGame(id, data)
    id = id or Game.save_id
    data = data or Game:save()
    Game.save_id = id
    Game.quick_save = nil
    love.filesystem.createDirectory("saves/"..Mod.info.id)
    love.filesystem.write("saves/"..Mod.info.id.."/file_"..id..".json", JSON.encode(data))
end

function Kristal.loadGame(id)
    id = id or Game.save_id
    local path = "saves/"..Mod.info.id.."/file_"..id..".json"
    if love.filesystem.getInfo(path) then
        local data = JSON.decode(love.filesystem.read(path))
        Game:load(data, id)
    else
        Game:load(nil, id)
    end
end

function Kristal.getSaveFile(id, path)
    id = id or Game.save_id
    local path = "saves/"..(path or Mod.info.id).."/file_"..id..".json"
    if love.filesystem.getInfo(path) then
        return JSON.decode(love.filesystem.read(path))
    end
end

function Kristal.hasAnySaves(path)
    local path = "saves/"..(path or Mod.info.id)
    return love.filesystem.getInfo(path) and (#love.filesystem.getDirectoryItems(path) > 0)
end

function Kristal.saveData(file, data, path)
    love.filesystem.createDirectory("saves/"..(path or Mod.info.id))
    love.filesystem.write("saves/"..(path or Mod.info.id).."/"..file..".json", JSON.encode(data or {}))
end

function Kristal.loadData(file, path)
    local path = "saves/"..(path or Mod.info.id).."/"..file..".json"
    if love.filesystem.getInfo(path) then
        return JSON.decode(love.filesystem.read(path))
    end
end

function Kristal.eraseData(file, path)
    love.filesystem.remove("saves/"..(path or Mod.info.id).."/"..file..".json")
end

function Kristal.modCall(f, ...)
    if Mod and Mod[f] and type(Mod[f]) == "function" then
        return Mod[f](Mod, ...)
    end
end

function Kristal.libCall(id, f, ...)
    if not Mod then return end

    if not id then
        local result
        for _,lib in pairs(Mod.libs) do
            if lib[f] and type(lib[f]) == "function" then
                local lib_result = lib[f](lib, ...)
                result = lib_result or result
            end
        end
        return result
    else
        local lib = Mod.libs[id]
        if lib and lib[f] and type(lib[f]) == "function" then
            return lib[f](lib, ...)
        end
    end
end

function Kristal.callEvent(f, ...)
    if not Mod then return end

    local lib_result = Kristal.libCall(nil, f, ...)
    local mod_result = Kristal.modCall(f, ...)

    return mod_result or lib_result
end

function Kristal.modGet(k)
    if Mod and Mod[k] then
        return Mod[k]
    end
end

function Kristal.getModOption(name)
    return Mod and Mod.info and Mod.info[name]
end

function Kristal.getLibConfig(lib_id, key, merge, deep_merge)
    if not Mod then return end

    local lib = Mod.libs[lib_id]

    if not lib then error("No library found: "..lib_id) end

    local lib_config = lib.info and lib.info.config or {}
    local mod_config = Mod.info and Mod.info.config and Utils.getAnyCase(Mod.info.config, lib_id) or {}

    local lib_value = Utils.getAnyCase(lib_config, key)
    local mod_value = Utils.getAnyCase(mod_config, key)

    if mod_value ~= nil and lib_value == nil then
        return mod_value
    elseif lib_value ~= nil and mod_value == nil then
        return lib_value
    elseif type(lib_value) == "table" and merge then
        return Utils.merge(Utils.copy(lib_value, true), mod_value, deep_merge)
    else
        return mod_value
    end
end

function Kristal.executeModScript(path, ...)
    if not Mod or not Mod.info.script_chunks[path] then
        return false
    else
        return true, Mod.info.script_chunks[path](...)
    end
end

function Kristal.executeLibScript(lib, path, ...)
    if not Mod then
        return false
    end

    if not lib then
        for _,library in pairs(Mod.libs) do
            if library.info.script_chunks[path] then
                return true, library.info.script_chunks[path](...)
            end
        end
        return false
    else
        local library = Mod.libs[path]
        if not library or not library.info.script_chunks[path] then
            return false
        else
            return true, library.info.script_chunks[path](...)
        end
    end
end

function Kristal.clearModHooks()
    for _,hook in ipairs(Utils.__MOD_HOOKS) do
        hook.target[hook.name] = hook.orig
    end
    Utils.__MOD_HOOKS = {}
end

function Kristal.clearModSubclasses()
    for class,subs in pairs(MOD_SUBCLASSES) do
        for _,sub in ipairs(subs) do
            if class.__includers then
                Utils.removeFromTable(class.__includers, sub)
            end
        end
    end
    MOD_SUBCLASSES = {}
end

local _require = require
local _newRequire = function(path, ...)
    if Mod then
        path = path:gsub("%.", "/")
        local success, result
        if not ACTIVE_LIB then
            success, result = Kristal.executeModScript(path, ...)
        else
            success, result = Kristal.executeLibScript(ACTIVE_LIB.info.id, path, ...)
        end
        if not success then
            error("No script found: "..path)
        end
        return result
    else
        return _require(path, ...)
    end
end
require = _newRequire
function rawRequire(...)
    require = _require
    local result = {require(...)}
    require = _newRequire
    return unpack(result)
end