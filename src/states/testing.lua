local teststate = {}

function teststate:enter()
    self.font = kristal.assets.getFont("main")
    self.face = kristal.assets.getTexture("face/ralsei_hat/spr_face_r_dark_9")
    self.timer = 0

    self.stage = Object()

    self.stage:add(DialogueText("* These [color:yellow]birds[color:reset] are [color:yellow]Pissing[color:reset] me\noff...\n\n* I'm the [color:ff00ff]sussy [color:red]among us[color:reset] and [speed:0.2]nobody[speed:1] can\nstop me\n\n* Except law enforcement", 20, 20))

    --self.funnytext = DialogueText("* I'm the ULTIMATE   [color:yellow]STARWALKER", 20, 120)
    --self.stage:add(self.funnytext)

    --self.stage:add(DialogueText("[color:ff00ff]* Amogus[color:reset] sussy [color:red]Impostor", 20, 220))
end

function teststate:update(dt)
    self.stage:update(dt)

    self.timer = self.timer + dt
    --for i,char in ipairs(self.funnytext.chars) do
    --    if char.color then
    --        local color = {utils.hslToRgb((self.timer + (i * 0.1)) % 1, 1, 0.5)}
    --        char.color = {color[1], color[2], color[3], 1}
    --    end
    --end
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