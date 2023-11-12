---@class TextMenuItemComponent : AbstractMenuItemComponent
---@overload fun(...) : TextMenuItemComponent
local TextMenuItemComponent, super = Class(AbstractMenuItemComponent)

function TextMenuItemComponent:init(text, callback, options)
    super.init(self, 0, 0, FitSizing(), FitSizing(), callback)

    options = options or {}

    if type(text) == "string" then
        text = Text(text)
    end
    self.text = self:addChild(text)

    self.highlight = options.highlight ~= false

    self.color = options.color or COLORS.yellow
    self.selected_color = options.selected_color or COLORS.white
end

function TextMenuItemComponent:onHovered(hovered, initial)
    super.onHovered(self, hovered, initial)

    if self.highlight and hovered then
        self.text:setColor(self.color)
    else
        self.text:setColor(self.selected_color)
    end
end

return TextMenuItemComponent
