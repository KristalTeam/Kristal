---@class MainMenu
local MainMenu = {}

MainMenu.BACKGROUND_SHADER = love.graphics.newShader([[
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

function MainMenu:init()
end

function MainMenu:enter()
    -- Load menu music
    self.music = Music() -- "mod_menu", 1, 0.95

    Kristal.showBorder(0.5)

    -- Initialize variables for the background animation
    self.fader_alpha = 1
    self.animation_sine = 0
    self.background_alpha = 0

    -- Assets required for the background animation
    self.background_image_wave = Assets.getTexture("kristal/title_bg_wave")
    self.background_image_animation = Assets.getFrames("kristal/title_bg_anim")

    -- Initialize variables for the menu
    self.stage = Stage()

    -- Initialize all states
    self.title_screen = MainMenuTitle(self)
    self.options = MainMenuOptions(self)
    self.credits = MainMenuCredits(self)
    self.mod_list = MainMenuModList(self)
    self.mod_create = MainMenuModCreate(self)
    self.mod_config = MainMenuModConfig(self)
    self.mod_error = MainMenuModError(self)
    self.file_select = MainMenuFileSelect(self)
    self.file_name_screen = MainMenuFileName(self)
    self.default_name_screen = MainMenuDefaultName(self)
    self.controls = MainMenuControls(self)
    self.deadzone_config = MainMenuDeadzone(self)

    -- Register states
    self.state = "NONE"
    self.state_manager = StateManager("NONE", self, true)
    self.state_manager:addState("TITLE", self.title_screen)
    self.state_manager:addState("OPTIONS", self.options)
    self.state_manager:addState("CREDITS", self.credits)
    self.state_manager:addState("MODSELECT", self.mod_list)
    self.state_manager:addState("MODCREATE", self.mod_create)
    self.state_manager:addState("MODCONFIG", self.mod_config)
    self.state_manager:addState("MODERROR", self.mod_error)
    self.state_manager:addState("FILESELECT", self.file_select)
    self.state_manager:addState("FILENAME", self.file_name_screen)
    self.state_manager:addState("DEFAULTNAME", self.default_name_screen)
    self.state_manager:addState("CONTROLS", self.controls)
    self.state_manager:addState("DEADZONE", self.deadzone_config)

    self.fader = Fader()
    self.fader.layer = 10000
    self.stage:addChild(self.fader)

    self.heart = Sprite("player/heart_menu")
    self.heart.visible = true
    self.heart:setOrigin(0.5, 0.5)
    self.heart:setScale(2, 2)
    self.heart:setColor(Kristal.getSoulColor())
    self.heart.layer = 100
    self.stage:addChild(self.heart)

    self.heart_outline = Sprite("player/heart_menu_outline", self.heart.width / 2, self.heart.height / 2)
    self.heart_outline.visible = false
    self.heart_outline:setOrigin(0.5, 0.5)
    self.heart:addChild(self.heart_outline)

    self.heart_target_x = 0
    self.heart_target_y = 0

    -- Assets required for the menu
    self.menu_font = Assets.getFont("main")
    self.small_font = Assets.getFont("main", 16)

    self.background_fade = 1

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
        self:setState("TITLE")
    end

    Kristal.setPresence({
        state = "In the menu",
        details = "Main menu",
        largeImageKey = "logo",
        largeImageText = "Kristal v" .. tostring(Kristal.Version),
        startTimestamp = os.time(),
        instance = 1
    })
end

function MainMenu:leave()
    self.music:remove()
    for _, v in pairs(self.mod_list.music) do
        v:remove()
    end
end

function MainMenu:focus()
    if not TARGET_MOD and not self.mod_list.loading_mods then
        local mod_paths = love.filesystem.getDirectoryItems("mods")
        if not Utils.equal(mod_paths, self.mod_list.last_loaded) then
            self.mod_list:reloadMods()
            self.mod_list.last_loaded = mod_paths
        end
    end
end

function MainMenu:onKeyPressed(key, is_repeat)
    if MOD_LOADING then return end

    if self.state ~= "CONTROLS" then
        if not Input.shouldProcess(key, true) then
            return
        end
    end

    -- Check input for the current state
    self.state_manager:call("keypressed", key, is_repeat)
end

function MainMenu:onKeyReleased(key)
    if MOD_LOADING then return end

    -- Check input for the current state
    self.state_manager:call("keyreleased", key)
end

function MainMenu:update()
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
        for k, v in pairs(self.mod_list.fades) do
            if k == mod.id and v < 1 then
                self.mod_list.fades[k] = math.min(1, v + (DT / 0.5))
            elseif k ~= mod.id and v > 0 then
                self.mod_list.fades[k] = math.max(0, v - (DT / 0.5))
            end
        end
    else
        self.background_fade = math.min(1, self.background_fade + (DT / 0.5))
        for k, v in pairs(self.mod_list.fades) do
            if v > 0 then
                self.mod_list.fades[k] = math.max(0, v - (DT / 0.5))
            end
        end
    end

    -- Update preview music fading
    if not TARGET_MOD then
        local fade_waiting = false
        for k, v in pairs(self.mod_list.music) do
            if v.started and v.volume > (self.mod_list.music_options[k].volume * 0.1) then
                fade_waiting = true
                break
            end
        end

        if mod and self.mod_list.music[mod.id] then
            local mod_music = self.mod_list.music[mod.id]
            local options = self.mod_list.music_options[mod.id]

            if not mod_music.started and not fade_waiting and self.music.volume == 0 then
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

        for k, v in pairs(self.mod_list.music) do
            if (not mod or k ~= mod.id) and v.started then
                if not v:isPlaying() then
                    v:stop()
                elseif self.mod_list.music_options[k].pause then
                    v:fade(0, 0.5, function (music) music:pause() end)
                else
                    v:fade(0, 0.5, function (music) music:stop() end)
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
    for k, v in pairs(self.mod_list.scripts) do
        v.fade = self.mod_list.fades[k]
        v.selected = self.mod_list:getSelectedButton() == mod_button
        if v.update then
            local success, msg = pcall(v.update, v)
            if not success then
                Kristal.Console:warn("preview.lua error in " .. Kristal.Mods.getMod(k).name .. ": " .. msg)
                self.mod_list.scripts[k] = nil
            end
        end
    end

    -- Update the stage (mod menu)
    self.stage:update()

    -- Update the current state
    self.state_manager:update()

    -- Move the heart closer to the target
    if self.heart.visible then
        if (math.abs((self.heart_target_x - self.heart.x)) <= 2) then
            self.heart.x = self.heart_target_x
        end
        if (math.abs((self.heart_target_y - self.heart.y)) <= 2) then
            self.heart.y = self.heart_target_y
        end
        self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * DTMULT
        self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * DTMULT
    end
end

function MainMenu:draw()
    -- Draw the menu background
    self:drawBackground()

    -- Draw the engine version
    self:drawVersion()

    -- Draw the current state
    love.graphics.push()
    self.state_manager:draw()
    love.graphics.pop()

    -- Draw mod preview overlays
    for modid, script in pairs(self.mod_list.scripts) do
        if script.drawOverlay then
            love.graphics.push()
            local success, msg = pcall(script.drawOverlay, script)
            if not success then
                Kristal.Console:warn("preview.lua error in " .. Kristal.Mods.getMod(modid).name .. ": " .. msg)
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
    self.fader_alpha = math.max(0, self.fader_alpha - (0.08 * DTMULT))

    -- Reset the draw color
    Draw.setColor(1, 1, 1, 1)
end

function MainMenu:drawBackground()
    -- This code was originally 30 fps, so we need a deltatime variable to multiply some values by
    local dt_mult = DT * 30

    if not (TARGET_MOD and self.selected_mod.preview) then
        -- We need to draw the background on a canvas
        local bg_canvas = Draw.pushCanvas(320, 240)
        love.graphics.clear(0, 0, 0, 1)

        -- Set the shader to use
        love.graphics.setShader(self.BACKGROUND_SHADER)
        self.BACKGROUND_SHADER:send("bg_sine", self.animation_sine)
        self.BACKGROUND_SHADER:send("bg_mag", 6)
        self.BACKGROUND_SHADER:send("wave_height", 240)
        self.BACKGROUND_SHADER:send("texsize",
            { self.background_image_wave:getWidth(), self.background_image_wave:getHeight() })

        self.BACKGROUND_SHADER:send("sine_mul", 1)
        Draw.setColor(1, 1, 1, self.background_alpha * 0.8)
        Draw.draw(self.background_image_wave, 0, math.floor(-10 - (self.background_alpha * 20)))
        self.BACKGROUND_SHADER:send("sine_mul", -1)
        Draw.draw(self.background_image_wave, 0, math.floor(-10 - (self.background_alpha * 20)))
        Draw.setColor(1, 1, 1, 1)

        love.graphics.setShader()

        self:drawAnimStrip(self.background_image_animation, (self.animation_sine / 12), 0,
            (((10 - (self.background_alpha * 20)) + 240) - 70), (self.background_alpha * 0.46))
        self:drawAnimStrip(self.background_image_animation, ((self.animation_sine / 12) + 0.4), 0,
            (((10 - (self.background_alpha * 20)) + 240) - 70), (self.background_alpha * 0.56))
        self:drawAnimStrip(self.background_image_animation, ((self.animation_sine / 12) + 0.8), 0,
            (((10 - (self.background_alpha * 20)) + 240) - 70), (self.background_alpha * 0.7))

        -- Reset canvas to draw to
        Draw.popCanvas()

        -- Draw the canvas on the screen scaled by 2x
        Draw.setColor(1, 1, 1, self.background_fade)
        Draw.draw(bg_canvas, 0, 0, 0, 2, 2)
    end

    -- Draw mod previews
    for _, mod in ipairs(self.mod_list.mods) do
        local fade = self.mod_list.fades[mod.id]
        if mod.preview and fade > 0 then
            -- Draw to mod's preview to a small canvas
            local canvas = Draw.pushCanvas(320, 240, { clear = false })
            love.graphics.clear(0, 0, 0, 1)

            self:drawAnimStrip(mod.preview, (self.animation_sine / 12), 0, (10 - (self.background_alpha * 20)),
                (self.background_alpha * 0.46))
            self:drawAnimStrip(mod.preview, ((self.animation_sine / 12) + 0.4), 0, (10 - (self.background_alpha * 20)),
                (self.background_alpha * 0.56))
            self:drawAnimStrip(mod.preview, ((self.animation_sine / 12) + 0.8), 0, (10 - (self.background_alpha * 20)),
                (self.background_alpha * 0.7))

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
                Kristal.Console:warn("preview.lua error in " .. mod.name .. ": " .. msg)
                self.mod_list.scripts[mod.id] = nil
            end
            love.graphics.pop()
        end
    end

    -- Reset the draw color
    Draw.setColor(1, 1, 1, 1)
end

function MainMenu:drawAnimStrip(sprite, subimg, x, y, alpha)
    Draw.setColor(1, 1, 1, alpha)

    local index = #sprite > 1 and ((math.floor(subimg) % (#sprite - 1)) + 1) or 1

    Draw.draw(sprite[index], math.floor(x), math.floor(y))
end

function MainMenu:shouldDrawVersion()
    return
        self.state ~= "CONTROLS" and
        self.state ~= "MODCREATE" and
        self.state ~= "MODCONFIG"
end

function MainMenu:drawVersion()
    if not self:shouldDrawVersion() then
        return
    end

    local ver_y = SCREEN_HEIGHT - self.small_font:getHeight()

    if not TARGET_MOD then
        local ver_string = self.ver_string
        if self.state == "TITLE" and Kristal.Version.major == 0 then
            ver_string = ver_string .. " (Unstable)"
        end

        love.graphics.setFont(self.small_font)
        Draw.setColor(1, 1, 1, 0.5)
        love.graphics.print(ver_string, 4, ver_y)

        if self.selected_mod then
            local compatible, mod_version = self.mod_list:checkCompatibility()
            if not compatible then
                Draw.setColor(1, 0.5, 0.5, 0.75)
                local op = "/"
                if Kristal.Version < mod_version then
                    op = "<"
                elseif Kristal.Version > mod_version then
                    op = ">"
                end
                love.graphics.print(" " .. op .. " v" .. tostring(mod_version), 4 + self.small_font:getWidth(ver_string),
                    ver_y)
            end
        end
    else
        local full_ver = "Kristal: " .. self.ver_string

        if self.selected_mod.version then
            ver_y = ver_y - self.small_font:getHeight()
            full_ver = self.selected_mod.name .. ": " .. self.selected_mod.version .. "\n" .. full_ver
        end

        love.graphics.setFont(self.small_font)
        Draw.setColor(1, 1, 1, 0.5)
        love.graphics.print(full_ver, 4, ver_y)
    end

    Draw.setColor(1, 1, 1)
    love.graphics.setFont(self.menu_font)
end

function MainMenu:setState(state, ...)
    self.state_manager:setState(state, ...)
end

function MainMenu:pushState(state, ...)
    self.state_manager:pushState(state, ...)
end

function MainMenu:popState()
    self.state_manager:popState()
end

return MainMenu
