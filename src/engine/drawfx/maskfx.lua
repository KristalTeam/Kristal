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
    love.graphics.stencil(function()
        local last_shader = love.graphics.getShader()
        love.graphics.setShader(Kristal.Shaders["Mask"])
        Draw.draw(mask)
        love.graphics.setShader(last_shader)
    end, "replace", 1)
    if not self.inverted then
        love.graphics.setStencilTest("greater", 0)
    else
        love.graphics.setStencilTest("less", 1)
    end
    Draw.drawCanvas(texture)
    love.graphics.setStencilTest()
end

return MaskFX