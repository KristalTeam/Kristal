---@class Component : Object
---@overload fun(...) : Component
local Component, super = Class(Object)

function Component:init(x, y, x_sizing, y_sizing)
    super.init(self, x, y, 0, 0)

    self.margins = { 0, 0, 0, 0 }
    self.padding = { 0, 0, 0, 0 }

    -- visible, hidden, scroll
    self.overflow = "visible"
    self.scroll_x = 0
    self.scroll_y = 0

    self.focused = false

    self:setLayout(Layout())
    self:setSizing(x_sizing or Sizing(), y_sizing or x_sizing or Sizing())
end

function Component:setFocused(focused)
    self.focused = focused

    -- make siblings unfocused
    if self.focused then
        if self.parent then
            for _, child in ipairs(self.parent.children) do
                if child ~= self then
                    if child.isFocused and child:isFocused() and child.setFocused then
                        child:setFocused(false)
                    end
                end
            end
            if self.parent.isFocused and (not self.parent:isFocused()) and self.parent.setFocused then
                self.parent:setFocused(true)
            end
        end
    else
        -- make all children unfocused
        for _, child in ipairs(self.children) do
            if child.isFocused and child:isFocused() and child.setFocused then
                child:setFocused(false)
            end
        end
    end
end

function Component:isFocused()
    return self.focused
end

function Component:setMargins(left, top, right, bottom)
    self.margins = {
        left,
        top or left,
        right or left,
        bottom or top or left
    }
end

function Component:setPadding(left, top, right, bottom)
    self.padding = {
        left,
        top or left,
        right or left,
        bottom or top or left
    }
end

function Component:setOverflow(overflow)
    self.overflow = overflow
end

function Component:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info,
        "Margins: (" ..
        self.margins[1] .. ", " .. self.margins[2] .. ", " .. self.margins[3] .. ", " .. self.margins[4] .. ")")
    table.insert(info,
        "Padding: (" ..
        self.padding[1] .. ", " .. self.padding[2] .. ", " .. self.padding[3] .. ", " .. self.padding[4] .. ")")
    -- logical size
    table.insert(info, "Logical Size: (" .. self.width .. ", " .. self.height .. ")")
    -- total size
    local total_width, total_height = self:getTotalSize()
    table.insert(info, "Total Size: (" .. total_width .. ", " .. total_height .. ")")
    -- working size
    local working_width, working_height = self:getWorkingSize()
    table.insert(info, "Working Size: (" .. working_width .. ", " .. working_height .. ")")
    return info
end

function Component:draw()
    if DEBUG_RENDER then
        -- draw margins
        love.graphics.setColor(0, 1, 1, 0.25)
        -- left rectangle
        love.graphics.rectangle("fill", -self.margins[1], -self.margins[2], self.margins[1],
            self.height + self.margins[2] + self.margins[4])
        -- top rectangle
        love.graphics.rectangle("fill", 0, -self.margins[2], self.width + self.margins[3],
            self.margins[2])
        -- right rectangle
        love.graphics.rectangle("fill", self.width, 0, self.margins[3], self.height)
        -- bottom rectangle
        love.graphics.rectangle("fill", 0, self.height, self.width + self.margins[3], self.margins[4])

        -- draw padding
        love.graphics.setColor(1, 0, 1, 0.25)
        -- left rectangle
        love.graphics.rectangle("fill", 0, 0, self.padding[1], self.height)
        -- top rectangle
        love.graphics.rectangle("fill", 0, 0, self.width, self.padding[2])
        -- right rectangle
        love.graphics.rectangle("fill", self.width - self.padding[3], 0, self.padding[3], self.height)
        -- bottom rectangle
        love.graphics.rectangle("fill", 0, self.height - self.padding[4], self.width, self.padding[4])

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", 0, 0, self.width, self.height)

        self.layout:draw()

        if self:isFocused() then
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.rectangle("line", 0, 0, self.width, self.height)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)

    if self.overflow == "hidden" or self.overflow == "scroll" then
        Draw.pushScissor()
        Draw.scissor(0, 0, self.width, self.height)
    end

    super.draw(self)

    if self.overflow == "hidden" or self.overflow == "scroll" then
        Draw.popScissor()
    end
end

function Component:update()
    super.update(self)
    self.layout:refresh()
    if self.x_sizing then
        self.width = self.x_sizing:getWidth()
    end
    if self.y_sizing then
        self.height = self.y_sizing:getHeight()
    end
end

function Component:setLayout(layout)
    self.layout = layout
    self.layout.parent = self
end

function Component:setSizing(x_sizing, y_sizing)
    self.x_sizing = x_sizing
    self.x_sizing.parent = self
    self.y_sizing = y_sizing
    self.y_sizing.parent = self
end

function Component:onAddToStage(stage)
    super.onAddToStage(self, stage)

    if self:isFocused() then
        -- make sure parent is focused as well
        if self.parent and self.parent.setFocused and (not self.parent:isFocused()) then
            self.parent:setFocused(true)
        end
    end

    self.layout:refresh()
    if self.x_sizing then
        self.width = self.x_sizing:getWidth()
    end
    if self.y_sizing then
        self.height = self.y_sizing:getHeight()
    end
end

function Component:getTotalSize()
    return
        (self.width + self.margins[1] + self.margins[3]) * self.scale_x,
        (self.height + self.margins[2] + self.margins[4]) * self.scale_y
end

function Component:getWorkingSize()
    return
        (self.width - self.padding[1] - self.padding[3]) * self.scale_x,
        (self.height - self.padding[2] - self.padding[4]) * self.scale_y
end

function Component:getScaledMargins()
    return
        self.margins[1] * self.scale_x,
        self.margins[2] * self.scale_y,
        self.margins[3] * self.scale_x,
        self.margins[4] * self.scale_y
end

function Component:getScaledPadding()
    return
        self.padding[1] * self.scale_x,
        self.padding[2] * self.scale_y,
        self.padding[3] * self.scale_x,
        self.padding[4] * self.scale_y
end

function Component:getComponents()
    return self.children
end

return Component
