---@class ShaderFX : FXBase
---@overload fun(...) : ShaderFX
local ShaderFX, super = Class(FXBase)

function ShaderFX:init(shader, vars, transformed, priority)
    super.init(self, priority or 0)

    self.shader = shader

    self.transformed = transformed or false

    self.vars = vars or {}
end

function ShaderFX:draw(texture)
    local last_shader = love.graphics.getShader()
    love.graphics.setShader(self.shader)
    for k,v in pairs(self.vars) do
        if type(v) == "function" then
            self.shader:send(k, v())
        else
            self.shader:send(k, v)
        end
    end
    Draw.drawCanvas(texture)
    love.graphics.setShader(last_shader)
end

return ShaderFX