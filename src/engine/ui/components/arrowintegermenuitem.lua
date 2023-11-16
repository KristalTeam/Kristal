---@class ArrowIntegerMenuItemComponent : IntegerMenuItemComponent
---@field offset number
---@field hide_unfocused_arrows boolean
---@overload fun(...) : ArrowIntegerMenuItemComponent
local ArrowIntegerMenuItemComponent, super = Class(IntegerMenuItemComponent)

---@param from integer
---@param to integer
---@param value integer
---@param on_changed? function
---@param options? table
function ArrowIntegerMenuItemComponent:init(from, to, value, on_changed, options)
    super.init(self, from, to, value, on_changed, options)
    options = options or {}

    self.offset = options.offset or 26
    self:setPadding(self.offset, 0, self.offset, 0)

    self.hide_unfocused_arrows = options.hide_unfocused_arrows or false
end

function ArrowIntegerMenuItemComponent:onSelected()
    Assets.playSound("ui_select")
    self:setFocused()
    if self.selected_color then
        self.text:setColor(self.selected_color)
    end
end

function ArrowIntegerMenuItemComponent:draw()
    super.draw(self)

    local off = 0
    love.graphics.setColor(self.color)
    if self:isFocused() then
        love.graphics.setColor(self.selected_color)
        off = (math.sin(Kristal.getTime() / 0.2) * 2)
    end

    if not self.hide_unfocused_arrows or self:isFocused() then
        Draw.draw(Assets.getTexture("kristal/menu_arrow_left"), -off, 4, 0, 2, 2)
        Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), self.width - 16 + off, 4, 0, 2, 2)
    end
end

return ArrowIntegerMenuItemComponent
