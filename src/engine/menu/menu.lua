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

Menu.INTRO_TEXT = {{1, 1, 1, 1}, "Welcome to Kristal,\nthe DELTARUNE fangame engine!\n\nAdd mods to the ", {1, 1, 0, 1}, "mods folder", {1, 1, 1, 1}, "\nto continue.\n\nPress (X) to return to the main menu."}

function Menu:enter()
    -- STATES: MAINMENU, MODSELECT, FILESELECT, OPTIONS, VOLUME, CONTROLS
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
    self.stage = Object()

    self.list = nil

    self.files = nil

    self.heart = Sprite("player/heart_menu")
    self.heart.visible = true
    self.heart:setOrigin(0.5, 0.5)
    self.heart.layer = 100
    self.stage:addChild(self.heart)

    self.heart_target_x = 196
    self.heart_target_y = 238

    -- Assets required for the menu
    self.menu_font = Assets.getFont("main")

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
    self.selecting_key = false
    self.selected_bind = 1

    self.noise_timer = 0
end

function Menu:setState(state)
    local old_state = self.state
    self.state = state
    self:onStateChange(old_state, self.state)
end

function Menu:onStateChange(old_state, new_state)
    if old_state == "MODSELECT" then
        --self.list:clearMods()
        --self.list:remove()
        --self.list = nil
        self.list.active = false
        self.list.visible = false
    elseif old_state == "FILESELECT" then
        self.files:remove()
    end
    if new_state == "MAINMENU" then
        self.selected_mod_button = nil
        self.selected_mod = nil
    elseif new_state == "MODSELECT" then
        if not self.list then
            self.list = ModList(69, 70, 502, 370)
            self.list.layer = 50
            self.stage:addChild(self.list)
            self:buildMods()
        else
            self.list.active = true
            self.list.visible = true
        end
    elseif new_state == "FILESELECT" then
        self.files = FileList(self, self.selected_mod)
        self.files.layer = 50
        self.stage:addChild(self.files)
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
                self.loading_mods = true
                self:reloadMods()
                self.last_loaded = mod_paths
            end
        end
    end
end

function Menu:reloadMods()
    if self.loading_mods then return end

    self.loading_mods = true
    Kristal.loadAssets("", "mods", "", function()
        self.loading_mods = false

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
    for _,mod in ipairs(Kristal.Mods.getMods()) do
        local button = ModButton(mod.name or mod.id, 424, 62, mod)

        if mod.preview then
            self.mod_fades[mod.id] = self.mod_fades[mod.id] or {fade = 0}
            if not self.mod_fades[mod.id].canvas then
                self.mod_fades[mod.id].canvas = love.graphics.newCanvas(320, 240)
            end
        end

        if mod.has_preview_lua then
            local chunk = love.filesystem.load(mod.path.."/preview.lua")
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
end

function Menu:drawAnimStrip(sprite, subimg, x, y, alpha)
    love.graphics.setColor(1, 1, 1, alpha)

    local index = #sprite > 1 and ((math.floor(subimg) % (#sprite - 1)) + 1) or 1

    love.graphics.draw(sprite[index], math.floor(x), math.floor(y))
end

function Menu:printShadow(text, x, y, color, center, limit)
    -- Draw the shadow, offset by two pixels to the bottom right
    love.graphics.setFont(self.menu_font)
    love.graphics.setColor({0, 0, 0, 1})
    love.graphics.printf(text, x + 2, y + 2, limit or self.menu_font:getWidth(text), center and "center" or "left")

    -- Draw the main text
    love.graphics.setColor(color or {1, 1, 1, 1})
    love.graphics.printf(text, x, y, limit or self.menu_font:getWidth(text), center and "center" or "left")
end

function Menu:update(dt)
    local mod_button, current_mod
    if self.list and self.state == "MODSELECT" then
        self.selected_mod_button = self.list:getSelected()
        self.selected_mod = self.list:getSelectedMod()
    end
    mod_button = self.selected_mod_button
    current_mod = self.selected_mod

    -- Update fade between previews
    if (current_mod and (current_mod.preview or mod_button.preview_script)) then
        if mod_button.preview_script and mod_button.preview_script.hide_background ~= false then
            self.background_fade = math.max(0, self.background_fade - (dt / 0.5))
        else
            self.background_fade = math.min(1, self.background_fade + (dt / 0.5))
        end
        for k,v in pairs(self.mod_fades) do
            if k == current_mod.id and v.fade < 1 then
                v.fade = math.min(1, v.fade + (dt / 0.5))
            elseif k ~= current_mod.id and v.fade > 0 then
                v.fade = math.max(0, v.fade - (dt / 0.5))
            end
        end
    else
        self.background_fade = math.min(1, self.background_fade + (dt / 0.5))
        for k,v in pairs(self.mod_fades) do
            if v.fade > 0 then
                v.fade = math.max(0, v.fade - (dt / 0.5))
            end
        end
    end

    -- Update preview scripts
    if self.list then
        for k,v in pairs(self.list.mods) do
            if v.preview_script then
                v.preview_script.fade = self.mod_fades[v.id].fade
                v.preview_script.selected = v.selected
                v.preview_script:update(dt)
            end
        end
    end

    -- Update the stage (mod menu)
    self.stage:update(dt)

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
            Game:setVolume(Game:getVolume() - ((2 * DTMULT) / 100))
            if self.noise_timer >= 3 then
                self.noise_timer = self.noise_timer - 3
                Assets.stopAndPlaySound("snd_noise")
            end
        end
        if Input.down("right") then
            Game:setVolume(Game:getVolume() + ((2 * DTMULT) / 100))
            if self.noise_timer >= 3 then
                self.noise_timer = self.noise_timer - 3
                Assets.stopAndPlaySound("snd_noise")
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
        self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * (dt * 30)
        self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * (dt * 30)
    end
end

function Menu:draw()
    -- Draw the menu background
    self:drawBackground()

    if self.state == "MAINMENU" then
        love.graphics.draw(self.logo, 160, 70)
        self:printShadow("Play a mod", 215, 219)
        self:printShadow("Open mods folder", 215, 219 + 32)
        self:printShadow("Options", 215, 219 + 64)
        self:printShadow("Credits", 215, 219 + 96)
    elseif self.state == "OPTIONS" or self.state == "VOLUME" then

        self:printShadow("( OPTIONS )", 0, 48, {1, 1, 1, 1}, true, 640)

        local menu_x = 185 - 14
        local menu_y = 110

        self:printShadow("Master Volume",  menu_x, menu_y + (32 * 0))
        self:printShadow("Controls",       menu_x, menu_y + (32 * 1))
        self:printShadow("Simplify VFX",   menu_x, menu_y + (32 * 2))
        self:printShadow("Fullscreen",     menu_x, menu_y + (32 * 3))
        self:printShadow("Auto-Run",       menu_x, menu_y + (32 * 4))
        self:printShadow("Skip Intro",     menu_x, menu_y + (32 * 5))
        self:printShadow("Display FPS",    menu_x, menu_y + (32 * 6))
        self:printShadow("Debug Hotkeys",  menu_x, menu_y + (32 * 7))
        self:printShadow("Back",           menu_x, menu_y + (32 * 9))

        self:printShadow(Utils.round(Game:getVolume() * 100) .. "%",  menu_x + (8 * 32), menu_y + (32 * 0))
        self:printShadow(Kristal.Config["simplifyVFX"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 2))
        self:printShadow(Kristal.Config["fullscreen"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 3))
        self:printShadow(Kristal.Config["autoRun"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 4))
        self:printShadow(Kristal.Config["skipIntro"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 5))
        self:printShadow(Kristal.Config["showFPS"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 6))
        self:printShadow(Kristal.Config["debug"] and "ON" or "OFF", menu_x + (8 * 32), menu_y + (32 * 7))
    elseif self.state == "CONTROLS" then
        self:printShadow("( CONTROLS )", 0, 48, {1, 1, 1, 1}, true, 640)

        local menu_x = 185 - 14
        local menu_y = 110

        local y_offset = 0

        for index, name in ipairs(Input.order) do
            self:printShadow(name:upper(),  menu_x, menu_y + (32 * y_offset))

            self:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
            y_offset = y_offset + 1
        end

        for name, value in pairs(Input.aliases) do
            if not Utils.containsValue(Input.order, name) then
                self:printShadow(name:upper(),  menu_x, menu_y + (32 * y_offset))

                self:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
                --self:printShadow(Utils.titleCase(value[1]),    menu_x + (8 * 32), menu_y + (32 * y_offset))
                y_offset = y_offset + 1
            end
        end

        self:printShadow("Reset to defaults",  menu_x, menu_y + (32 * y_offset))
        self:printShadow("Back",  menu_x, menu_y + (32 * (y_offset + 1)))

    elseif self.state == "MODSELECT" then
        -- Draw introduction text if no mods exist

        if self.loading_mods then
            self:printShadow("Loading mods...", 0, 115 - 8, {1, 1, 1, 1}, true, 640)
        else
            if #self.list.mods == 0 then
                self.heart_target_x = -8
                self.heart_target_y = -8
                self.list.active = false
                self.list.visible = false
                self:printShadow(Menu.INTRO_TEXT, 0, 115 - 8, {1, 1, 1, 1}, true, 640)
            else
                -- Draw some menu text
                self:printShadow("Choose your world.", 80, 34 - 8, {1, 1, 1, 1})
                self:printShadow("(X) Return to main menu", 294 + (16 * 3), 454 - 8, {1, 1, 1, 1})
            end
        end
    elseif self.state == "FILESELECT" then
        local mod_name = string.upper(self.selected_mod.name or self.selected_mod.id)
        self:printShadow(mod_name, 16, 8, {1, 1, 1, 1})
    elseif self.state == "CREDITS" then
        self:printShadow("( OPTIONS )", 0, 48, {1, 1, 1, 1}, true, 640)
        self:printShadow("It just... showed up one day.", 0, 240 - 8 - 16, {1, 1, 1, 1}, true, 640)
        self:printShadow("(Not really. Real page soon.)", 0, 240 - 8 + 16, {0.7, 0.7, 0.7, 1}, true, 640)
    else
        self:printShadow("Nothing here for now!", 0, 240 - 8, {1, 1, 1, 1}, true, 640)
    end

    -- Draw mod preview overlays
    if self.list then
        for k,v in pairs(self.list.mods) do
            if v.preview_script and v.preview_script.drawOverlay then
                love.graphics.push()
                v.preview_script:drawOverlay()
                love.graphics.pop()
            end
        end
    end

    self.stage:draw()

    -- Draw the screen fade
    love.graphics.setColor(0, 0, 0, self.fader_alpha)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    -- Change the fade opacity for the next frame
    self.fader_alpha = math.max(0,self.fader_alpha - (0.08 * (DT * 30)))

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
    local x_offset = 0
    if self.selected_option == (y_offset + 1) then
        for i, v in ipairs(self:getKeysFromAlias(name)) do
            local drawstr = Utils.titleCase(v)
            if i < #self:getKeysFromAlias(name) then
                drawstr = drawstr .. ", "
            end
            if i < self.selected_bind then
                x_offset = x_offset - self.menu_font:getWidth(drawstr) - 8
            end
        end
    end
    Draw.pushScissor()
    Draw.scissor(380, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    for i, v in ipairs(self:getKeysFromAlias(name)) do
        local drawstr = Utils.titleCase(v)
        if i < #self:getKeysFromAlias(name) then
            drawstr = drawstr .. ", "
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
            end
        end
        self:printShadow(drawstr, menu_x + (8 * 32) + x_offset, menu_y + (32 * y_offset), color)
        x_offset = x_offset + self.menu_font:getWidth(drawstr) + 8
    end
    Draw.popScissor()
end

function Menu:keypressed(key, _, is_repeat)
    if MOD_LOADING then return end

    if self.state == "MAINMENU" then
        if Input.isConfirm(key) then
            self.ui_select:stop()
            self.ui_select:play()
            if self.selected_option == 1 then
                self:setState("MODSELECT")
            elseif self.selected_option == 2 then
                love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/mods")
            elseif self.selected_option == 3 then
                self.heart_target_x = 152
                self.heart_target_y = 129
                self.selected_option = 1
                self:setState("OPTIONS")
            elseif self.selected_option == 4 then
                self.heart_target_x = -8
                self.heart_target_y = -8
                self:setState("CREDITS")
            end
            return
        end
        local old = self.selected_option
        if Input.is("up"   , key) then self.selected_option = self.selected_option - 1 end
        if Input.is("down" , key) then self.selected_option = self.selected_option + 1 end
        if Input.is("left" , key) then self.selected_option = self.selected_option - 1 end
        if Input.is("right", key) then self.selected_option = self.selected_option + 1 end
        self.selected_option = math.max(1, math.min(4, self.selected_option))

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
            self.selected_option = 3
            self.heart_target_y = 238 + (2 * 32)
            Kristal.saveConfig()
            return
        end
        local old = self.selected_option
        if Input.is("up"   , key) then self.selected_option = self.selected_option - 1 end
        if Input.is("down" , key) then self.selected_option = self.selected_option + 1 end
        if Input.is("left" , key) then self.selected_option = self.selected_option - 1 end
        if Input.is("right", key) then self.selected_option = self.selected_option + 1 end
        self.selected_option = math.max(1, math.min(9, self.selected_option))

        local y_off = (self.selected_option - 1) * 32
        if self.selected_option >= 9 then
            y_off = y_off + 32
        end

        self.heart_target_x = 152
        self.heart_target_y = 129 + y_off

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
                Kristal.Config["fullscreen"] = not Kristal.Config["fullscreen"]
                love.window.setFullscreen(Kristal.Config["fullscreen"])
            elseif self.selected_option == 5 then
                Kristal.Config["autoRun"] = not Kristal.Config["autoRun"]
            elseif self.selected_option == 6 then
                Kristal.Config["skipIntro"] = not Kristal.Config["skipIntro"]
            elseif self.selected_option == 7 then
                Kristal.Config["showFPS"] = not Kristal.Config["showFPS"]
            elseif self.selected_option == 8 then
                Kristal.Config["debug"] = not Kristal.Config["debug"]
            elseif self.selected_option == 9 then
                self:setState("MAINMENU")
                self.heart_target_x = 196
                self.selected_option = 3
                self.heart_target_y = 238 + (2 * 32)
                Kristal.saveConfig()
            end
        end
    elseif self.state == "VOLUME" then
        if Input.isCancel(key) or Input.isConfirm(key) then
            Game:setVolume(Utils.round(Game:getVolume() * 100) / 100)
            self:setState("OPTIONS")
            self.ui_select:stop()
            self.ui_select:play()
            self.heart_target_x = 152
            self.heart_target_y = 129 + (self.selected_option - 1) * 32
        end
    elseif self.state == "MODSELECT" then
        if key == "f5" then
            self.ui_select:stop()
            self.ui_select:play()
            self:reloadMods()
        end

        if #self.list.mods > 0 then
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
            elseif Input.isCancel(key) then
                self:setState("MAINMENU")
                self.ui_move:stop()
                self.ui_move:play()
                self.heart_target_x = 196
                self.heart_target_y = 238
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
            self.ui_move:stop()
            self.ui_move:play()
            self.heart_target_x = 196
            self.selected_option = 4
            self.heart_target_y = 238 + (3 * 32)
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

            self.heart_target_x = 152
            self.heart_target_y = 129 + (self.selected_option - 1) * 32

            if Input.isConfirm(key) then
                self.rebinding = false
                self.selecting_key = false
                if (self.selected_option == Utils.tableLength(Input.aliases) + 1) then
                    Input.loadBinds(true) -- reset binds
                    self.ui_select:stop()
                    self.ui_select:play()
                    self.selected_option = Utils.tableLength(Input.aliases) + 1
                    self.heart_target_y = 129 + (self.selected_option - 1) * 32
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
            -- rebind!!
            local worked = Input.setBind(Input.orderedNumberToKey(self.selected_option), self.selected_bind, key)

            self.rebinding = false
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

function Menu:getKeysFromAlias(key)
    if (self.rebinding or self.selecting_key) and (key == Input.orderedNumberToKey(self.selected_option)) then
        local temp = Utils.copy(Input.getKeysFromAlias(key))
        table.insert(temp, "---")
        return temp
    end
    return Input.getKeysFromAlias(key)
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

    -- Draw mod previews
    if self.list then
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
    end

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

return Menu