---@class LabelMenuItemComponent : AbstractMenuItemComponent
---@overload fun(...) : LabelMenuItemComponent
local LabelMenuItemComponent, super = Class(AbstractMenuItemComponent)

function LabelMenuItemComponent:init(text, child, x_sizing, y_sizing, options)
    super.init(self, x_sizing or FillSizing(), y_sizing or FitSizing(), nil, options)

    self:setLayout(HorizontalLayout({align="space-between"}))

    if type(text) == "string" then
        text = Text(text)
    end
    self.text = self:addChild(text)

    self.child = self:addChild(child)
end

function LabelMenuItemComponent:update()
    super.update(self)
end

function LabelMenuItemComponent:onHovered(hovered, initial)
    self.child:onHovered(hovered, initial)
end

function LabelMenuItemComponent:onSelected()
    self.child:onSelected()
end

function LabelMenuItemComponent:setFocused()
    self.child:setFocused()
end

return LabelMenuItemComponent
