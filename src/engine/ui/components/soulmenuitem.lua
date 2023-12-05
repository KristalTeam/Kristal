---@class SoulMenuItemComponent : AbstractMenuItemComponent
---@field draw_soul boolean
---@overload fun(...) : SoulMenuItemComponent
local SoulMenuItemComponent, super = Class(AbstractMenuItemComponent)

---@param child Object
---@param callback? function
---@param options? table
function SoulMenuItemComponent:init(child, callback, options)
    super.init(self, FitSizing(), FitSizing(), callback, options)
    self:setPadding(28, 0, 0, 0)
    self.draw_soul = true

    if child then
        self:addChild(child)
    end
end

---@param parent Object
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

    if self.draw_soul and self.selected and self.parent:isFocused() then
        love.graphics.setColor(Kristal.getSoulColor())
        love.graphics.draw(Assets.getTexture("player/heart_menu"), 0, 10, 0, 2, 2)
    end
end

return SoulMenuItemComponent
