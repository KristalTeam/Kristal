---@class InputButton: Object
---@overload fun(button:string, x:number, y:number, scale:number): InputButton
local InputButton, super = Class(Object)

function InputButton:init(button,x,y,scale)
    scale = (scale or 1) * 2
    super.init(self,x,y,12,12)
    self.collider = CircleCollider(self,6,6, 6)
    self.sprite = self:addChild(Sprite("kristal/buttons/switch/"..button))
    self:setScale(scale)
    self.sprite.y = -1
    self.button = button
    self.input_command_prefix = "gamepad:"
end

function InputButton:pressed(button)
    if not button then
        local used_button = 0
        for i=1, Input.mouse_button_max do
            local success, success_button = self:pressed(i)
            used_button = math.max(used_button, success_button)
            if success then
                return true, success_button
            end
        end
        return false, used_button
    end
    local clicked, x, y, presses = Input.mouseDown(button)
    if not clicked then
        return false, 0
    end
    if self.collider then
        local point = PointCollider(nil, x, y)
        return self.collider:collidesWith(point), button
    else
        -- roughly same code as DebugSystem:detectObject(x, y)
        local mx, my = self:getFullTransform():inverseTransformPoint(x, y)
        local rect = self:getDebugRectangle() or { 0, 0, self.width, self.height }
        if mx >= rect[1] and mx < rect[1] + rect[3] and my >= rect[2] and my < rect[2] + rect[4] then
            return true, button
        end
    end
    return false, button
end

function InputButton:update()
    super.update(self)
    if self:pressed() then
        if not self.is_pressed then
            Input.onKeyPressed(self.input_command_prefix..self.button, false)
        end
        self.is_pressed = true
    elseif self.is_pressed then
        Input.onKeyReleased(self.input_command_prefix..self.button)
        self.is_pressed = false
    end
end

function InputButton:setDpadMode()
    self.input_command_prefix = "gamepad:ls"
    return self
end

function InputButton:draw()
    self.sprite.alpha = 0.5
    if self:pressed() then
        self.sprite.alpha = 1
    end
    self.x = math.floor((self.x/(self.sprite.scale_x*1))+.5)*(self.sprite.scale_x*1)
    self.y = math.floor((self.y/(self.sprite.scale_y*1))+.5)*(self.sprite.scale_y*1)
    super.draw(self)
end

return InputButton