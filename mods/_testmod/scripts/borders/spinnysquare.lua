---@class Border.spinnysquare: Border
local SpinnySquare, super = Class(Border)

function SpinnySquare:init()
    super.init(self)
end

function SpinnySquare:drawRect(max_depth, white)
    if max_depth < 0 then return end
    love.graphics.push("all")
    if white then
        Draw.setColor(1,1,1)
    else
        Draw.setColor(0.2,0.2,0.2)
    end
    love.graphics.scale(
        Utils.clampMap(
            math.sin(Kristal.getTime()),
            -1, 1, 0.6, 0.93
        )
    )
    love.graphics.rotate(math.rad(20))
    love.graphics.rectangle("fill", -1000*BORDER_SCALE, -1000*BORDER_SCALE, 1000*2*BORDER_SCALE, 1000*2*BORDER_SCALE)
    self:drawRect(max_depth - 1, not white)
    love.graphics.pop()
end

function SpinnySquare:draw()
    love.graphics.push("all")
    love.graphics.translate(1920*0.5*BORDER_SCALE, 1080*0.5*BORDER_SCALE)
    love.graphics.scale(2)
    love.graphics.rotate(math.rad(Kristal.getTime() * 20))

    self:drawRect(20, true)
    love.graphics.pop()
    -- TODO: find a better way to add the fading
    Draw.setColor(COLORS.black, 1-BORDER_ALPHA)
    love.graphics.rectangle("fill", -love.graphics.getWidth(), -love.graphics.getHeight(), love.graphics.getWidth()*2, love.graphics.getHeight()*2)
end

return SpinnySquare