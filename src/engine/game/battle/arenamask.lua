local ArenaMask, super = Class(Object)

function ArenaMask:init(layer, x, y, arena)
    super:init(self, x, y)

    self.layer = layer or Utils.lerp(LAYERS["below_bullets"], LAYERS["bullets"], 0.5)
    self.arena = arena
end

function ArenaMask:getArena()
    return self.arena or Game.battle.arena
end

function ArenaMask:preDraw()
    super:preDraw(self)
    local arena = self:getArena()
    if arena and arena.visible then
        love.graphics.stencil(function()
            love.graphics.push()
            love.graphics.origin()
            love.graphics.applyTransform(arena:getFullTransform())
            love.graphics.setColor(1, 1, 1)
            arena:drawMask()
            love.graphics.pop()
        end)
        love.graphics.setStencilTest("greater", 0)
    end
end

function ArenaMask:postDraw()
    local arena = self:getArena()
    if arena and arena.visible then
        love.graphics.setStencilTest()
    end
    super:postDraw(self)
end

return ArenaMask