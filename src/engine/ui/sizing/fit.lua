---@class FitSizing : Sizing
---@field parent Component
---@overload fun(...) : FitSizing
local FitSizing, super = Class(Sizing)

function FitSizing:init()
    super.init(self)
end

---@return number width
function FitSizing:getWidth()
    local width = 0
    for _, child in ipairs(self:getComponents()) do
        if child.x_sizing and child.x_sizing:includes(FillSizing) then goto continue end
        local x = child.x - ({self.parent:getScaledPadding()})[1] - (child.margins and ({child:getScaledMargins()})[1] or 0)
        local child_width, _ = child:getScaledSize()
        if (child.getTotalSize) then child_width, _ = child:getTotalSize() end
        child_width = x + child_width
        if child_width > width then
            width = child_width
        end
        ::continue::
    end
    return width + ({self.parent:getScaledPadding()})[1] + ({self.parent:getScaledPadding()})[3]
end

---@return number height
function FitSizing:getHeight()
    local height = 0
    for _, child in ipairs(self:getComponents()) do
        if child.y_sizing and child.y_sizing:includes(FillSizing) then goto continue end
        local y = child.y - ({self.parent:getScaledPadding()})[2] - (child.margins and ({child:getScaledMargins()})[2] or 0)
        local _, child_height = child:getScaledSize()
        if (child.getTotalSize) then _, child_height = child:getTotalSize() end
        child_height = y + child_height
        if child_height > height then
            height = child_height
        end
        ::continue::
    end
    return height + ({self.parent:getScaledPadding()})[2] + ({self.parent:getScaledPadding()})[4]
end

function FitSizing:refresh()
    super.refresh(self)
end

return FitSizing
