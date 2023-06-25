---@class Gradient : FXBase
---@overload fun(...) : Gradient
local Gradient, super = Class(FXBase)

function Gradient:init(from, to, alpha, dir, bounds)
    super.init(self, 200)
    self.from = from
    self.from[4] = 1
    self.to = to
    self.to[4] = 1
    self.alpha = alpha or 1
    self.dir = dir or 0
    self.bounds = bounds
end

function Gradient:draw(texture)
    local last_shader = love.graphics.getShader()
    Draw.setColor(1,1,1)
    local shader = Kristal.Shaders["AngleGradient"]
    love.graphics.setShader(shader)
    shader:sendColor("from", self.from)
    shader:sendColor("to", self.to)
    shader:send("amount", self.alpha)
    shader:send("angle", self.dir)
    local bx, by, bw, bh = unpack(self.bounds or {self:getObjectBounds()})
    shader:send("bounds", {bx/SCREEN_WIDTH, by/SCREEN_HEIGHT, bw/SCREEN_WIDTH, bh/SCREEN_HEIGHT})
    Draw.draw(texture)
    love.graphics.setShader(last_shader)
end

return Gradient