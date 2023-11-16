---@class VerticalLayout : Layout
---@overload fun(...) : VerticalLayout
local VerticalLayout, super = Class(Layout)

function VerticalLayout:init(options)
    super.init(self, options)
end

function VerticalLayout:refresh()
    super.refresh(self)

    if self.align == "start" then
        local y_position = 0
        for _, child in ipairs(self:getComponents()) do
            child.y = child.y + y_position
            local _, height = child:getScaledSize()
            y_position = y_position + (child.getTotalSize and ({child:getTotalSize()})[2] or height)
            y_position = y_position + self.gap
        end
    elseif self.align == "end" then
        local y_position = ({self:getInnerArea()})[2] - self:calculateTotalSize()
        for _, child in ipairs(self:getComponents()) do
            child.y = child.y + y_position
            local _, height = child:getScaledSize()
            y_position = y_position + (child.getTotalSize and ({child:getTotalSize()})[2] or height)
            y_position = y_position + self.gap
        end
    elseif self.align == "center" then
        local y_position = (({self:getInnerArea()})[2] - self:calculateTotalSize()) / 2
        for _, child in ipairs(self:getComponents()) do
            child.y = child.y + y_position
            local _, height = child:getScaledSize()
            y_position = y_position + (child.getTotalSize and ({child:getTotalSize()})[2] or height)
            y_position = y_position + self.gap
        end
    elseif self.align == "space-between" then
        local y_position = 0
        local total_height = self:calculateTotalSize()
        local gap = (self.parent.height - total_height) / (#self:getComponents() - 1)
        for _, child in ipairs(self:getComponents()) do
            child.y = child.y + y_position
            local _, height = child:getScaledSize()
            y_position = y_position + (child.getTotalSize and ({child:getTotalSize()})[2] or height)
            y_position = y_position + gap
        end
    elseif self.align == "space-around" then
        local y_position = 0
        local total_height = self:calculateTotalSize()
        local gap = (self.parent.height - total_height) / (#self:getComponents() * 2)
        for _, child in ipairs(self:getComponents()) do
            y_position = y_position + gap
            child.y = child.y + y_position
            local _, height = child:getScaledSize()
            y_position = y_position + (child.getTotalSize and ({child:getTotalSize()})[2] or height)
            y_position = y_position + gap
        end
    elseif self.align == "space-evenly" then
        local y_position = 0
        local total_height = self:calculateTotalSize()
        local gap = (self.parent.height - total_height) / (#self:getComponents() + 1)
        for _, child in ipairs(self:getComponents()) do
            y_position = y_position + gap
            child.y = child.y + y_position
            local _, height = child:getScaledSize()
            y_position = y_position + (child.getTotalSize and ({child:getTotalSize()})[2] or height)
            y_position = y_position + gap
        end
    end
end

function VerticalLayout:calculateTotalSize()
    local y_position = 0
    for index, child in ipairs(self:getComponents()) do
        local _, height = child:getScaledSize()
        y_position = y_position + (child.getTotalSize and ({child:getTotalSize()})[2] or height)
        if index ~= #self:getComponents() then
            y_position = y_position + self.gap
        end
    end
    return y_position
end

function VerticalLayout:draw()
    love.graphics.setColor(1,0,1,0.25)
    if self.align == "start" then
        local y_position = self:calculateTotalSize()
        Draw.rectangle("stripes", 0, y_position, self.parent.width, self.parent.height - y_position)
        Draw.rectangle("line", 0, y_position, self.parent.width, self.parent.height - y_position)
    elseif self.align == "end" then
        local y_position = self:calculateTotalSize()
        Draw.rectangle("stripes", 0, 0, self.parent.width, self.parent.height - y_position)
        Draw.rectangle("line", 0, 0, self.parent.width, self.parent.height - y_position)
    elseif self.align == "center" then
        -- top and bottom
        local y_position = self:calculateTotalSize()
        Draw.rectangle("stripes", 0, 0, self.parent.width, (self.parent.height - y_position) / 2)
        Draw.rectangle("line", 0, 0, self.parent.width, (self.parent.height - y_position) / 2)
        Draw.rectangle("stripes", 0, self.parent.height - (self.parent.height - y_position) / 2, self.parent.width, (self.parent.height - y_position) / 2)
        Draw.rectangle("line", 0, self.parent.height - (self.parent.height - y_position) / 2, self.parent.width, (self.parent.height - y_position) / 2)
    end
end

return VerticalLayout
