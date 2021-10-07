local teststate = {}

local GRADIENT_H_SHADER = love.graphics.newShader([[
    extern vec4 from;
    extern vec4 to;
    extern number scale;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        return Texel(texture, texture_coords) * (from + (to - from) * mod(texture_coords.x / scale, 1)) * color;
    }
]])

local GRADIENT_V_SHADER = love.graphics.newShader([[
    extern vec4 from;
    extern vec4 to;
    extern number scale;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        return Texel(texture, texture_coords) * (from + (to - from) * mod(texture_coords.y / scale, 1)) * color;
    }
]])

GRADIENT_H_SHADER:send("scale", 1)
GRADIENT_V_SHADER:send("scale", 1)

function teststate:enter()
    self.font = kristal.assets.getFont("main")
    self.face = kristal.assets.getTexture("face/ralsei_hat/spr_face_r_dark_9")
    self.thing_scale = 1
end

function teststate:update(dt)
end

function teststate:keypressed(key)
    if key == "left" then
        self.thing_scale = self.thing_scale / 2
    elseif key == "right" then
        self.thing_scale = self.thing_scale * 2
    end
end

function teststate:draw()
    love.graphics.clear()

    local text1 = {{1, 1, 1, 1}, "* These ", {0, 0, 0, 0}, "birds", {1, 1, 1, 1}, " are ", {0, 0, 0, 0}, "Pissing", {1, 1, 1, 1}, " me\n    off..."}
    local text2 = {{0, 0, 0, 0}, "* These ", {1, 1, 1, 1}, "birds", {0, 0, 0, 0}, " are ", {1, 1, 1, 1}, "Pissing", {0, 0, 0, 0}, " me\n    off..."}

    self:drawTextColored(text1, 20, 20)
    self:drawTextColored(text2, 20, 20, COLORS.yellow)

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

function teststate:drawTextColored(text, x, y, color)
    local full_text = utils.getCombinedText(text)
    local text_lines = utils.split(full_text, "\n")
    local canvas = kristal.graphics.getCanvas("text:"..full_text, self.font:getWidth(full_text), self.font:getHeight() * #text_lines)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.font)
    local old_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.printf(text, 0, 0, self.font:getWidth(full_text), "left")
    love.graphics.setCanvas(old_canvas)

    love.graphics.setShader(GRADIENT_V_SHADER)
    GRADIENT_V_SHADER:send("from", utils.copy(color or COLORS.dkgray))
    GRADIENT_V_SHADER:send("to", utils.copy(color or COLORS.navy))
    GRADIENT_V_SHADER:send("scale", 1/#text_lines)
    love.graphics.setColor(1, 1, 1, color and 0.3 or 1)
    love.graphics.draw(canvas, x + 1, y + 1)

    GRADIENT_V_SHADER:send("from", utils.copy(COLORS.white))
    GRADIENT_V_SHADER:send("to", utils.copy(color or COLORS.white))
    GRADIENT_V_SHADER:send("scale", 1/#text_lines)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, x, y)

    GRADIENT_V_SHADER:send("scale", 1)
    love.graphics.setShader()
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