---@class MainMenuBoxComponent : Component
---@overload fun(...) : MainMenuBoxComponent
local MainMenuBoxComponent, super = Class(Component)

---@param x_sizing? Sizing
---@param y_sizing? Sizing
---@param options? table
function MainMenuBoxComponent:init(x_sizing, y_sizing, options)
    super.init(self, x_sizing, y_sizing, options)
    self:setPadding(4)
end

function MainMenuBoxComponent:draw()
    super.draw(self)

    -- Make sure the line is a single pixel wide
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    -- Set the color
    Draw.setColor(self:getDrawColor())
    -- Draw the rectangles
    love.graphics.rectangle("line", 0, 0, self.width + 1, self.height + 1)
    -- Increase the width and height by one instead of two to produce the broken effect
    love.graphics.rectangle("line", -1, -1, self.width + 2, self.height + 2)
    love.graphics.rectangle("line", -2, -2, self.width + 5, self.height + 5)
    -- Here too
    love.graphics.rectangle("line", -3, -3, self.width + 6, self.height + 6)
end

return MainMenuBoxComponent
