---@class HorizontalLayout : Layout
---@overload fun(...) : HorizontalLayout
local HorizontalLayout, super = Class(Layout)

function HorizontalLayout:init(options)
    super.init(self, options)
end

function HorizontalLayout:refresh()
    super.refresh(self)

    if self.align == "start" then
        local x_position = 0
        for _, child in ipairs(self:getComponents()) do
            child.x = child.x + x_position
            local width, _ = child:getScaledSize()
            x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
            x_position = x_position + self.gap
        end
    elseif self.align == "end" then
        local x_position = ({self:getInnerArea()})[2] - self:calculateTotalSize()
        for _, child in ipairs(self:getComponents()) do
            child.x = child.x + x_position
            local width, _ = child:getScaledSize()
            x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
            x_position = x_position + self.gap
        end
    elseif self.align == "center" then
        local x_position = (({self:getInnerArea()})[1] - self:calculateTotalSize()) / 2
        for _, child in ipairs(self:getComponents()) do
            child.x = child.x + x_position
            local width, _ = child:getScaledSize()
            x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
            x_position = x_position + self.gap
        end
    elseif self.align == "space-between" then
        local x_position = 0
        local total_width = self:calculateTotalSize()
        local gap = (self.parent.width - total_width) / (#self:getComponents() - 1)
        for _, child in ipairs(self:getComponents()) do
            child.x = child.x + x_position
            local width, _ = child:getScaledSize()
            x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
            x_position = x_position + gap
        end
    elseif self.align == "space-around" then
        local x_position = 0
        local total_width = self:calculateTotalSize()
        local gap = (self.parent.width - total_width) / (#self:getComponents() * 2)
        for _, child in ipairs(self:getComponents()) do
            x_position = x_position + gap
            child.x = child.x + x_position
            local width, _ = child:getScaledSize()
            x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
            x_position = x_position + gap
        end
    elseif self.align == "space-evenly" then
        local x_position = 0
        local total_width = self:calculateTotalSize()
        local gap = (self.parent.width - total_width) / (#self:getComponents() + 1)
        for _, child in ipairs(self:getComponents()) do
            x_position = x_position + gap
            child.x = child.x + x_position
            local width, _ = child:getScaledSize()
            x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
        end
    end
end

function HorizontalLayout:calculateTotalSize()
    local x_position = 0
    for index, child in ipairs(self:getComponents()) do
        local width, _ = child:getScaledSize()
        x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
        if index ~= #self:getComponents() then
            x_position = x_position + self.gap
        end
    end
    return x_position
end

function HorizontalLayout:draw()
    love.graphics.setColor(1,0,1,0.25)
    if self.align == "start" then
        local x_position = self:calculateTotalSize()
        Draw.rectangle("stripes", x_position, 0, self.parent.width - x_position, self.parent.height)
        Draw.rectangle("line", x_position, 0, self.parent.width - x_position, self.parent.height)
    elseif self.align == "end" then
        local x_position = self:calculateTotalSize()
        Draw.rectangle("stripes", 0, 0, self.parent.width - x_position, self.parent.height)
        Draw.rectangle("line", 0, 0, self.parent.width - x_position, self.parent.height)
    elseif self.align == "center" then
        -- top and bottom
        local x_position = self:calculateTotalSize()
        Draw.rectangle("stripes", 0, 0, (self.parent.width - x_position) / 2, self.parent.height)
        Draw.rectangle("line", 0, 0, (self.parent.width - x_position) / 2, self.parent.height)
        Draw.rectangle("stripes", self.parent.width - (self.parent.width - x_position) / 2, 0, (self.parent.width - x_position) / 2, self.parent.height)
        Draw.rectangle("line", self.parent.width - (self.parent.width - x_position) / 2, 0, (self.parent.width - x_position) / 2, self.parent.height)
    end
end

return HorizontalLayout
