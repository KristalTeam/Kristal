---@class SoulMenuItemComponent : AbstractMenuItemComponent
---@overload fun(...) : SoulMenuItemComponent
local SoulMenuItemComponent, super = Class(AbstractMenuItemComponent)

function SoulMenuItemComponent:init(child, callback, options)
    super.init(self, FitSizing(), FitSizing(), callback, options)
    self:setPadding(28, 0, 0, 0)
    self.draw_soul = true

    if child then
        self:addChild(child)
    end
end

function SoulMenuItemComponent:onAdd(parent)
    super.onAdd(self, parent)
    -- check if the parent is a EasingSoulMenuComponent
    if parent:includes(EasingSoulMenuComponent) then
        self:setPadding(0, 0, 0, 0)
        self.draw_soul = false
    end
end

function SoulMenuItemComponent:draw()
    super.draw(self)

    if self.draw_soul and self.selected then
        love.graphics.setColor(Kristal.getSoulColor())
        love.graphics.draw(Assets.getTexture("player/heart_menu"), 0, 10, 0, 2, 2)
    end
end

return SoulMenuItemComponent
