local ModMenu = {}

ModMenu.SHADER_TEST = love.graphics.newShader([[
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
    print(Utils.dump(love.graphics.getSystemLimits()))

    ModMenu.music = love.audio.newSource("assets/music/mod_menu.ogg", "stream")
    ModMenu.music:setVolume(1)
    ModMenu.music:setPitch(0.95)
    ModMenu.music:setLooping(true)
    ModMenu.music:play()

    ModMenu.fader_alpha = 1

    ModMenu.BG_SINER = 0
    ModMenu.BGMAGNITUDE = 6

    ModMenu.BG_ALPHA = 0
    ModMenu.ANIM_SINER = 0
    ModMenu.ANIM_SINER_B = 0

    ModMenu.version_text = "1.07"

    ModMenu.IMAGE_MENU = Assets:getTexture("kristal/title_bg_full")
    ModMenu.IMAGE_MENU_WAVE = Assets:getTexture("kristal/title_bg_wave")
    ModMenu.IMAGE_MENU_ANIMATION = {
        Assets:getTexture("kristal/title_bg_anim_0"),
        Assets:getTexture("kristal/title_bg_anim_1"),
        Assets:getTexture("kristal/title_bg_anim_2"),
        Assets:getTexture("kristal/title_bg_anim_3"),
        Assets:getTexture("kristal/title_bg_anim_4")
    }

    ModMenu.advance = true
end

function ModMenu:init()
    ModMenu.bg_canvas = love.graphics.newCanvas(320,240)
    ModMenu.bg_canvas:setFilter("nearest", "nearest")
end

-- draw_background_part_ext (image, left, top, width, height, x, y, xscale, yscale, alpha)

--ModMenu:drawScissor(
--    ModMenu.IMAGE_MENU,
--    0,
--    i,
--    ModMenu.__WAVEWIDTH,
--    1,
--    (  math.sin(((i / 8) + (ModMenu.BG_SINER / 30)))  * ModMenu.__WAVEMAG),
--    ((-10 + i) - (ModMenu.BG_ALPHA * 20)),
--    1,
--    1,
--    (ModMenu.BG_ALPHA * 0.8)
--)

function ModMenu:drawScissor(image, left, top, width, height, x, y, xscale, yscale, alpha)
    love.graphics.push()
    love.graphics.scale(xscale, yscale)
    love.graphics.setScissor(math.floor(x), math.floor(y), width, height)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(image, math.floor(x) - left, math.floor(y) - top)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setScissor()
    love.graphics.pop()
end

function ModMenu:draw_sprite_ext(sprite, subimg, x, y, xscale, yscale, alpha)
    love.graphics.push()
    love.graphics.scale(xscale, yscale)

    love.graphics.setColor(1, 1, 1, alpha)

    local index = (math.floor(subimg) % (#sprite - 1)) + 1

    love.graphics.draw(sprite[index], math.floor(x), math.floor(y))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

function love.keypressed(g)
    ModMenu.advance = true
end

function ModMenu:draw()
    local dt = love.timer.getDelta()

    love.graphics.setCanvas(ModMenu.bg_canvas)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 1)

    --dt = (1 / 30)

    ModMenu.ANIM_SINER = ModMenu.ANIM_SINER + 1      * (dt * 30)
    ModMenu.ANIM_SINER_B = ModMenu.ANIM_SINER_B + 1  * (dt * 30)
    ModMenu.BG_SINER = ModMenu.BG_SINER + 1          * (dt * 30)
    if (ModMenu.BG_ALPHA < 0.5) then
        ModMenu.BG_ALPHA = ModMenu.BG_ALPHA + (0.04 - (ModMenu.BG_ALPHA / 14)) * (dt * 30)
    end
    if (ModMenu.BG_ALPHA > 0.5) then
        ModMenu.BG_ALPHA = 0.5
    end

    ModMenu.__WAVEHEIGHT = 240
    ModMenu.__WAVEWIDTH = 320
    --[[for i = 0, (ModMenu.__WAVEHEIGHT - 50) - 1 do
        ModMenu.__WAVEMINUS = ((ModMenu.BGMAGNITUDE * (i / ModMenu.__WAVEHEIGHT)) * 1.3)
        if (ModMenu.__WAVEMINUS > ModMenu.BGMAGNITUDE) then
            ModMenu.__WAVEMAG = 0
        else
            ModMenu.__WAVEMAG = (ModMenu.BGMAGNITUDE - ModMenu.__WAVEMINUS)
        end
        ModMenu:drawScissor(ModMenu.IMAGE_MENU, 0, i, ModMenu.__WAVEWIDTH, 1, (  math.sin(((i / 8) + (ModMenu.BG_SINER / 30)))  * ModMenu.__WAVEMAG), ((-10 + i) - (ModMenu.BG_ALPHA * 20)), 1, 1, (ModMenu.BG_ALPHA * 0.8))
        ModMenu:drawScissor(ModMenu.IMAGE_MENU, 0, i, ModMenu.__WAVEWIDTH, 1, ((-math.sin(((i / 8) + (ModMenu.BG_SINER / 30)))) * ModMenu.__WAVEMAG), ((-10 + i) - (ModMenu.BG_ALPHA * 20)), 1, 1, (ModMenu.BG_ALPHA * 0.8))
    end]]
    love.graphics.setShader(ModMenu.SHADER_TEST)
    ModMenu.SHADER_TEST:send("bg_sine", ModMenu.BG_SINER)
    ModMenu.SHADER_TEST:send("bg_mag", ModMenu.BGMAGNITUDE)
    ModMenu.SHADER_TEST:send("wave_height", ModMenu.__WAVEHEIGHT)
    ModMenu.SHADER_TEST:send("texsize", {ModMenu.IMAGE_MENU_WAVE:getWidth(), ModMenu.IMAGE_MENU_WAVE:getHeight()})
    ModMenu.SHADER_TEST:send("sine_mul", 1)
    love.graphics.setColor(1, 1, 1, ModMenu.BG_ALPHA * 0.8)
    love.graphics.draw(ModMenu.IMAGE_MENU_WAVE, 0, math.floor(-10 - (ModMenu.BG_ALPHA * 20)))
    ModMenu.SHADER_TEST:send("sine_mul", -1)
    love.graphics.draw(ModMenu.IMAGE_MENU_WAVE, 0, math.floor(-10 - (ModMenu.BG_ALPHA * 20)))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader()

    ModMenu:draw_sprite_ext(ModMenu.IMAGE_MENU_ANIMATION, ( ModMenu.ANIM_SINER / 12),        0, (((10 - (ModMenu.BG_ALPHA * 20)) + ModMenu.__WAVEHEIGHT) - 70), 1, 1, (ModMenu.BG_ALPHA * 0.46))
    ModMenu:draw_sprite_ext(ModMenu.IMAGE_MENU_ANIMATION, ((ModMenu.ANIM_SINER / 12) + 0.4), 0, (((10 - (ModMenu.BG_ALPHA * 20)) + ModMenu.__WAVEHEIGHT) - 70), 1, 1, (ModMenu.BG_ALPHA * 0.56))
    ModMenu:draw_sprite_ext(ModMenu.IMAGE_MENU_ANIMATION, ((ModMenu.ANIM_SINER / 12) + 0.8), 0, (((10 - (ModMenu.BG_ALPHA * 20)) + ModMenu.__WAVEHEIGHT) - 70), 1, 1, (ModMenu.BG_ALPHA * 0.7))

    love.graphics.setCanvas() --This sets the target back to the screen
    love.graphics.draw(ModMenu.bg_canvas, 0, 0, 0, 2, 2)

    love.graphics.setColor(0, 0, 0, ModMenu.fader_alpha)
    ModMenu.fader_alpha = ModMenu.fader_alpha - (0.08 * (dt * 30))
    love.graphics.rectangle("fill", 0, 0, 640, 480)
    love.graphics.setColor(1, 1, 1, 1)
end

return ModMenu