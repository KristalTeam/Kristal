---@class BooleanMenuItemComponent : AbstractMenuItemComponent
---@overload fun(...) : BooleanMenuItemComponent
local BooleanMenuItemComponent, super = Class(AbstractMenuItemComponent)

function BooleanMenuItemComponent:init(value, on_changed, options)
    super.init(self, FitSizing(), FitSizing(), nil, options)

    options = options or {}

    if type(value) == "function" then
        value = value()
    end
    self.value = value

    self.on_changed = on_changed

    self.on_text = options.on_text or "ON"
    self.off_text = options.off_text or "OFF"

    self.text = Text(value and self.on_text or self.off_text)
    self:addChild(self.text)
end

function BooleanMenuItemComponent:onSelected()
    Assets.playSound("ui_select")
    self.value = not self.value
    self.text:setText(self.value and self.on_text or self.off_text)
    if self.on_changed then
        self.on_changed(self.value)
    end
end

return BooleanMenuItemComponent
