---@class ArrowListMenuItemComponent : ListMenuItemComponent
---@overload fun(...) : ArrowListMenuItemComponent
local ArrowListMenuItemComponent, super = Class(ListMenuItemComponent)

function ArrowListMenuItemComponent:init(list, value, on_changed, options)
    super.init(self, list, value, on_changed, options)
    options = options or {}

    self.offset = options.offset or 26
    self:setPadding(self.offset, 0, self.offset, 0)
end

function ArrowListMenuItemComponent:onSelected()
    Assets.playSound("ui_select")
    self:setFocused(true)
    if self.selected_color then
        self.text:setColor(self.selected_color)
    end
end

function ArrowListMenuItemComponent:draw()
    super.draw(self)

    local off = 0
    love.graphics.setColor(self.color)
    if self:isFocused() then
        love.graphics.setColor(self.selected_color)
        off = (math.sin(Kristal.getTime() / 0.2) * 2)
    end

    Draw.draw(Assets.getTexture("kristal/menu_arrow_left"), -off, 4, 0, 2, 2)
    Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), self.width - 16 + off, 4, 0, 2, 2)
end

return ArrowListMenuItemComponent
