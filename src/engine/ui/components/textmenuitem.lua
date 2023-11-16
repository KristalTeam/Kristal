---@class TextMenuItemComponent : AbstractMenuItemComponent
---@field text Text
---@field highlight boolean
---@field color table
---@field selected_color table
---@overload fun(...) : TextMenuItemComponent
local TextMenuItemComponent, super = Class(AbstractMenuItemComponent)

---@param text Text|string
---@param callback? function
---@param options? table
function TextMenuItemComponent:init(text, callback, options)
    super.init(self, FitSizing(), FitSizing(), callback, options)

    options = options or {}

    if type(text) == "string" then
        text = Text(text)
    end
    self.text = self:addChild(text)

    self.highlight = options.highlight ~= false

    self.color = options.color or COLORS.yellow
    self.selected_color = options.selected_color or COLORS.white
end

---@param hovered boolean
---@param initial boolean
function TextMenuItemComponent:onHovered(hovered, initial)
    super.onHovered(self, hovered, initial)

    if self.highlight and hovered then
        self.text:setColor(self.color)
    else
        self.text:setColor(self.selected_color)
    end
end

return TextMenuItemComponent
