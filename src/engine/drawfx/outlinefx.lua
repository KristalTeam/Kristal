local OutlineFX, super = Class(FXBase)

function OutlineFX:init(color, settings, priority)
    super:init(self, priority or 0)

    settings = settings or {}

    self.color = color or {1, 1, 1}
    self.thickness = settings["thickness"] or 1
    self.amount = settings["amount"] or 1
    self.cutout = settings["cutout"]

    self.cutout_shader = Kristal.Shaders["Mask"]
end

function OutlineFX:setColor(r, g, b, a)
    self.color = {r, g, b, a}
end

function OutlineFX:getColor()
    return self.color[1], self.color[2], self.color[3]
end

function OutlineFX:isActive()
    return super:isActive(self) and self.amount > 0
end

function OutlineFX:draw(texture)
    local last_shader = love.graphics.getShader()

    if self.cutout then
        love.graphics.stencil((function()
            love.graphics.setShader(self.cutout_shader)
            love.graphics.drawCanvas(texture)
            love.graphics.setShader()
        end), "replace", 1)

        love.graphics.setStencilTest("less", 1)
    end

    local shader = Kristal.Shaders["AddColor"]
    love.graphics.setShader(shader)

    shader:send("inputcolor", {self:getColor()})
    shader:send("amount", self.amount)

    local object = self.parent

    local mult_x = self.thickness
    local mult_y = self.thickness

    local hierarchy = object:getHierarchy()

    for _, parent in ipairs(hierarchy) do
        mult_x = mult_x * parent.scale_x
        mult_y = mult_y * parent.scale_y
    end

    local outline = Draw.pushCanvas(texture:getWidth(), texture:getHeight())
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

    Draw.popCanvas()


    love.graphics.setColor(1, 1, 1, self.color[4])
    love.graphics.drawCanvas(outline)
    love.graphics.setColor(1, 1, 1, 1)

    -- Center
    love.graphics.translate(0, -1 * mult_y)
    love.graphics.setShader(last_shader)
    love.graphics.drawCanvas(texture)

    if self.cutout then
        love.graphics.setStencilTest()
    end
end

return OutlineFX