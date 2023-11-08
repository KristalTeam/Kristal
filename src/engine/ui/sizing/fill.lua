---@class FillSizing : FitSizing
---@overload fun(...) : FillSizing
local FillSizing, super = Class(FitSizing)

function FillSizing:init()
    super.init(self)
end

function FillSizing:getWidth()
    return math.max(super.getWidth(self), self.parent.parent.width - self.parent.parent.padding[1] - self.parent.parent.padding[3])
end

function FillSizing:getHeight()
    return math.max(super.getHeight(self), self.parent.parent.height - self.parent.parent.padding[2] - self.parent.parent.padding[4])
end

function FillSizing:refresh()
    super.refresh(self)
end

return FillSizing
