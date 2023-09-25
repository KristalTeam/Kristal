---@class UIComponent : Object
---@overload fun(...) : UIComponent
local UIComponent, super = Class(Object)

function UIComponent:init(x, y, width, height)
    super.init(self, x, y, width, height)

    self:setLayout(Layout())

    self.margins = { 0, 0, 0, 0 }
    self.padding = { 0, 0, 0, 0 }
end

function UIComponent:update()
    self.layout:refresh()
end

function UIComponent:setLayout(layout)
    self.layout = layout
    self.layout.parent = self
end

function UIComponent:getTotalSize()
    return self.width + self.margins[1] + self.margins[3], self.height + self.margins[2] + self.margins[4]
end

function UIComponent:getWorkingSize()
    return self.width - self.padding[1] - self.padding[3], self.height - self.padding[2] - self.padding[4]
end

return UIComponent
