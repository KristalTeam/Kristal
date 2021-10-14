local Menu = {}

Menu.TEST_MOD_LIST = false

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

Menu.INTRO_TEXT = {{1, 1, 1, 1}, "Welcome to Kristal,\nthe DELTARUNE fangame engine!\n\nAdd mods to the ", {1, 1, 0, 1}, "mods folder", {1, 1, 1, 1}, "\nto continue.\n\nPress (X) to open the mods folder\nPress (C) to open the options menu"}

function Menu:enter()
    print("i am so gay")

    love.keyboard.setKeyRepeat(true)

    -- Load menu music
    self.music = love.audio.newSource("assets/music/mod_menu.ogg", "stream")
    self.music:setVolume(1)
    self.music:setPitch(0.95)
    self.music:setLooping(true)
    self.music:play()

    self.ui_move = love.audio.newSource("assets/sounds/ui_move.wav", "static")
    self.ui_select = love.audio.newSource("assets/sounds/ui_select.wav", "static")

    -- Initialize variables for the background animation
    self.fader_alpha = 1
    self.animation_sine = 0
    self.background_alpha = 0

    -- Assets required for the background animation
    self.background_image_wave = Assets.getTexture("kristal/title_bg_wave")
    self.background_image_animation = Assets.getFrames("kristal/title_bg_anim")

    -- Initialize variables for the menu
    self.stage = Object()

    self.list = ModList(104, 70, 432, 370)
    self.stage:addChild(self.list)

    self.heart = Sprite("player/heart_menu")
    self.heart.visible = false
    self.heart:setOrigin(0.5, 0.5)
    self.stage:addChild(self.heart)

    self.heart_target_x = 0
    self.heart_target_y = 0
    self.heart_locked_x = nil
    self.heart_locked_y = nil

    -- Assets required for the menu
    self.menu_font = Assets.getFont("main")

    -- Preview fading stuff
    self.background_fade = 1
    self.mod_fades = {}

    -- Load the mods
    self.loading_mods = false
    self.last_loaded = nil
    self:buildMods()
end

function Menu:leave()
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
    if not self.loading_mods and not self.TEST_MOD_LIST then
        local mod_paths = love.filesystem.getDirectoryItems("mods")
        if not Utils.equal(mod_paths, self.last_loaded) then
            self.loading_mods = true
            self:reloadMods()
            self.last_loaded = mod_paths
        end
    end
end

function Menu:reloadMods()
    if self.loading_mods then return end

    self.loading_mods = true
    Kristal.LoadAssets("", "mods", "", function()
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
    if self.TEST_MOD_LIST then
        for i = 1,15 do
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

        if mod.preview_lua then
            local chunk = love.filesystem.load(mod.path.."/"..mod.preview_lua)
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
    love.graphics.setColor(color)
    love.graphics.printf(text, x, y, limit or self.menu_font:getWidth(text), center and "center" or "left")
end

function Menu:calculateMenuItemPosition(i, offset)
    return (74 + ((62 + 8) * (i - 1)) + offset)
end

function Menu:update(dt)
    local mod_button = self.list:getSelected()
    local current_mod = mod_button and mod_button.mod

    -- Update fade between previews
    if current_mod and (current_mod.preview or mod_button.preview_script) then
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
    for k,v in pairs(self.list.mods) do
        if v.preview_script then
            v.preview_script.fade = self.mod_fades[v.id].fade
            v.preview_script.selected = v.selected
            v.preview_script:update(dt)
        end
    end

    -- Update the stage (mod menu)
    self.stage:update(dt)

    -- Move the heart closer to the target 
    if not mod_button then
        self.heart.visible = false
    else
        local button_heart_x, button_heart_y = mod_button:getRelativePos(self.list, mod_button:getHeartPos())
        self.heart_target_x = self.list.x + button_heart_x
        self.heart_target_y = self.list.y + button_heart_y - (self.list.scroll_target - self.list.scroll)
        if not self.heart.visible then
            self.heart.visible = true
            self.heart:setPosition(self.heart_target_x, self.heart_target_y)
        else
            if (math.abs((self.heart_target_x - self.heart.x)) <= 2) or self.heart_locked_x == mod_button then
                self.heart.x = self.heart_target_x
                self.heart_locked_x = mod_button
            else
                self.heart_locked_x = nil
            end
            if (math.abs((self.heart_target_y - self.heart.y)) <= 2) or self.heart_locked_y == mod_button then
                self.heart.y = self.heart_target_y
                self.heart_locked_y = mod_button
            else
                self.heart_locked_y = nil
            end
            self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * (dt * 30)
            self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * (dt * 30)
        end
    end
end

function Menu:draw()
    -- Draw the menu background
    self:drawBackground()

    -- Draw introduction text if no mods exist
    if #self.list.mods == 0 then
        Menu:printShadow(Menu.INTRO_TEXT, 0, 115 - 8, {1, 1, 1, 1}, true, 640)
    else
        -- Draw some menu text
        Menu:printShadow("Choose your world.", 80, 34 - 8, {1, 1, 1, 1})
        Menu:printShadow("(X) Mods Folder   (C) Options", 294, 454 - 8, {1, 1, 1, 1})

        -- Draw the stage (mod menu, heart)
        self.stage:draw()
    end

    -- Draw mod preview overlays
    for k,v in pairs(self.list.mods) do
        if v.preview_script and v.preview_script.drawOverlay then
            love.graphics.push()
            v.preview_script:drawOverlay()
            love.graphics.pop()
        end
    end

    -- Draw the screen fade
    love.graphics.setColor(0, 0, 0, self.fader_alpha)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    -- Change the fade opacity for the next frame
    self.fader_alpha = math.max(0,self.fader_alpha - (0.08 * (DT * 30)))

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu:keypressed(key, _, is_repeat)
    if MOD_LOADING then return end

    if key == "f5" then
        self:reloadMods()
    end

    if key == "x" then
        self.ui_select:stop()
        self.ui_select:play()
        love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/mods")
    end

    if #self.list.mods > 0 then
        if key == "z" then
            self.ui_select:stop()
            self.ui_select:play()

            local current_mod = self.list:getSelectedMod()
            if current_mod then
                if current_mod.transition then
                    Kristal.LoadAssets(current_mod.path, "sprites", Kristal.States["DarkTransition"].SPRITE_DEPENDENCIES, function()
                        Gamestate.switch(Kristal.States["DarkTransition"], current_mod)
                    end)
                else
                    Kristal.LoadMod(current_mod.id)
                end
            end
            return
        end

        if key == "up"    then self.list:selectUp(is_repeat)   end
        if key == "down"  then self.list:selectDown(is_repeat) end
        if key == "left"  then self.list:pageUp(is_repeat)     end
        if key == "right" then self.list:pageDown(is_repeat)   end
    end
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
    love.graphics.setCanvas(self.bg_canvas)
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
    love.graphics.setCanvas(SCREEN_CANVAS)

    -- Draw the canvas on the screen scaled by 2x
    love.graphics.setColor(1, 1, 1, self.background_fade)
    love.graphics.draw(self.bg_canvas, 0, 0, 0, 2, 2)

    -- Draw mod previews
    for k,v in pairs(self.list.mods) do
        local mod_preview = self.mod_fades[v.id]
        if v.mod and v.mod.preview and mod_preview.fade > 0 then
            -- Draw to the mod's preview canvas
            love.graphics.setCanvas(mod_preview.canvas)
            love.graphics.clear(0, 0, 0, 1)

            self:drawAnimStrip(v.mod.preview, ( self.animation_sine / 12),        0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.46))
            self:drawAnimStrip(v.mod.preview, ((self.animation_sine / 12) + 0.4), 0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.56))
            self:drawAnimStrip(v.mod.preview, ((self.animation_sine / 12) + 0.8), 0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.7))

            -- Draw canvas scaled 2x to the screen
            love.graphics.setCanvas(SCREEN_CANVAS)
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