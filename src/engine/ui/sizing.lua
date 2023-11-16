---@class Sizing : Class
---
---@field parent Component|nil
local Sizing = Class()

function Sizing:init()
end

function Sizing:refresh()
end

---@return number width
function Sizing:getWidth()
    return self.parent.width
end

---@return number height
function Sizing:getHeight()
    return self.parent.height
end

---@return number width, number height
function Sizing:getSize()
    return self:getWidth(), self:getHeight()
end

---@return Object[] components
function Sizing:getComponents()
    return self.parent:getComponents()
end

return Sizing
