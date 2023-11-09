---@class FillSizing : FitSizing
---@overload fun(...) : FillSizing
local FillSizing, super = Class(FitSizing)

function FillSizing:init()
    super.init(self)
end

function FillSizing:getWidth()
    local width, _ = self.parent.parent:getWorkingSize()
    return math.max(super.getWidth(self), width)
end

function FillSizing:getHeight()
    local _, height = self.parent.parent:getWorkingSize()
    return math.max(super.getHeight(self), height)
end

function FillSizing:refresh()
    super.refresh(self)
end

return FillSizing
