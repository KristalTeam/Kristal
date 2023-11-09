---@class SeparatorComponent : Component
---@overload fun(...) : SeparatorComponent
local SeparatorComponent, super = Class(Component)

function SeparatorComponent:init(x, y, vertical)
    super.init(self, x, y, vertical and FixedSizing(8) or FillSizing(), vertical and FillSizing() or FixedSizing(8))
    self.vertical = vertical
end

function SeparatorComponent:draw()
    love.graphics.setLineWidth(4)
    love.graphics.setColor(1, 1, 1, 1)
    if self.vertical then
        love.graphics.line(4, 0, 4, self.height)
    else
        love.graphics.line(0, 4, self.width, 4)
    end
end

return SeparatorComponent
