local menu = {}

menu.TEST_MOD_LIST = false

menu.BACKGROUND_SHADER = love.graphics.newShader([[
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

menu.INTRO_TEXT = {{1, 1, 1, 1}, "Welcome to Kristal,\nthe DELTARUNE fangame engine!\n\nAdd mods to the ", {1, 1, 0, 1}, "mods folder", {1, 1, 1, 1}, "\nto continue.\n\nPress (X) to open the mods folder\nPress (C) to open the options menu"}

function menu:enter()
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
    self.background_image_wave = kristal.assets.getTexture("kristal/title_bg_wave")
    self.background_image_animation = {
        kristal.assets.getTexture("kristal/title_bg_anim_0"),
        kristal.assets.getTexture("kristal/title_bg_anim_1"),
        kristal.assets.getTexture("kristal/title_bg_anim_2"),
        kristal.assets.getTexture("kristal/title_bg_anim_3"),
        kristal.assets.getTexture("kristal/title_bg_anim_4")
    }

    -- Initialize variables for the menu
    self.menu_offset_target = 0
    self.menu_offset = 0

    self.heart_target_x = 108 + 20
    self.heart_target_y = menu:calculateMenuItemPosition(1, 0) + 22
    self.heart_x = self.heart_target_x
    self.heart_y = self.heart_target_y

    -- Assets required for the menu
    self.menu_heart = kristal.assets.getTexture("player/heart_menu")
    self.menu_font = kristal.assets.getFont("main")

    -- Preview fading stuff
    self.background_fade = 1
    self.mod_fades = {}

    -- Load the mods
    self:loadMods()
    self.selected = 1
end

function menu:leave()
    self.music:stop()
end

function menu:drawMenuRectangle(x, y, width, height, color)
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

function menu:init()
    -- We'll draw the background on a canvas, then resize it 2x
    self.bg_canvas = love.graphics.newCanvas(320,240)
    -- No filtering
    self.bg_canvas:setFilter("nearest", "nearest")
end

function menu:focus()
    self:loadMods()
    self.selected = math.min(math.max(self.selected, 1), #self.mods)
end

function menu:loadMods()
    if self.TEST_MOD_LIST then
        self.mods = {}
        for i = 1,15 do
            table.insert(self.mods, {name = "Example Mod "..i})
        end
        return
    end
    self.mods = {}
    for _,path in ipairs(love.filesystem.getDirectoryItems("mods")) do
        local full_path = "mods/"..path
        local hidden = false
        local mod = {name = path, path = path}
        if love.filesystem.getInfo(full_path.."/mod.json") then
            local info = lib.json.decode(love.filesystem.read(full_path.."/mod.json"))
            mod.name = info.name or path
            hidden = info.hidden
        end
        if love.filesystem.getInfo(full_path.."/preview.png") then
            mod.preview = {love.graphics.newImage(full_path.."/preview.png")}
        else
            local i = 0
            local preview = {}
            while love.filesystem.getInfo(full_path.."/preview_"..i..".png") do
                table.insert(preview, love.graphics.newImage(full_path.."/preview_"..i..".png"))
                i = i + 1
            end
            if #preview > 0 then
                mod.preview = preview
            end
            self.mod_fades[mod] = self.mod_fades[mod] or {fade = 0}
            if not self.mod_fades[mod].canvas then
                self.mod_fades[mod].canvas = love.graphics.newCanvas(320, 240)
            end
        end
        if love.filesystem.getInfo(full_path.."/preview.lua") then
            local chunk = love.filesystem.load(full_path.."/preview.lua")
            local success, result = pcall(chunk, full_path)
            if success then
                self.mod_fades[mod] = self.mod_fades[mod] or {fade = 0}
                mod.preview_script = result
                if mod.preview_script.init then
                    mod.preview_script:init()
                end
            else
                print("preview.lua error in "..mod.name..": "..result)
            end
        end
        if love.filesystem.getInfo(full_path.."/preview.lua") then
            local chunk = love.filesystem.load(full_path.."/preview.lua")
            local success, result = pcall(chunk, full_path)
            if success then
                self.mod_fades[mod] = self.mod_fades[mod] or {fade = 0}
                mod.preview_script = result
                if mod.preview_script.init then
                    mod.preview_script:init()
                end
            else
                print("preview.lua error in "..mod.name..": "..result)
            end
        end
        if not hidden then
            table.insert(self.mods, mod)
        end
    end
end

function menu:drawAnimStrip(sprite, subimg, x, y, alpha)
    love.graphics.setColor(1, 1, 1, alpha)

    local index = (math.floor(subimg) % (#sprite - 1)) + 1

    love.graphics.draw(sprite[index], math.floor(x), math.floor(y))
end

function menu:printShadow(text, x, y, color, center, limit)
    -- Draw the shadow, offset by two pixels to the bottom right
    love.graphics.setFont(self.menu_font)
    love.graphics.setColor({0, 0, 0, 1})
    love.graphics.printf(text, x + 2, y + 2, limit or self.menu_font:getWidth(text), center and "center" or "left")

    -- Draw the main text
    love.graphics.setColor(color)
    love.graphics.printf(text, x, y, limit or self.menu_font:getWidth(text), center and "center" or "left")
end

function menu:calculateMenuItemPosition(i, offset)
    return (74 + ((62 + 8) * (i - 1)) + offset)
end

function menu:update(dt)
    -- Update fade between previews
    local current_mod = self.mods[self.selected]
    if current_mod and (current_mod.preview or current_mod.preview_script) then
        if current_mod.preview_script and current_mod.preview_script.hide_background ~= false then
            self.background_fade = math.max(0, self.background_fade - (dt / 0.5))
        else
            self.background_fade = math.min(1, self.background_fade + (dt / 0.5))
        end
        for k,v in pairs(self.mod_fades) do
            if k == current_mod and v.fade < 1 then
                v.fade = math.min(1, v.fade + (dt / 0.5))
            elseif k ~= current_mod and v.fade > 0 then
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
    for k,v in pairs(self.mods) do
        if v.preview_script then
            v.preview_script.fade = self.mod_fades[v].fade
            v.preview_script.selected = (self.selected == k)
            v.preview_script:update(dt)
        end
    end
end

function menu:draw()
    local dt = love.timer.getDelta()

    -- Draw the menu background
    self:drawBackground()

    -- Draw introduction text if no mods exist
    if #self.mods == 0 then
        menu:printShadow(menu.INTRO_TEXT, 0, 115 - 8, {1, 1, 1, 1}, true, 640)
    else
        -- Draw some menu text
        menu:printShadow("Choose your world.", 80, 34 - 8, {1, 1, 1, 1})
        menu:printShadow("(X) Mods Folder   (C) Options", 294, 454 - 8, {1, 1, 1, 1})
    end

    -- Move the mod menu closer to the target
    if (math.abs((self.menu_offset_target - self.menu_offset)) <= 2) then
        self.menu_offset = self.menu_offset_target
    end

    self.menu_offset = self.menu_offset + ((self.menu_offset_target - self.menu_offset) / 2) * (dt * 30)

    -- Draw the mods
    love.graphics.setScissor(104, 70, 432, 370)
    for i = 1, #self.mods do
        local x = 108
        local y = menu:calculateMenuItemPosition(i, self.menu_offset)
        local color = {154/255, 154/255, 179/255, 1}
        if self.selected == i then
            color = {1, 1, 1, 1}
        end
        menu:drawMenuRectangle(x, y, 424, 62, color)
        menu:printShadow(self.mods[i].name, x + 50, y + 14, color)
    end

    love.graphics.setScissor()

    -- Move the heart closer to the target
    if (math.abs((self.heart_target_x - self.heart_x)) <= 2) then
        self.heart_x = self.heart_target_x
    end
    if (math.abs((self.heart_target_y - self.heart_y)) <= 2) then
        self.heart_y = self.heart_target_y
    end

    self.heart_x = self.heart_x + ((self.heart_target_x - self.heart_x) / 2) * (dt * 30)
    self.heart_y = self.heart_y + ((self.heart_target_y - self.heart_y) / 2) * (dt * 30)

    -- Draw the heart (only if we have to)
    if #self.mods > 0 then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.menu_heart, self.heart_x, self.heart_y)
    end

    -- Draw the scrollbar (only if we have to)
    if #self.mods > 5 then
        -- Draw the scrollbar background
        love.graphics.setColor({0, 0, 0, 0.5})
        love.graphics.rectangle("fill", 538, 70, 4, 370)

        -- Draw the scrollbar with lots of math I don't understand
        local menu_height = (62 + 8) * #self.mods
        local scrollbar_height = (370 / menu_height) * 370
        local scrollbar_y = ((-self.menu_offset / 370) * scrollbar_height) + 70

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 538, scrollbar_y, 4, scrollbar_height)
    end

    -- Draw mod preview overlays
    for k,v in pairs(self.mods) do
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
    self.fader_alpha = math.max(0,self.fader_alpha - (0.08 * (dt * 30)))

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

function menu:keypressed(key, _, is_repeat)
    if MOD_LOADING then return end

    if key == "x" then
        self.ui_select:stop()
        self.ui_select:play()
        love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/mods")
    end

    if #self.mods > 0 then
        if key == "z" then
            self.ui_select:stop()
            self.ui_select:play()

            kristal.loadMod(self.mods[self.selected].path)
            return
        end

        local total_min_offset = -math.max(0, (#self.mods * 70) - 370)
        local total_max_offset = 0

        local play_move = false
        if key == "up"    then self.selected = self.selected - 1; play_move = true end
        if key == "down"  then self.selected = self.selected + 1; play_move = true end
        if key == "left"  then 
            if self.selected == #self.mods then
                self.selected = math.max(1, #self.mods - 4)
            elseif self.selected > 5 then
                self.selected = self.selected - 5
                self.menu_offset_target = self.menu_offset_target + 350
            elseif self.selected == 1 then
                self.selected = self.selected - 1
                self.menu_offset_target = total_min_offset
            else
                self.selected = 1
                self.menu_offset_target = total_max_offset
            end
            play_move = true
        end
        if key == "right" then
            if self.selected < #self.mods - 4 then
                self.selected = self.selected + 5
                self.menu_offset_target = self.menu_offset_target - 350
            elseif self.selected == #self.mods then
                self.selected = self.selected + 1
                self.menu_offset_target = total_max_offset
            else
                self.selected = #self.mods
                self.menu_offset_target = total_min_offset
            end
            play_move = true
        end

        if self.selected > #self.mods then
            if is_repeat then
                self.selected = #self.mods
                play_move = false
            else
                self.selected = 1
            end
        end
        if self.selected < 1 then
            if is_repeat then
                self.selected = 1
                play_move = false
            else
                self.selected = #self.mods
            end
        end

        if play_move then
            self.ui_move:stop()
            self.ui_move:play()
        end

        local min_offset = math.max(-70 * (self.selected - 1), total_min_offset)
        local max_offset = math.min(300 - (70 * (self.selected - 1)), total_max_offset)

        self.menu_offset_target = math.min(max_offset, math.max(min_offset, self.menu_offset_target))

        self.heart_target_y = menu:calculateMenuItemPosition(self.selected, self.menu_offset_target) + 22
    end
end

function menu:drawBackground()
    -- This code was originally 30 fps, so we need a deltatime variable to multiply some values by
    local dt = love.timer.getDelta()
    local dt_mult = love.timer.getDelta() * 30

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
    love.graphics.setCanvas()

    -- Draw the canvas on the screen scaled by 2x
    love.graphics.setColor(1, 1, 1, self.background_fade)
    love.graphics.draw(self.bg_canvas, 0, 0, 0, 2, 2)

    -- Draw mod previews
    for k,v in pairs(self.mods) do
        local mod_preview = self.mod_fades[k]
        if v.preview and mod_preview.fade > 0 then
            -- Draw to the mod's preview canvas
            love.graphics.setCanvas(mod_preview.canvas)
            love.graphics.clear(0, 0, 0, 1)

            self:drawAnimStrip(v.preview, ( self.animation_sine / 12),        0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.46))
            self:drawAnimStrip(v.preview, ((self.animation_sine / 12) + 0.4), 0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.56))
            self:drawAnimStrip(v.preview, ((self.animation_sine / 12) + 0.8), 0, (10 - (self.background_alpha * 20)), (self.background_alpha * 0.7))

            -- Draw canvas scaled 2x to the screen
            love.graphics.setCanvas()
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

return menu