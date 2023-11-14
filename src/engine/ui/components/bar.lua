---@class BarComponent : Component
---@field progress number
---@field vertical boolean
---@field background table
---@field fill table
---@overload fun(...) : BarComponent
local BarComponent, super = Class(Component)

---@param progress number
---@param x_sizing? Sizing
---@param y_sizing? Sizing
---@param options? table
function BarComponent:init(progress, x_sizing, y_sizing, options)
    super.init(self, x_sizing, y_sizing, options)
    options = options or {}
    self.progress = progress
    self.vertical = options.vertical or false
    self.background = options.background or COLORS.maroon
    self.fill = options.fill or COLORS.red
end

function BarComponent:getProgress()
    local progress = self.progress
    if (type(self.progress) == "function") then
        progress = self.progress()
    end
    return Utils.clamp(progress, 0, 1)
end

function BarComponent:draw()
    love.graphics.setColor(self.background)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    love.graphics.setColor(self.fill)
    if self.vertical then
        love.graphics.rectangle("fill", 0, self.height * (1 - self:getProgress()), self.width, self.height * self:getProgress())
    else
        love.graphics.rectangle("fill", 0, 0, self.width * self:getProgress(), self.height)
    end
end

return BarComponent
