---@class MaskFX : FXBase
---@overload fun(...) : MaskFX
local MaskFX, super = Class(FXBase)

function MaskFX:init(mask, draw_children, priority)
    super.init(self, priority or 1000)

    self.mask = mask
    if draw_children ~= nil then
        self.draw_children = draw_children
    else
        self.draw_children = mask ~= nil
    end

    self.inverted = false
end

function MaskFX:draw(texture)
    local mask_obj
    if not self.mask then
        mask_obj = self.parent
    elseif isClass(self.mask) then
        mask_obj = self.mask
    end
    local mask = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    if type(self.mask) == "function" then
        local result = self.mask()
        if result then
            mask_obj = result
        end
    end
    if mask_obj then
        love.graphics.applyTransform(mask_obj.parent:getFullTransform())
        if mask_obj.drawMask then
            mask_obj:preDraw()
            mask_obj:drawMask()
            mask_obj:postDraw()
        else
            mask_obj:fullDraw(not self.draw_children)
        end
    end
    Draw.popCanvas()

    Draw.setColor(1, 1, 1)

    local drawStencil = function()
        Draw.pushShader("Mask")
        Draw.drawCanvas(mask)
        Draw.popShader()
    end

    local major, _, _, _ = love.getVersion()

    if major >= 12 then
        love.graphics.setStencilMode("draw", 1, "always")
        love.graphics.clear(false, true, false)

        drawStencil()

        if not self.inverted then
            love.graphics.setStencilMode("test", 1, "less")
        else
            love.graphics.setStencilMode("test", 0, "greater")
        end
    else
        love.graphics.stencil(drawStencil, "replace", 1)

        if not self.inverted then
            love.graphics.setStencilTest("greater", 0)
        else
            love.graphics.setStencilTest("less", 1)
        end
    end

    Draw.drawCanvas(texture)

    if major >= 12 then
        love.graphics.setStencilMode()
    else
        love.graphics.setStencilTest()
    end
end

return MaskFX
