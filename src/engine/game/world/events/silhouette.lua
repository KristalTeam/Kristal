---@class Silhouette : Event
---@overload fun(...) : Silhouette
local Silhouette, super = Class(Event)

function Silhouette:init(x, y, w, h)
    super.init(self, x, y, w, h)

    self.solid = false
end

function Silhouette:drawCharacter(object)
    love.graphics.push()
    object:preDraw()
    object:draw()
    object:postDraw()
    love.graphics.pop()
end

function Silhouette:draw()
    super.draw(self)

    local canvas = Draw.pushCanvas(self.width, self.height)
    love.graphics.clear()

    love.graphics.translate(-self.x, -self.y)

    for _, object in ipairs(Game.world.children) do
        if object:includes(Character) then
            love.graphics.setShader(Kristal.Shaders["AddColor"])

            Kristal.Shaders["AddColor"]:send("inputcolor", { 0, 0, 0, 1 })
            Kristal.Shaders["AddColor"]:send("amount", 1)

            self:drawCharacter(object)

            love.graphics.setShader()
        end
    end

    Draw.popCanvas()

    Draw.setColor(0, 0, 0, 0.5)
    Draw.draw(canvas)
    Draw.setColor(1, 1, 1, 1)
end

return Silhouette
