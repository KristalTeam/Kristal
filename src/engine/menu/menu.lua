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
        number wave_mag = max(0, bg_mag - bg_minus);
        vec2 coords = vec2(max(0, min(1, texture_coords.x + (sine_mul * sin((i / 8) + (bg_sine / 30)) * wave_mag) / texsize.x)), max(0, min(1, texture_coords.y + 0.0)));
        return Texel(texture, coords) * color;
    }
]])

function Menu:enter()
    -- STATES: MAINMENU, MODSELECT, FILESELECT, OPTIONS, VOLUME, WINDOWSCALE, CONTROLS
    self.state = "MAINMENU"

    love.keyboard.setKeyRepeat(true)

    -- Load menu music
    self.music = Music("mod_menu", 1, 0.95)

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

    self.list = ModList(69, 70, 502, 370)
    self.list.active = false
    self.list.visible = false
    self.list.layer = 50
    self.stage:addChild(self.list)

    self.files = nil

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

    self.heart_target_x = 196
    self.heart_target_y = 238

    self.options_target_y = 0
    self.options_y = 0

    -- Assets required for the menu
    self.menu_font = Assets.getFont("main")
    self.small_font = Assets.getFont("main", 16)

    -- Preview fading stuff
    self.background_fade = 1
    self.mod_fades = {}

    -- Load the mods
    self.loading_mods = false
    self.last_loaded = nil

    self.logo = Assets.getTexture("kristal/title_logo_shadow")
    self.selected_option = 1

    self.selected_mod_button = nil
    self.selected_mod = nil

    self.rebinding = false
    self.rebinding_shift = false
    self.rebinding_ctrl = false
    self.rebinding_alt = false
    self.rebinding_cmd = false

    self.selecting_key = false
    self.selected_bind = 1

    self.noise_timer = 0

    self.has_target_saves = false
    self.target_mod_offset = TARGET_MOD and 1 or 0

    self:buildMods()

    self.left_credits = {
        {"Lead Developers", COLORS.silver},
        "Nyakorita",
        "SylviBlossom",
        "",
        {"Developers", COLORS.silver},
        "Vitellary",
        "",
        {"Assets", COLORS.silver},
        "Toby Fox",
        "Temmie Chang",
        "DELTARUNE team"
    }

    self.right_credits = {
        {"GitHub Contributors", COLORS.silver},
        "Archie-osu",
        "Luna",
        "",
        {"Documentation", COLORS.silver},
        "Vitellary",
        "",
        {"Battle Name Font", COLORS.silver},
        "TheCyVap",
    }
end

function Menu:setState(state)
    local old_state = self.state
    self.state = state
    self:onStateChange(old_state, self.state)
end

function Menu:onStateChange(old_state, new_state)
    if old_state == "MODSELECT" then
        self.list.active = false
        self.list.visible = false
    elseif old_state == "FILESELECT" then
        self.files:remove()
    end
    if new_state == "MAINMENU" then
        self.selected_mod_button = nil
        self.selected_mod = nil
    elseif new_state == "MODSELECT" then
        self.list.active = true
        self.list.visible = true
        self.intro_text = {{1, 1, 1, 1}, "Welcome to Kristal,\nthe DELTARUNE fangame engine!\n\nAdd mods to the ", {1, 1, 0, 1}, "mods folder", {1, 1, 1, 1}, "\nto continue.\n\nPress "..Input.getText("cancel").." to return to the main menu."}
    elseif new_state == "FILESELECT" then
        self.files = FileList(self, self.selected_mod)
        self.files.layer = 50
        self.stage:addChild(self.files)
    elseif new_state == "OPTIONS" then
        if old_state ~= "VOLUME" and old_state ~= "WINDOWSCALE" then
            self.options_target_y = 0
            self.options_y = 0
        end
    elseif new_state == "CONTROLS" then
        self.options_target_y = 0
        self.options_y = 0
    end
end

function Menu:leave()
    love.keyboard.setKeyRepeat(false)
    self.music:stop()
end

function Menu:drawMenuRectangle(x, y, width, height, color)
    love.graphics.push()
    -- Draw the transparent background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Make sure the line is a single pixel wide
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    -- Set the color
    love.graphics.setColor(color)
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
    if self.state == "MODSELECT" then
        if not self.loading_mods and not self.TEST_MOD_LIST then
            local mod_paths = love.filesystem.getDirectoryItems("mods")
            if not Utils.equal(mod_paths, self.last_loaded) then
                self:reloadMods()
                self.last_loaded = mod_paths
            end
        end
    end
end

function Menu:reloadMods()
    if self.loading_mods then return end

    self.loading_mods = true

    Kristal.Mods.clear()
    Kristal.loadAssets("", "mods", "", function()
        self.loading_mods = false

        self:rebuildMods()
    end)
end

function Menu:buildMods()
    self.built_mods = true
    if self.TEST_MOD_LIST then
        for i = 1,self.TEST_MOD_COUNT do
            self.list:addMod(ModButton("Example Mod "..i, 424, 62))
        end
        return
    end
    local sorted_mods = Utils.copy(Kristal.Mods.getMods())
    table.sort(sorted_mods, function(a, b)
        local a_fav = Utils.containsValue(Kristal.Config["favorites"], a.id)
        local b_fav = Utils.containsValue(Kristal.Config["favorites"], b.id)
        return (a_fav and not b_fav) or (a_fav == b_fav and a.path:lower() < b.path:lower())
    end)
    for _,mod in ipairs(sorted_mods) do
        local button = ModButton(mod.name or mod.id, 424, 62, mod)

        if mod.preview then
            self.mod_fades[mod.id] = self.mod_fades[mod.id] or {fade = 0}
            if not self.mod_fades[mod.id].canvas then
                self.mod_fades[mod.id].canvas = love.graphics.newCanvas(320, 240)
            end
        end

        if mod.preview_script_path then
            local chunk = love.filesystem.load(mod.preview_script_path)
            local success, result = pcall(chunk, mod.path)
            if success then
                self.mod_fades[mod.id] = self.mod_fades[mod.id] or {fade = 0}
                button.preview_script = result
                if button.preview_script.init then
                    button.preview_script:init(mod, button, self)
                end
            else
                print("preview.lua error in "..mod.name..": "..result)
            end
        end

        if not mod.hidden then
            self.list:addMod(button)
        end
    end
    self.last_loaded = love.filesystem.getDirectoryItems("mods")

    if TARGET_MOD then
        local _,index = self.list:getById(TARGET_MOD)
        if not index then
            error("No mod found: "..TARGET_MOD)
        else
            self.list:select(index, true)
        end
        self.has_target_saves = Kristal.hasAnySaves(TARGET_MOD)
    end
end

function Menu:rebuildMods()
    local last_scroll = self.list.scroll_target
    local last_selected = self.list:getSelectedId()

    self.list:clearMods()
    self:buildMods()

    local used = {}
    for _,mod in ipairs(self.list.mods) do
        used[mod.id] = true
    end
    for k,v in pairs(self.mod_fades) do
        if not used[k] then
            self.mod_fades[k] = nil
        end
    end

    local button, i = self.list:getById(last_selected)
    if i ~= nil then
        self.list:select(i, true)
        self.list:setScroll(last_scroll)
    end
end

function Menu:drawAnimStrip(sprite, subimg, x, y, alpha)
    love.graphics.setColor(1, 1, 1, alpha)

    local index = #sprite > 1 and ((math.floor(subimg) % (#sprite - 1)) + 1) or 1

    love.graphics.draw(sprite[index], math.floor(x), math.floor(y))
end

function Menu:printShadow(text, x, y, color, align, limit)
    -- Draw the shadow, offset by two pixels to the bottom right
    love.graphics.setFont(self.menu_font)
    love.graphics.setColor({0, 0, 0, 1})
    love.graphics.printf(text, x + 2, y + 2, limit or self.menu_font:getWidth(text), align or "left")

    -- Draw the main text
    love.graphics.setColor(color or {1, 1, 1, 1})
    love.graphics.printf(text, x, y, limit or self.menu_font:getWidth(text), align or "left")
end

function Menu:update()
    local mod_button, current_mod
    if self.state == "MODSELECT" or TARGET_MOD then
        self.selected_mod_button = self.list:getSelected()
        self.selected_mod = self.list:getSelectedMod()
    end
    mod_button = self.selected_mod_button
    current_mod = self.selected_mod

    -- Update fade between previews
    if (current_mod and (current_mod.preview or mod_button.preview_script)) then
        if mod_button.preview_script and mod_button.preview_script.hide_background ~= false then
            self.background_fade = math.max(0, self.background_fade - (DT / 0.5))
        else
            self.background_fade = math.min(1, self.background_fade + (DT / 0.5))
        end
        for k,v in pairs(self.mod_fades) do
            if k == current_mod.id and v.fade < 1 then
                v.fade = math.min(1, v.fade + (DT / 0.5))
            elseif k ~= current_mod.id and v.fade > 0 then
                v.fade = math.max(0, v.fade - (DT / 0.5))
            end
        end
    else
        self.background_fade = math.min(1, self.background_fade + (DT / 0.5))
        for k,v in pairs(self.mod_fades) do
            if v.fade > 0 then
                v.fade = math.max(0, v.fade - (DT / 0.5))
            end
        end
    end

    -- Update preview scripts
    for k,v in pairs(self.list.mods) do
        if v.preview_script then
            v.preview_script.fade = self.mod_fades[v.id].fade
            v.preview_script.selected = v.selected
            v.preview_script:update()
        end
    end

    -- Update the stage (mod menu)
    self.stage:update()

    -- Move the heart closer to the target
    if self.state == "MODSELECT" then
        if mod_button then
            local lhx, lhy = mod_button:getHeartPos()
            local button_heart_x, button_heart_y = mod_button:getRelativePos(lhx, lhy, self.list)
            self.heart_target_x = self.list.x + button_heart_x
            self.heart_target_y = self.list.y + button_heart_y - (self.list.scroll_target - self.list.scroll)
        end
    elseif self.state == "FILESELECT" then
        self.heart_target_x, self.heart_target_y = self.files:getHeartPos()
    elseif self.state == "VOLUME" then
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

    if not self.heart.visible then
        self.heart.visible = true
        self.heart:setPosition(self.heart_target_x, self.heart_target_y)
    else
        if (math.abs((self.heart_target_x - self.heart.x)) <= 2) then
            self.heart.x = self.heart_target_x
        end
        if (math.abs((self.heart_target_y - self.heart.y)) <= 2)then
            self.heart.y = self.heart_target_y
        end
        self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * DTMULT
        self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * DTMULT
    end

    -- Toggle heart favorite outline
    if self.state == "MODSELECT" and mod_button then
        self.heart_outline.visible = mod_button:isFavorited()
        self.heart_outline:setColor(mod_button:getFavoritedColor())
    else
        self.heart_outline.visible = false
    end

    if (math.abs((self.options_target_y - self.options_y)) <= 2) then
        self.options_y = self.options_target_y
    end
    self.options_y = self.options_y + ((self.options_target_y - self.options_y) / 2) * DTMULT
end

function Menu:optionsShown()
    return self.state == "OPTIONS" or self.state == "VOLUME" or self.state == "WINDOWSCALE"
end

function Menu:draw()
    -- Draw the menu background
    self:drawBackground()

    -- Draw the engine version
    self:drawVersion()

    if self.state == "MAINMENU" then
        local logo_img = self.selected_mod and self.selected_mod.logo or self.logo

        love.graphics.draw(logo_img, SCREEN_WIDTH/2 - logo_img:getWidth()/2, 105 - logo_img:getHeight()/2)
        --love.graphics.draw(self.selected_mod and self.selected_mod.logo or self.logo, 160, 70)

        if TARGET_MOD then
            if self.has_target_saves then
                self:printShadow("Load game", 215, 219)
            else
                self:printShadow("Start game", 215, 219)
            end
            self:printShadow("Options", 215, 219 + 32)
            self:printShadow("Credits", 215, 219 + 64)
            self:printShadow("Quit", 215, 219 + 96)
        else
            self:printShadow("Play a mod", 215, 219)
            self:printShadow("Open mods folder", 215, 219 + 32)
            self:printShadow("Options", 215, 219 + 64)
            self:printShadow("Credits", 215, 219 + 96)
            self:printShadow("Quit", 215, 219 + 128)
        end
    elseif self:optionsShown() then

        self:printShadow("( OPTIONS )", 0, 48, {1, 1, 1, 1}, "center", 640)

        local menu_x = 185 - 14
        local menu_y = 110

        local width = 320
        local height = 32 * 10
        local total_height = 32 * 13 -- should be the amount of options there are

        Draw.pushScissor()
        Draw.scissor(menu_x, menu_y, width + 10, height + 10)

        menu_y = menu_y + self.options_y

        self:printShadow("Master Volume",     menu_x, menu_y + (32 * 0))
        self:printShadow("Controls",          menu_x, menu_y + (32 * 1))
        self:printShadow("Simplify VFX",      menu_x, menu_y + (32 * 2))
        self:printShadow("Window Scale",      menu_x, menu_y + (32 * 3))
        self:printShadow("Fullscreen",        menu_x, menu_y + (32 * 4))
        self:printShadow("Auto-Run",          menu_x, menu_y + (32 * 5))
        self:printShadow("Skip Intro",        menu_x, menu_y + (32 * 6))
        self:printShadow("Display FPS",       menu_x, menu_y + (32 * 7))
        self:printShadow("Debug Hotkeys",     menu_x, menu_y + (32 * 8))
        self:printShadow("Use System Mouse",  menu_x, menu_y + (32 * 9))
        self:printShadow("Always Show Mouse", menu_x, menu_y + (32 * 10))
        self:printShadow("Back",              menu_x, menu_y + (32 * 12))

        self:printShadow(Utils.round(Kristal.getVolume() * 100) .. "%",  menu_x + (8 * 32), menu_y + (32 * 0))
        self:printShadow(Kristal.Config["simplifyVFX"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 2))
        self:printShadow(tostring(Kristal.Config["windowScale"]).."x", menu_x + (8 * 32), menu_y + (32 * 3))
        self:printShadow(Kristal.Config["fullscreen"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 4))
        self:printShadow(Kristal.Config["autoRun"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 5))
        self:printShadow(Kristal.Config["skipIntro"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 6))
        self:printShadow(Kristal.Config["showFPS"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 7))
        self:printShadow(Kristal.Config["debug"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 8))
        self:printShadow(Kristal.Config["systemCursor"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 9))
        self:printShadow(Kristal.Config["alwaysShowCursor"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 10))

        -- Draw the scrollbar background
        love.graphics.setColor({0, 0, 0, 0.5})
        love.graphics.rectangle("fill", menu_x + width, 0, 4, menu_y + height - self.options_y)

        local scrollbar_height = (height / total_height) * height
        local scrollbar_y = (-self.options_y / (total_height - height)) * (height - scrollbar_height)

        Draw.popScissor()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", menu_x + width, menu_y + scrollbar_y - self.options_y, 4, scrollbar_height)

    elseif self.state == "CONTROLS" then
        self:printShadow("( CONTROLS )", 0, 48, {1, 1, 1, 1}, "center", 640)

        local menu_x = 185 - 14
        local menu_y = 110

        local width = 400
        local height = 32 * 10
        local total_height = 32 * (#Input.order + 4) -- should be the amount of options there are

        Draw.pushScissor()
        Draw.scissor(menu_x, menu_y, width + 10, height + 10)

        menu_y = menu_y + self.options_y

        local y_offset = 0

        for index, name in ipairs(Input.order) do
            self:printShadow(name:gsub("_", " "):upper(),  menu_x, menu_y + (32 * y_offset))

            self:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
            y_offset = y_offset + 1
        end

        for name, value in pairs(Input.aliases) do
            if not Utils.containsValue(Input.order, name) then
                self:printShadow(name:gsub("_", " "):upper(),  menu_x, menu_y + (32 * y_offset))

                self:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
                --self:printShadow(Utils.titleCase(value[1]),    menu_x + (8 * 32), menu_y + (32 * y_offset))
                y_offset = y_offset + 1
            end
        end

        self:printShadow("Reset to defaults",  menu_x, menu_y + (32 * (y_offset + 1)))
        self:printShadow("Back",  menu_x, menu_y + (32 * (y_offset + 2)))

        -- Draw the scrollbar background (lighter than the others since it's against black)
        love.graphics.setColor({1, 1, 1, 0.5})
        love.graphics.rectangle("fill", menu_x + width, 0, 4, menu_y + height - self.options_y)

        local scrollbar_height = (height / total_height) * height
        local scrollbar_y = (-self.options_y / (total_height - height)) * (height - scrollbar_height)

        Draw.popScissor()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", menu_x + width, menu_y + scrollbar_y - self.options_y, 4, scrollbar_height)

    elseif self.state == "MODSELECT" then
        -- Draw introduction text if no mods exist

        if self.loading_mods then
            self:printShadow("Loading mods...", 0, 115 - 8, {1, 1, 1, 1}, "center", 640)
        else
            if #self.list.mods == 0 then
                self.heart_target_x = -8
                self.heart_target_y = -8
                self.list.active = false
                self.list.visible = false
                self:printShadow(self.intro_text, 0, 115 - 8, {1, 1, 1, 1}, "center", 640)
            else
                -- Draw some menu text
                self:printShadow("Choose your world.", 80, 34 - 8, {1, 1, 1, 1})

                local control_text = Input.getText("menu").." "..(self.heart_outline.visible and "Unfavorite" or "Favorite  ").."  "..Input.getText("cancel").." Back"
                self:printShadow(control_text, 580 + (16 * 3) - self.menu_font:getWidth(control_text), 454 - 8, {1, 1, 1, 1})
            end
        end
    elseif self.state == "FILESELECT" then
        local mod_name = string.upper(self.selected_mod.name or self.selected_mod.id)
        self:printShadow(mod_name, 16, 8, {1, 1, 1, 1})
    elseif self.state == "CREDITS" then
        self:printShadow("( CREDITS )", 0, 48, {1, 1, 1, 1}, "center", 640)

        for index, value in ipairs(self.left_credits) do
            local color = {1, 1, 1, 1}
            local offset = 0
            if type(value) == "table" then
                color = value[2]
                value = value[1]
            else
                offset = offset + 32
            end
            self:printShadow(value, 32 + offset, 64 + (32 * index), color)
        end

        for index, value in ipairs(self.right_credits) do
            local color = {1, 1, 1, 1}
            local offset = 0
            if type(value) == "table" then
                color = value[2]
                value = value[1]
            else
                offset = offset - 32
            end
            self:printShadow(value, 0, 64 + (32 * index), color, "right", 640 - 32 + offset)

            self:printShadow("Back", 0, 454 - 8, {1, 1, 1, 1}, "center", 640)
        end
    else
        self:printShadow("Nothing here for now!", 0, 240 - 8, {1, 1, 1, 1}, "center", 640)
    end

    -- Draw mod preview overlays
    for k,v in pairs(self.list.mods) do
        if v.preview_script and v.preview_script.drawOverlay then
            love.graphics.push()
            v.preview_script:drawOverlay()
            love.graphics.pop()
        end
    end

    self.stage:draw()

    -- Draw the screen fade
    love.graphics.setColor(0, 0, 0, self.fader_alpha)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    -- Change the fade opacity for the next frame
    self.fader_alpha = math.max(0,self.fader_alpha - (0.08 * DTMULT))

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu:drawVersion()
    local ver_string = "v"..tostring(Kristal.Version)
    local ver_y = SCREEN_HEIGHT - self.small_font:getHeight()

    if not TARGET_MOD then

        if self.state == "MAINMENU" and Kristal.Version.major == 0 then
            ver_string = ver_string .. " (Unstable)"
        end

        love.graphics.setFont(self.small_font)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.print(ver_string, 4, ver_y)

        if self.selected_mod_button then
            local compatible, mod_version = self.selected_mod_button:checkCompatibility()
            if not compatible then
                love.graphics.setColor(1, 0.5, 0.5, 0.75)
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
        local full_ver = "Kristal: "..ver_string

        if self.selected_mod.version then
            ver_y = ver_y - self.small_font:getHeight()
            full_ver = self.selected_mod.name..": "..self.selected_mod.version.."\n"..full_ver
        end

        love.graphics.setFont(self.small_font)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.print(full_ver, 4, ver_y)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.menu_font)
end

function Menu:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
    local x_offset = 0
    if self.selected_option == (y_offset + 1) then
        for i, v in ipairs(self:getKeysFromAlias(name)) do
            local drawstr = v:upper()
            if i < #self:getKeysFromAlias(name) then
                drawstr = drawstr .. ", "
            end
            if i < self.selected_bind then
                x_offset = x_offset - self.menu_font:getWidth(drawstr) - 8
            end
        end
    end
    Draw.pushScissor()
    Draw.scissorPoints(380, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    for i, v in ipairs(self:getKeysFromAlias(name)) do
        local drawstr = v:upper()
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
        if i < #self:getKeysFromAlias(name) then
            drawstr = drawstr .. ", "
        end
        self:printShadow(drawstr, menu_x + (8 * 32) + x_offset, menu_y + (32 * y_offset), color)
        x_offset = x_offset + self.menu_font:getWidth(drawstr) + 8
    end
    Draw.popScissor()
end

function Menu:keypressed(key, _, is_repeat)
    if MOD_LOADING then return end
    if OVERLAY_OPEN then return end

    if self.state ~= "CONTROLS" then
        if not Input.processKeyPressedFunc(key) then
            return
        end
    end

    if self.state == "MAINMENU" then
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
        if Input.is("up"   , key) then self.selected_option = self.selected_option - 1 end
        if Input.is("down" , key) then self.selected_option = self.selected_option + 1 end
        if Input.is("left" , key) then self.selected_option = self.selected_option - 1 end
        if Input.is("right", key) then self.selected_option = self.selected_option + 1 end
        if self.selected_option > 5 - self.target_mod_offset then self.selected_option = is_repeat and (5 - self.target_mod_offset) or 1                            end
        if self.selected_option < 1                          then self.selected_option = is_repeat and 1                            or (5 - self.target_mod_offset) end

        if old ~= self.selected_option then
            self.ui_move:stop()
            self.ui_move:play()
        end

        self.heart_target_x = 196
        self.heart_target_y = 238 + (self.selected_option - 1) * 32
    elseif self.state == "OPTIONS" then
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
        local old = self.selected_option
        if Input.is("up"   , key) then self.selected_option = self.selected_option - 1  end
        if Input.is("down" , key) then self.selected_option = self.selected_option + 1  end
        if Input.is("left" , key) then self.selected_option = self.selected_option - 1  end
        if Input.is("right", key) then self.selected_option = self.selected_option + 1  end
        if self.selected_option > 12 then self.selected_option = is_repeat and 12 or 1  end
        if self.selected_option < 1  then self.selected_option = is_repeat and 1  or 12 end

        local y_off = (self.selected_option - 1) * 32
        if self.selected_option >= 12 then
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

        if old ~= self.selected_option then
            self.ui_move:stop()
            self.ui_move:play()
        end

        if Input.isConfirm(key) then
            self.ui_select:stop()
            self.ui_select:play()
            if self.selected_option == 1 then
                self:setState("VOLUME")
                self.heart_target_x = 408
            elseif self.selected_option == 2 then
                self:setState("CONTROLS")
                self.rebinding = false
                self.selecting_key = false
                self.heart_target_x = 152
                self.heart_target_y = 129 + 0 * 32
                self.selected_option = 1
            elseif self.selected_option == 3 then
                Kristal.Config["simplifyVFX"] = not Kristal.Config["simplifyVFX"]
            elseif self.selected_option == 4 then
                self:setState("WINDOWSCALE")
                self.heart_target_x = 408
            elseif self.selected_option == 5 then
                Kristal.Config["fullscreen"] = not Kristal.Config["fullscreen"]
                love.window.setFullscreen(Kristal.Config["fullscreen"])
            elseif self.selected_option == 6 then
                Kristal.Config["autoRun"] = not Kristal.Config["autoRun"]
            elseif self.selected_option == 7 then
                Kristal.Config["skipIntro"] = not Kristal.Config["skipIntro"]
            elseif self.selected_option == 8 then
                Kristal.Config["showFPS"] = not Kristal.Config["showFPS"]
            elseif self.selected_option == 9 then
                Kristal.Config["debug"] = not Kristal.Config["debug"]
            elseif self.selected_option == 10 then
                Kristal.Config["systemCursor"] = not Kristal.Config["systemCursor"]
                Kristal.updateCursor()
            elseif self.selected_option == 11 then
                Kristal.Config["alwaysShowCursor"] = not Kristal.Config["alwaysShowCursor"]
                Kristal.updateCursor()
            elseif self.selected_option == 12 then
                self:setState("MAINMENU")
                self.heart_target_x = 196
                self.selected_option = 3
                self.heart_target_y = 238 + (2 * 32)
                Kristal.saveConfig()
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
    elseif self.state == "MODSELECT" then
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
                if self.selected_mod then
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

            if Input.is("up", key)    then self.list:selectUp(is_repeat)   end
            if Input.is("down", key)  then self.list:selectDown(is_repeat) end
            if Input.is("left", key)  then self.list:pageUp(is_repeat)     end
            if Input.is("right", key) then self.list:pageDown(is_repeat)   end
        end
    elseif self.state == "FILESELECT" then
        if not is_repeat then
            self.files:keypressed(key)
        end
    elseif self.state == "CREDITS" then
        if Input.isCancel(key) or Input.isConfirm(key) then
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
    elseif self.state == "CONTROLS" then
        if (not self.rebinding) and (not self.selecting_key) then
            local old = self.selected_option
            if Input.is("up"   , key) then self.selected_option = self.selected_option - 1 end
            if Input.is("down" , key) then self.selected_option = self.selected_option + 1 end
            if Input.is("left" , key) then self.selected_option = self.selected_option - 1 end
            if Input.is("right", key) then self.selected_option = self.selected_option + 1 end
            self.selected_option = math.max(1, math.min(Utils.tableLength(Input.aliases) + 2, self.selected_option))

            if old ~= self.selected_option then
                self.ui_move:stop()
                self.ui_move:play()
            end

            local y_off = (self.selected_option - 1) * 32
            if self.selected_option > (#Input.order + 1) then
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
                self.selected_option = 2
                self.ui_select:stop()
                self.ui_select:play()
                Input.saveBinds()
                self.heart_target_x = 152
                self.heart_target_y = 129 + 1 * 32
            elseif Input.isConfirm(key) then
                self.rebinding = false
                self.selecting_key = false
                if (self.selected_option == Utils.tableLength(Input.aliases) + 1) then
                    Input.loadBinds(true) -- reset binds
                    self.ui_select:stop()
                    self.ui_select:play()
                    self.selected_option = Utils.tableLength(Input.aliases) + 1
                    self.heart_target_y = (129 + (self.selected_option) * 32) + self.options_target_y
                elseif (self.selected_option == Utils.tableLength(Input.aliases) + 2) then
                    self:setState("OPTIONS")
                    self.selected_option = 2
                    self.ui_select:stop()
                    self.ui_select:play()
                    Input.saveBinds()
                    self.heart_target_x = 152
                    self.heart_target_y = 129 + 1 * 32
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
            self.selected_bind = math.max(1, math.min(#self:getKeysFromAlias(table_key), self.selected_bind))

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
            if key == "lshift" or key == "rshift" then
                self.rebinding_shift = true
            elseif key == "lctrl" or key == "rctrl" then
                self.rebinding_ctrl = true
            elseif key == "lalt" or key == "ralt" then
                self.rebinding_alt = true
            elseif key == "lgui" or key == "rgui" then
                self.rebinding_cmd = true
            else
                local bound_key
                if key ~= "escape" then
                    bound_key = {key}

                    -- https://ux.stackexchange.com/questions/58185/normative-ordering-for-modifier-key-combinations
                    if self.rebinding_cmd   then table.insert(bound_key, 1, "cmd"  ) end
                    if self.rebinding_shift then table.insert(bound_key, 1, "shift") end
                    if self.rebinding_alt   then table.insert(bound_key, 1, "alt"  ) end
                    if self.rebinding_ctrl  then table.insert(bound_key, 1, "ctrl" ) end

                    if #bound_key == 1 then
                        bound_key = bound_key[1]
                    end
                else
                    bound_key = "escape"
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
    else
        if Input.isCancel(key) or Input.isConfirm(key) then
            self:setState("OPTIONS")
            self.ui_move:stop()
            self.ui_move:play()
            self.heart_target_x = 152
            self.heart_target_y = 129 + (self.selected_option - 1) * 32
        end
    end
end

function Menu:keyreleased(key)
    if MOD_LOADING then return end
    if OVERLAY_OPEN then return end

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

function Menu:getKeysFromAlias(key)
    local keys = {}
    for _,k in ipairs(Input.getKeysFromAlias(key)) do
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

    -- Math
    self.animation_sine = self.animation_sine + (1 * dt_mult)

    if (self.background_alpha < 0.5) then
        self.background_alpha = self.background_alpha + (0.04 - (self.background_alpha / 14)) * dt_mult
    end

    if (self.background_alpha > 0.5) then
        self.background_alpha = 0.5
    end

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
        love.graphics.setColor(1, 1, 1, self.background_alpha * 0.8)
        love.graphics.draw(self.background_image_wave, 0, math.floor(-10 - (self.background_alpha * 20)))
        self.BACKGROUND_SHADER:send("sine_mul", -1)
        love.graphics.draw(self.background_image_wave, 0, math.floor(-10 - (self.background_alpha * 20)))
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.setShader()

        self:drawAnimStrip(self.background_image_animation, ( self.animation_sine / 12),        0, (((10 - (self.background_alpha * 20)) + 240) - 70), (self.background_alpha * 0.46))
        self:drawAnimStrip(self.background_image_animation, ((self.animation_sine / 12) + 0.4), 0, (((10 - (self.background_alpha * 20)) + 240) - 70), (self.background_alpha * 0.56))
        self:drawAnimStrip(self.background_image_animation, ((self.animation_sine / 12) + 0.8), 0, (((10 - (self.background_alpha * 20)) + 240) - 70), (self.background_alpha * 0.7))

        -- Reset canvas to draw to
        Draw.setCanvas(SCREEN_CANVAS)

        -- Draw the canvas on the screen scaled by 2x
        love.graphics.setColor(1, 1, 1, self.background_fade)
        love.graphics.draw(self.bg_canvas, 0, 0, 0, 2, 2)
    end

    -- Draw mod previews
    for k,v in pairs(self.list.mods) do
        local mod_preview = self.mod_fades[v.id]
        if v.mod and v.mod.preview and mod_preview.fade > 0 then
            -- Draw to the mod's preview canvas
            Draw.setCanvas(mod_preview.canvas)
            love.graphics.clear(0, 0, 0, 1)

            self:drawAnimStrip(v.mod.preview, ( self.animation_sine / 12),        0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.46))
            self:drawAnimStrip(v.mod.preview, ((self.animation_sine / 12) + 0.4), 0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.56))
            self:drawAnimStrip(v.mod.preview, ((self.animation_sine / 12) + 0.8), 0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.7))

            -- Draw canvas scaled 2x to the screen
            Draw.setCanvas(SCREEN_CANVAS)
            love.graphics.setColor(1, 1, 1, mod_preview.fade)
            love.graphics.draw(mod_preview.canvas, 0, 0, 0, 2, 2)
        end
        if v.preview_script and v.preview_script.draw then
            -- Draw from the mod's preview script
            love.graphics.push()
            v.preview_script:draw()
            love.graphics.pop()
        end
    end

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

return Menu