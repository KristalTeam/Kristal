---@class Menu
local Menu = {}

Menu.TEST_MOD_LIST = false
Menu.TEST_MOD_COUNT = 0

Menu.BACKGROUND_SHADER = love.graphics.newShader([[
    extern number bg_sine;
    extern number bg_mag;
    extern number wave_height;
    extern number sine_mul;
    extern vec2 texsize;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        number i = texture_coords.y * texsize.y;
        number bg_minus = ((bg_mag * (i / wave_height)) * 1.3);
        number wave_mag = max(0.0, bg_mag - bg_minus);
        vec2 coords = vec2(max(0.0, min(1.0, texture_coords.x + (sine_mul * sin((i / 8.0) + (bg_sine / 30.0)) * wave_mag) / texsize.x)), max(0.0, min(1.0, texture_coords.y + 0.0)));
        return Texel(texture, coords) * color;
    }
]])

function Menu:enter()
    -- Load menu music
    self.music = Music() -- "mod_menu", 1, 0.95

    Kristal.showBorder(0.5)

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.ui_cant_select = Assets.newSound("ui_cant_select")

    -- Initialize variables for the background animation
    self.fader_alpha = 1
    self.animation_sine = 0
    self.background_alpha = 0

    -- Assets required for the background animation
    self.background_image_wave = Assets.getTexture("kristal/title_bg_wave")
    self.background_image_animation = Assets.getFrames("kristal/title_bg_anim")

    -- Initialize variables for the menu
    self.stage = Stage()

    self.state = "MAINMENU"

    self.main_screen = MenuMain(self)
    self.credits = MenuCredits(self)
    self.mod_list = MenuModList(self)
    self.mod_create = MenuModCreate(self)
    self.mod_config = MenuModConfig(self)
    self.mod_error = MenuModError(self)
    self.file_select = MenuFileSelect(self)
    self.file_name_screen = MenuFileName(self)

    -- STATES: MODERROR, MAINMENU, MODSELECT, FILESELECT, FILENAME, DEFAULTNAME, OPTIONS, VOLUME, WINDOWSCALE, CONTROLS
    self.state = "NONE"
    self.state_manager = StateManager("NONE", self, true)
    self.state_manager:addState("MAINMENU", self.main_screen)
    self.state_manager:addState("CREDITS", self.credits)
    self.state_manager:addState("MODSELECT", self.mod_list)
    self.state_manager:addState("MODCREATE", self.mod_create)
    self.state_manager:addState("MODCONFIG", self.mod_config)
    self.state_manager:addState("MODERROR", self.mod_error)
    self.state_manager:addState("FILESELECT", self.file_select)
    self.state_manager:addState("FILENAME", self.file_name_screen)

    self.naming_screen = nil

    self.fader = Fader()
    self.fader.layer = 10000
    self.stage:addChild(self.fader)

    self.heart = Sprite("player/heart_menu")
    self.heart.visible = true
    self.heart:setOrigin(0.5, 0.5)
    self.heart:setScale(2, 2)
    self.heart:setColor(1, 0, 0)
    self.heart.layer = 100
    self.stage:addChild(self.heart)

    self.heart_outline = Sprite("player/heart_menu_outline", self.heart.width/2, self.heart.height/2)
    self.heart_outline.visible = false
    self.heart_outline:setOrigin(0.5, 0.5)
    self.heart:addChild(self.heart_outline)

    self.heart_target_x = 0
    self.heart_target_y = 0

    self.options_target_y = 0
    self.options_y = 0

    self.config_target_y = 0
    self.config_y = 0

    -- Assets required for the menu
    self.menu_font = Assets.getFont("main")
    self.small_font = Assets.getFont("main", 16)

    self.background_fade = 1

    self.logo = Assets.getTexture("kristal/title_logo_shadow")
    self.selected_option = 1

    self.control_menu = "keyboard"

    self.state_stack = {}

    self.rebinding = false
    self.rebinding_shift = false
    self.rebinding_ctrl = false
    self.rebinding_alt = false
    self.rebinding_cmd = false

    self.selecting_key = false
    self.selected_bind = 1

    self.noise_timer = 0

    self.has_target_saves = TARGET_MOD and Kristal.hasAnySaves(TARGET_MOD) or false
    self.target_mod_offset = TARGET_MOD and 1 or 0

    ---@type table<string, {id: string, name: string, options: {name: string, value: (fun(x:number, y:number):any)|nil, callback: fun()}[]}>
    self.options = {}
    self.options_pages = {}
    self.options_page_index = 1

    self:initializeOptions()

    -----@alias creditsline string|{[1]: string, [2]: number[]}
    -----@type {[1]: string, [2]: creditsline[], [3]: creditsline[]|nil}[]
    --self.credits = {
    --    {
    --        "Kristal Engine",
    --        {
    --            {"Lead Developers", COLORS.silver},
    --            "Nyakorita",
    --            "SylviBlossom",
    --            "vitellary",
    --            "",
    --            {"Assets", COLORS.silver},
    --            "Toby Fox",
    --            "Temmie Chang",
    --            "DELTARUNE team",
    --            "",
    --            "",
    --        },
    --        {
    --            {"GitHub Contributors", COLORS.silver},
    --            "Agent 7",
    --            "Archie-osu",
    --            "Dobby233Liu",
    --            "Luna",
    --            "prokube",
    --            "AcousticJamm",
    --            "Simbel",
    --            "Bor",
    --            "MrOinky",
    --            "",
    --        }
    --    },
    --    --[[{
    --        "Kristal Engine",
    --        {
    --            {"GitHub Contributors", COLORS.silver},
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            ""
    --        },
    --        {
    --            {"GitHub Contributors", COLORS.silver},
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --            "",
    --        }
    --    }]]
    --}
    --self.credits_page = 1

    --self.page_scroll_direction = "right"
    --self.page_scroll_timer = 0

    --self.create = {}

    self.mod_list:buildModList()

    self.ver_string = "v" .. tostring(Kristal.Version)
    local trimmed_commit = GitFinder:fetchTrimmedCommit()
    if trimmed_commit then
        self.ver_string = self.ver_string .. " (" .. trimmed_commit .. ")"
    end

    if not self.music:isPlaying() then
        self.music:play("mod_menu", 1, 0.95)
    end

    if #Kristal.Mods.failed_mods > 0 then
        self:setState("MODERROR")
    else
        self:setState("MAINMENU")
    end
end

function Menu:setState(state)
    self.state_manager:setState(state)
end

function Menu:onStateChange(old_state, new_state)
    --[[if old_state == "MODSELECT" then
        self.list.active = false
        self.list.visible = false
    --[[elseif old_state == "FILESELECT" then
        if new_state == "FILENAME" then
            self.files.active = false
            self.files.visible = false
        else
            self.files:remove()
            self.files = nil
        end]]
    --elseif old_state == "FILENAME" or old_state == "DEFAULTNAME" then
    if old_state == "DEFAULTNAME" then
        self.naming_screen:remove()
        self.heart.visible = true
    end
    --[[if new_state == "MAINMENU" then
        self.selected_mod_button = nil
        self.selected_mod = nil]]
    --[[if new_state == "MODSELECT" then
        self.list.active = true
        self.list.visible = true
    --[[elseif new_state == "FILESELECT" then
        if old_state == "FILENAME" then
            self.files.visible = true
            self.files.active = true
        else
            self.files = FileList(self, self.selected_mod)
            self.files.layer = 50
            self.stage:addChild(self.files)
        end]]
    --[[elseif new_state == "FILENAME" then
        local mod = self.selected_mod
        self.naming_screen = FileNamer(12, function(name)
            Kristal.loadMod(mod.id, self.file_select.selected_y, name)

            if mod.transition then
                self.naming_screen.name_preview.visible = false
                self.naming_screen.text:setText("")
            elseif self.naming_screen.do_fadeout then
                self.fader:fadeOut{speed = 0.5, color = {0, 0, 0}}
            else
                self.fader.fade_color = {0, 0, 0}
                self.fader.alpha = 1
            end
        end, nil, nil, mod.nameInput ~= "force" and Kristal.Config["defaultName"])
        self.naming_screen.cancel_callback = function()
            self:setState("FILESELECT")
        end
        self.naming_screen.do_fadeout = mod.whiteFade ~= false and not mod.transition
        self.naming_screen.layer = 50
        self.stage:addChild(self.naming_screen)
        self.heart.visible = false]]
    if new_state == "DEFAULTNAME" then
        local mod = self.selected_mod
        self.naming_screen = FileNamer({
            name = Kristal.Config["defaultName"],
            limit = 12,
            start_confirm = true,

            mod = mod,

            on_confirm = function(name)
                Kristal.Config["defaultName"] = name
                self:setState("OPTIONS")
            end,
            on_cancel = function()
                Kristal.Config["defaultName"] = ""
                self:setState("OPTIONS")
            end
        })
        self.naming_screen.layer = 50
        self.stage:addChild(self.naming_screen)
        self.heart.visible = false
    elseif new_state == "OPTIONS" then
        if old_state ~= "VOLUME" and old_state ~= "WINDOWSCALE" and old_state ~= "FPSOPTION" and old_state ~= "BORDER" and old_state ~= "DEFAULTNAME" then
            self.options_target_y = 0
            self.options_y = 0
        end
    elseif new_state == "CONTROLS" then
        self.options_target_y = 0
        self.options_y = 0
    end
    --[[elseif new_state == "CREATE" then
        if old_state ~= "CONFIG" then
            self.selected_option = 1
            self:onCreateEnter()
            self:setSubState("MENU")
        else
            self.selected_option = 4
        end]]
    --[[elseif new_state == "CONFIG" then
        self.selected_option = 1
        self:onConfigEnter()
        self:setSubState("MENU")
    end]]
end

function Menu:setSubState(state)
    local old_state = self.substate
    self.substate = state
    self:onSubStateChange(old_state, self.substate)
end

function Menu:pushState(new_state)
    table.insert(self.state_stack, {
        state = self.state,
        substate = self.substate,
        selected_option = self.selected_option,
        heart_target_x = self.heart_target_x,
        heart_target_y = self.heart_target_y,
        options_target_y = self.options_target_y,
        options_y = self.options_y,
    })
    if new_state then
        self:setState(new_state)
    end
end

function Menu:popState()
    local state = table.remove(self.state_stack)
    self:setState(state.state)
    self:setSubState(state.substate)
    self.selected_option = state.selected_option
    self.heart_target_x = state.heart_target_x
    self.heart_target_y = state.heart_target_y
    self.options_target_y = state.options_target_y
    self.options_y = state.options_y
end

function Menu:leave()
    self.music:remove()
    for _,v in pairs(self.mod_list.music) do
        v:remove()
    end
end

function Menu:drawMenuRectangle(x, y, width, height, color)
    love.graphics.push()
    -- Draw the transparent background
    Draw.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Make sure the line is a single pixel wide
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    -- Set the color
    Draw.setColor(color)
    -- Draw the rectangles
    love.graphics.rectangle("line", x,     y,     width + 1, height + 1)
    -- Increase the width and height by one instead of two to produce the broken effect
    love.graphics.rectangle("line", x - 1, y - 1, width + 2, height + 2)
    love.graphics.rectangle("line", x - 2, y - 2, width + 5, height + 5)
    -- Here too
    love.graphics.rectangle("line", x - 3, y - 3, width + 6, height + 6)
    love.graphics.pop()
end

function Menu:init()
    -- We'll draw the background on a canvas, then resize it 2x
    self.bg_canvas = love.graphics.newCanvas(320,240)
    -- No filtering
    self.bg_canvas:setFilter("nearest", "nearest")
end

function Menu:focus()
    if not TARGET_MOD and not self.mod_list.loading_mods then
        local mod_paths = love.filesystem.getDirectoryItems("mods")
        if not Utils.equal(mod_paths, self.mod_list.last_loaded) then
            self.mod_list:reloadMods()
            self.mod_list.last_loaded = mod_paths
        end
    end
end


--- Adds a page to the options menu.
---@param id   string # The id of the page, referred to when adding options.
---@param name string # The name of the page, displayed in the options menu.
function Menu:registerOptionsPage(id, name)
    if Utils.containsValue(self.options_pages, id) then
        return
    end

    table.insert(self.options_pages, id)

    self.options[id] = {
        id = id,
        name = name,
        options = {}
    }
end

--- Adds an option to the menu's options list.
---@param page     string|string[]             # The page (or pages) the option should be added to. Must be registered with `registerOptionsPage` first.
---@param name     string                      # The name of the option, displayed in the options list.
---@param value?   fun(x:number, y:number):any # A function which is called to get the value displayed for the option.
---@param callback fun()                       # A function called when the user selects this option.
function Menu:registerOption(page, name, value, callback)
    local pages = type(page) == "table" and page or {page}

    for _, page_id in ipairs(pages) do
        table.insert(self.options[page_id].options, {
            name = name,
            value = value,
            callback = callback
        })
    end
end

--- *(Called internally)*  
--- Convenience method to add a menu option based on a config option which is toggled on and off.
---@param page   string|string[]         # The page (or pages) the option should be added to. Must be registered with `registerOptionsPage` first.
---@param name   string                  # The name of the option, displayed in the options list.
---@param config string                  # The config option to toggle.
---@param callback? fun(toggled:boolean) # Additional callback for when the option is toggled.
function Menu:registerConfigOption(page, name, config, callback)
    self:registerOption(page, name, function()
        return Kristal.Config[config] and "ON" or "OFF"
    end, function()
        Kristal.Config[config] = not Kristal.Config[config]
        if callback then
            callback(Kristal.Config[config])
        end
    end)
end

function Menu:initializeOptions()
    self:registerOptionsPage("general", "GENERAL")
    self:registerOptionsPage("graphics", "GRAPHICS")
    self:registerOptionsPage("engine", "ENGINE")

    ---------------------
    -- General Options
    ---------------------

    self:registerOption("general", "Master Volume", function()
        return Utils.round(Kristal.getVolume() * 100) .. "%"
    end, function()
        self:setState("VOLUME")
        self.heart_target_x = 408
    end)

    local function enterControls(type)
        self:setState("CONTROLS")
        self.control_menu = type
        self.rebinding = false
        self.selecting_key = false
        self.heart_target_x = 152
        self.heart_target_y = 129 + 0 * 32
        self.selected_option = 1
    end
    self:registerOption("general", "Keyboard Controls", nil, function() enterControls("keyboard") end)
    self:registerOption("general", "Gamepad Controls", nil, function() enterControls("gamepad") end)

    self:registerConfigOption("general", "Auto-Run", "autoRun")

    ---------------------
    -- Graphics Options
    ---------------------

    self:registerConfigOption({"general", "graphics"}, "Fullscreen", "fullscreen", function(toggled)
        love.window.setFullscreen(toggled)
    end)

    self:registerOption({"general", "graphics"}, "Window Scale", function()
        return tostring(Kristal.Config["windowScale"]) .. "x"
    end, function()
        self:setState("WINDOWSCALE")
        self.heart_target_x = 408
    end)

    self:registerOption({"general", "graphics"}, "Border", function()
        return Kristal.getBorderName()
    end, function ()
        self:setState("BORDER")
        self.heart_target_x = 408
    end)

    self:registerConfigOption({"general", "graphics"}, "Simplify VFX", "simplifyVFX")

    self:registerOption("graphics", "Target FPS", function(x, y)
        if Kristal.Config["fps"] > 0 then
            return Kristal.Config["fps"]
        else
            Draw.setColor(0, 0, 0)
            Draw.draw(Assets.getTexture("kristal/menu_infinity"), x + 2, y + 11, 0, 2, 2)
            Draw.setColor(1, 1, 1)
            Draw.draw(Assets.getTexture("kristal/menu_infinity"), x, y + 9, 0, 2, 2)
        end
    end, function()
        self:setState("FPSOPTION")
        self.heart_target_x = 408
    end)

    self:registerConfigOption("graphics", "VSync", "vSync", function(toggled)
        love.window.setVSync(toggled and 1 or 0)
    end)
    self:registerConfigOption("graphics", "Frame Skip", "frameSkip")

    ---------------------
    -- Engine Options
    ---------------------

    self:registerConfigOption("engine", "Skip Intro", "skipIntro")
    self:registerConfigOption("engine", "Display FPS", "showFPS")

    self:registerOption("engine", "Default Name", function()
        return Kristal.Config["defaultName"]
    end, function()
        self:setState("DEFAULTNAME")
    end)
    self:registerConfigOption("engine", "Skip Name Entry", "skipNameEntry")

    self:registerConfigOption("engine", "Debug Hotkeys", "debug")
    self:registerConfigOption("engine", "Use System Mouse", "systemCursor", function() Kristal.updateCursor() end)
    self:registerConfigOption("engine", "Always Show Mouse", "alwaysShowCursor", function() Kristal.updateCursor() end)
end

function Menu:drawAnimStrip(sprite, subimg, x, y, alpha)
    Draw.setColor(1, 1, 1, alpha)

    local index = #sprite > 1 and ((math.floor(subimg) % (#sprite - 1)) + 1) or 1

    Draw.draw(sprite[index], math.floor(x), math.floor(y))
end

function Menu:update()
    if self.state == "MODSELECT" or TARGET_MOD then
        self.selected_mod = self.mod_list:getSelectedMod()
        self.selected_mod_button = self.mod_list:getSelectedButton()
    end
    local mod = self.selected_mod
    local mod_button = self.selected_mod_button

    -- Update fade between previews
    if mod and (mod.preview or self.mod_list.scripts[mod.id]) then
        local script = self.mod_list.scripts[mod.id]
        if script and script.hide_background ~= false then
            self.background_fade = math.max(0, self.background_fade - (DT / 0.5))
        else
            self.background_fade = math.min(1, self.background_fade + (DT / 0.5))
        end
        for k,v in pairs(self.mod_list.fades) do
            if k == mod.id and v < 1 then
                self.mod_list.fades[k] = math.min(1, v + (DT / 0.5))
            elseif k ~= mod.id and v > 0 then
                self.mod_list.fades[k] = math.max(0, v - (DT / 0.5))
            end
        end
    else
        self.background_fade = math.min(1, self.background_fade + (DT / 0.5))
        for k,v in pairs(self.mod_list.fades) do
            if v > 0 then
                self.mod_list.fades[k] = math.max(0, v - (DT / 0.5))
            end
        end
    end

    -- Update preview music fading
    if not TARGET_MOD then
        local fade_waiting = false
        for k,v in pairs(self.mod_list.music) do
            if v:isPlaying() and v.volume > (self.mod_list.music_options[k].volume * 0.1) then
                fade_waiting = true
                break
            end
        end

        if mod and self.mod_list.music[mod.id] then
            local mod_music = self.mod_list.music[mod.id]
            local options = self.mod_list.music_options[mod.id]

            if not mod_music:isPlaying() and not fade_waiting and self.music.volume == 0 then
                mod_music:setVolume(0)
                if options.sync then
                    mod_music:play()
                    mod_music:seek(self.music:tell())
                else
                    mod_music:resume()
                end
            end
            if mod_music:isPlaying() then
                mod_music:fade(options.volume, 0.5)
            end

            if self.music.volume > 0 then
                self.music:fade(0, 0.5)
            end
        else
            if not fade_waiting and self.music.volume < 1 then
                self.music:fade(1, 0.5)
            end
        end

        for k,v in pairs(self.mod_list.music) do
            if (not mod or k ~= mod.id) and v:isPlaying() then
                if self.mod_list.music_options[k].pause then
                    v:fade(0, 0.5, function(music) music:pause() end)
                else
                    v:fade(0, 0.5, function(music) music:stop() end)
                end
            end
        end
    end

    -- Update background animation and alpha
    self.animation_sine = self.animation_sine + (1 * DTMULT)

    if (self.background_alpha < 0.5) then
        self.background_alpha = self.background_alpha + (0.04 - (self.background_alpha / 14)) * DTMULT
    end

    if (self.background_alpha > 0.5) then
        self.background_alpha = 0.5
    end

    -- Update preview scripts
    for k,v in pairs(self.mod_list.scripts) do
        v.fade = self.mod_list.fades[k]
        v.selected = self.mod_list:getSelectedButton() == mod_button
        if v.update then
            local success, msg = pcall(v.update, v)
            if not success then
                Kristal.Console:warn("preview.lua error in "..Kristal.Mods.getMod(k).name..": "..msg)
                self.mod_list.scripts[k] = nil
            end
        end
    end

    -- Update the stage (mod menu)
    self.stage:update()

    -- Update the current state
    self.state_manager:update()

    -- Move the heart closer to the target
    --[[if self.state == "MODSELECT" then
        if mod_button then
            local lhx, lhy = mod_button:getHeartPos()
            local button_heart_x, button_heart_y = mod_button:getRelativePos(lhx, lhy, self.list)
            self.heart_target_x = self.list.x + button_heart_x
            self.heart_target_y = self.list.y + button_heart_y - (self.list.scroll_target - self.list.scroll)
        end]]
    --[[elseif self.state == "FILESELECT" then
        self.heart_target_x, self.heart_target_y = self.files:getHeartPos()]]
    if self.state == "VOLUME" then
        self.noise_timer = self.noise_timer + DTMULT
        if Input.down("left") then
            Kristal.setVolume(Kristal.getVolume() - ((2 * DTMULT) / 100))
            if self.noise_timer >= 3 then
                self.noise_timer = self.noise_timer - 3
                Assets.stopAndPlaySound("noise")
            end
        end
        if Input.down("right") then
            Kristal.setVolume(Kristal.getVolume() + ((2 * DTMULT) / 100))
            if self.noise_timer >= 3 then
                self.noise_timer = self.noise_timer - 3
                Assets.stopAndPlaySound("noise")
            end
        end
        if (not Input.down("right")) and (not Input.down("left")) then
            self.noise_timer = 3
        end
    end

    if self.heart.visible then
        if (math.abs((self.heart_target_x - self.heart.x)) <= 2) then
            self.heart.x = self.heart_target_x
        end
        if (math.abs((self.heart_target_y - self.heart.y)) <= 2)then
            self.heart.y = self.heart_target_y
        end
        self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * DTMULT
        self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * DTMULT
    end

    if (math.abs((self.options_target_y - self.options_y)) <= 2) then
        self.options_y = self.options_target_y
    end
    self.options_y = self.options_y + ((self.options_target_y - self.options_y) / 2) * DTMULT

    --[[if (math.abs((self.config_target_y - self.config_y)) <= 2) then
        self.config_y = self.config_target_y
    end
    self.config_y = self.config_y + ((self.config_target_y - self.config_y) / 2) * DTMULT]]

    --[[if self.page_scroll_timer > 0 then
        self.page_scroll_timer = Utils.approach(self.page_scroll_timer, 0, DT)
    end]]
end

function Menu:optionsShown()
    return self.state == "OPTIONS" or self.state == "VOLUME" or self.state == "WINDOWSCALE" or self.state == "FPSOPTION" or self.state == "BORDER"
end

function Menu:draw()
    -- Draw the menu background
    self:drawBackground()

    -- Draw the engine version
    self:drawVersion()

    -- Draw the current state
    love.graphics.push()
    self.state_manager:draw()
    love.graphics.pop()

    --[[if self.state == "MODERROR" then
        local failed_mods = Kristal.Mods.failed_mods or {}
        local plural = #failed_mods == 1 and "mod" or "mods"
        Draw.printShadow({{255, 255, 0}, tostring(#failed_mods), {255, 255, 255}, " " .. plural .. " failed to load!"}, -1, 96, 2, "center", 640)

        local moderrors = 0
        local liberrors = 0

        for k,v in pairs(failed_mods) do
            if v.file == "mod.json" then
                moderrors = moderrors + 1
            elseif v.file == "lib.json" then
                liberrors = liberrors + 1
            end
        end

        local y = 128

        if moderrors > 0 then
            Draw.printShadow({"The following mods have invalid ", {196, 196, 196}, "mod.json", {255, 255, 255}, " files:"}, -1, y, 2, "center", 640)

            y = y + 64

            for k,v in pairs(failed_mods) do
                if v.file == "mod.json" then
                    Draw.printShadow({{255, 127, 127}, v.path}, -1, y, 2, "center", 640)
                    y = y + 32
                end
            end
            y = y + 32
        end

        if liberrors > 0 then
            Draw.printShadow({"The following mods use invalid ", {196, 196, 196}, "lib.json", {255, 255, 255}, " files:"}, -1, y, 2, "center", 640)

            y = y + 64

            for k,v in pairs(failed_mods) do
                if v.file == "lib.json" then
                    Draw.printShadow({{255, 127, 127}, v.path}, -1, y, 2, "center", 640)
                    y = y + 32
                end
            end
        end

        Draw.printShadow("Got it", -1, 454 - 8, 2, "center", 640)]]

    --[[elseif self.state == "MAINMENU" then
        local logo_img = self.selected_mod and self.selected_mod.logo or self.logo

        Draw.draw(logo_img, SCREEN_WIDTH/2 - logo_img:getWidth()/2, 105 - logo_img:getHeight()/2)
        --Draw.draw(self.selected_mod and self.selected_mod.logo or self.logo, 160, 70)

        if TARGET_MOD then
            if self.has_target_saves then
                Draw.printShadow("Load game", 215, 219)
            else
                Draw.printShadow("Start game", 215, 219)
            end
            Draw.printShadow("Options", 215, 219 + 32)
            Draw.printShadow("Credits", 215, 219 + 64)
            Draw.printShadow("Quit", 215, 219 + 96)
        else
            Draw.printShadow("Play a mod", 215, 219)
            Draw.printShadow("Open mods folder", 215, 219 + 32)
            Draw.printShadow("Options", 215, 219 + 64)
            Draw.printShadow("Credits", 215, 219 + 96)
            Draw.printShadow("Quit", 215, 219 + 128)
        end]]
    if self:optionsShown() then
        local page = self.options_pages[self.options_page_index]
        local options = self.options[page].options

        local title = self.options[page].name
        local title_width = self.menu_font:getWidth(title)

        Draw.setColor(COLORS.silver)
        Draw.printShadow("( OPTIONS )", 0, 0, 2, "center", 640)

        Draw.setColor(1, 1, 1)
        Draw.printShadow(title, 0, 48, 2, "center", 640)

        if self.state == "OPTIONS" and #self.options_pages > 1 then
            love.graphics.setColor(COLORS.white)

            local l_offset, r_offset = 0, 0

            if self.page_scroll_timer > 0 then
                if self.page_scroll_direction == "left" then
                    l_offset = -4
                elseif self.page_scroll_direction == "right" then
                    r_offset = 4
                end
            end

            Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), 320 + (title_width / 2) + 8  + r_offset, 52, 0, 2, 2)
            Draw.draw(Assets.getTexture("kristal/menu_arrow_left"),  320 - (title_width / 2) - 26 + l_offset, 52, 0, 2, 2)
        end

        local menu_x = 185 - 14
        local menu_y = 110

        local width = 360
        local height = 32 * 10
        local total_height = 32 * #options

        Draw.pushScissor()
        Draw.scissor(menu_x, menu_y, width + 10, height + 10)

        menu_y = menu_y + self.options_y

        for i, option in ipairs(options) do
            local y = menu_y + 32 * (i - 1)

            Draw.printShadow(option.name, menu_x, y)

            local value_x = menu_x + (32 * 8)
            local value = option.value and option.value(value_x, y) or nil

            if value then
                Draw.printShadow(tostring(value), value_x, y)
            end
        end

        -- Draw the scrollbar background if the menu scrolls
        if total_height > height then
            Draw.setColor({0, 0, 0, 0.5})
            love.graphics.rectangle("fill", menu_x + width, 0, 4, menu_y + height - self.options_y)

            local scrollbar_height = (height / total_height) * height
            local scrollbar_y = (-self.options_y / (total_height - height)) * (height - scrollbar_height)

            Draw.popScissor()
            Draw.setColor(1, 1, 1, 1)
            love.graphics.rectangle("fill", menu_x + width, menu_y + scrollbar_y - self.options_y, 4, scrollbar_height)
        else
            Draw.popScissor()
        end

        Draw.printShadow("Back", 0, 454 - 8, 2, "center", 640)

    elseif self.state == "CONTROLS" then
        Draw.setColor(COLORS.silver)
        Draw.printShadow("( OPTIONS )", 0, 0, 2, "center", 640)

        Draw.setColor(1, 1, 1)
        Draw.printShadow(""..self.control_menu:upper().." CONTROLS", 0, 48, 2, "center", 640)

        local menu_x = 185 - 14
        local menu_y = 110

        local width = 460
        local height = 32 * 10
        local total_height = 32 * (#Input.order + 4) -- should be the amount of options there are

        Draw.pushScissor()
        Draw.scissor(menu_x, menu_y, width + 10, height + 10)

        menu_y = menu_y + self.options_y

        local y_offset = 0

        for index, name in ipairs(Input.order) do
            Draw.printShadow(name:gsub("_", " "):upper(),  menu_x, menu_y + (32 * y_offset))

            self:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
            y_offset = y_offset + 1
        end

        local bind_list = self.control_menu == "gamepad" and Input.gamepad_bindings or Input.key_bindings
        for name, value in pairs(bind_list) do
            if not Utils.containsValue(Input.order, name) then
                Draw.printShadow(name:gsub("_", " "):upper(),  menu_x, menu_y + (32 * y_offset))

                self:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
                --Draw.printShadow(Utils.titleCase(value[1]),    menu_x + (8 * 32), menu_y + (32 * y_offset))
                y_offset = y_offset + 1
            end
        end

        y_offset = y_offset + 1

        if self.control_menu == "gamepad" then
            Draw.printShadow("Configure Deadzone",  menu_x, menu_y + (32 * y_offset))
            y_offset = y_offset + 1
        end

        Draw.printShadow("Reset to defaults", menu_x, menu_y + (32 * y_offset))
        Draw.printShadow("Back", menu_x, menu_y + (32 * (y_offset + 1)))

        -- Draw the scrollbar background (lighter than the others since it's against black)
        Draw.setColor({1, 1, 1, 0.5})
        love.graphics.rectangle("fill", menu_x + width, 0, 4, menu_y + height - self.options_y)

        local scrollbar_height = (height / total_height) * height
        local scrollbar_y = (-self.options_y / (total_height - height)) * (height - scrollbar_height)

        Draw.popScissor()
        Draw.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", menu_x + width, menu_y + scrollbar_y - self.options_y, 4, scrollbar_height)

        Draw.setColor(COLORS.silver)
        Draw.printShadow("CTRL+ALT+SHIFT+T to reset binds.", 0, 480 - 32, 2, "center", 640)
        Draw.setColor(1, 1, 1)
    elseif self.state == "DEADZONE" then
        Draw.setColor(COLORS.silver)
        Draw.printShadow("( OPTIONS )", 0, 0, 2, "center", 640)

        Draw.setColor(1, 1, 1)
        Draw.printShadow("DEADZONE CONFIG", 0, 48, 2, "center", 640)

        love.graphics.setLineStyle("rough")
        love.graphics.setLineWidth(2)

        local function drawStick(type, x, y, radius)
            local stick_x, stick_y, deadzone

            if type == "left" then
                stick_x, stick_y = Input.gamepad_left_x, Input.gamepad_left_y
                deadzone = Kristal.Config["leftStickDeadzone"]
            elseif type == "right" then
                stick_x, stick_y = Input.gamepad_right_x, Input.gamepad_right_y
                deadzone = Kristal.Config["rightStickDeadzone"]
            end

            Draw.setColor(0, 0, 0)
            love.graphics.circle("fill", x + 2, y + 4, radius + 1)
            Draw.setColor(0.33, 0.33, 0.33)
            love.graphics.circle("fill", x, y, radius)
            Draw.setColor(0.16, 0.16, 0.16)
            love.graphics.circle("fill", x, y, radius * deadzone)
            Draw.setColor(1, 1, 1)
            love.graphics.circle("line", x, y, radius)

            local magnitude = math.sqrt(stick_x * stick_x + stick_y * stick_y)
            if magnitude > 1 then
                stick_x = stick_x / magnitude
                stick_y = stick_y / magnitude
                magnitude = 1
            end
            if magnitude <= deadzone then
                Draw.setColor(1, 0, 0)
            else
                Draw.setColor(0, 1, 0)
            end

            local cx, cy = x + (stick_x * (radius - 8)), y + (stick_y * (radius - 8))
            love.graphics.circle("line", cx, cy, 8)
            love.graphics.circle("fill", cx, cy, 2)
        end

        drawStick("left", 200, 200, 80)
        drawStick("right", 440, 200, 80)

        local function drawSlider(index, type, x, y)
            if self.selected_option == index and self.substate == "SLIDER" then
                Draw.setColor(0, 1, 1)
            else
                Draw.setColor(1, 1, 1)
            end

            Draw.printShadow("<", x, y)
            Draw.printShadow(">", x + 80, y)

            local deadzone = Kristal.Config[type .. "StickDeadzone"]
            deadzone = math.floor(deadzone * 100)

            Draw.printShadow(deadzone .. "%", x + 16, y, 2, "center", 64)
        end

        Draw.setColor(1, 1, 1)

        drawSlider(1, "left", 152, 296)
        drawSlider(2, "right", 392, 296)

        Draw.printShadow("Back", 286, 364)
    --[[elseif self.state == "MODSELECT" then
        -- Draw introduction text if no mods exist

        if self.loading_mods then
            Draw.printShadow("Loading mods...", 0, 115 - 8, {1, 1, 1, 1}, "center", 640)
        else
            if #self.list.mods == 0 then
                self.heart_target_x = -8
                self.heart_target_y = -8
                self.list.active = false
                self.list.visible = false

                self.intro_text = {{1, 1, 1, 1}, "Welcome to Kristal,\nthe DELTARUNE fangame engine!\n\nAdd mods to the ", {1, 1, 0, 1}, "mods folder", {1, 1, 1, 1}, "\nto continue."}
                Draw.printShadow(self.intro_text, 0, 160 - 8, {1, 1, 1, 1}, "center", 640)

                local string_part_1 = "Press "
                local string_part_2 = Input.getText("cancel")
                local string_part_3 = " to return to the main menu."

                local part_2_width = self.menu_font:getWidth(string_part_2)
                if Input.usingGamepad() then
                    part_2_width = 32
                end

                local total_width = self.menu_font:getWidth(string_part_1) + part_2_width + self.menu_font:getWidth(string_part_3)

                -- Draw each part, using total_width to center it
                Draw.printShadow(string_part_1, 320 - (total_width / 2), 480 - 32, COLORS.silver)

                local part_2_xpos = 320 - (total_width / 2) + self.menu_font:getWidth(string_part_1)
                if Input.usingGamepad() then
                    Draw.setColor(0, 0, 0, 1)
                    Draw.draw(Input.getText("cancel", nil, true), part_2_xpos + 4 + 2, 480 - 32 + 4, 0, 2, 2)
                    Draw.setColor(1, 1, 1, 1)
                    Draw.draw(Input.getText("cancel", nil, true), part_2_xpos + 4, 480 - 32 + 2, 0, 2, 2)
                else
                    Draw.printShadow(string_part_2, part_2_xpos, 480 - 32, COLORS.silver)
                end
                Draw.printShadow(string_part_3, 320 - (total_width / 2) + self.menu_font:getWidth(string_part_1) + part_2_width, 480 - 32, COLORS.silver)
            else
                -- Draw some menu text
                Draw.printShadow("Choose your world.", 80, 34 - 8, {1, 1, 1, 1})

                local control_menu_width = 0
                local control_cancel_width = 0
                if Input.usingGamepad() then
                    control_menu_width = 32
                    control_cancel_width = 32
                else
                    control_menu_width = self.menu_font:getWidth(Input.getText("menu"))
                    control_cancel_width = self.menu_font:getWidth(Input.getText("cancel"))
                end

                local x_pos = self.menu_font:getWidth(" Back")
                Draw.printShadow(" Back", 580 + (16 * 3) - x_pos, 454 - 8, {1, 1, 1, 1})
                x_pos = x_pos + control_cancel_width
                if Input.usingGamepad() then
                    Draw.setColor(0, 0, 0, 1)
                    Draw.draw(Input.getText("cancel", nil, true), 580 + (16 * 3) - x_pos + 2, 454 - 8 + 4, 0, 2, 2)
                    Draw.setColor(1, 1, 1, 1)
                    Draw.draw(Input.getText("cancel", nil, true), 580 + (16 * 3) - x_pos, 454 - 8 + 2, 0, 2, 2)
                else
                    Draw.printShadow(Input.getText("cancel"), 580 + (16 * 3) - x_pos, 454 - 8, {1, 1, 1, 1})
                end
                local fav = self.heart_outline.visible and " Unfavorite  " or " Favorite  "
                x_pos = x_pos + self.menu_font:getWidth(fav)
                Draw.printShadow(fav, 580 + (16 * 3) - x_pos, 454 - 8, {1, 1, 1, 1})
                x_pos = x_pos + control_menu_width
                if Input.usingGamepad() then
                    Draw.setColor(0, 0, 0, 1)
                    Draw.draw(Input.getText("menu", nil, true), 580 + (16 * 3) - x_pos + 2, 454 - 8 + 4, 0, 2, 2)
                    Draw.setColor(1, 1, 1, 1)
                    Draw.draw(Input.getText("menu", nil, true), 580 + (16 * 3) - x_pos, 454 - 8 + 2, 0, 2, 2)
                else
                    Draw.printShadow(Input.getText("menu"), 580 + (16 * 3) - x_pos, 454 - 8, {1, 1, 1, 1})
                end
                --local control_text = Input.getText("menu").." "..(self.heart_outline.visible and "Unfavorite" or "Favorite  ").."  "..Input.getText("cancel").." Back"
                --Draw.printShadow(control_text, 580 + (16 * 3) - self.menu_font:getWidth(control_text), 454 - 8, {1, 1, 1, 1})
            end
        end]]
    --[[elseif self.state == "FILESELECT" or self.state == "FILENAME" then
        local mod_name = string.upper(self.selected_mod.name or self.selected_mod.id)
        Draw.printShadow(mod_name, 16, 8, {1, 1, 1, 1})]]
    --[[elseif self.state == "CREDITS" then
        local page = self.credits[self.credits_page]

        local title = page[1]:upper()
        local title_width = self.menu_font:getWidth(title)

        Draw.setColor(COLORS.silver)
        Draw.printShadow("( CREDITS )", 0, 0, 2, "center", 640)

        Draw.setColor(1, 1, 1)
        Draw.printShadow(title, 0, 48, 2, "center", 640)

        if #self.credits > 1 then
            local l_offset, r_offset = 0, 0

            if self.page_scroll_timer > 0 then
                if self.page_scroll_direction == "left" then
                    l_offset = -4
                elseif self.page_scroll_direction == "right" then
                    r_offset = 4
                end
            end

            if self.credits_page >= #self.credits then
                love.graphics.setColor(COLORS.silver)
            end
            Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), 320 + (title_width / 2) + 8 + r_offset, 52, 0, 2, 2)
            love.graphics.setColor(COLORS.white)
            if self.credits_page <= 1 then
                love.graphics.setColor(COLORS.silver)
            end
            Draw.draw(Assets.getTexture("kristal/menu_arrow_left"), 320 - (title_width / 2) - 26 + l_offset, 52, 0, 2, 2)
            love.graphics.setColor(COLORS.white)
        end

        local left_column = page[2]
        local right_column = page[3] or {}

        for index, value in ipairs(left_column) do
            local color = {1, 1, 1, 1}
            local offset = 0
            if type(value) == "table" then
                color = value[2]
                value = value[1]
            else
                offset = offset + 32
            end
            Draw.setColor(color)
            Draw.printShadow(value, 32 + offset, 64 + (32 * index))
        end
        for index, value in ipairs(right_column) do
            local color = {1, 1, 1, 1}
            local offset = 0
            if type(value) == "table" then
                color = value[2]
                value = value[1]
            else
                offset = offset - 32
            end
            Draw.setColor(color)
            Draw.printShadow(value, 0, 64 + (32 * index), 2, "right", 640 - 32 + offset)
        end

        Draw.setColor(1, 1, 1)
        Draw.printShadow("Back", 0, 454 - 8, 2, "center", 640)]]
    --[[elseif self.state == "CREATE" then
        self:drawCreate()]]
    --[[elseif self.state == "CONFIG" then
        self:drawConfig()]]
    elseif self.state == "DEFAULTNAME" then
        -- nothing
    else
        --Draw.printShadow("Nothing here for now!", 0, 240 - 8 - 16, {1, 1, 1, 1}, "center", 640)
        --Draw.printShadow("(...how'd you manage that?)", 0, 240 - 8 + 16, COLORS.silver, "center", 640)
    end

    -- Draw mod preview overlays
    for modid,script in pairs(self.mod_list.scripts) do
        if script.drawOverlay then
            love.graphics.push()
            local success, msg = pcall(script.drawOverlay, script)
            if not success then
                Kristal.Console:warn("preview.lua error in "..Kristal.Mods.getMod(modid).name..": "..msg)
                self.mod_list.scripts[modid] = nil
            end
            love.graphics.pop()
        end
    end

    self.stage:draw()

    -- Draw the screen fade
    Draw.setColor(0, 0, 0, self.fader_alpha)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    -- Change the fade opacity for the next frame
    self.fader_alpha = math.max(0,self.fader_alpha - (0.08 * DTMULT))

    -- Reset the draw color
    Draw.setColor(1, 1, 1, 1)
end

function Menu:drawVersion()
    local ver_y = SCREEN_HEIGHT - self.small_font:getHeight()

    if not TARGET_MOD then

        local ver_string = self.ver_string
        if self.state == "MAINMENU" and Kristal.Version.major == 0 then
            ver_string = ver_string .. " (Unstable)"
        end

        love.graphics.setFont(self.small_font)
        Draw.setColor(1, 1, 1, 0.5)
        love.graphics.print(ver_string, 4, ver_y)

        if self.mod_list:getSelectedMod() then
            local compatible, mod_version = self.mod_list:checkCompatibility()
            if not compatible then
                Draw.setColor(1, 0.5, 0.5, 0.75)
                local op = "/"
                if Kristal.Version < mod_version then
                    op = "<"
                elseif Kristal.Version > mod_version then
                    op = ">"
                end
                love.graphics.print(" "..op.." v"..tostring(mod_version), 4 + self.small_font:getWidth(ver_string), ver_y)
            end
        end
    else
        local full_ver = "Kristal: "..self.ver_string

        if self.selected_mod.version then
            ver_y = ver_y - self.small_font:getHeight()
            full_ver = self.selected_mod.name..": "..self.selected_mod.version.."\n"..full_ver
        end

        love.graphics.setFont(self.small_font)
        Draw.setColor(1, 1, 1, 0.5)
        love.graphics.print(full_ver, 4, ver_y)
    end

    Draw.setColor(1, 1, 1)
    love.graphics.setFont(self.menu_font)
end

function Menu:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
    local x_offset = 0
    if self.selected_option == (y_offset + 1) then
        for i, v in ipairs(self:getBoundKeys(name)) do
            local drawstr = v:upper()
            if Utils.startsWith(v, "gamepad:") then
                drawstr = "     "
            end
            if i < #self:getBoundKeys(name) then
                drawstr = drawstr .. ", "
            end
            if i < self.selected_bind then
                x_offset = x_offset - self.menu_font:getWidth(drawstr) - 8
            end
        end
    end
    Draw.pushScissor()
    Draw.scissorPoints(380, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    for i, v in ipairs(self:getBoundKeys(name)) do
        local drawstr = v:upper()
        local btn = nil
        if Utils.startsWith(v, "gamepad:") then
            drawstr = "     "
            btn = Input.getButtonTexture(v)
        end
        local color = {1, 1, 1, 1}
        if self.selecting_key or self.rebinding then
            if self.selected_option == (y_offset + 1) then
                color = {0.5, 0.5, 0.5, 1}
            end
        end
        if (self.selected_option == (y_offset + 1)) and (i == self.selected_bind) then
            color = {1, 1, 1, 1}
            if self.rebinding then
                color = {0, 1, 1, 1}

                if self.rebinding_shift or self.rebinding_ctrl or self.rebinding_alt or self.rebinding_cmd then
                    drawstr = ""

                    if self.rebinding_cmd   then drawstr = "CMD+"  ..drawstr end
                    if self.rebinding_shift then drawstr = "SHIFT+"..drawstr end
                    if self.rebinding_alt   then drawstr = "ALT+"  ..drawstr end
                    if self.rebinding_ctrl  then drawstr = "CTRL+" ..drawstr end
                end
            end
        end
        if i < #self:getBoundKeys(name) then
            drawstr = drawstr .. ", "
        end
        Draw.setColor(color)
        Draw.printShadow(drawstr, menu_x + (8 * 32) + x_offset, menu_y + (32 * y_offset))
        if btn then
            Draw.setColor(0, 0, 0, 1)
            Draw.draw(btn, menu_x + (8 * 32) + x_offset + 2, menu_y + (32 * y_offset) + 4, 0, 2, 2)
            Draw.setColor(1, 1, 1, 1)
            Draw.draw(btn, menu_x + (8 * 32) + x_offset, menu_y + (32 * y_offset) + 2, 0, 2, 2)
        end
        x_offset = x_offset + self.menu_font:getWidth(drawstr) + 8
        Draw.setColor(1, 1, 1)
    end
    Draw.popScissor()
end

function Menu:onKeyPressed(key, is_repeat)
    if MOD_LOADING then return end

    if self.state ~= "CONTROLS" then
        if not Input.shouldProcess(key, true) then
            return
        end
    end

    --[[if self.state == "MAINMENU" then
        if Input.isConfirm(key) then
            self.ui_select:stop()
            self.ui_select:play()
            if self.selected_option == 1 then
                if not TARGET_MOD then
                    self:setState("MODSELECT")
                elseif self.has_target_saves then
                    self:setState("FILESELECT")
                else
                    Kristal.loadMod(TARGET_MOD, 1)
                end
            elseif self.selected_option == 2 and not TARGET_MOD then
                love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/mods")
            elseif self.selected_option == 3 - self.target_mod_offset then
                self.heart_target_x = 152
                self.heart_target_y = 129
                self.selected_option = 1
                self:setState("OPTIONS")
            elseif self.selected_option == 4 - self.target_mod_offset then
                self.heart_target_x = 320 - 32 - 16 + 1
                self.heart_target_y = 480 - 16 + 1
                self:setState("CREDITS")
            elseif self.selected_option == 5 - self.target_mod_offset then
                love.event.quit()
            end
            return
        end
        local old = self.selected_option
        if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1 end
        if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1 end
        if Input.is("left" , key) and not Input.usingGamepad() then self.selected_option = self.selected_option - 1 end
        if Input.is("right", key) and not Input.usingGamepad() then self.selected_option = self.selected_option + 1 end
        if self.selected_option > 5 - self.target_mod_offset then self.selected_option = is_repeat and (5 - self.target_mod_offset) or 1                            end
        if self.selected_option < 1                          then self.selected_option = is_repeat and 1                            or (5 - self.target_mod_offset) end

        if old ~= self.selected_option then
            self.ui_move:stop()
            self.ui_move:play()
        end

        self.heart_target_x = 196
        self.heart_target_y = 238 + (self.selected_option - 1) * 32]]
    if self.state == "OPTIONS" then
        if Input.isCancel(key) then
            self:setState("MAINMENU")
            self.ui_move:stop()
            self.ui_move:play()
            self.heart_target_x = 196
            self.selected_option = 3 - self.target_mod_offset
            self.heart_target_y = 238 + (2 - self.target_mod_offset) * 32
            Kristal.saveConfig()
            return
        end

        local move_noise = false

        local page_dir = "right"
        local old_page = self.options_page_index
        if Input.is("left" , key) then
            self.options_page_index = self.options_page_index - 1
            page_dir = "left"
        end
        if Input.is("right", key) then
            self.options_page_index = self.options_page_index + 1
            page_dir = "right"
        end
        self.options_page_index = (self.options_page_index - 1) % #self.options_pages + 1

        if self.options_page_index ~= old_page then
            move_noise = true
            self.selected_option = 1
            self.options_target_y = 0
            self.options_y = 0
            self.page_scroll_direction = page_dir
            self.page_scroll_timer = 0.1
        end

        local page = self.options_pages[self.options_page_index]
        local options = self.options[page].options
        local max_option = #options + 1

        local old_option = self.selected_option
        if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1  end
        if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1  end
        if self.selected_option > max_option then self.selected_option = is_repeat and max_option or 1          end
        if self.selected_option < 1          then self.selected_option = is_repeat and 1          or max_option end

        if old_option ~= self.selected_option then
            move_noise = true
        end

        if self.selected_option < max_option then
            local y_off = (self.selected_option - 1) * 32

            if y_off + self.options_target_y < 0 then
                self.options_target_y = self.options_target_y + (0 - (y_off + self.options_target_y))
            end

            if y_off + self.options_target_y > (9 * 32) then
                self.options_target_y = self.options_target_y + ((9 * 32) - (y_off + self.options_target_y))
            end

            self.heart_target_x = 152
            self.heart_target_y = 129 + y_off + self.options_target_y
        else
            -- "Back" button
            self.heart_target_x = 320 - 32 - 16 + 1
            self.heart_target_y = 480 - 16 + 1
        end

        if move_noise then
            self.ui_move:stop()
            self.ui_move:play()
        end

        if Input.isConfirm(key) then
            self.ui_select:stop()
            self.ui_select:play()

            if self.selected_option == max_option then
                -- "Back" button
                self:setState("MAINMENU")
                self.heart_target_x = 196
                self.selected_option = 3
                self.heart_target_y = 238 + (2 * 32)
                Kristal.saveConfig()
            else
                options[self.selected_option].callback()
            end
        end
    elseif self.state == "VOLUME" then
        if Input.isCancel(key) or Input.isConfirm(key) then
            Kristal.setVolume(Utils.round(Kristal.getVolume() * 100) / 100)
            self:setState("OPTIONS")
            self.ui_select:stop()
            self.ui_select:play()
            self.heart_target_x = 152
            self.heart_target_y = (129 + (self.selected_option - 1) * 32) + self.options_target_y
        end
    elseif self.state == "BORDER" then
        if Input.isCancel(key) or Input.isConfirm(key) then
            self:setState("OPTIONS")
            self.ui_select:stop()
            self.ui_select:play()
            self.heart_target_x = 152
            self.heart_target_y = (129 + (self.selected_option - 1) * 32) + self.options_target_y
        end
        local border_index = -1
        for current_index, border in ipairs(BORDER_TYPES) do
            if border[1] == Kristal.Config["borders"] then
                border_index = current_index
            end
        end
        if border_index == -1 then
            border_index = 1
        end
        local old_index = border_index
        if Input.is("left", key) then
            border_index = math.max(border_index - 1, 1)
        end
        if Input.is("right", key) then
            border_index = math.min(border_index + 1, #BORDER_TYPES)
        end
        if old_index ~= border_index then
            self.ui_move:stop()
            self.ui_move:play()
            Kristal.Config["borders"] = BORDER_TYPES[border_index][1]
            if BORDER_TYPES[border_index][1] == "off" then
                Kristal.resetWindow()
            elseif BORDER_TYPES[old_index][1] == "off" then
                Kristal.resetWindow()
            end
        end
    elseif self.state == "FPSOPTION" then
        if Input.isCancel(key) or Input.isConfirm(key) then
            FRAMERATE = Kristal.Config["fps"]
            self:setState("OPTIONS")
            self.ui_select:stop()
            self.ui_select:play()
            self.heart_target_x = 152
            self.heart_target_y = (129 + (self.selected_option - 1) * 32) + self.options_target_y
        end
        if Input.is("left", key) then
            if FRAMERATE == 0 or FRAMERATE > 240 then
                FRAMERATE = 240
            elseif FRAMERATE > 144 then
                FRAMERATE = 144
            elseif FRAMERATE > 120 then
                FRAMERATE = 120
            elseif FRAMERATE > 60 then
                FRAMERATE = 60
            elseif FRAMERATE > 30 then
                FRAMERATE = 30
            else
                FRAMERATE = 0
            end
            self.ui_move:stop()
            self.ui_move:play()
            Kristal.Config["fps"] = FRAMERATE
        elseif Input.is("right", key) then
            if FRAMERATE < 30 then
                FRAMERATE = 30
            elseif FRAMERATE < 60 then
                FRAMERATE = 60
            elseif FRAMERATE < 120 then
                FRAMERATE = 120
            elseif FRAMERATE < 144 then
                FRAMERATE = 144
            elseif FRAMERATE < 240 then
                FRAMERATE = 240
            else
                FRAMERATE = 0
            end
            self.ui_move:stop()
            self.ui_move:play()
            Kristal.Config["fps"] = FRAMERATE
        end
    elseif self.state == "WINDOWSCALE" then
        if Input.isCancel(key) or Input.isConfirm(key) then
            self:setState("OPTIONS")
            self.ui_select:stop()
            self.ui_select:play()
            self.heart_target_x = 152
            self.heart_target_y = (129 + (self.selected_option - 1) * 32) + self.options_target_y
        end
        local scale = Kristal.Config["windowScale"]
        if Input.is("right", key) then
            if scale < 1 then
                scale = scale * 2
            else
                scale = scale + 1
            end
        elseif Input.is("left", key) then
            if scale > 0.125 then
                if scale <= 1 then
                    scale = scale / 2
                else
                    scale = scale - 1
                end
            else
                Kristal.Config["windowScale"] = 1
                self.ui_move:stop()
                self.ui_move:play()
                love.event.quit()
                return
            end
        end
        if Kristal.Config["windowScale"] ~= scale then
            Kristal.Config["fullscreen"] = false
            Kristal.Config["windowScale"] = scale
            self.ui_move:stop()
            self.ui_move:play()
            Kristal.resetWindow()
        end
    --[[elseif self.state == "MODSELECT" then
        if key == "f5" then
            self.ui_select:stop()
            self.ui_select:play()
            self:reloadMods()
        end

        if Input.isCancel(key) then
            self:setState("MAINMENU")
            self.ui_move:stop()
            self.ui_move:play()
            self.heart_target_x = 196
            self.heart_target_y = 238
        elseif #self.list.mods > 0 then
            if Input.isConfirm(key) then
                if self.list:isOnCreate() then
                    self.ui_select:stop()
                    self.ui_select:play()
                    self.heart_target_x = 64 - 19
                    self.heart_target_y = 128 + 19
                    self:setState("CREATE")
                elseif self.selected_mod then
                    self.ui_select:stop()
                    self.ui_select:play()
                    if self.selected_mod["useSaves"] or (self.selected_mod["useSaves"] == nil and not self.selected_mod["encounter"]) then
                        self:setState("FILESELECT")
                    else
                        Kristal.loadMod(self.selected_mod.id)
                    end
                end
                return
            elseif Input.isMenu(key) then
                if self.selected_mod then
                    self.ui_select:stop()
                    self.ui_select:play()

                    local is_favorited = Utils.containsValue(Kristal.Config["favorites"], self.selected_mod.id)
                    if is_favorited then
                        Utils.removeFromTable(Kristal.Config["favorites"], self.selected_mod.id)
                    else
                        table.insert(Kristal.Config["favorites"], self.selected_mod.id)
                    end

                    Kristal.saveConfig()
                    self:rebuildMods()
                end
            end

            if Input.is("up", key) then self.list:selectUp(is_repeat) end
            if Input.is("down", key) then self.list:selectDown(is_repeat) end
            if not Input.isGamepad(key) then
                if Input.is("left", key) and not is_repeat then self.list:pageUp(is_repeat) end
                if Input.is("right", key) and not is_repeat then self.list:pageDown(is_repeat) end
            end
        end]]
    --[[elseif self.state == "FILESELECT" then
        if not is_repeat then
            self.files:onKeyPressed(key)
        end]]
    --[[elseif self.state == "FILENAME" or self.state == "DEFAULTNAME" then
        -- this needs to be here apparently]]
        -- not anymore
    elseif self.state == "DEFAULTNAME" then
        -- wait actually kinda
    --[[elseif self.state == "CREDITS" then
        if Input.isCancel(key) or Input.isConfirm(key) then
            self.credits_page = 1
            self:setState("MAINMENU")
            if Input.isCancel(key) then
                self.ui_move:stop()
                self.ui_move:play()
            else
                self.ui_select:stop()
                self.ui_select:play()
            end
            self.heart_target_x = 196
            self.selected_option = 4 - self.target_mod_offset
            self.heart_target_y = 238 + (3 - self.target_mod_offset) * 32
        end
        local page_dir = "right"
        local page_now = self.credits_page
        if Input.is("left", key) then
            page_now = page_now - 1
            page_dir = "left"
        end
        if Input.is("right", key) then
            page_now = page_now + 1
            page_dir = "right"
        end
        page_now = Utils.clamp(page_now, 1, #self.credits)
        if page_now ~= self.credits_page then
            self.credits_page = page_now
            self.ui_move:stop()
            self.ui_move:play()
            self.page_scroll_direction = page_dir
            self.page_scroll_timer = 0.1
        end]]
    elseif self.state == "CONTROLS" then
        if (not self.rebinding) and (not self.selecting_key) then
            local bind_list = self.control_menu == "gamepad" and Input.gamepad_bindings or Input.key_bindings
            local option_count = Utils.tableLength(bind_list) + 2
            if self.control_menu == "gamepad" then
                option_count = option_count + 1
            end

            local old = self.selected_option
            if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1 end
            if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1 end
            if Input.is("left" , key) and not Input.usingGamepad() then self.selected_option = self.selected_option - 1 end
            if Input.is("right", key) and not Input.usingGamepad() then self.selected_option = self.selected_option + 1 end
            if self.selected_option < 1            then self.selected_option = is_repeat and 1 or option_count end
            if self.selected_option > option_count then self.selected_option = is_repeat and option_count or 1 end

            if old ~= self.selected_option then
                self.ui_move:stop()
                self.ui_move:play()
            end

            local y_off = (self.selected_option - 1) * 32
            if self.selected_option > (Utils.tableLength(bind_list)) then
                y_off = y_off + 32
            end

            if y_off + self.options_target_y < 0 then
                self.options_target_y = self.options_target_y + (0 - (y_off + self.options_target_y))
            end

            if y_off + self.options_target_y > (9 * 32) then
                self.options_target_y = self.options_target_y + ((9 * 32) - (y_off + self.options_target_y))
            end

            self.heart_target_x = 152
            self.heart_target_y = 129 + y_off + self.options_target_y

            if Input.isCancel(key) then
                self:setState("OPTIONS")
                self.selected_option = self.control_menu == "gamepad" and 3 or 2
                self.ui_select:stop()
                self.ui_select:play()
                Input.saveBinds()
                self.heart_target_x = 152
                self.heart_target_y = 129 + (self.selected_option - 1) * 32
            elseif Input.isConfirm(key) then
                self.rebinding = false
                self.selecting_key = false
                 -- Reset to Defaults
                if (self.selected_option == option_count - 1) then
                    Input.resetBinds(self.control_menu == "gamepad")
                    self.ui_select:stop()
                    self.ui_select:play()
                    self.selected_option = option_count - 1
                    self.heart_target_y = (129 + (self.selected_option) * 32) + self.options_target_y
                -- Back
                elseif (self.selected_option == option_count) then
                    self:setState("OPTIONS")
                    self.selected_option = 2
                    self.ui_select:stop()
                    self.ui_select:play()
                    Input.saveBinds()
                    self.heart_target_x = 152
                    self.heart_target_y = 129 + 1 * 32
                -- (Gamepad) Configure Deadzone
                elseif self.control_menu == "gamepad" and self.selected_option == option_count - 2 then
                    self:pushState("DEADZONE")
                    self:setSubState("SELECT")
                    self.selected_option = 1
                    self.ui_select:stop()
                    self.ui_select:play()
                    self.heart_target_x = 152 - 18
                    self.heart_target_y = 296 + 16
                else
                    self.rebinding = false
                    self.selecting_key = true
                    self.heart_target_x = 408
                    self.selected_bind = 1
                    self.ui_select:stop()
                    self.ui_select:play()
                end
            end
        elseif self.selecting_key then
            local table_key = Input.orderedNumberToKey(self.selected_option)

            local old = self.selected_bind
            if Input.is("left" , key) then self.selected_bind = self.selected_bind - 1 end
            if Input.is("right", key) then self.selected_bind = self.selected_bind + 1 end
            self.selected_bind = math.max(1, math.min(#self:getBoundKeys(table_key), self.selected_bind))

            if old ~= self.selected_bind then
                self.ui_move:stop()
                self.ui_move:play()
            end

            if Input.isConfirm(key) then
                self.rebinding = true
                self.selecting_key = false
                self.heart_target_x = 408
                self.ui_select:stop()
                self.ui_select:play()
            end
            if Input.isCancel(key) then
                self.rebinding = false
                self.selecting_key = false
                self.selected_bind = 1
                self.heart_target_x = 152
                self.ui_select:stop()
                self.ui_select:play()
            end
        elseif self.rebinding then
            Input.clear(key)

            local gamepad = self.control_menu == "gamepad"
            if not gamepad and key == "lshift" or key == "rshift" then
                self.rebinding_shift = true
            elseif not gamepad and key == "lctrl" or key == "rctrl" then
                self.rebinding_ctrl = true
            elseif not gamepad and key == "lalt" or key == "ralt" then
                self.rebinding_alt = true
            elseif not gamepad and key == "lgui" or key == "rgui" then
                self.rebinding_cmd = true
            else
                local valid_key = true
                local bound_key
                if key ~= "escape" then
                    if gamepad ~= Utils.startsWith(key, "gamepad:") then
                        valid_key = false
                    else
                        bound_key = {key}

                        -- https://ux.stackexchange.com/questions/58185/normative-ordering-for-modifier-key-combinations
                        if self.rebinding_cmd   then table.insert(bound_key, 1, "cmd"  ) end
                        if self.rebinding_shift then table.insert(bound_key, 1, "shift") end
                        if self.rebinding_alt   then table.insert(bound_key, 1, "alt"  ) end
                        if self.rebinding_ctrl  then table.insert(bound_key, 1, "ctrl" ) end

                        if #bound_key == 1 then
                            bound_key = bound_key[1]
                        end
                    end
                else
                    bound_key = "escape"
                end

                if valid_key then
                    -- rebind!!
                    local worked = Input.setBind(Input.orderedNumberToKey(self.selected_option), self.selected_bind, bound_key, self.control_menu == "gamepad")

                    self.rebinding = false
                    self.rebinding_shift = false
                    self.rebinding_ctrl = false
                    self.rebinding_alt = false
                    self.rebinding_cmd = false
                    self.heart_target_x = 152
                    self.selected_bind = 1
                    if worked then
                        self.ui_select:stop()
                        self.ui_select:play()
                    else
                        self.ui_cant_select:stop()
                        self.ui_cant_select:play()
                    end
                end
            end
        end
    elseif self.state == "DEADZONE" then
        if self.substate == "SELECT" then
            if Input.isCancel(key) then
                self:popState()
                self.ui_select:stop()
                self.ui_select:play()
            end
            local last_selected = self.selected_option
            if not Input.isThumbstick(key) then
                if Input.is("down", key) then
                    self.selected_option = 3
                elseif Input.is("up", key) then
                    self.selected_option = 1
                end
                if Input.is("right", key) and self.selected_option == 1 then
                    self.selected_option = 2
                elseif Input.is("left", key) and self.selected_option == 2 then
                    self.selected_option = 1
                end
            end
            if last_selected ~= self.selected_option then
                self.ui_move:stop()
                self.ui_move:play()
            end
            if self.selected_option == 1 then
                self.heart_target_x = 152 - 18
                self.heart_target_y = 296 + 16
            elseif self.selected_option == 2 then
                self.heart_target_x = 392 - 18
                self.heart_target_y = 296 + 16
            elseif self.selected_option == 3 then
                self.heart_target_x = 270
                self.heart_target_y = 382
            end
            if Input.isConfirm(key) then
                self.ui_select:stop()
                self.ui_select:play()

                if self.selected_option == 3 then
                    self:popState()
                else
                    self:setSubState("SLIDER")
                end
            end
        elseif self.substate == "SLIDER" then
            if not is_repeat and (Input.isCancel(key) or Input.isConfirm(key)) then
                self:setSubState("SELECT")
                self.ui_select:stop()
                self.ui_select:play()
                Kristal.saveConfig()
            end
            local config_name = (self.selected_option == 1 and "left" or "right") .. "StickDeadzone"
            local deadzone = Kristal.Config[config_name]
            if not Input.isThumbstick(key) then
                if Input.is("left", key) then
                    deadzone = math.max(0, deadzone - 0.01)
                    self.ui_move:stop()
                    self.ui_move:play()
                elseif Input.is("right", key) then
                    deadzone = math.min(1, deadzone + 0.01)
                    self.ui_move:stop()
                    self.ui_move:play()
                end
            end
            Kristal.Config[config_name] = deadzone
        end
    --[[elseif self.state == "CREATE" then
        self:handleCreateInput(key, is_repeat)]]
    --[[elseif self.state == "CONFIG" then
        self:handleConfigInput(key, is_repeat)]]
    else
        -- Check input for the current state
        self.state_manager:call("keypressed", key, is_repeat)
    end
end

--[[function Menu:onCreateEnter()
    self.create = {
        name = {""},
        id = {""},
        adjusted = true,
        base_chapter_selected = 2,
        base_chapters = {1, 2},
        transition = false,
        config = {}
    }

    self:registerCreateModConfig("enableStorage",          "Enable Storage",            "Extra 48-slot item storage",                                "selection", {nil, true, false})
    self:registerCreateModConfig("smallSaveMenu",          "Small Save Menu",           "Single-file save menu with no storage/recruits options",    "selection", {nil, true, false})
    self:registerCreateModConfig("partyActions",           "X-Actions",                 "Whether X-Actions appear in spell menu by default",         "selection", {nil, true, false})
    self:registerCreateModConfig("growStronger",           "Grow Stronger",             "Stat increases after defeating an enemy with violence",     "selection", {nil, true, false})
    self:registerCreateModConfig("growStrongerChara",      "Grow Stronger Character",   "The character who grows stronger if they're in the party",  "selection", {nil, "kris", "ralsei", "susie", "noelle"}) -- unhardcode
    self:registerCreateModConfig("susieStyle",             "Susie Style",               "What sprite set Susie should use",                          "selection", {nil, 1, 2})
    self:registerCreateModConfig("ralseiStyle",            "Ralsei Style",              "What sprite set Ralsei should use",                         "selection", {nil, 1, 2})
    self:registerCreateModConfig("oldTensionBar",          "Old Tension Bar",           "Whether the Tension Bar uses blocky corners or not.",       "selection", {nil, true, false})
    self:registerCreateModConfig("oldUIPositions",         "Old UI Positions",          "Whether to use Chapter 1 positions of UI elements or not.", "selection", {nil, true, false})
    self:registerCreateModConfig("targetSystem",           "Targeting System",          "Whether battles should use the targeting system or not",    "selection", {nil, true, false})
    self:registerCreateModConfig("speechBubble",           "Speech Bubble Style",       "The default style for enemy speech bubbles",                "selection", {nil, "round", "cyber"}) -- unhardcode
    self:registerCreateModConfig("enemyAuras",             "Enemy Aura",                "The red aura around enemies",                               "selection", {nil, true, false})
    self:registerCreateModConfig("mercyMessages",          "Mercy Messages",            "Seeing +X% when an enemy's mercy goes up",                  "selection", {nil, true, false})
    self:registerCreateModConfig("mercyBar",               "Mercy Bar",                 "Whether the mercy bar should appear or not",                "selection", {nil, true, false})
    self:registerCreateModConfig("enemyBarPercentages",    "Stat Bar Percentages",      "Whether the HP and Mercy bars should show percentages",     "selection", {nil, true, false})
    self:registerCreateModConfig("pushBlockInputLock",     "Push Block Input Locking",  "Whether pushing a block should freeze the player",          "selection", {nil, true, false})
    self:registerCreateModConfig("keepTensionAfterBattle", "Keep Tension After Battle", "Whether TP should be kept after battle instead of reset",   "selection", {nil, true, false})
    self:registerCreateModConfig("overworldSpells",        "Overworld Spells",          "Whether spells should be usable in the overworld",          "selection", {nil, true, false})
end

function Menu:registerCreateModConfig(id, name, description, type, options)
    table.insert(self.create.config, {
        id = id,
        name = name,
        description = description,
        type = type,
        options = options,
        selected = 1
    })
end

function Menu:handleCreateInput(key, is_repeat)
    if self.substate == "MENU" then
        if Input.isCancel(key) then
            self:setState("MODSELECT")
            self.ui_move:stop()
            self.ui_move:play()
            return
        end
        local old = self.selected_option
        if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1  end
        if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1  end
        if Input.is("left" , key) and not Input.usingGamepad() then self.selected_option = self.selected_option - 1  end
        if Input.is("right", key) and not Input.usingGamepad() then self.selected_option = self.selected_option + 1  end
        if self.selected_option > 5 then self.selected_option = is_repeat and 5 or 1    end
        if self.selected_option < 1 then self.selected_option = is_repeat and 1 or 5    end

        local y_off = (self.selected_option - 1) * 32
        if self.selected_option >= 5 then
            y_off = y_off + 32
        end

        self.heart_target_x = 45
        self.heart_target_y = 147 + y_off

        if old ~= self.selected_option then
            self.ui_move:stop()
            self.ui_move:play()
        end

        if Input.isConfirm(key) then
            if self.selected_option == 1 then
                self.ui_select:stop()
                self.ui_select:play()
                self:setSubState("NAME")
            elseif self.selected_option == 2 then
                self.ui_select:stop()
                self.ui_select:play()
                self:setSubState("ID")
            elseif self.selected_option == 3 then
                self.ui_select:stop()
                self.ui_select:play()
                self:setSubState("CHAPTER")
            elseif self.selected_option == 4 then
                self.ui_select:stop()
                self.ui_select:play()
                self.heart_target_x = 64 - 19
                self.heart_target_y = 128 + 19
                self:setState("CONFIG")
            elseif self.selected_option == 5 then
                local valid = true
                if self.create["name"][1] == "" or self.create["id"][1] == "" then valid = false end
                if love.filesystem.getInfo("mods/" .. self.create["id"][1] .. "/") then valid = false end

                if not valid then
                    self.ui_cant_select:stop()
                    self.ui_cant_select:play()
                    return
                end


                self.ui_select:stop()
                self.ui_select:play()
                self:createMod()
                self:setState("MODSELECT")
            end
        end
    elseif self.substate == "NAME" then
        if key == "escape" then
            self:setSubState("MENU")
            self:onCreateCancel()
            self.ui_move:stop()
            self.ui_move:play()
            return
        end
    elseif self.substate == "ID" then
        if key == "escape" then
            self:onCreateCancel()
            self:setSubState("MENU")
            self.ui_move:stop()
            self.ui_move:play()
            return
        end
    elseif self.substate == "CHAPTER" then
        if Input.isConfirm(key) or Input.isCancel(key) then
            self:setSubState("MENU")
            self.ui_select:stop()
            self.ui_select:play()
            return
        end
        if Input.is("left", key) then
            self.ui_move:stop()
            self.ui_move:play()
            self.create.base_chapter_selected = self.create.base_chapter_selected - 1
            if self.create.base_chapter_selected < 1 then self.create.base_chapter_selected = 2 end
        end
        if Input.is("right", key) then
            self.ui_move:stop()
            self.ui_move:play()
            self.create.base_chapter_selected = self.create.base_chapter_selected + 1
            if self.create.base_chapter_selected > 2 then self.create.base_chapter_selected = 1 end
        end
    end
end]]


--[[function Menu:onConfigEnter(old_state)
    self.config_target_y = 0
    self.config_y = 0
end

function Menu:handleConfigInput(key, is_repeat)
    if self.substate == "MENU" then
        if Input.isCancel(key) then
            self:setState("MODCREATE")
            self.ui_move:stop()
            self.ui_move:play()
            return
        end
        local old = self.selected_option
        if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1  end
        if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1  end
        if Input.is("left" , key) and not Input.usingGamepad() then self.selected_option = self.selected_option - 1  end
        if Input.is("right", key) and not Input.usingGamepad() then self.selected_option = self.selected_option + 1  end
        if self.selected_option > (#self.create.config + 1) then self.selected_option = is_repeat and (#self.create.config + 1) or 1                            end
        if self.selected_option < 1                         then self.selected_option = is_repeat and 1                         or (#self.create.config + 1)    end

        local y_off = (self.selected_option - 1) * 32
        if self.selected_option >= #self.create.config + 1 then
            y_off = y_off + 32
        end

        if y_off + self.config_target_y < 0 then
            self.config_target_y = self.config_target_y + (0 - (y_off + self.config_target_y))
        end

        if y_off + self.config_target_y > (7 * 32) then
            self.config_target_y = self.config_target_y + ((7 * 32) - (y_off + self.config_target_y))
        end

        self.heart_target_x = 45
        self.heart_target_y = 147 + y_off + self.config_target_y

        if old ~= self.selected_option then
            self.ui_move:stop()
            self.ui_move:play()
        end

        if Input.isConfirm(key) then
            if self.selected_option == (#self.create.config + 1) then
                self:setState("MODCREATE")
                self.ui_select:stop()
                self.ui_select:play()
                return
            else
                self.heart_target_x = self.heart_target_x + 45 + 167 + 140
                self:setSubState("SELECTION")
                self.ui_select:stop()
                self.ui_select:play()
            end
        end
    elseif self.substate == "SELECTION" then
        local value = self.create.config[self.selected_option]
        if Input.isConfirm(key) or Input.isCancel(key) then
            local y_off = (self.selected_option - 1) * 32
            self.heart_target_x = 45
            self.heart_target_y = 147 + y_off + self.config_target_y
            self:setSubState("MENU")
            self.ui_select:stop()
            self.ui_select:play()
            return
        end
        if Input.is("left", key) then
            self.ui_move:stop()
            self.ui_move:play()
            value.selected = value.selected - 1
            if value.selected < 1 then value.selected = #value.options end
        end
        if Input.is("right", key) then
            self.ui_move:stop()
            self.ui_move:play()
            value.selected = value.selected + 1
            if value.selected > #value.options then value.selected = 1 end
        end
    end
end


function Menu:drawConfig()
    Draw.printShadow("Edit Feature Config", 0, 48, 2, "center", 640)

    local menu_x = 64
    local menu_y = 128

    local width = 540
    local height = 32 * 8
    local total_height = 32 * (#self.create.config + 2)

    Draw.pushScissor()
    Draw.scissor(menu_x, menu_y, width + 10, height + 10)

    menu_y = menu_y + self.config_y
    for index, config_option in ipairs(self.create.config) do
        local y_off = (index - 1) * 32
        local x_off = 0

        local x = menu_x + x_off
        local y = menu_y + y_off
        Draw.printShadow(config_option.name, x, y, 2, "left", 640)

        local option = config_option.options[config_option.selected]
        local option_text = option
        if (option == nil)   then option_text = "Default" end
        if (option == true)  then option_text = "True"    end
        if (option == false) then option_text = "False"   end

        Draw.printShadow(option_text, x + 140 + 256, y)

        if self.substate == "SELECTION" and self.selected_option == index then
            local width = self.menu_font:getWidth(option_text)
            Draw.setColor(COLORS.white)
            local off = (math.sin(Kristal.getTime() / 0.2) * 2) + 2
            Draw.draw(Assets.getTexture("kristal/menu_arrow_left"),  x + 140 + 256 - 16 - 8 - off, y + 4, 0, 2, 2)
            Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), x + 140 + width + 256 + 6 + off, y + 4, 0, 2, 2)
        end
    end

    Draw.printShadow("Back", menu_x, menu_y + (#self.create.config + 1) * 32, 2, "left", 640)

    -- Draw the scrollbar background
    Draw.setColor({1, 1, 1, 0.5})
    love.graphics.rectangle("fill", menu_x + width, 0, 4, menu_y + height - self.config_y)

    local scrollbar_height = (height / total_height) * height
    local scrollbar_y = (-self.config_y / (total_height - height)) * (height - scrollbar_height)

    Draw.popScissor()
    Draw.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", menu_x + width, menu_y + scrollbar_y - self.config_y, 4, scrollbar_height)

    local option = self.create.config[self.selected_option]
    local text
    if option then
        text = option.description
    else
        text = "Return to the mod creation menu"
    end
    Draw.setColor(COLORS.silver)

    local width, wrapped = self.menu_font:getWrap(text, 580)
    for i, line in ipairs(wrapped) do
        Draw.printShadow(line, 0, 480 + (32 * i) - (32 * (#wrapped + 1)), 2, "center", 640)
    end

    Draw.setColor(1, 1, 1)
end]]

function Menu:onSubStateChange(old, new)
    --[[if self.state == "CREATE" then
        if new == "MENU" then
            self.heart_target_x = 45
        elseif new == "NAME" then
            self.heart_target_x = 45 + 167
            self:openInput("name")
        elseif new == "ID" then
            self.heart_target_x = 45 + 167
            self:openInput("id", function(letter)
                local disallowed = {"/", "\\", "*", ".", "?", ":", "\"", "<", ">", "|"}
                if Utils.containsValue(disallowed, letter) then
                    return false
                end
                if letter == " "  then return "_" end
                return letter:lower()
            end)
        elseif new == "CHAPTER" then
            self.heart_target_x = 45 + 167 + 64
        end
    end]]
end

--function Menu:disallowWindowsFolders(str, auto)
--    -- Check if STR is a disallowed file name in windows (e.g. "CON")
--    if Utils.containsValue({"CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"}, str:upper()) then
--        if not auto then Assets.playSound("locker") end
--        str = "disallowed_id"
--    end
--    return str
--end
--
--function Menu:adjustCreateID()
--    local str = self.create.name[1]
--
--    str = self:disallowWindowsFolders(str, true)
--
--    local newstr = ""
--    for i = 1, utf8.len(str) do
--        local offset = utf8.offset(str, i)
--        local char = string.sub(str, offset, offset)
--        local disallowed = {"/", "\\", "*", ".", "?", ":", "\"", "<", ">", "|"}
--        if Utils.containsValue(disallowed, char) then
--            char = ""
--        end
--        if char == " " then char = "_" end
--        newstr = newstr .. char:lower()
--    end
--    self.create.id[1] = newstr
--    self.create.adjusted = true
--end
--
--function Menu:openInput(id, restriction)
--    TextInput.attachInput(self.create[id], {
--        multiline = false,
--        enter_submits = true,
--        clear_after_submit = false,
--        text_restriction = restriction,
--    })
--    TextInput.submit_callback = function(...) self:onCreateSubmit(id) end
--    if id == "name" then
--        TextInput.text_callback = function() self:attemptUpdateID("name") end
--    else
--        TextInput.text_callback = nil
--    end
--end
--
--function Menu:attemptUpdateID(id)
--    if (id == "name" or id == "id") and self.create.id[1] == "" then
--        self:adjustCreateID()
--    end
--    if (id == "name" and self.create.adjusted) then
--        self:adjustCreateID()
--    end
--end
--
--function Menu:createMod()
--    local name = self.create.name[1]
--    local id = self.create.id[1]
--
--    local config_formatted = "            "
--    for i, option in ipairs(self.create.config) do
--        local chosen = option.options[option.selected]
--        local text = chosen
--
--        if chosen == true  then
--            text = "true"
--        elseif chosen == false then
--            text = "false"
--        elseif type(chosen) == "number" then
--            text = tostring(chosen)
--        elseif type(chosen) == "string" then
--            text = "\"" .. chosen .. "\""
--        else
--            text = "UNHANDLED_TYPE_REPORT_TO_DEVS"
--        end
--
--        if chosen ~= nil then
--            config_formatted = config_formatted .. "// " .. option.description .. "\n            "
--            config_formatted = config_formatted .. "\"" .. option.id .. "\": " .. text .. "," .. "\n            "
--        end
--    end
--    config_formatted = config_formatted .. "// End of config"
--
--    local formatting_dict = {
--        id = id,
--        name = name,
--        engineVer = "v" .. tostring(Kristal.Version),
--        chapter = self.create.base_chapters[self.create.base_chapter_selected],
--        transition = self.create.transition and "true" or "false",
--        config = config_formatted
--    }
--
--    -- Create the directory
--    local dir = "mods/" .. id .. "/"
--
--    if not love.filesystem.getInfo(dir) then
--        love.filesystem.createDirectory(dir)
--    end
--
--    -- Copy the files from mod_template
--    local files = Utils.findFiles("mod_template")
--    for i, file in ipairs(files) do
--        local src = "mod_template/" .. file
--        local dst = dir .. file
--        dst = dst:gsub("modid", id)
--        local info = love.filesystem.getInfo(src)
--        if info then
--            if info.type == "file" then
--                if file == "mod.json" then
--                    -- Special handling in case we're mod.json
--                    local data = love.filesystem.read("string", src) --[[@as string]]
--                    data = Utils.format(data, formatting_dict)
--
--                    local write_file = love.filesystem.newFile(dst)
--                    write_file:open("w")
--                    write_file:write(data)
--                    write_file:close()
--                else
--                    -- Copy the file
--                    local data = love.filesystem.read("data", src)
--                    local write_file = love.filesystem.newFile(dst)
--                    write_file:open("w")
--                    write_file:write(data)
--                    write_file:close()
--                end
--            else
--                -- Create the directory
--                love.filesystem.createDirectory(dst)
--            end
--        end
--    end
--
--    -- Reload mods
--    self:reloadMods()
--end
--
--function Menu:onCreateSubmit(id)
--    self.ui_select:stop()
--    self.ui_select:play()
--    TextInput.input = {""}
--    TextInput.endInput()
--
--    if id == "id" then
--        self.create.adjusted = false
--        self.create["id"][1] = self:disallowWindowsFolders(self.create["id"][1], false)
--    end
--
--    self:attemptUpdateID(id)
--
--    Input.clear("return")
--
--    self:setSubState("MENU")
--end
--
--function Menu:onCreateCancel()
--    TextInput.input = {""}
--    TextInput.endInput()
--    self:setSubState("MENU")
--end
--
--function Menu:drawCreate()
--    Draw.printShadow("Create New Mod", 0, 48, "center", 640)
--
--    local menu_x = 64
--    local menu_y = 128
--
--    self:drawInputLine("Mod name: ",          menu_x, menu_y + (32 * 0), "name")
--    self:drawInputLine("Mod ID:   ",          menu_x, menu_y + (32 * 1), "id")
--    Draw.printShadow(  "Base chapter: ",      menu_x, menu_y + (32 * 2))
--    Draw.printShadow(  "Edit feature config", menu_x, menu_y + (32 * 3))
--    Draw.printShadow(  "Create mod",          menu_x, menu_y + (32 * 5))
--
--    local off = 256
--    self:drawSelectionField(menu_x + off, menu_y + (32 * 2), "base_chapter_selected", self.create.base_chapters, "CHAPTER")
--    --self:drawCheckbox(menu_x + off, menu_y + (32 * 3), "transition")
--
--    Draw.setColor(COLORS.silver)
--
--    if self.selected_option == 1 then
--        Draw.printShadow("The name of your mod. Shows in the menu.", 0, 480 - 32, 2, "center", 640)
--    elseif self.selected_option == 2 then
--        Draw.printShadow("The ID of your mod. Must be unique.", 0, 480 - 32, 2, "center", 640)
--    elseif self.selected_option == 3 then
--        Draw.printShadow("The chapter to base your mod off of in", 0, 480 - 64 - 32, 2, "center", 640)
--        Draw.printShadow("terms of features. Individual features", 0, 480 - 64, 2, "center", 640)
--        Draw.printShadow("can be toggled in the config.", 0, 480 - 32, 2, "center", 640)
--    elseif self.selected_option == 4 then
--        Draw.printShadow("Edit individual Kristal features.", 0, 480 - 32, 2, "center", 640)
--    elseif self.selected_option == 5 then
--        if self.create.id[1] == "" then
--            Draw.setColor(1, 0.6, 0.6)
--            Draw.printShadow("You must enter a valid ID.", 0, 480 - 32, 2, "center", 640)
--        elseif self.create.name[1] == "" then
--            Draw.setColor(1, 0.6, 0.6)
--            Draw.printShadow("You must enter a valid name.", 0, 480 - 32, 2, "center", 640)
--        else
--            Draw.printShadow("Create the mod.", 0, 480 - 32, 2, "center", 640)
--        end
--    end
--
--    Draw.setColor(1, 1, 1)
--
--    if TextInput.active and (self.substate ~= "MENU") then
--        TextInput.draw({
--            x = self.create.input_pos_x,
--            y = self.create.input_pos_y,
--            font = self.menu_font,
--            print = function(text, x, y) Draw.printShadow(text, x, y) end,
--        })
--    end
--end
--
--function Menu:drawSelectionField(x, y, id, options, state)
--    if self.state == "MODCREATE" then
--        Draw.printShadow(options[self.create[id]], x, y)
--    elseif self.state == "CONFIG" then
--        Draw.printShadow(options[self.config[id]], x, y)
--    end
--
--    if self.substate == state then
--        Draw.setColor(COLORS.white)
--        local off = (math.sin(Kristal.getTime() / 0.2) * 2) + 2
--        Draw.draw(Assets.getTexture("kristal/menu_arrow_left"), x - 16 - 8 - off, y + 4, 0, 2, 2)
--        Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), x + 16 + 8 - 4 + off, y + 4, 0, 2, 2)
--    end
--end
--
--function Menu:drawCheckbox(x, y, id)
--    x = x - 8
--    local checked = self.create[id]
--    love.graphics.setLineWidth(2)
--    Draw.setColor(COLORS.black)
--    love.graphics.rectangle("line", x + 2 + 2, y + 2 + 2, 32 - 4, 32 - 4)
--    Draw.setColor(checked and COLORS.white or COLORS.silver)
--    love.graphics.rectangle("line", x + 2, y + 2, 32 - 4, 32 - 4)
--    if checked then
--        Draw.setColor(COLORS.black)
--        love.graphics.rectangle("line", x + 6 + 2, y + 6 + 2, 32 - 12, 32 - 12)
--        Draw.setColor(COLORS.aqua)
--        love.graphics.rectangle("fill", x + 6, y + 6, 32 - 12, 32 - 12)
--    end
--end
--
--function Menu:drawInputLine(name, x, y, id)
--    Draw.printShadow(name, x, y)
--    love.graphics.setLineWidth(2)
--    local line_x  = x + 128 + 32 + 16
--    local line_x2 = line_x + 416 - 32
--    local line_y = 32 - 4 - 1 + 2
--    Draw.setColor(0, 0, 0, 1)
--    love.graphics.line(line_x + 2, y + line_y + 2, line_x2 + 2, y + line_y + 2)
--    Draw.setColor(COLORS.silver)
--    love.graphics.line(line_x, y + line_y, line_x2, y + line_y)
--
--    if self.create[id] ~= TextInput.input then
--        Draw.printShadow(self.create[id][1], line_x, y)
--    else
--        self.create.input_pos_x = line_x
--        self.create.input_pos_y = y
--    end
--end

function Menu:onKeyReleased(key)
    if MOD_LOADING then return end

    if self.state == "CONTROLS" and self.rebinding then
        -- TODO: Maybe move this into a function? Copying code is gross

        local released_modifier =
            (self.rebinding_ctrl  and (key == "lctrl"  or key == "rctrl" )) or
            (self.rebinding_shift and (key == "lshift" or key == "rshift")) or
            (self.rebinding_alt   and (key == "lalt"   or key == "ralt"  )) or
            (self.rebinding_cmd   and (key == "lcmd"   or key == "rcmd"  ))

        if released_modifier then
            local bound_key = {}

            -- https://ux.stackexchange.com/questions/58185/normative-ordering-for-modifier-key-combinations
            if self.rebinding_cmd   then table.insert(bound_key, 1, "cmd"  ) end
            if self.rebinding_shift then table.insert(bound_key, 1, "shift") end
            if self.rebinding_alt   then table.insert(bound_key, 1, "alt"  ) end
            if self.rebinding_ctrl  then table.insert(bound_key, 1, "ctrl" ) end

            if #bound_key == 1 then
                bound_key = bound_key[1]
            end

            -- rebind!!
            local worked = Input.setBind(Input.orderedNumberToKey(self.selected_option), self.selected_bind, bound_key)

            self.rebinding = false
            self.rebinding_shift = false
            self.rebinding_ctrl = false
            self.rebinding_alt = false
            self.rebinding_cmd = false
            self.heart_target_x = 152
            self.selected_bind = 1
            if worked then
                self.ui_select:stop()
                self.ui_select:play()
            else
                self.ui_cant_select:stop()
                self.ui_cant_select:play()
            end
        end
    end
end

function Menu:getBoundKeys(key)
    local keys = {}
    for _,k in ipairs(Input.getBoundKeys(key, self.control_menu == "gamepad")) do
        if type(k) == "table" then
            table.insert(keys, table.concat(k, "+"))
        else
            table.insert(keys, k)
        end
    end
    if (self.rebinding or self.selecting_key) and (key == Input.orderedNumberToKey(self.selected_option)) then
        table.insert(keys, "---")
        return keys
    end
    return keys
end

function Menu:drawBackground()
    -- This code was originally 30 fps, so we need a deltatime variable to multiply some values by
    local dt_mult = DT * 30

    if not (TARGET_MOD and self.selected_mod.preview) then
        -- We need to draw the background on a canvas
        Draw.setCanvas(self.bg_canvas)
        love.graphics.clear(0, 0, 0, 1)

        -- Set the shader to use
        love.graphics.setShader(self.BACKGROUND_SHADER)
        self.BACKGROUND_SHADER:send("bg_sine", self.animation_sine)
        self.BACKGROUND_SHADER:send("bg_mag", 6)
        self.BACKGROUND_SHADER:send("wave_height", 240)
        self.BACKGROUND_SHADER:send("texsize", {self.background_image_wave:getWidth(), self.background_image_wave:getHeight()})

        self.BACKGROUND_SHADER:send("sine_mul", 1)
        Draw.setColor(1, 1, 1, self.background_alpha * 0.8)
        Draw.draw(self.background_image_wave, 0, math.floor(-10 - (self.background_alpha * 20)))
        self.BACKGROUND_SHADER:send("sine_mul", -1)
        Draw.draw(self.background_image_wave, 0, math.floor(-10 - (self.background_alpha * 20)))
        Draw.setColor(1, 1, 1, 1)

        love.graphics.setShader()

        self:drawAnimStrip(self.background_image_animation, ( self.animation_sine / 12),        0, (((10 - (self.background_alpha * 20)) + 240) - 70), (self.background_alpha * 0.46))
        self:drawAnimStrip(self.background_image_animation, ((self.animation_sine / 12) + 0.4), 0, (((10 - (self.background_alpha * 20)) + 240) - 70), (self.background_alpha * 0.56))
        self:drawAnimStrip(self.background_image_animation, ((self.animation_sine / 12) + 0.8), 0, (((10 - (self.background_alpha * 20)) + 240) - 70), (self.background_alpha * 0.7))

        -- Reset canvas to draw to
        Draw.setCanvas(SCREEN_CANVAS)

        -- Draw the canvas on the screen scaled by 2x
        Draw.setColor(1, 1, 1, self.background_fade)
        Draw.draw(self.bg_canvas, 0, 0, 0, 2, 2)
    end

    -- Draw mod previews
    for _,mod in ipairs(self.mod_list.mods) do
        local fade = self.mod_list.fades[mod.id]
        if mod.preview and fade > 0 then
            -- Draw to mod's preview to a small canvas
            local canvas = Draw.pushCanvas(320, 240, {clear = false})
            love.graphics.clear(0, 0, 0, 1)

            self:drawAnimStrip(mod.preview, ( self.animation_sine / 12),        0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.46))
            self:drawAnimStrip(mod.preview, ((self.animation_sine / 12) + 0.4), 0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.56))
            self:drawAnimStrip(mod.preview, ((self.animation_sine / 12) + 0.8), 0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.7))

            Draw.popCanvas()

            -- Draw canvas scaled 2x to the screen
            Draw.setColor(1, 1, 1, fade)
            Draw.draw(canvas, 0, 0, 0, 2, 2)
        end

        local script = self.mod_list.scripts[mod.id]
        if script and script.draw then
            -- Draw from the mod's preview script
            love.graphics.push()
            local success, msg = pcall(script.draw, script)
            if not success then
                Kristal.Console:warn("preview.lua error in "..mod.name..": "..msg)
                self.mod_list.scripts[mod.id] = nil
            end
            love.graphics.pop()
        end
    end

    -- Reset the draw color
    Draw.setColor(1, 1, 1, 1)
end

return Menu