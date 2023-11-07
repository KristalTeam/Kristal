---@class HorizontalLayout : Layout
---@overload fun(...) : HorizontalLayout
local HorizontalLayout, super = Class(Layout)

function HorizontalLayout:init(gap)
    super.init(self)
    self.gap = gap
end

function HorizontalLayout:refresh()
    super.refresh(self)
    local x_position = 0
    for _, child in ipairs(self.parent.children) do
        child.x = child.x + x_position
        local width, _ = child:getSize()
        x_position = x_position + (child.getTotalSize and child:getTotalSize()[1] or width)
        x_position = x_position + self.gap
    end
end

return HorizontalLayout
