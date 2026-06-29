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
    Draw.pushShader("Mask")
    self:drawCharacter(object)
    Draw.popShader()
end

function Outline:draw()
    super.draw(self)

    local canvas = Draw.pushCanvas(self.width, self.height)
    love.graphics.clear()

    love.graphics.translate(-self.x, -self.y)

    local major, _, _, _ = love.getVersion()

    for _, object in ipairs(Game.world.children) do
        if object:includes(Character) then
            if major >= 12 then
                love.graphics.clear(false, true, false)
                love.graphics.setStencilMode("draw", 1, "replace")

                self:drawMask(object)

                love.graphics.setStencilMode("test", 0, "greater")
            else
                love.graphics.stencil(function() self:drawMask(object) end, "replace", 1)
                love.graphics.setStencilTest("less", 1)
            end

            local shader = Draw.pushShader(Kristal.Shaders["AddColor"], { amount = 1 })
            shader:sendColor("inputcolor", { object.actor:getColor() })

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

            Draw.popShader()

            if major >= 12 then
                love.graphics.setStencilMode()
            else
                love.graphics.setStencilTest()
            end
        end
    end

    Draw.popCanvas()

    Draw.draw(canvas)
end

return Outline
