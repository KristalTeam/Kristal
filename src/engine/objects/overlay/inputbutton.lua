---@class InputButton: Object
---@overload fun(button:string, buttons_table: nil, x:number, y:number, scale:number): InputButton
local InputButton, super = Class(Object)

function InputButton:init(button,buttons_table,x,y,scale)
    scale = (scale or 1) * 2
    super.init(self,x,y,14,14)
    self:setOrigin(.5)
    self.collider = CircleCollider(self,8,7,7)
    self.sprite = self:addChild(Sprite("kristal/buttons/mobile/ui/"..button))
    self:setScale(scale)
    self.sprite.y = -1
    self.button = button
    self.input_command_prefix = "gamepad:"
end

---Checks if the object is currently being clicked, held, or tapped.
---@param collider Collider? The collider to use. Defaults to `self.collider`.
---@return boolean pressed True if the button is being pressed
---@return number pressure How much pressure is being applied, if the device supports it. Otherwise, 0 or 1.
function InputButton:buttonDown(collider)
    collider = collider or self.collider
    assert(collider, "Need a collider to check self:buttonDown()!")
    for _,touch_index in ipairs(love.touch.getTouches()) do
        local x,y = Input.getTouchPosition(touch_index)
        local pressure = love.touch.getPressure(touch_index)
        local radius = pressure * 30
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
    if self:buttonDown() then
        if not self.is_pressed then
            Input.onKeyPressed("mobile:"..self.button, false)
        end
        self.is_pressed = true
    elseif self.is_pressed then
        self.is_pressed = false
        Input.onKeyReleased("mobile:"..self.button)
    end
end

function InputButton:setDpadMode()
    self.input_command_prefix = "gamepad:ls"
    self.sprite:set("kristal/buttons/mobile/ui/right")
    self.rotation = math.rad(({
        up = -90,
        down = 90,
        left = 180,
        right = 0,
    })[self.button])
    local w = 30
    self.collider = ColliderGroup(self, {
        PolygonCollider(self, {
            {16,w},
            {-7,7},
            {16,14-w}
        })
    })
    return self
end

function InputButton:draw()
    self.sprite.alpha = 0.5
    -- self.sprite:setFrame(1)
    if self:buttonDown() then
        self.sprite.alpha = 1
        -- self.sprite:setFrame(2)
    end
    if DEBUG_RENDER then
        self.collider:draw(unpack(COLORS.green))
    end
    super.draw(self)
end

return InputButton