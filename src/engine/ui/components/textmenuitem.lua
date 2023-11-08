---@class TextMenuItemComponent : AbstractMenuItemComponent
---@overload fun(...) : TextMenuItemComponent
local TextMenuItemComponent, super = Class(AbstractMenuItemComponent)

function TextMenuItemComponent:init(text, callback)
    super.init(self, 0, 0, FillSizing(), FitSizing())

    self.text = self:addChild(Text(text))

    self.color = COLORS.yellow
    self.selected_color = COLORS.white

    self.callback = callback
end

function TextMenuItemComponent:onHovered(hovered, initial)
    super.onHovered(self, hovered, initial)

    if hovered then
        self.text:setColor(self.color)
    else
        self.text:setColor(self.selected_color)
    end
end

function TextMenuItemComponent:onSelected()
    super.onSelected(self)

    if self.callback then
        self:callback()
    end
end

return TextMenuItemComponent
