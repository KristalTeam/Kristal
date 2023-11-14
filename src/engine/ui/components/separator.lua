---@class SeparatorComponent : Component
---@field vertical boolean
---@overload fun(...) : SeparatorComponent
local SeparatorComponent, super = Class(Component)

---@param options? table
function SeparatorComponent:init(options)
    options = options or {}
    self.vertical = options.vertical or false
    super.init(self, self.vertical and FixedSizing(8) or FillSizing(), self.vertical and FillSizing() or FixedSizing(8), options)
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
