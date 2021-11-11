local Silhouette, super = Class(Event)

function Silhouette:init(data)
    super:init(self, data.x, data.y, data.width, data.height)

    self.solid = false

    self:setOrigin(0, 0)
    self:setHitbox(0, 0, data.width, data.height)

    self.canvas = love.graphics.newCanvas(data.width, data.height)
end

function Silhouette:drawCharacter(object)
    love.graphics.push()
    object:preDraw()
    object:draw()
    object:postDraw()
    love.graphics.pop()
end

function Silhouette:draw()
    super:draw(self)

    Draw.pushCanvas(self.canvas)
    love.graphics.clear()

    love.graphics.translate(-self.x, -self.y)

    for _, object in ipairs(Game.world.children) do
        if object:includes(Character) then

            love.graphics.setShader(Kristal.Shaders["AddColor"])

            Kristal.Shaders["AddColor"]:send("inputcolor", {0, 0, 0, 1})
            Kristal.Shaders["AddColor"]:send("amount", 1)

            self:drawCharacter(object)

            love.graphics.setShader()
        end
    end

    Draw.popCanvas()

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.draw(self.canvas)
    love.graphics.setColor(1, 1, 1, 1)
end

return Silhouette