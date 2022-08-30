local BattleOutlineFX, super = Class(FXBase)

function BattleOutlineFX:init(priority)
    super:init(self, priority or 0)
end

function BattleOutlineFX:isActive()
    return super:isActive(self) and self.amount > 0
end

function BattleOutlineFX:setAlpha(alpha)
    self.amount = alpha
end

function BattleOutlineFX:draw(texture)
    local last_shader = love.graphics.getShader()

    local object = self.parent

    local mult_x = 1
    local mult_y = 1

    local hierarchy = object:getHierarchy()

    for _, parent in ipairs(hierarchy) do
        mult_x = mult_x * parent.scale_x
        mult_y = mult_y * parent.scale_y
    end

    love.graphics.setColor(1, 1, 1, 1)

    local outline = Draw.pushCanvas(texture:getWidth(), texture:getHeight())

    love.graphics.clear()

    local shader = Kristal.Shaders["AddColor"]
    love.graphics.setShader(shader)

    shader:send("amount", 1)
    shader:send("inputcolor", {Game:getSoulColor()})

    -- Left
    love.graphics.translate(-1 * mult_x, 0)
    love.graphics.drawCanvas(texture)
    -- Right
    love.graphics.translate(2 * mult_x, 0)
    love.graphics.drawCanvas(texture)
    -- Up
    love.graphics.translate(-1 * mult_x, -1 * mult_y)
    love.graphics.drawCanvas(texture)
    -- Down
    love.graphics.translate(0, 2 * mult_y)
    love.graphics.drawCanvas(texture)

    love.graphics.drawCanvas(texture)

    Draw.popCanvas()

    love.graphics.setShader(last_shader)

    love.graphics.setColor(1, 1, 1, self.amount)
    love.graphics.drawCanvas(outline)
    love.graphics.setColor(1, 1, 1)

    love.graphics.setShader(shader)
    shader:send("inputcolor", {32/255, 32/255, 32/255})
    shader:send("amount", self.amount)

    love.graphics.drawCanvas(texture)

    love.graphics.setShader(last_shader)
end

return BattleOutlineFX