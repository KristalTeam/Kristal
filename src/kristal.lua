local Kristal = {}

if not HOTSWAPPING then

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

Kristal.Loader = {
    in_channel = nil,
    out_channel = nil,
    thread = nil,

    next_key = 0,
    waiting = 0,
    end_funcs = {}
}

end

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
    if window_scale ~= 1 or Kristal.Config["fullscreen"] or Kristal.bordersEnabled() then
        Kristal.resetWindow()
    end

    -- toggle vsync
    love.window.setVSync(Kristal.Config["vSync"] and 1 or 0)

    -- register gamepad mapping DB
    love.joystick.loadGamepadMappings("gamecontrollerdb.txt")

    -- update framerate
    FRAMERATE = Kristal.Config["fps"]

    -- set master volume
    Kristal.setVolume(Kristal.Config["masterVolume"] or 1)

    -- hide mouse
    Kristal.hideCursor()

    -- make mouse sprite
    MOUSE_SPRITE = love.graphics.newImage((love.math.random(1000) <= 1) and "assets/sprites/kristal/starwalker.png" or "assets/sprites/kristal/mouse.png")

    -- setup structure
    love.filesystem.createDirectory("mods")
    love.filesystem.createDirectory("saves")

    -- default registry
    Registry.initialize()

    -- Chapter defaults
    Kristal.ChapterConfigs = {}
    Kristal.ChapterConfigs[1] = JSON.decode(love.filesystem.read("configs/chapter1.json"))
    Kristal.ChapterConfigs[2] = JSON.decode(love.filesystem.read("configs/chapter2.json"))

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
        love.graphics.clear(0, 0, 0, 1)
        orig(...)
        Kristal.Stage:draw()
        Kristal.Overlay:draw()
        Draw.setCanvas()

        love.graphics.setColor(1, 1, 1, 1)

        if Kristal.bordersEnabled() then
            local border = Kristal.getBorder()

            local dynamic = Kristal.Config["borders"] == "dynamic"

            if dynamic and BORDER_FADING == "OUT" and BORDER_FADE_FROM then
                border = BORDER_FADE_FROM
            end

            if border then
                local border_texture = Assets.getTexture("borders/"..border)

                love.graphics.scale(Kristal.getGameScale())
                love.graphics.setColor(1, 1, 1, dynamic and BORDER_ALPHA or 1)
                if border_texture then
                    love.graphics.draw(border_texture, 0, 0, 0, BORDER_SCALE)
                end
                if dynamic then
                    Kristal.callEvent("onBorderDraw", border, border_texture)
                end
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.reset()
            end

            LAST_BORDER = border
        end

        -- Draw the game canvas
        love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
        love.graphics.scale(Kristal.getGameScale())
        love.graphics.draw(SCREEN_CANVAS, -SCREEN_WIDTH/2, -SCREEN_HEIGHT/2)

        love.graphics.reset()
        love.graphics.scale(Kristal.getGameScale())

        if (not Kristal.Config["systemCursor"]) and (Kristal.Config["alwaysShowCursor"] or MOUSE_VISIBLE) and love.window then
            if Input.usingGamepad() then
                love.graphics.setColor(0, 0, 0, 0.5)
                love.graphics.circle("fill", Input.gamepad_cursor_x, Input.gamepad_cursor_y, Input.gamepad_cursor_size)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.circle("line", Input.gamepad_cursor_x, Input.gamepad_cursor_y, Input.gamepad_cursor_size)
            elseif MOUSE_SPRITE and love.window.hasMouseFocus() then
                love.graphics.draw(MOUSE_SPRITE, love.mouse.getX() / Kristal.getGameScale(), love.mouse.getY() / Kristal.getGameScale())
            end
        end

        Draw._clearUnusedCanvases()

        if PERFORMANCE_TEST then
            Utils.popPerformance()
            Utils.printPerformance()
            PERFORMANCE_TEST_STAGE = nil
            PERFORMANCE_TEST = nil
        end
    end)

    -- start load thread
    Kristal.Loader.in_channel = love.thread.getChannel("load_in")
    Kristal.Loader.out_channel = love.thread.getChannel("load_out")

    Kristal.Loader.thread = love.thread.newThread("src/engine/loadthread.lua")
    Kristal.Loader.thread:start()

    if Kristal.Args["mod"] then
        TARGET_MOD = Kristal.Args["mod"][1]
    end

    -- load menu
    Gamestate.switch(Kristal.States["Loading"])
end

function love.quit()
    Kristal.saveConfig()
    if Kristal.Loader.thread and Kristal.Loader.thread:isRunning() then
        Kristal.Loader.in_channel:push("stop")
    end
end

function love.update(dt)
    BASE_DT = dt
    if FAST_FORWARD then
        CURRENT_SPEED_MULT = FAST_FORWARD_SPEED
        dt = dt * FAST_FORWARD_SPEED
    else
        CURRENT_SPEED_MULT = 1
    end
    DT = dt
    DTMULT = dt * 30
    RUNTIME = RUNTIME + dt

    if BORDER_FADING == "OUT" then
        BORDER_ALPHA = BORDER_ALPHA - (dt / BORDER_FADE_TIME)
        if BORDER_ALPHA <= 0 and BORDER_TRANSITIONING then
            BORDER_FADING = "IN"
            BORDER_FADE_FROM = nil
            BORDER_TRANSITIONING = false
        end
    elseif BORDER_FADING == "IN" then
        BORDER_ALPHA = BORDER_ALPHA + (dt / BORDER_FADE_TIME)
    end
    BORDER_ALPHA = Utils.clamp(BORDER_ALPHA, 0, 1)

    if MOUSE_VISIBLE then
        local cursor_speed = (16 * (dt * 30))
        local thumb_x, thumb_y = Input.getLeftThumbstick()
        Input.gamepad_cursor_x = Input.gamepad_cursor_x + thumb_x * cursor_speed
        Input.gamepad_cursor_y = Input.gamepad_cursor_y + thumb_y * cursor_speed
        Input.gamepad_cursor_x = Utils.clamp(Input.gamepad_cursor_x, 0, love.graphics.getWidth() / Kristal.getGameScale())
        Input.gamepad_cursor_y = Utils.clamp(Input.gamepad_cursor_y, 0, love.graphics.getHeight() / Kristal.getGameScale())
    end

    LibTimer.update()
    Music.update()
    Assets.update()
    TextInput.update()

    if Kristal.Loader.waiting > 0 then
        local msg = Kristal.Loader.out_channel:pop()
        if msg then
            Kristal.Loader.waiting = Kristal.Loader.waiting - 1

            if Kristal.Loader.waiting == 0 then
                Kristal.Overlay.setLoading(false)
            end

            Assets.loadData(msg.data.assets)
            Kristal.Mods.loadData(msg.data.mods)

            if Kristal.Loader.end_funcs[msg.key] then
                Kristal.Loader.end_funcs[msg.key]()
                Kristal.Loader.end_funcs[msg.key] = nil
            end
        end
    end
end

function love.textinput(key)
    TextInput.onTextInput(key)
    Kristal.callEvent("onTextInput", key)
end

function love.mousepressed(win_x, win_y, button, istouch, presses)
    local x, y = Input.getMousePosition(win_x, win_y)
    if Kristal.DebugSystem then
        Kristal.DebugSystem:onMousePressed(x, y, button, istouch, presses)
    end
    Kristal.callEvent("onMousePressed", x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- Adjust to be inside of the screen
    x, y = Input.getMousePosition(x, y)
    dx, dy = Input.getMousePosition(dx, dy, true)
    Kristal.callEvent("onMouseMoved", x, y, dx, dy, istouch)
end

function love.mousereleased(x, y, button, istouch, presses)
    if Kristal.DebugSystem then
        Kristal.DebugSystem:onMouseReleased(x, y, button, istouch, presses)
    end
    Kristal.callEvent("onMouseReleased", x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, is_repeat)
    if not is_repeat then
        Input.onKeyPressed(key, false)
    else
        TextInput.onKeyPressed(key)
    end
end

function love.keyreleased(key)
    Input.onKeyReleased(key)
end

function Kristal.onKeyPressed(key, is_repeat)
    if Input.ctrl() and Input.shift() and Input.alt() and key == "t" and not is_repeat then -- Panic button for binds
        Input.resetBinds()
        Input.saveBinds()
        Assets.playSound("impact")
        return
    end

    if not TextInput.active then
        if not Utils.startsWith(key, "gamepad:") then
            Input.active_gamepad = nil
        end

        local state = Kristal.getState()
        if state.onKeyPressed and not OVERLAY_OPEN then
            state:onKeyPressed(key, is_repeat)
        end
    end

    if Input.processKeyPressedFunc(key) and not TextInput.active then
        if Input.is("debug_menu", key) then
            if Kristal.DebugSystem then
                Input.clear("debug_menu")
                if Kristal.DebugSystem:isMenuOpen() then
                    Assets.playSound("ui_move")
                    Kristal.DebugSystem:closeMenu()
                else
                    Kristal.DebugSystem:openMenu()
                end
            end
        elseif Input.is("console", key) then
            if Kristal.DebugSystem and Kristal.DebugSystem:isMenuOpen() then
                Assets.playSound("ui_move")
                Kristal.DebugSystem:closeMenu()
            elseif Kristal.Console then
                if not Kristal.Console.is_open then
                    Input.clear("console")
                    Kristal.Console:open()
                end
            end
        end
    end

    if Kristal.DebugSystem then
        Kristal.DebugSystem:onKeyPressed(key, is_repeat)
    end

    local console_open = Kristal.Console and Kristal.Console.is_open

    if not is_repeat then
        if key == "f2" or (Input.is("fast_forward", key) and not console_open) then
            FAST_FORWARD = not FAST_FORWARD
        elseif key == "f3" then
            love.system.openURL("https://github.com/KristalTeam/Kristal/wiki")
        elseif key == "f4" or (key == "return" and Input.alt()) then
            Kristal.Config["fullscreen"] = not Kristal.Config["fullscreen"]
            love.window.setFullscreen(Kristal.Config["fullscreen"])
        elseif key == "f6" then
            DEBUG_RENDER = not DEBUG_RENDER
        elseif key == "f8" then
            print("Hotswapping files...\nNOTE: Might be unstable. If anything goes wrong, it's not our fault :P")
            Hotswapper.scan()
        elseif key == "r" and Input.ctrl() and not console_open then
            if Kristal.getModOption("hardReset") then
                love.event.quit("restart")
            else
                if Mod then
                    if Input.alt() then
                        Kristal.quickReload("none")
                    elseif Input.shift() then
                        Kristal.quickReload("save")
                    else
                        Kristal.quickReload("temp")
                    end
                else
                    Kristal.returnToMenu()
                end
            end
        end
    end

    if not is_repeat then
        TextInput.onKeyPressed(key)
    end
end

function Kristal.onKeyReleased(key)
    if not TextInput.active and not OVERLAY_OPEN then
        local state = Kristal.getState()
        if state.onKeyReleased then
            state:onKeyReleased(key)
        end
    end
end

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function Kristal.errorHandler(msg)
    local copy_color = {1, 1, 1, 1}
    local anim_index = 1
    local starwalker_error = (love.math.random(100) <= 5) -- 5% chance for starwalker
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

    msg = tostring(msg or "nil")

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

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(smaller_font)
        love.graphics.printf("Kristal v" .. tostring(Kristal.Version), -20, 10, 640, "right")

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
            elseif e == "keypressed" and a == "c" and Input.ctrl() then
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

        if love.timer then
            DT = love.timer.step()
        end

        draw()
    end

end

function Kristal.setState(state, ...)
    if type(state) == "string" then
        Gamestate.switch(Kristal.States[state], ...)
    else
        Gamestate.switch(state, ...)
    end
end

function Kristal.getState()
    return Gamestate.current()
end

function Kristal.getTime()
    return RUNTIME
end

function Kristal.setVolume(volume)
    Kristal.Config["masterVolume"] = Utils.clamp(volume, 0, 1)
    love.audio.setVolume(volume)
    Kristal.saveConfig()
end

function Kristal.updateCursor()
    if MOUSE_VISIBLE then
        Kristal.showCursor()
    elseif not MOUSE_VISIBLE then
        Kristal.hideCursor()
    end

    if not Kristal.Config["systemCursor"] then
        love.mouse.setVisible(false)
    else
        if Kristal.Config["alwaysShowCursor"] then love.mouse.setVisible(true) end
    end
end

function Kristal.hideCursor()
    if (not Kristal.Config["systemCursor"]) then
        love.mouse.setVisible(false)
    end
    if (Kristal.Config["systemCursor"]) and not Kristal.Config["alwaysShowCursor"] then
        love.mouse.setVisible(false)
    end

    MOUSE_VISIBLE = false
end

function Kristal.showCursor()
    if Kristal.Config["systemCursor"] then
        love.mouse.setVisible(true)
    end
    MOUSE_VISIBLE = true
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
    -- Remove the dark transition
    for _,object in ipairs(Kristal.Stage.children) do
        if object:includes(DarkTransition) then
            object:remove()
        end
    end
    -- Reload mods and return to memu
    Kristal.loadAssets("", "mods", "", function()
        Gamestate.switch(Kristal.States["Menu"])
    end)

    Kristal.DebugSystem:refresh()
    -- End input if it's open
    if not Kristal.Console.is_open then
        TextInput.endInput()
    end
end

-- Mode can be "temp", "save", or "none"
function Kristal.quickReload(mode)
    -- Temporarily save game variables
    local save, save_id, encounter
    if mode == "temp" then
        save = Game:save()
        save_id = Game.save_id
        encounter = Game.battle and Game.battle.encounter and Game.battle.encounter.id
    elseif mode == "save" then
        save_id = Game.save_id
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
        if mode ~= "save" then
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
        else
            Kristal.loadMod(mod_id, save_id)
        end
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
    Kristal.Loader.waiting = Kristal.Loader.waiting + 1
    if after then
        Kristal.Loader.end_funcs[Kristal.Loader.next_key] = after
    end
    Kristal.Loader.in_channel:push({
        key = Kristal.Loader.next_key,
        dir = dir,
        loader = loader,
        paths = paths
    })
    Kristal.Loader.next_key = Kristal.Loader.next_key + 1
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

        -- Add the current library to the libs table first, before lib.lua execution
        Mod.libs[lib_id] = lib

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

        -- Add the current library to the libs table (again, with the real final value)
        Mod.libs[lib_id] = lib
    end

    local new_file = not save_id or not Kristal.hasSaveFile(save_id, mod.id)

    if not new_file or not mod.transition or after then
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
                        if Game.world and Game.world.player then
                            local px, py = Game.world.player:getScreenPos()
                            transition.final_y = py
                        end
                    end
                end)
            end
            transition.land_callback = function()
                if Game and Game.world and Game.world.player then
                    local kx, ky = transition.kris_sprite:localToScreenPos(transition.kris_width / 2, 0)
                    -- TODO: Hardcoded offsets for now... Figure out why these are required
                    Game.world.player:setScreenPos(kx - 2, transition.final_y - 2)
                    Game.world.player.visible = false
                    Game.world.player:setFacing("down")

                    if not transition.kris_only and Game.world.followers[1] then
                        local sx, sy = transition.susie_sprite:localToScreenPos(transition.susie_width / 2, 0)
                        Game.world.followers[1]:setScreenPos(sx + 6, transition.final_y - 6)
                        Game.world.followers[1].visible = false
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
        use_callback = use_callback and not lib_result
    end

    -- Call Mod:preInit
    local mod_result = Kristal.modCall("preInit")
    use_callback = use_callback and not mod_result

    -- Initialize registry
    Registry.initialize()

    -- Return true if no "preInit" explicitly returns true
    return use_callback
end

function Kristal.resetWindow()
    local window_scale = Kristal.Config["windowScale"]
    local window_width  = SCREEN_WIDTH * window_scale
    local window_height = SCREEN_HEIGHT * window_scale

    if Kristal.bordersEnabled() then
        local border_width, border_height = Kristal.getRelativeBorderSize()
        window_width  = window_width  + border_width
        window_height = window_height + border_height
    end

    love.window.setMode(window_width, window_height, {
        fullscreen = Kristal.Config["fullscreen"],
        vsync = Kristal.Config["vSync"]
    })
end

function Kristal.bordersEnabled()
    return Kristal.Config["borders"] ~= "off"
end

function Kristal.getBorderSize()
    if Kristal.bordersEnabled() then
        return (BORDER_WIDTH * BORDER_SCALE) * Kristal.Config["windowScale"], (BORDER_HEIGHT * BORDER_SCALE) * Kristal.Config["windowScale"]
    end
    return 0, 0
end

function Kristal.getRelativeBorderSize()
    if Kristal.bordersEnabled() then
        return ((BORDER_WIDTH  * BORDER_SCALE) - SCREEN_WIDTH ) * Kristal.Config["windowScale"],
               ((BORDER_HEIGHT * BORDER_SCALE) - SCREEN_HEIGHT) * Kristal.Config["windowScale"]
    end
    return 0, 0
end

function Kristal.getBorder()
    if not REGISTRY_LOADED then
        return nil
    end

    local border = Kristal.getBorderData(Kristal.Config["borders"])

    if border[1] == "dynamic" then
        return Kristal.processDynamicBorder()
    elseif border[3] then
        if type(border[3]) == "function" then
            return border[3]()
        end
        return border[3]
    end
    return nil
end

function Kristal.processDynamicBorder()
    if Kristal.getState() == Game then
        return Game:getBorder()
    elseif Kristal.getState() == Kristal.States["Menu"] then
        return "castle"
    end
end

function Kristal.stageTransitionExists()
    return #Kristal.Stage:getObjects(DarkTransition) ~= 0
end

function Kristal.hideBorder(time, keep_old)
    BORDER_FADING = "OUT"
    BORDER_FADE_TIME = time or 0.5
    BORDER_FADE_FROM = keep_old and LAST_BORDER or nil
    BORDER_TRANSITIONING = false
end

function Kristal.transitionBorder(time)
    if BORDER_ALPHA > 0 then
        BORDER_FADING = "OUT"
    end
    BORDER_FADE_TIME = (time or 1) / 2
    BORDER_FADE_FROM = LAST_BORDER
    BORDER_TRANSITIONING = true
end

function Kristal.showBorder(time)
    BORDER_FADING = "IN"
    BORDER_FADE_TIME = time or 0.5
    BORDER_FADE_FROM = nil
    BORDER_TRANSITIONING = false
    LAST_BORDER = Kristal.getBorder()
end

function Kristal.getBorderName()
    local border = Kristal.getBorderData(Kristal.Config["borders"])
    return border[2]
end

function Kristal.getBorderData(id)
    for _,border in ipairs(BORDER_TYPES) do
        if border[1] == id then
            return border
        end
    end
    return BORDER_TYPES[1]
end

function Kristal.getGameScale()
    if Kristal.bordersEnabled() then
        return math.min(love.graphics.getWidth() / (BORDER_WIDTH * BORDER_SCALE), love.graphics.getHeight() / (BORDER_HEIGHT * BORDER_SCALE))
    else
        return math.min(love.graphics.getWidth() / SCREEN_WIDTH, love.graphics.getHeight() / SCREEN_HEIGHT)
    end
end

function Kristal.getSideOffsets()
    return (love.graphics.getWidth()  - (SCREEN_WIDTH  * Kristal.getGameScale())) / 2,
           (love.graphics.getHeight() - (SCREEN_HEIGHT * Kristal.getGameScale())) / 2
end

function Kristal.loadConfig()
    local config = {
        windowScale = 1,
        skipIntro = false,
        showFPS = false,
        fps = 60,
        vSync = false,
        debug = false,
        fullscreen = false,
        simplifyVFX = false,
        autoRun = false,
        masterVolume = 1,
        favorites = {},
        systemCursor = false,
        alwaysShowCursor = false,
        objectSelectionSlowdown = true,
        borders = "off"
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

function Kristal.loadGame(id, fade)
    id = id or Game.save_id
    local path = "saves/"..Mod.info.id.."/file_"..id..".json"
    if love.filesystem.getInfo(path) then
        local data = JSON.decode(love.filesystem.read(path))
        Game:load(data, id, fade)
    else
        Game:load(nil, id, fade)
    end
end

function Kristal.getSaveFile(id, path)
    id = id or Game.save_id
    local path = "saves/"..(path or Mod.info.id).."/file_"..id..".json"
    if love.filesystem.getInfo(path) then
        return JSON.decode(love.filesystem.read(path))
    end
end

function Kristal.hasSaveFile(id, path)
    id = id or Game.save_id
    local path = "saves/"..(path or Mod.info.id).."/file_"..id..".json"
    return love.filesystem.getInfo(path) ~= nil
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
        local library = Mod.libs[lib]
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

---@diagnostic disable-next-line: lowercase-global
function modRequire(path, ...)
    path = path:gsub("%.", "/")
    local success, result = Kristal.executeModScript(path, ...)
    if not success then
        error("No script found: "..path)
    end
    return result
end

---@diagnostic disable-next-line: lowercase-global
function libRequire(lib, path, ...)
    path = path:gsub("%.", "/")
    local success, result = Kristal.executeLibScript(lib, path, ...)
    if not success then
        error("No script found: "..path)
    end
    return result
end

return Kristal