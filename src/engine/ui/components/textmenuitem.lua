---@class TextMenuItemComponent : AbstractMenuItemComponent
---@overload fun(...) : TextMenuItemComponent
local TextMenuItemComponent, super = Class(AbstractMenuItemComponent)

function TextMenuItemComponent:init(text, callback)
    super.init(self, 0, 0, FitSizing(), FitSizing(), callback)

    self.text = self:addChild(Text(text))

    self.color = COLORS.yellow
    self.selected_color = COLORS.white
end

function TextMenuItemComponent:onHovered(hovered, initial)
    super.onHovered(self, hovered, initial)

    if hovered then
        self.text:setColor(self.color)
    else
        self.text:setColor(self.selected_color)
    end
end

return TextMenuItemComponent
