---@class FixedSizing : Sizing
---@overload fun(...) : FixedSizing
local FixedSizing, super = Class(Sizing)

function FixedSizing:init(width, height)
    super.init(self)
    self.width = width
    self.height = height
end

function FixedSizing:getWidth()
    return self.width
end

function FixedSizing:getHeight()
    return self.height
end

function FixedSizing:refresh()
    super.refresh(self)
end

return FixedSizing
