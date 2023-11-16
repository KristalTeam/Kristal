---@class BasicMenuComponent : AbstractMenuComponent
---@field horizontal boolean
---@field hold boolean
---@field cancel_callback function
---@overload fun(...) : BasicMenuComponent
local BasicMenuComponent, super = Class(AbstractMenuComponent)

---@param x_sizing? Sizing
---@param y_sizing? Sizing
---@param options? table
function BasicMenuComponent:init(x_sizing, y_sizing, options)
    super.init(self, x_sizing, y_sizing, options)
    options = options or {}
    self.horizontal = options.horizontal or false
    self.hold = options.hold or false
    self.cancel_callback = nil
end

function BasicMenuComponent:update()
    super.update(self)

    if self:isFocused() then
        if self.horizontal and Input.pressed("left", self.hold) or Input.pressed("up", self.hold) then
            Input.clear(self.horizontal and "left" or "up")
            self:previous()
        elseif self.horizontal and Input.pressed("right", self.hold) or Input.pressed("down", self.hold) then
            Input.clear(self.horizontal and "right" or "down")
            self:next()
        elseif Input.pressed("confirm") then
            Input.clear("confirm")
            if self:getMenuItems()[self.selected_item] and self:getMenuItems()[self.selected_item].onSelected then
                self:getMenuItems()[self.selected_item]:onSelected()
            end
        elseif Input.pressed("cancel") then
            Input.clear("cancel")
            if self.cancel_callback then
                self.cancel_callback()
            end
        end
    end
end

function BasicMenuComponent:setCancelCallback(callback)
    self.cancel_callback = callback
end

return BasicMenuComponent
