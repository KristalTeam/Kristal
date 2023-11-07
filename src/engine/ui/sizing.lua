---@class Sizing : Class
---
---@field parent UIComponent|nil
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

return Sizing
