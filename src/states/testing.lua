local teststate = {}

function teststate:enter()
    self.face = kristal.assets.getTexture("face/ralsei_hat/spr_face_r_dark_9")
end

function teststate:update(dt)
end

function teststate:draw()
    love.graphics.clear(1, 1, 1)
    self:drawScissor(self.face, 12, 31, 30, 12, 5, 10, 1, 1, 1)
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