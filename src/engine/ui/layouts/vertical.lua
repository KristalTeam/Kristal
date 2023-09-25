---@class VerticalLayout : Layout
---@overload fun(...) : VerticalLayout
local VerticalLayout, super = Class(Layout)

---@param parent? UIComponent
function VerticalLayout:init(parent)
    super.init(self, parent)
end

function VerticalLayout:refresh()
    super.refresh(self)
    local y_position = 0
    for _, child in ipairs(self.parent.children) do
        child.y = child.y + y_position
        y_position = y_position + child:getTotalSize()[2]
    end
end

return VerticalLayout
