---@class BooleanMenuItemComponent : AbstractMenuItemComponent
---@overload fun(...) : BooleanMenuItemComponent
local BooleanMenuItemComponent, super = Class(AbstractMenuItemComponent)

function BooleanMenuItemComponent:init(value, on_changed)
    super.init(self, 0, 0, FitSizing(), FitSizing())

    if type(value) == "function" then
        value = value()
    end
    self.value = value

    self.text = Text(value and "ON" or "OFF")
    self:addChild(self.text)

    self.on_changed = on_changed
end

function BooleanMenuItemComponent:onSelected()
    Assets.playSound("ui_select")
    self.value = not self.value
    self.text:setText(self.value and "ON" or "OFF")
    if self.on_changed then
        self:on_changed(self.value)
    end
end

return BooleanMenuItemComponent
