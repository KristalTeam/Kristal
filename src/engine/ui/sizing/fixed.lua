---@class FixedSizing : Sizing
---@overload fun(...) : FixedSizing
local FixedSizing, super = Class(Sizing)

function FixedSizing:init(width, height)
    super.init(self)
    self.width = width
    self.height = height or width
end

---@return number width
function FixedSizing:getWidth()
    return self.width
end

---@return number height
function FixedSizing:getHeight()
    return self.height
end

function FixedSizing:refresh()
    super.refresh(self)
end

return FixedSizing
