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

---Checks if the object is currently being clicked, held, or tapped.
---@param collider Collider? The collider to use. Defaults to `self.collider`.
---@return boolean pressed True if the button is being pressed
---@return number pressure How much pressure is being applied, if the device supports it. Otherwise, 0 or 1.
function InputButton:pressed(collider)
    collider = collider or self.collider
    assert(collider, "Need a collider to check self:pressed()!")
    for _,touch_index in ipairs(love.touch.getTouches()) do
        local x,y = love.touch.getPosition(touch_index)
        local pressure = love.touch.getPressure(touch_index)
        local radius = pressure * 10
        local point = CircleCollider(nil, x+(radius/2), y+(radius/2), radius)
        if collider:collidesWith(point) then
            return true, pressure
        end
    end
    local clicked, x, y, presses = Input.mouseDown()
    if clicked then
        x,y = Input.getMousePosition()
        local point = PointCollider(nil, x, y)
        if collider:collidesWith(point) then
            return true, 1
        end
    end
    return false, 0
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