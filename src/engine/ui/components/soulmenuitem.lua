---@class SoulMenuItemComponent : AbstractMenuItemComponent
---@overload fun(...) : SoulMenuItemComponent
local SoulMenuItemComponent, super = Class(AbstractMenuItemComponent)

function SoulMenuItemComponent:init(child, callback)
    super.init(self, 0, 0, FitSizing(), FitSizing(), callback)
    self:setPadding(28, 0, 0, 0)
    if child then
        self:addChild(child)
    end
end

function SoulMenuItemComponent:draw()
    super.draw(self)

    if self.selected then
        love.graphics.setColor(COLORS.red)
        love.graphics.draw(Assets.getTexture("player/heart_menu"), 0, 10, 0, 2, 2)
    end
end

return SoulMenuItemComponent
