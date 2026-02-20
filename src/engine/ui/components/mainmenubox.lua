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
    Draw.setColor(self:getDrawColor())
    Draw.drawMenuRectangle(0, 0, self.width, self.height)
end

return MainMenuBoxComponent
