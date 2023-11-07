---@class UIComponent : Object
---@overload fun(...) : UIComponent
local UIComponent, super = Class(Object)

function UIComponent:init(x, y, sizing)
    super.init(self, x, y, 0, 0)

    self:setLayout(Layout())
    self:setSizing(sizing or Sizing())

    self.margins = { 0, 0, 0, 0 }
    self.padding = { 0, 0, 0, 0 }
end

function UIComponent:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info,
        "Margins: (" ..
        self.margins[1] .. ", " .. self.margins[2] .. ", " .. self.margins[3] .. ", " .. self.margins[4] .. ")")
    table.insert(info,
        "Padding: (" ..
        self.padding[1] .. ", " .. self.padding[2] .. ", " .. self.padding[3] .. ", " .. self.padding[4] .. ")")
    return info
end

function UIComponent:draw()
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
    end

    love.graphics.setColor(1, 1, 1, 1)

    super.draw(self)
end

function UIComponent:update()
    super.update(self)
    self.layout:refresh()
    if self.sizing then
        self.width = self.sizing:getWidth()
        self.height = self.sizing:getHeight()
    end
end

function UIComponent:setLayout(layout)
    self.layout = layout
    self.layout.parent = self
end

function UIComponent:setSizing(sizing)
    self.sizing = sizing
    self.sizing.parent = self
end

function UIComponent:getTotalSize()
    return self.width + self.margins[1] + self.margins[3], self.height + self.margins[2] + self.margins[4]
end

function UIComponent:getWorkingSize()
    return self.width - self.padding[1] - self.padding[3], self.height - self.padding[2] - self.padding[4]
end

return UIComponent
