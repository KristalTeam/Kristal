local teststate = {}

function teststate:enter()
    self.font = kristal.assets.getFont("main")
    self.face = kristal.assets.getTexture("face/ralsei_hat/spr_face_r_dark_9")
    self.timer = 0

    self.stage = Object()

    --self.stage:addChild(DialogueText("* These [color:yellow]birds[color:reset] are [color:yellow]Pissing[color:reset] me\noff[wait:1].[wait:1].[wait:1].\n\n[wait:10]* I'm the [color:ff00ff]sussy [color:red]among us[color:reset] and [speed:0.2]nobody[speed:1] can\nstop me\n\n[wait:20][instant]* Except [stopinstant][wait:30][instant]law [stopinstant][wait:50][speed:0.2]en[instant]force[stopinstant][wait:20][speed:2]ment", 20, 20))

    self.stage:addChild(DialogueText("* These [color:yellow]birds[color:reset] are [color:yellow]Pissing[color:reset] me\noff[wait:5].[wait:5].[wait:5].", 20, 20))

    self.funnytext = DialogueText("* I'm the ULTIMATE   [color:yellow]STARWALKER", 20, 120)
    self.stage:addChild(self.funnytext)

    self.stage:addChild(Text("[color:ff00ff]* Amogus[color:reset] sussy [color:red]Impostor", 20, 320, ShadedChar))

    self.stage:addChild(DarkTransitionLine(20))
    self.stage:addChild(DarkTransitionLine(30))
    self.stage:addChild(DarkTransitionLine(40))
    self.stage:addChild(DarkTransitionLine(50))
    self.stage:addChild(DarkTransitionLine(60))
    self.stage:addChild(DarkTransitionLine(70))
    self.stage:addChild(DarkTransitionLine(80))
    self.stage:addChild(DarkTransitionLine(90))
end

function teststate:update(dt)
    self.stage:update(dt)

    self.timer = self.timer + dt
    for i,char in ipairs(self.funnytext.chars) do
        if char.color[1] ~= 1 or char.color[2] ~= 1 or char.color[3] ~= 1 then
            local color = {utils.hslToRgb((self.timer + (i * 0.1)) % 1, 1, 0.5)}
            char.color = {color[1], color[2], color[3], 1}

            local scale = 1 + (math.sin(self.timer * 6 + (i * 0.5)) * 0.3)
            char.origin_y = math.max(0, scale - 1)

            char:setScaleOrigin(0.5, 1)
            char:setScale(1, scale)
        end
    end
end

function teststate:draw()
    love.graphics.clear()
    self.stage:draw()

    --[[local text1_lines = utils.split(text, "\n")
    local canvas = kristal.graphics.getCanvas("star_text", self.font:getWidth(text1), self.font:getHeight() * #text1_lines)

    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setFont(self.font)
    love.graphics.print(text)
    love.graphics.setCanvas()
    
    love.graphics.setShader(GRADIENT_H_SHADER)
    GRADIENT_H_SHADER:send("from", {1, 1, 0, 1}) -- spare color
    GRADIENT_H_SHADER:send("to", {0, 0.7, 1, 1}) -- pacify color
    GRADIENT_H_SHADER:send("scale", 1)
    love.graphics.draw(canvas, 20, 20)
    GRADIENT_H_SHADER:send("scale", 1)
    love.graphics.setShader()]]
end

function teststate:drawScissor(image, left, top, width, height, x, y, xscale, yscale, alpha)
    love.graphics.push("all")
    love.graphics.scale(xscale, yscale)
    love.graphics.setScissor(x, y, width, height)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(image, x - left, y - top)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return teststate