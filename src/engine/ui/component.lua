---@class Component : Object
---@overload fun(...) : Component
local Component, super = Class(Object)

function Component:init(x_sizing, y_sizing, options)
    super.init(self, 0, 0, 0, 0)

    self.margins = { 0, 0, 0, 0 }
    self.padding = { 0, 0, 0, 0 }

    -- visible, hidden, scroll
    self.overflow = "visible"
    self.scroll_x = 0
    self.scroll_y = 0

    self.scrollbar = nil

    self:setLayout(Layout())
    self:setSizing(x_sizing or Sizing(), y_sizing or x_sizing or Sizing())

end

function Component:setFocused()
    table.insert(Input.component_stack, self)
end

function Component:setUnfocused()
    table.remove(Input.component_stack)
end

function Component:isFocused()
    return Input.component_stack[#Input.component_stack] == self
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

function Component:setScrollbar(scrollbar)
    if self.scrollbar ~= nil then
        self:removeChild(self.scrollbar)
    end

    self.scrollbar = scrollbar
    self:addChild(scrollbar)
end

function Component:getScrollbarGutter()
    if self.scrollbar then
        return ({self.scrollbar:getTotalSize()})[1]
    end
    return 0
end

function Component:getScrollbarPosition()
    return self.width + (self.scrollbar and self.scrollbar.margins[1] or 0)
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
    -- inner
    local inner_width, inner_height = self:getInnerSize()
    table.insert(info, "Inner Size: (" .. inner_width .. ", " .. inner_height .. ")")
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
        Draw.scissor(0, 0, self.width + self:getScrollbarGutter(), self.height)
    end

    super.draw(self)

    if self.overflow == "hidden" or self.overflow == "scroll" then
        Draw.popScissor()
    end
end

function Component:update()
    super.update(self)
    self:reflow()
end

function Component:reflow(ignore)
    if self:isRemoved() then return end

    self.layout:refresh()
    self.old_width = self.width
    self.old_height = self.height
    if self.x_sizing then
        self.width = self.x_sizing:getWidth()
    end
    if self.y_sizing then
        self.height = self.y_sizing:getHeight()
    end

    for _, child in ipairs(self:getComponents()) do
        if child ~= self and child.reflow and child ~= ignore then
            child:reflow(self)
        end
    end

    if self.old_width ~= self.width or self.old_height ~= self.height then
        if self.parent.reflow then
            self.parent:reflow(self)
        end
    end

    if self.scrollbar then
        self.scrollbar:updatePosition()
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

    self.layout:refresh()
    if self.x_sizing then
        self.width = self.x_sizing:getWidth()
    end
    if self.y_sizing then
        self.height = self.y_sizing:getHeight()
    end
end

function Component:getTotalWidth()
    return (self.width + self.margins[1] + self.margins[3] + self:getScrollbarGutter()) * self.scale_x
end

function Component:getTotalHeight()
    return (self.height + self.margins[2] + self.margins[4]) * self.scale_y
end

function Component:getTotalSize()
    return self:getTotalWidth(), self:getTotalHeight()
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

function Component:getInnerWidth()
    -- width of the inner content, ignoring the real size of the component
    -- calculate using the children, can't rely on self.width

    local width = 0
    for _, child in ipairs(self:getComponents()) do
        if child.x_sizing and child.x_sizing:includes(FillSizing) then goto continue end
        local x = (child.x + self.scroll_x) - self.padding[1] - (child.margins and child.margins[1] or 0)
        local child_width, _ = child:getScaledSize()
        if (child.getTotalSize) then child_width, _ = child:getTotalSize() end
        child_width = x + child_width
        if child_width > width then
            width = child_width
        end
        ::continue::
    end
    return width
end

function Component:getInnerHeight()
    -- height of the inner content, ignoring the real size of the component
    -- calculate using the children, can't rely on self.height

    local height = 0
    for _, child in ipairs(self:getComponents()) do
        if child.y_sizing and child.y_sizing:includes(FillSizing) then goto continue end
        local y = (child.y + self.scroll_y) - self.padding[2] - (child.margins and child.margins[2] or 0)
        local _, child_height = child:getScaledSize()
        if (child.getTotalSize) then _, child_height = child:getTotalSize() end
        child_height = y + child_height
        if child_height > height then
            height = child_height
        end
        ::continue::
    end
    return height
end

function Component:getInnerSize()
    return self:getInnerWidth(), self:getInnerHeight()
end

function Component:getComponents()
    -- filter out scrollbar
    local components = {}
    for _, child in ipairs(self.children) do
        if child ~= self.scrollbar then
            table.insert(components, child)
        end
    end
    return components
end

return Component
