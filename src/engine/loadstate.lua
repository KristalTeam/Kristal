local Loading = {}

function Loading:init()
    self.logo = love.graphics.newImage("assets/sprites/kristal/title_logo.png")
    self.logo_heart = love.graphics.newImage("assets/sprites/kristal/title_logo_heart.png")

    -- We'll draw the logo on a canvas, then resize it 2x
    self.logo_canvas = love.graphics.newCanvas(320,240)
    -- No filtering
    self.logo_canvas:setFilter("nearest", "nearest")
end

function Loading:enter(from, dir)
    Mod = nil
    MOD_PATH = nil

    self.loading = false
    self.load_complete = false

    self.animation_done = false

    self.w = self.logo:getWidth()
    self.h = self.logo:getHeight()

    if not Kristal.Config["skipIntro"] then
        self.noise = love.audio.newSource("assets/sounds/kristal_intro.ogg", "static")
        self.end_noise = love.audio.newSource("assets/sounds/kristal_intro_end.ogg", "static")
        self.noise:play()
    else
        self:beginLoad()
    end

    self.siner = 0
    self.factor = 1
    self.factor2 = 0
    self.x = (320 / 2) - (self.w / 2)
    self.y = (240 / 2) - (self.h / 2) - 10
    self.animation_phase = 0
    self.animation_phase_timer = 0
    self.animation_phase_plus = 0
    self.logo_alpha = 1
    self.logo_alpha_2 = 1
    self.skipped = false
    self.skiptimer = 0
    self.key_check = not Kristal.Args["wait"]

    self.fader_alpha = 0
end

function Loading:beginLoad()
    Kristal.clearAssets(true)

    self.loading = true
    self.load_complete = false

    Kristal.loadAssets("", "all", "")
    Kristal.loadAssets("", "mods", "", function()
        self.loading = false
        self.load_complete = true

        Assets.saveData()
    end)
end

function Loading:update(dt)
    if self.load_complete and self.key_check and (self.animation_done or Kristal.Config["skipIntro"]) then
        if Kristal.Args["test"] then
            Gamestate.switch(Kristal.States["Testing"])
        else
            Gamestate.switch(Kristal.States["Menu"])
        end
    end
end

function Loading:drawScissor(image, left, top, width, height, x, y, alpha)
    love.graphics.push()

    local scissor_x = ((math.floor(x) >= 0) and math.floor(x) or 0)
    local scissor_y = ((math.floor(y) >= 0) and math.floor(y) or 0)
    love.graphics.setScissor(scissor_x, scissor_y, width, height)

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(image, math.floor(x) - left, math.floor(y) - top)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setScissor()
    love.graphics.pop()
end

function Loading:drawSprite(image, x, y, alpha)
    love.graphics.push()
    love.graphics.setScissor()

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(image, math.floor(x), math.floor(y), 0, 1, 1, image:getWidth()/2, image:getHeight()/2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end



function Loading:draw()
    if Kristal.Config["skipIntro"] then
        love.graphics.push()
        love.graphics.translate(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
        love.graphics.scale(2, 2)
        self:drawSprite(self.logo, 0, 0, 1)
        love.graphics.pop()
        return
    end

    local dt_mult = DT * 15

    -- We need to draw the logo on a canvas
    Draw.setCanvas(self.logo_canvas)
    love.graphics.clear()

    if (self.animation_phase == 0) then
        self.siner = self.siner + 1 * dt_mult
        self.factor = self.factor - (0.003 + (self.siner / 900)) * dt_mult
        if (self.factor < 0) then
            self.factor = 0
            self.animation_phase = 1
            if not self.loading and not self.load_complete then
                self:beginLoad()
            end
        end
        for i = 0, self.h - 1 do
            self.ia = ((self.siner / 25) - (math.abs((i - (self.h / 2))) * 0.05))
            self.xoff =  ((40 * math.sin((( self.siner / 5) + (i / 3))))        * self.factor)
            self.xoff2 = ((40 * math.sin((((self.siner / 5) + (i / 3)) + 0.6))) * self.factor)
            self.xoff3 = ((40 * math.sin((((self.siner / 5) + (i / 3)) + 1.2))) * self.factor)
            self:drawScissor(self.logo, 0, i, self.w, 2, (self.x + self.xoff ), (self.y + i), ((1 - self.factor) / 2))
            self:drawScissor(self.logo, 0, i, self.w, 2, (self.x + self.xoff2), (self.y + i), ((1 - self.factor) / 2))
            self:drawScissor(self.logo, 0, i, self.w, 2, (self.x + self.xoff3), (self.y + i), ((1 - self.factor) / 2))
        end
    end
    if (self.animation_phase == 1) then
        self:drawSprite(self.logo, self.x + (self.w / 2), self.y + (self.h / 2), self.logo_alpha)
        self.animation_phase_timer = self.animation_phase_timer + 1 * dt_mult
        if (self.animation_phase_timer >= 30) and self.load_complete then
            self.siner = 0
            self.factor = 0
            self.animation_phase = 2
            self.end_noise:play()
        end
    end
    if (self.animation_phase == 2) then
        if (self.animation_phase_plus == 0) then
            self.siner = self.siner + 0.5 * dt_mult
        end
        if (self.siner >= 20) then
            self.animation_phase_plus = 1
        end
        if (self.animation_phase_plus == 1) then
            self.siner = self.siner + 0.5 * dt_mult
            self.logo_alpha = self.logo_alpha - 0.02 * dt_mult
            self.logo_alpha_2 = self.logo_alpha_2 - 0.08 * dt_mult
        end

        self:drawSprite(self.logo, self.x + (self.w / 2), self.y + (self.h / 2), self.logo_alpha_2)
        self.mina = (self.siner / 30)
        if (self.mina >= 0.14) then
            self.mina = 0.14
        end
        self.factor2 = self.factor2 + 0.05 * dt_mult
        for i = 0, 9 do
            self:drawSprite(self.logo, ((self.x + (self.w / 2)) - (math.sin(((self.siner / 8) + (i / 2))) * (i * self.factor2))), ((self.y + (self.h / 2)) - (math.cos(((self.siner / 8) + (i / 2))) * (i * self.factor2))), (self.mina * self.logo_alpha))
            self:drawSprite(self.logo, ((self.x + (self.w / 2)) + (math.sin(((self.siner / 8) + (i / 2))) * (i * self.factor2))), ((self.y + (self.h / 2)) - (math.cos(((self.siner / 8) + (i / 2))) * (i * self.factor2))), (self.mina * self.logo_alpha))
            self:drawSprite(self.logo, ((self.x + (self.w / 2)) - (math.sin(((self.siner / 8) + (i / 2))) * (i * self.factor2))), ((self.y + (self.h / 2)) + (math.cos(((self.siner / 8) + (i / 2))) * (i * self.factor2))), (self.mina * self.logo_alpha))
            self:drawSprite(self.logo, ((self.x + (self.w / 2)) + (math.sin(((self.siner / 8) + (i / 2))) * (i * self.factor2))), ((self.y + (self.h / 2)) + (math.cos(((self.siner / 8) + (i / 2))) * (i * self.factor2))), (self.mina * self.logo_alpha))
        end
        self:drawSprite(self.logo_heart, self.x + (self.w / 2), self.y + (self.h / 2), self.logo_alpha)
        if (self.logo_alpha <= -0.5 and self.skipped == false) then
            self.animation_done = true
        end
    end

    -- Reset canvas to draw to
    Draw.setCanvas(SCREEN_CANVAS)

    -- Draw the canvas on the screen scaled by 2x
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.logo_canvas, 0, 0, 0, 2, 2)

    if self.skipped then
        -- Draw the screen fade
        love.graphics.setColor(0, 0, 0, self.fader_alpha)
        love.graphics.rectangle("fill", 0, 0, 640, 480)

        if self.fader_alpha > 1 then
            self.animation_done = true
            self.noise:stop()
            self.end_noise:stop()
        end

        -- Change the fade opacity for the next frame
        self.fader_alpha = math.max(0,self.fader_alpha + (0.04 * dt_mult))
        self.noise:setVolume(math.max(0, 1 - self.fader_alpha))
        self.end_noise:setVolume(math.max(0, 1 - self.fader_alpha))
    end

    -- Reset the draw color
    love.graphics.setColor(1, 1, 1, 1)
end

function Loading:keypressed(key)
    self.key_check = true
    self.skipped = true
    if not self.loading and not self.load_complete then
        self:beginLoad()
    end
end

return Loading