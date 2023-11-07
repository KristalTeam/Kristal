---@class Layout : Class
---
---@field parent UIComponent|nil
local Layout = Class()

function Layout:init()
end

function Layout:refresh()
    -- offset the children by the parent's padding
    for i, child in ipairs(self.parent.children) do
        child.x = self.parent.padding[1]
        child.y = self.parent.padding[2]
    end
end

return Layout
