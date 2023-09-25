---@class HorizontalLayout : Layout
---@overload fun(...) : HorizontalLayout
local HorizontalLayout, super = Class(Layout)

---@param parent? UIComponent
function HorizontalLayout:init(parent)
    super.init(self, parent)
end

function HorizontalLayout:refresh()
    super.refresh(self)
    local x_position = 0
    for _, child in ipairs(self.parent.children) do
        x_position = x_position + child.x
        child.x = x_position
        x_position = x_position + child:getTotalSize()[1]
    end
end

return HorizontalLayout
