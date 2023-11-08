---@class Layout : Class
---
---@field parent Component|nil
local Layout = Class()

function Layout:init(options)
    options = options or {}
    self.gap = options.gap or 0
    self.align = options.align or "start"
end

function Layout:refresh()
    -- offset the children by the parent's padding
    for i, child in ipairs(self.parent.children) do
        child.x = self.parent.padding[1]
        child.y = self.parent.padding[2]
    end
end

function Layout:getInnerArea()
    local width, height = self.parent:getSize()
    width = width - self.parent.padding[1] - self.parent.padding[3]
    height = height - self.parent.padding[2] - self.parent.padding[4]
    return width, height
end

return Layout
