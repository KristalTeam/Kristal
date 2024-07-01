local Kristal = {}

if not HOTSWAPPING then
    Kristal.Config = {}
    Kristal.Mods = require("src.engine.mods")
    Kristal.Overlay = require("src.engine.overlay")
    Kristal.Shaders = require("src.engine.shaders")
    Kristal.States = {
        ["Loading"] = require("src.engine.loadstate"),
        ["MainMenu"] = require("src.engine.menu.mainmenu"),
        ["Game"] = require("src.engine.game.game"),
        ["Testing"] = require("src.teststate"),
    }

    Kristal.Loader = {
        in_channel = nil,
        out_channel = nil,
        thread = nil,

        next_key = 0,
        waiting = 0,
        end_funcs = {},

        message = ""
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
    for _, arg in ipairs(args or {}) do
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

    -- Save the defaults so if we do setWindowTitle for a mod we're able to revert it
    -- Unfortunate variable names
    Kristal.icon = love.window.getIcon()
    Kristal.game_default_name = love.window.getTitle()

    -- pixel scaling (the good one)
    -- the second nearest isn't needed, but the love2d extension marks the second argument as required for some reason
    love.graphics.setDefaultFilter("nearest", "nearest")

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
    Kristal.setVolume(Kristal.Config["masterVolume"] or 0.6)

    -- hide mouse
    Kristal.hideCursor()

    -- make mouse sprite
    MOUSE_SPRITE = love.graphics.newImage((love.math.random(1000) <= 1) and "assets/sprites/kristal/starwalker.png" or
        "assets/sprites/kristal/mouse.png")

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

    PERFORMANCE_TEST = nil
    ---@type string|nil
    PERFORMANCE_TEST_STAGE = nil

    -- setup hooks
    Utils.hook(love, "update", function (orig, ...)
        if PERFORMANCE_TEST_STAGE == "UPDATE" then
            PERFORMANCE_TEST = {}
            Utils.pushPerformance("Total")
        end
        orig(...)
        Kristal.Stage:update()
        Kristal.Overlay:update()
        if PERFORMANCE_TEST then
            Utils.popPerformance()
            print("-------- PERFORMANCE --------")
            Utils.printPerformance()
            PERFORMANCE_TEST_STAGE = "DRAW"
            PERFORMANCE_TEST = nil
        end
    end)
    Utils.hook(love, "draw", function (orig, ...)
        if PERFORMANCE_TEST_STAGE == "DRAW" then
            PERFORMANCE_TEST = {}
            Utils.pushPerformance("Total")
        end

        love.graphics.reset()

        Draw.pushCanvas(SCREEN_CANVAS)
        love.graphics.clear(0, 0, 0, 1)
        orig(...)
        Kristal.Stage:draw()
        Kristal.Overlay:draw()
        Draw.popCanvas()

        Draw.setColor(1, 1, 1, 1)

        if Kristal.bordersEnabled() then
            local border = Kristal.getBorder()

            local dynamic = Kristal.Config["borders"] == "dynamic"

            if dynamic and BORDER_FADING == "OUT" and BORDER_FADE_FROM then
                border = BORDER_FADE_FROM
            end

            if border then
                local border_texture = Assets.getTexture("borders/" .. border)

                love.graphics.scale(Kristal.getGameScale())
                Draw.setColor(1, 1, 1, dynamic and BORDER_ALPHA or 1)
                if border_texture then
                    Draw.draw(border_texture, 0, 0, 0, BORDER_SCALE)
                end
                if dynamic then
                    Kristal.callEvent(KRISTAL_EVENT.onBorderDraw, border, border_texture)
                end
                Draw.setColor(1, 1, 1, 1)
                love.graphics.reset()
            end

            LAST_BORDER = border
        end

        -- Draw the game canvas
        love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
        love.graphics.scale(Kristal.getGameScale())
        Draw.draw(SCREEN_CANVAS, -SCREEN_WIDTH / 2, -SCREEN_HEIGHT / 2)

        love.graphics.reset()
        love.graphics.scale(Kristal.getGameScale())

        if (not Kristal.Config["systemCursor"]) and (Kristal.Config["alwaysShowCursor"] or MOUSE_VISIBLE) and love.window then
            if Input.usingGamepad() then
                Draw.setColor(0, 0, 0, 0.5)
                love.graphics.circle("fill", Input.gamepad_cursor_x, Input.gamepad_cursor_y, Input.gamepad_cursor_size)
                Draw.setColor(1, 1, 1, 1)
                love.graphics.circle("line", Input.gamepad_cursor_x, Input.gamepad_cursor_y, Input.gamepad_cursor_size)
            elseif MOUSE_SPRITE and love.window.hasMouseFocus() then
                Draw.draw(MOUSE_SPRITE, love.mouse.getX() / Kristal.getGameScale(),
                          love.mouse.getY() / Kristal.getGameScale())
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

    -- TARGET_MOD being already set -> is defined by the mod developer
    -- and we wouldn't want the user to overwrite it
    if not TARGET_MOD and Kristal.Args["mod"] then
        TARGET_MOD = Kristal.Args["mod"][1]
    end

    -- load menu
    Gamestate.switch(Kristal.States["Loading"])

    -- Initialize Discord RPC
    if DISCORD_RPC_AVAILABLE and Kristal.Config["discordRPC"] then
        DiscordRPC.initialize(DISCORD_RPC_ID, true)
        DiscordRPC.updatePresence(Kristal.getPresence())
    end
end

function love.quit()

    if DISCORD_RPC_AVAILABLE and Kristal.Config["discordRPC"] then
        DiscordRPC.shutdown()
    end

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
        Input.gamepad_cursor_y = Utils.clamp(Input.gamepad_cursor_y, 0,
                                             love.graphics.getHeight() / Kristal.getGameScale())
    end

    LibTimer.update()
    Music.update()
    Assets.update()
    TextInput.update()

    if Kristal.Loader.waiting > 0 then
        while Kristal.Loader.out_channel:getCount() > 0 do
            local msg = Kristal.Loader.out_channel:pop()
            if msg then
                if msg.status == "finished" then
                    Kristal.Loader.waiting = Kristal.Loader.waiting - 1

                    Kristal.Loader.message = ""

                    if Kristal.Loader.waiting == 0 then
                        Kristal.Overlay.setLoading(false)
                    end

                    Assets.loadData(msg.data.assets)
                    Kristal.Mods.loadData(msg.data.mods, msg.data.failed_mods)

                    if Kristal.Loader.end_funcs[msg.key] then
                        Kristal.Loader.end_funcs[msg.key]()
                        Kristal.Loader.end_funcs[msg.key] = nil
                    end
                elseif msg.status == "loading" then
                    Kristal.Loader.message = msg.path
                end
            end
        end
    end
end

function love.textinput(key)
    TextInput.onTextInput(key)
    Kristal.callEvent(KRISTAL_EVENT.onTextInput, key)
end

function love.mousepressed(win_x, win_y, button, istouch, presses)
    Input.active_gamepad = nil
    local x, y = Input.getMousePosition(win_x, win_y)
    if Kristal.DebugSystem then
        Kristal.DebugSystem:onMousePressed(x, y, button, istouch, presses)
    end
    Kristal.callEvent(KRISTAL_EVENT.onMousePressed, x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- Adjust to be inside of the screen
    x, y = Input.getMousePosition(x, y)
    dx, dy = Input.getMousePosition(dx, dy, true)
    Kristal.callEvent(KRISTAL_EVENT.onMouseMoved, x, y, dx, dy, istouch)
end

function love.mousereleased(x, y, button, istouch, presses)
    if Kristal.DebugSystem then
        Kristal.DebugSystem:onMouseReleased(x, y, button, istouch, presses)
    end
    Kristal.callEvent(KRISTAL_EVENT.onMouseReleased, x, y, button, istouch, presses)
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

    if not TextInput.active and not (Input.gamepad_locked and Input.isGamepad(key)) then
        if not Utils.startsWith(key, "gamepad:") then
            Input.active_gamepad = nil
        end

        local state = Kristal.getState()
        if state.onKeyPressed and not OVERLAY_OPEN then
            state:onKeyPressed(key, is_repeat)
        end
    end

    if Input.shouldProcess(key) and not TextInput.active then
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

    if not is_repeat and Input.shouldProcess(key) then
        if key == "f2" or (Input.is("fast_forward", key) and not console_open) then
            FAST_FORWARD = not FAST_FORWARD
        elseif key == "f3" then
            love.system.openURL("https://kristal.cc/wiki")
        elseif key == "f4" or (key == "return" and Input.alt()) then
            Kristal.Config["fullscreen"] = not Kristal.Config["fullscreen"]
            love.window.setFullscreen(Kristal.Config["fullscreen"])
        elseif key == "f6" then
            DEBUG_RENDER = not DEBUG_RENDER
        elseif key == "f8" then
            print("Hotswapping files...\nNOTE: Might be unstable. If anything goes wrong, it's not our fault :P")
            Hotswapper.scan()
        elseif key == "r" and Input.ctrl() and not console_open then
            if Kristal.getModOption("hardReset") or Input.alt() and Input.shift() then
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
    if Kristal.DebugSystem then
        Kristal.DebugSystem:onKeyReleased(key)
    end
    if not TextInput.active and not OVERLAY_OPEN then
        local state = Kristal.getState()
        if state.onKeyReleased then
            state:onKeyReleased(key)
        end
    end
end

function Kristal.onWheelMoved(x, y)
    if Kristal.DebugSystem then
        Kristal.DebugSystem:onWheelMoved(x, y)
    end
    if not TextInput.active and not OVERLAY_OPEN then
        local state = Kristal.getState()
        if state.onWheelMoved then
            state:onWheelMoved(x, y)
        end
    end
end

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end

--- Kristal alternative to the default love.errorhandler. \
--- Called when an error occurs.
---@param  msg string|table     The error message.
---@return function|nil handler The error handler, called every frame instead of the main loop.
function Kristal.errorHandler(msg)
    local copy_color = { 1, 1, 1, 1 }
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

    local critical = false
    local trace = nil
    if type(msg) == "table" then
        if msg.critical then
            if(msg.critical == "error in error handling") then
                critical = true
                msg =  "critical error"
            else
                msg = msg.critical
            end
        elseif msg.msg then
            local split = Utils.split(msg.msg, "\n")
            trace = table.concat(split, "\n", 2)
            msg = split[1]
        end
    end

    msg = tostring(msg or "nil")

    if not critical and not trace then
        error_printer(msg, 2)
    elseif trace then
        print("Error: " .. msg .. "\n" .. trace)
    end

    if not love.window or not love.graphics or not love.event then
        return
    end

    if not love.window.isOpen() then
        local width, height = SCREEN_WIDTH, SCREEN_HEIGHT
        if Kristal.Config and Kristal.Config["borders"] ~= "off" then
            width, height = BORDER_WIDTH * BORDER_SCALE, BORDER_HEIGHT * BORDER_SCALE
        end
        local success, status = pcall(love.window.setMode, width, SCREEN_HEIGHT * height)
        if not success or not status then
            return
        end
    end

    local window_scale = 1
    if Kristal.Config and Kristal.Config["borders"] ~= "off" then
        window_scale = math.min(love.graphics.getWidth() / (BORDER_WIDTH * BORDER_SCALE),
                                love.graphics.getHeight() / (BORDER_HEIGHT * BORDER_SCALE))
    else
        window_scale = math.min(love.graphics.getWidth() / SCREEN_WIDTH, love.graphics.getHeight() / SCREEN_HEIGHT)
    end

    local window_width = love.graphics.getWidth() / window_scale
    local window_height = love.graphics.getHeight() / window_scale

    -- Reset state.
    if Input then Input.clear(nil, true) end
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
        for i, v in ipairs(love.joystick.getJoysticks()) do
            v:setVibration()
        end
    end
    if love.audio then love.audio.stop() end

    love.graphics.reset()

    Draw.setColor(1, 1, 1, 1)

    if not trace then
        trace = ""
        if not critical then
            trace = debug.traceback("", 2)
        end
    end

    love.graphics.origin()

    local split = Utils.split(msg, ": ")

    local version_string = "Kristal v" .. tostring(Kristal.Version)
    local trimmed_commit = GitFinder:fetchTrimmedCommit()
    if trimmed_commit then
        version_string = version_string .. " (" .. trimmed_commit .. ")"
    end

    local mod_string = ""
    local lib_string = ""

    local w = 0
    local h = 18
    if Mod then
        mod_string = "Mod: " .. Mod.info.id .. " " .. (Mod.info.version or "v?.?.?")
        if Utils.tableLength(Mod.libs) > 0 then
            lib_string = "Libraries:"
            for _, lib in Kristal.iterLibraries() do
                local line = (lib.info.id or "") .. " " .. (lib.info.version or "v?.?.?")
                lib_string = lib_string .. "\n" .. line
                w = math.max(w, #line * 7)
                h = h + 16
            end
        end
    end
    local show_libraries = false

    local function draw()
        local pos = 32
        local ypos = pos
        love.graphics.origin()
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.scale(window_scale)

        Draw.setColor(1, 1, 1, 1)
        love.graphics.setFont(smaller_font)
        love.graphics.printf(version_string, -20, 10, window_width, "right")
        love.graphics.printf(mod_string, 20, 10, window_width)

        love.graphics.setFont(font)

        local warp = window_width - pos * 2
        if not critical then
            local header = "Error at " .. ( (#split - 1 > 0) and split[#split - 1] or "???").. " - " .. split[#split] --check if msg is one line long
            local _, lines = font:getWrap(header, warp)
            love.graphics.printf(
                { "Error at ", { 0.6, 0.6, 0.6, 1 }, ( (#split - 1 > 0) and split[#split - 1] or "???"), { 1, 1, 1, 1 }, " - " .. split[#split] }, pos,
                ypos,
                window_width - pos)
            ypos = ypos + (32 * #lines)
            love.graphics.setFont(font)

            for l in trace:gmatch("(.-)\n") do
                if not l:match("boot.lua") then
                    if l:match("stack traceback:") then
                        love.graphics.setFont(font)
                        love.graphics.printf("Traceback:", pos, ypos, warp)
                        ypos = ypos + 32
                    else
                        if ypos >= window_height - 40 - 32 then
                            love.graphics.printf("...", pos, ypos, warp)
                            break
                        end
                        love.graphics.setFont(smaller_font)
                        local _, e_lines = smaller_font:getWrap(l, warp)
                        love.graphics.printf(l, pos, ypos, warp)
                        ypos = ypos + 16 * #e_lines
                    end
                end
            end
        else
            love.graphics.printf("Critical Error!\nTry replicating the bug, we might catch it next time...", pos, ypos, warp)

            love.graphics.setFont(font)
            love.graphics.printf("Known causes:", pos, ypos + 96, warp)

            love.graphics.setFont(smaller_font)
            love.graphics.printf("- Stack overflow (recursive loop?)", pos + 24, ypos + 96 + 32, warp)
        end

        if starwalker_error then
            Draw.draw(starwalkertext, window_width - starwalkertext:getWidth() - 20,
                      window_height - starwalkertext:getHeight() - (starwalker:getHeight() * 2))

            love.graphics.push()
            love.graphics.scale(2, 2)
            Draw.draw(starwalker, (window_width / 2) - starwalker:getWidth(),
                      (window_height / 2) - starwalker:getHeight())
            love.graphics.pop()
        else
            anim_index = anim_index + (DT * 4)
            if anim_index >= 8 then
                anim_index = 1
            end

            local banana = banana_anim[math.floor(anim_index)]

            love.graphics.push()
            love.graphics.scale(2, 2)
            Draw.draw(banana, (window_width / 2) - banana:getWidth(), (window_height / 2) - banana:getHeight())
            love.graphics.pop()
        end

        -- DT shouldnt exceed 30FPS
        DT = math.min(love.timer.getDelta(), 1 / 30)

        copy_color[1] = copy_color[1] + (DT * 2)
        copy_color[3] = copy_color[3] + (DT * 2)

        love.graphics.setFont(smaller_font)
        if Kristal.getModOption("hardReset") then
            Draw.setColor(1, 1, 1, 1)
            love.graphics.print("Press ESC to restart the game", 8, window_height - (critical and 20 or 40))
        else
            Draw.setColor(1, 1, 1, 1)
            love.graphics.print("Press ESC to return to mod menu", 8, window_height - (critical and 20 or 40))
        end
        if not critical then
            Draw.setColor(copy_color)
            love.graphics.print("Press CTRL+C to copy traceback to clipboard", 8, window_height - 20)
        end

        if show_libraries then
            Draw.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 20, 38, w + 4, h + 2)
            Draw.setColor(1, 1, 1, 1)
            love.graphics.printf(lib_string, 22, 40, window_width, "left")
        end

        love.graphics.present()
    end

    local function copyToClipboard()
        if not love.system then return end
        copy_color = { 0, 1, 0, 1 }
        love.system.setClipboardText(tostring(msg) ..
            "\n" .. trace .. "\n\n" .. version_string .. "\n" .. mod_string .. "\n" .. lib_string)
        draw()
    end

    return function ()
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
            elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") and not critical then
                copyToClipboard()
            elseif e == "touchpressed" then
                local name = love.window.getTitle()
                if #name == 0 or name == "Untitled" then name = "Game" end
                local buttons = { "Yes", "No", enterbutton = 1, escapebutton = 2 }
                if love.system and not critical then
                    buttons[3] = "Copy to clipboard"
                end
                local errormessage = Kristal.getModOption("hardReset") and "Would you like to restart Kristal?" or
                    "Would you like to return to the Kristal menu?"
                local pressed = love.window.showMessageBox(name, errormessage, buttons)
                if pressed == 1 then
                    if Kristal.getModOption("hardReset") then
                        return "restart"
                    else
                        return "reload"
                    end
                elseif pressed == 3 then
                    copyToClipboard()
                end
            elseif e == "gamepadpressed" and b == "a" then
                if Kristal.getModOption("hardReset") then
                    return "restart"
                else
                    return "reload"
                end
            elseif e == "gamepadpressed" and b == "y" then
                copyToClipboard()
            end
        end

        if love.timer then
            DT = love.timer.step()
        end

        local x, y = love.mouse:getPosition()

        show_libraries = false
        if 20 < x and x < 20 + #mod_string * 7 and 10 < y and y < 26 then
            show_libraries = true
        end

        draw()

        love.timer.sleep(0.01)
    end
end

--- Switches the Gamestate to the given one.
---@param state table|string The gamestate to switch to.
---| "Loading" # The loading state, before entering the main menu.
---| "Menu"    # The main menu state.
---| "Game"    # The game state, entered when loading a mod.
---| "Testing" # The testing state, used in development.
---@param ... any Arguments passed to the gamestate.
function Kristal.setState(state, ...)
    if type(state) == "string" then
        Gamestate.switch(Kristal.States[state], ...)
    else
        Gamestate.switch(state, ...)
    end
end

---@return table state The current Gamestate.
function Kristal.getState()
    return Gamestate.current()
end

---@return number runtime The current runtime (`RUNTIME`), affected by timescale / fast-forward.
function Kristal.getTime()
    return RUNTIME
end

--- Helper function to set the current RPC information, and update the presence if enabled.
---@param presence table The presence information to set.
function Kristal.setPresence(presence)
    DISCORD_RPC_PRESENCE = presence or {}
    if DISCORD_RPC_AVAILABLE and Kristal.Config["discordRPC"] then
        DiscordRPC.updatePresence(presence)
    end
end

---@return table presence Get the current presence information.
function Kristal.getPresence()
    return DISCORD_RPC_PRESENCE
end

--- Sets the master volume to the given value and saves it to the config.
---@param volume number The volume to set.
function Kristal.setVolume(volume)
    Kristal.Config["masterVolume"] = Utils.clamp(volume, 0, 1)
    love.audio.setVolume(volume)
    Kristal.saveConfig()
end

--- Called internally to make sure the correct cursor is displayed.
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

--- Hides the mouse cursor.
function Kristal.hideCursor()
    if (not Kristal.Config["systemCursor"]) then
        love.mouse.setVisible(false)
    end
    if (Kristal.Config["systemCursor"]) and not Kristal.Config["alwaysShowCursor"] then
        love.mouse.setVisible(false)
    end

    MOUSE_VISIBLE = false
end

--- Shows the mouse cursor.
function Kristal.showCursor()
    if Kristal.Config["systemCursor"] then
        love.mouse.setVisible(true)
    end
    MOUSE_VISIBLE = true
end

--- Returns the current master volume from the config.
---@return number volume The current master volume.
function Kristal.getVolume()
    return Kristal.Config["masterVolume"]
end

--- Clears all state expected to be changed by mods. \
--- Called internally when exiting or reloading a mod.
function Kristal.clearModState()
    -- Clear disruptive active globals
    Object._clearCache()
    Draw._clearStacks()
    -- End the current mod
    Kristal.callEvent(KRISTAL_EVENT.unload)
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

    Kristal.setDesiredWindowTitleAndIcon()

    -- Restore assets and registry
    Assets.restoreData()
    Registry.initialize()
end

--- Exits the current mod and returns to the Kristal menu.
function Kristal.returnToMenu()
    -- Go to empty state
    Gamestate.switch({})
    -- Clear the mod
    Kristal.clearModState()

    -- Reload mods and return to memu
    Kristal.loadAssets("", "mods", "", function ()
        Kristal.setDesiredWindowTitleAndIcon()
        Gamestate.switch(MainMenu)
    end)

    Kristal.DebugSystem:refresh()
    -- End input if it's open
    if not Kristal.Console.is_open then
        TextInput.endInput()
    end
end

--- Reloads the current mod.
---@param mode string The mode to reload the mod in.
---| "temp" # Creates a temp-save and reloads the mod from there.
---| "save" # Reloads the mod from the last save.
---| "none" # Fully reloads the mod from the start of the game.
function Kristal.quickReload(mode)
    -- Temporarily save game variables
    local save, save_id, encounter, shop
    if mode == "temp" then
        save = Game:save()
        save_id = Game.save_id
        encounter = Game.battle and Game.battle.encounter and Game.battle.encounter.id
        shop = Game.shop and Game.shop.id
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
    Kristal.loadAssets("", "mods", "", function ()
        Kristal.setDesiredWindowTitleAndIcon()
        -- Reload the current mod directly
        if mode ~= "save" then
            Kristal.loadMod(mod_id, nil, nil, function ()
                -- Pre-initialize the current mod
                if Kristal.preInitMod(mod_id) then
                    Kristal.setDesiredWindowTitleAndIcon()
                    if save then
                        -- Switch to Game and load the temp save
                        Gamestate.switch(Game, save, save_id, false)
                        -- If we had an encounter, restart the encounter
                        if encounter then
                            Game:encounter(encounter, false)
                        elseif shop then -- If we were in a shop, re-enter it
                            Game:enterShop(shop)
                        end
                    else
                        -- Switch to Game
                        Gamestate.switch(Game)
                    end
                end
            end)
        else
            Kristal.loadMod(mod_id, save_id)
        end
    end)
end

--- Clears all currently loaded assets. Called internally in the Loading state.
---@param include_mods boolean Whether to clear loaded mods.
function Kristal.clearAssets(include_mods)
    Assets.clear()
    if include_mods then
        Kristal.Mods.clear()
    end
end

--- Loads assets of the specified type from the given directory, and calls the given callback when done.
---@param dir    string       The directory to load assets from.
---@param loader string       The type of assets to load.
---@param paths? string|table The specific asset paths to load.
---@param after? function     The function to call when done.
function Kristal.loadAssets(dir, loader, paths, after)
    Kristal.Loader.message = ""
    Kristal.Overlay.setLoading(true)
    Kristal.Loader.waiting = Kristal.Loader.waiting + 1

    if after then
        Kristal.Loader.end_funcs[Kristal.Loader.next_key] = after
    end

    if Kristal.Config["verboseLoader"] then
        Kristal.Loader.in_channel:push("verbose")
    end

    Kristal.Loader.in_channel:push({
        key = Kristal.Loader.next_key,
        dir = dir,
        loader = loader,
        paths = paths
    })
    Kristal.Loader.next_key = Kristal.Loader.next_key + 1
end

--- Initializes the specified mod and loads its assets. \
--- If an `after` callback is not provided, enters the mod, including dark transition if enabled.
---@param id         string   The id of the mod to load.
---@param save_id?   number   The id of the save to load the mod from. (1-3)
---@param save_name? string   The name to use for the save file.
---@param after?     function The function to call after assets have been loaded.
function Kristal.loadMod(id, save_id, save_name, after)
    -- Get the mod data (loaded from mod.json)
    local mod = Kristal.Mods.getAndLoadMod(id)

    -- No mod found; nothing to load
    if not mod then return end

    -- Create the Mod table, which is a global table that
    -- can contain a mod's custom variables and functions
    -- with Mod.info referencing the mod data (from the .json)
    Mod = Mod or { info = mod, libs = {} }

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
    for _, lib_id in ipairs(mod.lib_order) do
        local lib_info = mod.libs[lib_id]

        local lib = { info = lib_info }

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

    Kristal.loadModAssets(mod.id, "all", "", after or function ()
        if Kristal.preInitMod(mod.id) then
            Kristal.setDesiredWindowTitleAndIcon()
            Gamestate.switch(Kristal.States["Game"], save_id, save_name)
        end
    end)
end

--- Loads assets from a mod and its libraries. Called internally by `Kristal.loadMod`.
---@param id           string       The id of the mod to load assets from.
---@param asset_type?  string       The type of assets to load. (Defaults to "all")
---@param asset_paths? string|table The specific asset paths to load.
---@param after        function     The function to call after assets have been loaded.
function Kristal.loadModAssets(id, asset_type, asset_paths, after)
    -- Get the mod data (loaded from mod.json)
    local mod = Kristal.Mods.getAndLoadMod(id)

    -- No mod found; nothing to load
    if not mod then return end

    -- How many assets we need to load (1 for the mod, 1 for each library)
    local load_count = 1 + #mod.lib_order

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
    for _, lib_id in ipairs(mod.lib_order) do
        Kristal.loadAssets(mod.libs[lib_id].path, asset_type or "all", asset_paths or "", finishLoadStep)
    end
    Kristal.loadAssets(mod.path, asset_type or "all", asset_paths or "", finishLoadStep)
end

local function shouldWindowUseModBranding()
    local mod = TARGET_MOD and Kristal.Mods.getMod(TARGET_MOD) or (Mod and Mod.info)
    local use_mod_branding = false
    if mod then
        -- NOTE: setWindowTitle is the previous name of setWindowTitleAndIcon
        if TARGET_MOD then
            -- Unless the mod explicitly says it doesn't want to use mod branding, use it
            use_mod_branding = (mod.setWindowTitleAndIcon or mod.setWindowTitle) ~= false
        else
            -- If the mod explicitly says it wants to use mod branding, use it
            use_mod_branding = mod.setWindowTitleAndIcon or mod.setWindowTitle
        end
    end
    return use_mod_branding and mod
end

--- Called internally. Returns the current running/target mod's name
--- if it wants us to, or the default. \
--- Also see Kristal.setDesiredWindowTitleAndIcon().
function Kristal.getDesiredWindowTitle()
    local mod = shouldWindowUseModBranding()
    return mod and mod.name or Kristal.game_default_name
end

--- Called internally. Sets the title and icon of the game window
--- to either what mod requests to be or the defaults.
function Kristal.setDesiredWindowTitleAndIcon()
    local mod = shouldWindowUseModBranding()
    love.window.setIcon(mod and mod.window_icon_data or Kristal.icon)
    love.window.setTitle(mod and mod.name or Kristal.game_default_name)
end

--- Called internally. Calls the `preInit` event on the mod and initializes the registry.
---@param id string        The id of the mod to pre-initialize.
---@return boolean success Whether the mod should use default handling to enter the game.
function Kristal.preInitMod(id)
    -- Get the mod data (loaded from mod.json)
    local mod = Kristal.Mods.getAndLoadMod(id)

    -- No mod found; nothing to load
    if not mod then return false end

    -- Whether to call the "after" function
    local use_callback = true

    -- Call preInit on all libraries
    for _, lib_id in pairs(mod.lib_order) do
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

--- Called internally. Resets the window properties to the user config.
function Kristal.resetWindow()
    local window_scale  = Kristal.Config["windowScale"]
    local window_width  = SCREEN_WIDTH * window_scale
    local window_height = SCREEN_HEIGHT * window_scale

    if Kristal.bordersEnabled() then
        local border_width, border_height = Kristal.getRelativeBorderSize()
        window_width                      = window_width + border_width
        window_height                     = window_height + border_height
    end

    love.window.setMode(
        love.window.fromPixels(window_width),
        love.window.fromPixels(window_height),
        {
            fullscreen = Kristal.Config["fullscreen"],
            vsync = Kristal.Config["vSync"]
        }
    )

    -- Force tilelayers to redraw, since resetWindow destroys their canvases
    if Game.world then
        for _,tilelayer in ipairs(Game.world.stage:getObjects(TileLayer)) do
            tilelayer.drawn = false
        end
    end
end

---@return boolean console Whether Kristal is in console mode.
function Kristal.isConsole()
    local os = love.system.getOS()
    ---@diagnostic disable-next-line: undefined-field
    return USING_CONSOLE or (love._console ~= nil) or (os == "NX")
end

---@return table types The available border types, or `nil` if borders are disabled.
function Kristal.getBorderTypes()
    local types = {}

    if not Kristal.isConsole() then
        table.insert(types, { "off", "OFF", nil })
    end

    table.insert(types, { "dynamic", "Dynamic", nil })
    table.insert(types, { "simple", "Simple", "simple" })
    table.insert(types, { "none", "None", nil })

    return types
end

---@return boolean enabled Whether borders are enabled.
function Kristal.bordersEnabled()
    return Kristal.isConsole() or Kristal.Config["borders"] ~= "off"
end

--- Returns the dimensions of the screen border, or (0, 0) if borders are disabled.
---@return number width  The width of the border.
---@return number height The height of the border.
function Kristal.getBorderSize()
    if Kristal.bordersEnabled() then
        return (BORDER_WIDTH * BORDER_SCALE) * Kristal.Config["windowScale"],
            (BORDER_HEIGHT * BORDER_SCALE) * Kristal.Config["windowScale"]
    end
    return 0, 0
end

--- Returns the dimensions of the screen border relative to the game's size.
---@return number width  The width of the border.
---@return number height The height of the border.
function Kristal.getRelativeBorderSize()
    if Kristal.bordersEnabled() then
        return ((BORDER_WIDTH * BORDER_SCALE) - SCREEN_WIDTH) * Kristal.Config["windowScale"],
            ((BORDER_HEIGHT * BORDER_SCALE) - SCREEN_HEIGHT) * Kristal.Config["windowScale"]
    end
    return 0, 0
end

---@return string|nil border The currently displayed border, or `nil` if borders are disabled.
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

---@return string|nil border The currently displayed border if dynamic borders are enabled.
function Kristal.processDynamicBorder()
    if Kristal.getState() == Game then
        return Game:getBorder()
    elseif Kristal.getState() == MainMenu then
        return "castle"
    end
end

--- Fades out the screen border.
---@param time?     number  The time it takes to fade out the border. Defaults to `0.5`.
---@param keep_old? boolean Whether the old border stays during fadeout. Defaults to `false`.
function Kristal.hideBorder(time, keep_old)
    BORDER_FADING = "OUT"
    BORDER_FADE_TIME = time or 0.5
    BORDER_FADE_FROM = keep_old and LAST_BORDER or nil
    BORDER_TRANSITIONING = false
end

--- Transitions the screen border, fading it out and then back in to the current border.
---@param time? number The total time it takes to fade in and out. Defaults to `1`.
function Kristal.transitionBorder(time)
    if BORDER_ALPHA > 0 then
        BORDER_FADING = "OUT"
    end
    BORDER_FADE_TIME = (time or 1) / 2
    BORDER_FADE_FROM = LAST_BORDER
    BORDER_TRANSITIONING = true
end

--- Fades in the screen border.
---@param time? number The time it takes to fade in the border. Defaults to `0.5`.
function Kristal.showBorder(time)
    BORDER_FADING = "IN"
    BORDER_FADE_TIME = time or 0.5
    BORDER_FADE_FROM = nil
    BORDER_TRANSITIONING = false
    LAST_BORDER = Kristal.getBorder()
end

---@return string name The name of the current border config option.
function Kristal.getBorderName()
    local border = Kristal.getBorderData(Kristal.Config["borders"])
    return border[2]
end

--- Returns the border data table for the given border config id.
---@param id string The id of the border to get.
---@return table data The border data.
function Kristal.getBorderData(id)
    local types = Kristal.getBorderTypes()
    for _, border in ipairs(types) do
        if border[1] == id then
            return border
        end
    end
    return types[1]
end

---@return number scale The current game scale, based on the window dimensions.
function Kristal.getGameScale()
    if Kristal.bordersEnabled() then
        return math.min(love.graphics.getWidth() / (BORDER_WIDTH * BORDER_SCALE),
                        love.graphics.getHeight() / (BORDER_HEIGHT * BORDER_SCALE))
    else
        return math.min(love.graphics.getWidth() / SCREEN_WIDTH, love.graphics.getHeight() / SCREEN_HEIGHT)
    end
end

--- Returns the offsets of the game display, for calculating screen position.
---@return number x The x offset.
---@return number y The y offset.
function Kristal.getSideOffsets()
    return (love.graphics.getWidth() - (SCREEN_WIDTH * Kristal.getGameScale())) / 2,
        (love.graphics.getHeight() - (SCREEN_HEIGHT * Kristal.getGameScale())) / 2
end

--- Returns the soul color which should be used.
---@return number r The red value of the color.
---@return number g The green value of the color.
---@return number b The blue value of the color.
---@return number a The alpha value of the color.
function Kristal.getSoulColor()
    if Kristal.getState() == Game then
        return Game:getSoulColor()
    end
    return unpack(COLORS.red)
end

--- Called internally. Loads the saved user config, with default values.
---@return table config The user config.
function Kristal.loadConfig()
    local config = {
        windowScale = 1,
        skipIntro = false,
        showFPS = false,
        fps = 30,
        vSync = false,
        frameSkip = false,
        debug = false,
        fullscreen = false,
        simplifyVFX = false,
        autoRun = false,
        masterVolume = 0.6,
        favorites = {},
        systemCursor = false,
        alwaysShowCursor = false,
        objectSelectionSlowdown = true,
        borders = "off",
        leftStickDeadzone = 0.2,
        rightStickDeadzone = 0.2,
        defaultName = "",
        skipNameEntry = false,
        verboseLoader = false,
    }
    if love.filesystem.getInfo("settings.json") then
        Utils.merge(config, JSON.decode(love.filesystem.read("settings.json")))
    end
    return config
end

--- Saves the current config table to the `settings.json`.
function Kristal.saveConfig()
    love.filesystem.write("settings.json", JSON.encode(Kristal.Config))
end

--- Saves the game.
---@param id?   number The save file index to save to. (Defaults to the currently loaded save index)
---@param data? table  The data to save to the file. (Defaults to the output of `Game:save()`)
function Kristal.saveGame(id, data)
    id = id or Game.save_id
    data = data or Game:save()
    Game.save_id = id
    Game.quick_save = nil
    love.filesystem.createDirectory("saves/" .. Mod.info.id)
    love.filesystem.write("saves/" .. Mod.info.id .. "/file_" .. id .. ".json", JSON.encode(data))
end

--- Loads the game from a save file.
---@param id?   number  The save file index to load. (Defaults to the currently loaded save index)
---@param fade? boolean Whether the game should fade in after loading. (Defaults to `false`)
function Kristal.loadGame(id, fade)
    id = id or Game.save_id
    local path = "saves/" .. Mod.info.id .. "/file_" .. id .. ".json"
    if love.filesystem.getInfo(path) then
        local data = JSON.decode(love.filesystem.read(path))
        Game:load(data, id, fade)
    else
        Game:load(nil, id, fade)
    end
end

--- Returns the data from the specified save file.
---@param id?   number    The save file index to load. (Defaults to the currently loaded save index)
---@param path? string    The save folder to load from. (Defaults to the current mod's save folder)
---@return table|nil data The data loaded from the save file, or `nil` if the file doesn't exist.
function Kristal.getSaveFile(id, path)
    id = id or Game.save_id
    local full_path = "saves/" .. (path or Mod.info.id) .. "/file_" .. id .. ".json"
    if love.filesystem.getInfo(full_path) then
        return JSON.decode(love.filesystem.read(full_path))
    end
    return nil
end

--- Returns whether the specified save file exists.
---@param id?   number    The save file index to check. (Defaults to the currently loaded save index)
---@param path? string    The save folder to check. (Defaults to the current mod's save folder)
---@return boolean exists Whether the save file exists.
function Kristal.hasSaveFile(id, path)
    id = id or Game.save_id
    local full_path = "saves/" .. (path or Mod.info.id) .. "/file_" .. id .. ".json"
    return love.filesystem.getInfo(full_path) ~= nil
end

--- Returns whether the specified save folder has any save files.
---@param path? string    The save folder to check. (Defaults to the current mod's save folder)
---@return boolean exists Whether the save folder has any save files.
function Kristal.hasAnySaves(path)
    local full_path = "saves/" .. (path or Mod.info.id)
    return love.filesystem.getInfo(full_path) and (#love.filesystem.getDirectoryItems(full_path) > 0)
end

--- Saves the given data to a file in the save folder.
---@param file  string The file name to save to.
---@param data  table  The data to save.
---@param path? string The save folder to save to. (Defaults to the current mod's save folder)
function Kristal.saveData(file, data, path)
    love.filesystem.createDirectory("saves/" .. (path or Mod.info.id))
    love.filesystem.write("saves/" .. (path or Mod.info.id) .. "/" .. file .. ".json", JSON.encode(data or {}))
end

--- Loads and returns the data from a file in the save folder.
---@param file  string    The file name to load.
---@param path? string    The save folder to load from. (Defaults to the current mod's save folder)
---@return table|nil data The data loaded from the file, or `nil` if the file doesn't exist.
function Kristal.loadData(file, path)
    local full_path = "saves/" .. (path or Mod.info.id) .. "/" .. file .. ".json"
    if love.filesystem.getInfo(full_path) then
        return JSON.decode(love.filesystem.read(full_path))
    end
end

--- Erases a file from the save folder.
---@param file  string The file name to erase.
---@param path? string The save folder to erase from. (Defaults to the current mod's save folder)
function Kristal.eraseData(file, path)
    love.filesystem.remove("saves/" .. (path or Mod.info.id) .. "/" .. file .. ".json")
end

--- Calls a function from the current `Mod`, if it exists.
---@param f   string The function name to call.
---@param ... any    The arguments to pass to the function.
---@return ...       The returned values from the function call, if it exists.
function Kristal.modCall(f, ...)
    if Mod and Mod[f] and type(Mod[f]) == "function" then
        return Mod[f](Mod, ...)
    end
end

--- Calls a function from the specified library, if it exists. \
--- If `id` is not specified, the function will be called in all libraries, and the return value \
--- will be `or`'d between libraries.
---@param id  string|nil The library ID to call the function from, or `nil` to call in all libraries.
---@param f   string     The function name to call.
---@param ... any        The arguments to pass to the function.
---@return ...           The returned values from the function call, if it exists.
function Kristal.libCall(id, f, ...)
    if not Mod then return end

    if not id then
        local result = {}
        for _, lib in Kristal.iterLibraries() do
            if lib[f] and type(lib[f]) == "function" then
                local lib_results = {lib[f](lib, ...)}
                if(#lib_results > 0) then
                    result = lib_results
                end
            end
        end
        return Utils.unpack(result)
    else
        local lib = Mod.libs[id]
        if lib and lib[f] and type(lib[f]) == "function" then
            return lib[f](lib, ...)
        end
    end
end

--- Calls a function from all libraries, and then the current mod.
---@param f   string  The function name to call.
---@param ... any     The arguments to pass to the function.
---@return any result The result of the function calls `or`'d together.
function Kristal.callEvent(f, ...)
    if not Mod then return end
    local lib_result = {Kristal.libCall(nil, f, ...)}
    local mod_result = {Kristal.modCall(f, ...)}
    --print("EVENT: "..tostring(f), #mod_result, #lib_result)
    if(#mod_result > 0) then
        return Utils.unpack(mod_result)
    else
        return Utils.unpack(lib_result)
    end
end

--- Gets a value from the current `Mod`.
---@param key string The key of the value to get.
---@return any value The value at the key, or `nil` if it doesn't exist.
function Kristal.modGet(key)
    if Mod and Mod[key] then
        return Mod[key]
    end
end

--- Gets a value from the current mod's `mod.json`.
---@param key string The key of the value to get.
---@return any value The value at the key, or `nil` if it doesn't exist.
function Kristal.getModOption(key)
    return Mod and Mod.info and Mod.info[key]
end

--- Gets a library config option, defined in either `lib.json` or modified by the `mod.json`. \
--- Default values can be defined inside your library's `lib.json`:
--- ```json
--- "config": {
---    "option": "value"
--- }
--- ```
--- These can then be overridden inside a `mod.json` like so:
--- ```json
--- "config": {
---    "your_library_id": {
---        "option": "new value"
---    }
--- }
--- ```
---@param lib_id      string  The library ID to get the config option from.
---@param key         string  The key of the config option to get.
---@param merge?      boolean If the option is a table, whether to merge it with the default value. (Defaults to `false`)
---@param deep_merge? boolean If merge is enabled, whether to merge the tables deeply. (Defaults to `false`)
---@return any value          The value of the config option, or `nil` if it doesn't exist.
function Kristal.getLibConfig(lib_id, key, merge, deep_merge)
    if not Mod then return end

    local lib = Mod.libs[lib_id]

    if not lib then error("No library found: " .. lib_id) end

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

--- Executes a `.lua` script inside the mod folder.
---@param path string      The script name to execute.
---@param ...  any         The arguments to pass to the script.
---@return boolean success Whether the script was executed successfully.
---@return any     ...     The returned values from the script.
function Kristal.executeModScript(path, ...)
    if not Mod or not Mod.info.script_chunks[path] then
        return false
    else
        return true, Mod.info.script_chunks[path](...)
    end
end

--- Executes a `.lua` script inside the specified library folder. \
--- If `id` is not specified, the first script found from any library will be executed.
---@param lib  string|nil  The library ID to execute the script from, or `nil` to execute from any library.
---@param path string      The script name to execute.
---@param ...  any         The arguments to pass to the script.
---@return boolean success Whether the script was executed successfully.
---@return any     ...     The returned values from the script.
function Kristal.executeLibScript(lib, path, ...)
    if not Mod then
        return false
    end

    if not lib then
        for _, library in Kristal.iterLibraries() do
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

function Kristal.iterLibraries()
    local index = 0

    return function()
        index = index + 1

        if index <= #Mod.info.lib_order then
            local lib_id = Mod.info.lib_order[index]

            return lib_id, Mod.libs[lib_id]
        end
    end
end

--- Clears all mod-defined hooks from `Utils.hook`, and restores the original functions. \
--- Called internally when a mod is unloaded.
function Kristal.clearModHooks()
    for _, hook in ipairs(Utils.__MOD_HOOKS) do
        hook.target[hook.name] = hook.orig
    end
    Utils.__MOD_HOOKS = {}
end

--- Removes all mod-defined classes from base classes' `__includers` table.
--- Called internally when a mod is unloaded.
function Kristal.clearModSubclasses()
    for class, subs in pairs(MOD_SUBCLASSES) do
        for _, sub in ipairs(subs) do
            if class.__includers then
                Utils.removeFromTable(class.__includers, sub)
            end
        end
    end
    MOD_SUBCLASSES = {}
end

--- Executes a `.lua` script inside the mod folder.
---@param path string  The script name to execute.
---@param ...  any     The arguments to pass to the script.
---@return any ...     The returned values from the script.
---@diagnostic disable-next-line: lowercase-global
function modRequire(path, ...)
    path = path:gsub("%.", "/")
    local success, result = Kristal.executeModScript(path, ...)
    if not success then
        error("No script found: " .. path)
    end
    return result
end

--- Executes a `.lua` script inside the specified library folder.
---@param lib  string  The library ID to execute the script from.
---@param path string  The script name to execute.
---@param ...  any     The arguments to pass to the script.
---@return any ...     The returned values from the script.
---@diagnostic disable-next-line: lowercase-global
function libRequire(lib, path, ...)
    path = path:gsub("%.", "/")
    local success, result = Kristal.executeLibScript(lib, path, ...)
    if not success then
        error("No script found: " .. path)
    end
    return result
end

return Kristal
