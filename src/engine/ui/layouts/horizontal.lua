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
        for _, child in ipairs(self.parent.children) do
            child.x = child.x + x_position
            local width, _ = child:getSize()
            x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
            x_position = x_position + self.gap
        end
    elseif self.align == "end" then
        local x_position = ({self:getInnerArea()})[2] - self:calculateTotalSize()
        for _, child in ipairs(self.parent.children) do
            child.x = child.x + x_position
            local width, _ = child:getSize()
            x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
            x_position = x_position + self.gap
        end
    elseif self.align == "center" then
        local x_position = (({self:getInnerArea()})[1] - self:calculateTotalSize()) / 2
        for _, child in ipairs(self.parent.children) do
            child.x = child.x + x_position
            local width, _ = child:getSize()
            x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
            x_position = x_position + self.gap
        end
    end
end

function HorizontalLayout:calculateTotalSize()
    local x_position = 0
    for index, child in ipairs(self.parent.children) do
        local width, _ = child:getSize()
        x_position = x_position + (child.getTotalSize and ({child:getTotalSize()})[1] or width)
        if index ~= #self.parent.children then
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
