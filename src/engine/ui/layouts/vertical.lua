---@class VerticalLayout : Layout
---@overload fun(...) : VerticalLayout
local VerticalLayout, super = Class(Layout)

function VerticalLayout:init(gap)
    super.init(self)
    self.gap = gap or 0
end

function VerticalLayout:refresh()
    super.refresh(self)
    local y_position = 0
    for _, child in ipairs(self.parent.children) do
        child.y = child.y + y_position
        local _, height = child:getSize()
        y_position = y_position + (child.getTotalSize and child:getTotalSize()[2] or height)
        y_position = y_position + self.gap
    end
end

return VerticalLayout
