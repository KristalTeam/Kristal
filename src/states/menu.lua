local menu = {}

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

function menu:enter()
    print("i am so gay")

    -- Load menu music
    self.music = love.audio.newSource("assets/music/mod_menu.ogg", "stream")
    self.music:setVolume(1)
    self.music:setPitch(0.95)
    self.music:setLooping(true)
    self.music:play()

    -- Initialize variables for the animation
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
end

function menu:init()
    -- We'll draw the background on a canvas, then resize it 2x
    self.bg_canvas = love.graphics.newCanvas(320,240)
    -- No filtering
    self.bg_canvas:setFilter("nearest", "nearest")
end

function menu:drawAnimStrip(sprite, subimg, x, y, alpha)
    love.graphics.setColor(1, 1, 1, alpha)

    local index = (math.floor(subimg) % (#sprite - 1)) + 1

    love.graphics.draw(sprite[index], math.floor(x), math.floor(y))
end

function menu:draw()
    local dt = love.timer.getDelta()

    -- Draw the menu background
    self:drawBackground()

    -- Menu drawing should go here

    -- Draw the screen fade
    love.graphics.setColor(0, 0, 0, self.fader_alpha)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    -- Change the fade opacity for the next frame
    self.fader_alpha = math.max(0,self.fader_alpha - (0.08 * (dt * 30)))

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

function menu:drawBackground()
    -- This code was originally 30 fps, so we need a deltatime variable to multiply some values by
    local dt_mult = love.timer.getDelta() * 30

    -- We need to draw the background on a canvas
    love.graphics.setCanvas(self.bg_canvas)
    love.graphics.clear(0, 0, 0, 1)

    self.animation_sine = self.animation_sine + (1 * dt_mult)

    if (self.background_alpha < 0.5) then
        self.background_alpha = self.background_alpha + (0.04 - (self.background_alpha / 14)) * dt_mult
    end

    if (self.background_alpha > 0.5) then
        self.background_alpha = 0.5
    end

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
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bg_canvas, 0, 0, 0, 2, 2)

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

return menu