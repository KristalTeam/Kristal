--- Provides shared control/draw behavior for editor inputs/controls.
---@class EditorControl : Class
---@field children EditorControl[]
---@field clip boolean
---@field enabled boolean
---@field focusable boolean
---@field height number
---@field parent EditorControl?
---@field visible boolean
---@field width number
---@field x number
---@field y number
---@overload fun(x?: number, y?: number, width?: number, height?: number): EditorControl
local EditorControl = Class()

function EditorControl:init(x, y, width, height)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or 0
    self.visible = true
    self.enabled = true
    self.focusable = false
    self.clip = false
    self.parent = nil
    self.children = {}
end

function EditorControl:setBounds(x, y, width, height)
    self.x = x
    self.y = y
    self.width = math.max(0, width)
    self.height = math.max(0, height)
end

function EditorControl:addChild(child)
    if child.parent then
        child.parent:removeChild(child)
    end
    child.parent = self
    table.insert(self.children, child)
    return child
end

function EditorControl:removeChild(child)
    for index, candidate in ipairs(self.children) do
        if candidate == child then
            table.remove(self.children, index)
            child.parent = nil
            return child
        end
    end
end

function EditorControl:getGlobalPosition()
    local x, y = self.x, self.y
    local parent = self.parent
    while parent do
        x = x + parent.x
        y = y + parent.y
        parent = parent.parent
    end
    return x, y
end

function EditorControl:containsPoint(x, y)
    local global_x, global_y = self:getGlobalPosition()
    return x >= global_x and y >= global_y
        and x < global_x + self.width and y < global_y + self.height
end

function EditorControl:getControlAt(x, y)
    if not self.visible or not self.enabled or not self:containsPoint(x, y) then
        return nil
    end
    for index = #self.children, 1, -1 do
        local target = self.children[index]:getControlAt(x, y)
        if target then
            return target
        end
    end
    return self
end

function EditorControl:toLocal(x, y)
    local global_x, global_y = self:getGlobalPosition()
    return x - global_x, y - global_y
end

function EditorControl:update(dt)
    for _, child in ipairs(self.children) do
        if child.visible then
            child:update(dt)
        end
    end
end

function EditorControl:drawSelf() end

function EditorControl:draw()
    if not self.visible then return end
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    local old_scissor
    if self.clip then
        old_scissor = { love.graphics.getScissor() }
        local x1, y1 = love.graphics.transformPoint(0, 0)
        local x2, y2 = love.graphics.transformPoint(self.width, self.height)
        local x, y = math.min(x1, x2), math.min(y1, y2)
        local width, height = math.abs(x2 - x1), math.abs(y2 - y1)
        if old_scissor[1] then
            love.graphics.intersectScissor(x, y, width, height)
        else
            love.graphics.setScissor(x, y, width, height)
        end
    end
    self:drawSelf()
    for _, child in ipairs(self.children) do
        child:draw()
    end
    if self.clip then love.graphics.setScissor(unpack(old_scissor)) end
    love.graphics.pop()
end

function EditorControl:onFocus() end
function EditorControl:onBlur() end
function EditorControl:onMousePressed(x, y, button, presses) end
function EditorControl:onMouseMoved(x, y, dx, dy) end
function EditorControl:onMouseReleased(x, y, button, presses) end
function EditorControl:onWheelMoved(x, y) end
function EditorControl:onKeyPressed(key, is_repeat) end
function EditorControl:onKeyReleased(key) end
function EditorControl:onTextInput(text) end

return EditorControl
