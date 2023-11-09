---@class Sizing : Class
---
---@field parent Component|nil
local Sizing = Class()

function Sizing:init()
end

function Sizing:refresh()
end

function Sizing:getWidth()
    return self.parent.width
end

function Sizing:getHeight()
    return self.parent.height
end

function Sizing:getSize()
    return self:getWidth(), self:getHeight()
end

function Sizing:getComponents()
    return self.parent:getComponents()
end

return Sizing
