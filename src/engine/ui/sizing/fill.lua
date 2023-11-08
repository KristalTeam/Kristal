---@class FillSizing : Sizing
---@overload fun(...) : FillSizing
local FillSizing, super = Class(Sizing)

function FillSizing:init()
    super.init(self)
end

function FillSizing:getWidth()
    return self.parent.parent.width - self.parent.parent.padding[1] - self.parent.parent.padding[3]
end

function FillSizing:getHeight()
    return self.parent.parent.height - self.parent.parent.padding[2] - self.parent.parent.padding[4]
end

function FillSizing:refresh()
    super.refresh(self)
end

return FillSizing
