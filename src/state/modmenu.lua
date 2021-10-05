local ModMenu = {}

ModMenu.BACKGROUND_SHADER = love.graphics.newShader([[
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

function ModMenu:enter()
    print("i am so gay")

    -- Load menu music
    ModMenu.music = love.audio.newSource("assets/music/mod_menu.ogg", "stream")
    ModMenu.music:setVolume(1)
    ModMenu.music:setPitch(0.95)
    ModMenu.music:setLooping(true)
    ModMenu.music:play()

    -- Initialize variables for the animation
    ModMenu.fader_alpha = 1
    ModMenu.animation_sine = 0
    ModMenu.background_alpha = 0

    -- Assets required for the background animation
    ModMenu.background_image_wave = Assets:getTexture("kristal/title_bg_wave")
    ModMenu.background_image_animation = {
        Assets:getTexture("kristal/title_bg_anim_0"),
        Assets:getTexture("kristal/title_bg_anim_1"),
        Assets:getTexture("kristal/title_bg_anim_2"),
        Assets:getTexture("kristal/title_bg_anim_3"),
        Assets:getTexture("kristal/title_bg_anim_4")
    }
end

function ModMenu:init()
    -- We'll draw the background on a canvas, then resize it 2x
    ModMenu.bg_canvas = love.graphics.newCanvas(320,240)
    -- No filtering
    ModMenu.bg_canvas:setFilter("nearest", "nearest")
end

function ModMenu:drawAnimStrip(sprite, subimg, x, y, alpha)
    love.graphics.setColor(1, 1, 1, alpha)

    local index = (math.floor(subimg) % (#sprite - 1)) + 1

    love.graphics.draw(sprite[index], math.floor(x), math.floor(y))
end

function ModMenu:draw()
    local dt = love.timer.getDelta()

    -- Draw the menu background
    ModMenu:drawBackground()

    -- Menu drawing should go here

    -- Draw the screen fade
    love.graphics.setColor(0, 0, 0, ModMenu.fader_alpha)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    -- Change the fade opacity for the next frame
    ModMenu.fader_alpha = math.max(0,ModMenu.fader_alpha - (0.08 * (dt * 30)))

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

function ModMenu:drawBackground()
    -- This code was originally 30 fps, so we need a deltatime variable to multiply some values by
    local dt_mult = love.timer.getDelta() * 30

    -- We need to draw the background on a canvas
    love.graphics.setCanvas(ModMenu.bg_canvas)
    love.graphics.clear()

    ModMenu.animation_sine = ModMenu.animation_sine + (1 * dt_mult)

    if (ModMenu.background_alpha < 0.5) then
        ModMenu.background_alpha = ModMenu.background_alpha + (0.04 - (ModMenu.background_alpha / 14)) * dt_mult
    end

    if (ModMenu.background_alpha > 0.5) then
        ModMenu.background_alpha = 0.5
    end

    -- Set the shader to use
    love.graphics.setShader(ModMenu.BACKGROUND_SHADER)
    ModMenu.BACKGROUND_SHADER:send("bg_sine", ModMenu.animation_sine)
    ModMenu.BACKGROUND_SHADER:send("bg_mag", 6)
    ModMenu.BACKGROUND_SHADER:send("wave_height", 240)
    ModMenu.BACKGROUND_SHADER:send("texsize", {ModMenu.background_image_wave:getWidth(), ModMenu.background_image_wave:getHeight()})

    ModMenu.BACKGROUND_SHADER:send("sine_mul", 1)
    love.graphics.setColor(1, 1, 1, ModMenu.background_alpha * 0.8)
    love.graphics.draw(ModMenu.background_image_wave, 0, math.floor(-10 - (ModMenu.background_alpha * 20)))
    ModMenu.BACKGROUND_SHADER:send("sine_mul", -1)
    love.graphics.draw(ModMenu.background_image_wave, 0, math.floor(-10 - (ModMenu.background_alpha * 20)))
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setShader()

    ModMenu:drawAnimStrip(ModMenu.background_image_animation, ( ModMenu.animation_sine / 12),        0, (((10 - (ModMenu.background_alpha * 20)) + 240) - 70), (ModMenu.background_alpha * 0.46))
    ModMenu:drawAnimStrip(ModMenu.background_image_animation, ((ModMenu.animation_sine / 12) + 0.4), 0, (((10 - (ModMenu.background_alpha * 20)) + 240) - 70), (ModMenu.background_alpha * 0.56))
    ModMenu:drawAnimStrip(ModMenu.background_image_animation, ((ModMenu.animation_sine / 12) + 0.8), 0, (((10 - (ModMenu.background_alpha * 20)) + 240) - 70), (ModMenu.background_alpha * 0.7))

    -- Reset canvas to draw to
    love.graphics.setCanvas()

    -- Draw the canvas on the screen scaled by 2x
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ModMenu.bg_canvas, 0, 0, 0, 2, 2)

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

return ModMenu