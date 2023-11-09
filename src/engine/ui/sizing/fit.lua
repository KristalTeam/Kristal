---@class FitSizing : Sizing
---@overload fun(...) : FitSizing
local FitSizing, super = Class(Sizing)

function FitSizing:init()
    super.init(self)
end

function FitSizing:getWidth()
    local width = 0
    for _, child in ipairs(self:getComponents()) do
        local x = child.x - ({self.parent:getScaledPadding()})[1] - (child.margins and ({child:getScaledMargins()})[1] or 0)
        local child_width, _ = child:getScaledSize()
        if (child.getTotalSize) then child_width, _ = child:getTotalSize() end
        child_width = x + child_width
        if child_width > width then
            width = child_width
        end
    end
    return width + ({self.parent:getScaledPadding()})[1] + ({self.parent:getScaledPadding()})[3]
end

function FitSizing:getHeight()
    local height = 0
    for _, child in ipairs(self:getComponents()) do
        local y = child.y - ({self.parent:getScaledPadding()})[2] - (child.margins and ({child:getScaledMargins()})[2] or 0)
        local _, child_height = child:getScaledSize()
        if (child.getTotalSize) then _, child_height = child:getTotalSize() end
        child_height = y + child_height
        if child_height > height then
            height = child_height
        end
    end
    return height + ({self.parent:getScaledPadding()})[2] + ({self.parent:getScaledPadding()})[4]
end

function FitSizing:refresh()
    super.refresh(self)
end

return FitSizing
