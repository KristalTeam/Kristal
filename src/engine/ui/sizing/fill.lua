---@class FillSizing : FitSizing
---@field parent Component
---@overload fun(...) : FillSizing
local FillSizing, super = Class(FitSizing)

function FillSizing:init()
    super.init(self)
end

---@return number width
function FillSizing:getWidth()
    if self.parent.parent == nil then
        return super.getWidth(self)
    end

    local width, _ = self.parent.parent:getWorkingSize()
    return math.max(super.getWidth(self), width)
end

---@return number height
function FillSizing:getHeight()
    if self.parent.parent == nil then
        return super.getHeight(self)
    end

    local _, height = self.parent.parent:getWorkingSize()
    return math.max(super.getHeight(self), height)
end

function FillSizing:refresh()
    super.refresh(self)
end

return FillSizing
