local ModMenu = {}

function ModMenu:enter()
    print("i am so gay")

    --ModMenu.music = love.audio.newSource("AUDIO_STORY.ogg", "stream")
    --ModMenu.music:setVolume(1)
    --ModMenu.music:setPitch(0.95)
    --ModMenu.music:setLooping(true)
    --ModMenu.music:play()

    ModMenu.fader_alpha = 1

    ModMenu.BG_SINER = 0
    ModMenu.BGMAGNITUDE = 6

    ModMenu.BG_ALPHA = 0
    ModMenu.ANIM_SINER = 0
    ModMenu.ANIM_SINER_B = 0

    ModMenu.version_text = "1.07"

    ModMenu.IMAGE_MENU = Assets:getTexture("kristal/title_bg_full")
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
    love.graphics.push("all")
    love.graphics.scale(xscale, yscale)
    love.graphics.setScissor(x + left, y + top, width, height)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(image, x, y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

function ModMenu:draw_sprite_ext(sprite, subimg, x, y, xscale, yscale, alpha)
    love.graphics.push("all")
    love.graphics.scale(xscale, yscale)

    love.graphics.setColor(1, 1, 1, alpha)

    local index = (math.floor(subimg) % (#sprite - 1)) + 1

    love.graphics.draw(sprite[index], x, y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

function love.keypressed(g)
    ModMenu.advance = true
end

function ModMenu:draw()
    local dt = love.timer.getDelta( )

    love.graphics.setCanvas(ModMenu.bg_canvas)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 1)

    --dt = (1 / 30)

    if ModMenu.advance then

    ModMenu.ANIM_SINER = ModMenu.ANIM_SINER + 1      * (dt * 30)
    ModMenu.ANIM_SINER_B = ModMenu.ANIM_SINER_B + 1  * (dt * 30)
    ModMenu.BG_SINER = ModMenu.BG_SINER + 1          * (dt * 30)
    if (ModMenu.BG_ALPHA < 0.5) then
        ModMenu.BG_ALPHA = (ModMenu.BG_ALPHA + (0.04 - (ModMenu.BG_ALPHA / 14))) * (dt * 30)
    end
    if (ModMenu.BG_ALPHA > 0.5) then
        ModMenu.BG_ALPHA = 0.5
    end
    end
    ModMenu.__WAVEHEIGHT = 240
    ModMenu.__WAVEWIDTH = 320
    for i = 0, (ModMenu.__WAVEHEIGHT - 50) - 1 do
        ModMenu.__WAVEMINUS = ((ModMenu.BGMAGNITUDE * (i / ModMenu.__WAVEHEIGHT)) * 1.3)
        if (ModMenu.__WAVEMINUS > ModMenu.BGMAGNITUDE) then
            ModMenu.__WAVEMAG = 0
        else
            ModMenu.__WAVEMAG = (ModMenu.BGMAGNITUDE - ModMenu.__WAVEMINUS)
        end
        ModMenu:drawScissor(ModMenu.IMAGE_MENU, 0, i, ModMenu.__WAVEWIDTH, 1, (  math.sin(((i / 8) + (ModMenu.BG_SINER / 30)))  * ModMenu.__WAVEMAG), ((-10 + i) - (ModMenu.BG_ALPHA * 20)), 1, 1, (ModMenu.BG_ALPHA * 0.8))
        ModMenu:drawScissor(ModMenu.IMAGE_MENU, 0, i, ModMenu.__WAVEWIDTH, 1, ((-math.sin(((i / 8) + (ModMenu.BG_SINER / 30)))) * ModMenu.__WAVEMAG), ((-10 + i) - (ModMenu.BG_ALPHA * 20)), 1, 1, (ModMenu.BG_ALPHA * 0.8))
    end
    ModMenu:draw_sprite_ext(ModMenu.IMAGE_MENU_ANIMATION, ( ModMenu.ANIM_SINER / 12),        0, (((10 - (ModMenu.BG_ALPHA * 20)) + ModMenu.__WAVEHEIGHT) - 70), 1, 1, (ModMenu.BG_ALPHA * 0.46))
    ModMenu:draw_sprite_ext(ModMenu.IMAGE_MENU_ANIMATION, ((ModMenu.ANIM_SINER / 12) + 0.4), 0, (((10 - (ModMenu.BG_ALPHA * 20)) + ModMenu.__WAVEHEIGHT) - 70), 1, 1, (ModMenu.BG_ALPHA * 0.56))
    ModMenu:draw_sprite_ext(ModMenu.IMAGE_MENU_ANIMATION, ((ModMenu.ANIM_SINER / 12) + 0.8), 0, (((10 - (ModMenu.BG_ALPHA * 20)) + ModMenu.__WAVEHEIGHT) - 70), 1, 1, (ModMenu.BG_ALPHA * 0.7))

    love.graphics.setCanvas() --This sets the target back to the screen
    love.graphics.draw(ModMenu.bg_canvas, 0, 0, 0, 2, 2)

    --ModMenu.advance = false
    love.graphics.setColor(0, 0, 0, ModMenu.fader_alpha)
    ModMenu.fader_alpha = ModMenu.fader_alpha - (0.08 * (dt * 30))
    love.graphics.rectangle("fill", 0, 0, 640, 480)
    love.graphics.setColor(1, 1, 1, 1)
end

return ModMenu