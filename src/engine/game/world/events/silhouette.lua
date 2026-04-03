--- A region in the Overworld that draws silhouettes of character's inside it that draw on top of the world. The original characters are not hidden. \
--- `Silhouette` is an [`Event`](lua://Event.init) - naming an object `silhouette` on an `objects` layer in a map creates this object. \
---@class Silhouette : Event
---
---@field solid boolean
---
---@field color Color *[Property `color`]* The color that will be used for the silhouette. (Defaults to `{ 0, 0, 0, 0.5 }`)
---
---@overload fun(...) : Silhouette
local Silhouette, super = Class(Event)

function Silhouette:init(x, y, shape, properties)
    super.init(self, x, y, shape)

    properties = properties or {}

    self.solid = false

    self.color = TiledUtils.parseColorProperty(properties["color"]) or { 0, 0, 0, 0.5 }
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

    love.graphics.setShader(Kristal.Shaders["White"])
    Kristal.Shaders["White"]:send("whiteAmount", 1)
    for _, object in ipairs(Game.world.children) do
        if object:includes(Character) then
            self:drawCharacter(object)
        end
    end
    love.graphics.setShader()

    Draw.popCanvas()

    Draw.setColor(self.color)
    Draw.draw(canvas)
    Draw.setColor(1, 1, 1, 1)
end

return Silhouette
