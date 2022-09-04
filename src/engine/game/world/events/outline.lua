--- A region in the Overworld that draws a colored stencil outline for all [`Character`](lua://Character.init)'s inside. \
--- `Outline` is an [`Event`](lua://Event.init) - naming an object `outline` on an `objects` layer in a map creates this object. \
--- The color of a Character's outline is affected by the [color of it's actor](lua://Actor.getColor)
---
---@class Outline : Event
---
---@field solid     boolean
---@field shader    love.Shader
---
---@overload fun(...) : Outline
local Outline, super = Class(Event)

function Outline:init(x, y, shape)
    super.init(self, x, y, shape)

    self.solid = false

    self.shader = love.graphics.newShader([[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
           if (Texel(texture, texture_coords).a == 0.0) {
              // a discarded pixel wont be applied as the stencil.
              discard;
           }
           return vec4(1.0);
        }
    ]])
end

---@param object Object
function Outline:drawCharacter(object)
    love.graphics.push()
    object:preDraw()
    object:draw()
    object:postDraw()
    love.graphics.pop()
end

---@param object Object
function Outline:drawMask(object)
    love.graphics.setShader(self.shader)
    self:drawCharacter(object)
    love.graphics.setShader()
end

function Outline:draw()
    super.draw(self)

    local canvas = Draw.pushCanvas(self.width, self.height)
    love.graphics.clear()

    love.graphics.translate(-self.x, -self.y)

    for _, object in ipairs(Game.world.children) do
        if object:includes(Character) then

            love.graphics.setColorMask(false)
            love.graphics.setStencilMode("replace", "always", 1)
            love.graphics.clear()

            self:drawMask(object)

            love.graphics.setStencilMode("keep", "less", 1)
            love.graphics.setColorMask(true)

            love.graphics.setShader(Kristal.Shaders["AddColor"])

            Kristal.Shaders["AddColor"]:sendColor("inputcolor", { object.actor:getColor() })
            Kristal.Shaders["AddColor"]:send("amount", 1)

            love.graphics.translate(-2, 0)
            self:drawCharacter(object)
            love.graphics.translate(2, 0)

            love.graphics.translate(2, 0)
            self:drawCharacter(object)
            love.graphics.translate(-2, 0)

            love.graphics.translate(0, 2)
            self:drawCharacter(object)
            love.graphics.translate(0, -2)

            love.graphics.translate(0, -2)
            self:drawCharacter(object)
            love.graphics.translate(0, 2)

            love.graphics.setShader()

            love.graphics.setStencilMode()
        end
    end

    Draw.popCanvas()

    Draw.draw(canvas)
end

return Outline
