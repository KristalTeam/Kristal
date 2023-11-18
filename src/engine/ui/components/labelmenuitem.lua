---@class LabelMenuItemComponent : AbstractMenuItemComponent
---@field text Text
---@field child AbstractMenuItemComponent
---@overload fun(...) : LabelMenuItemComponent
local LabelMenuItemComponent, super = Class(AbstractMenuItemComponent)

---@param text string|Text
---@param child AbstractMenuItemComponent
---@param x_sizing? Sizing
---@param y_sizing? Sizing
---@param options? table
function LabelMenuItemComponent:init(text, child, x_sizing, y_sizing, options)
    super.init(self, x_sizing or FillSizing(), y_sizing or FitSizing(), nil, options)

    self:setLayout(HorizontalLayout({align="space-between"}))

    if type(text) == "string" then
        text = Text(text)
    end
    self.text = self:addChild(text)

    if not child.parent then
        self:addChild(child)
    end

    self.child = child
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
