---@class ShaderFX : FXBase
---@overload fun(shader:string|love.Shader,vars?:table,transformed?:boolean,priority?:number) : ShaderFX
local ShaderFX, super = Class(FXBase)

function ShaderFX:init(shader, vars, transformed, priority)
    super.init(self, priority or 0)

    if type(shader) == "string" then
        shader = Assets.getShader(shader)
    end

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