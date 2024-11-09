---@class InputButton: Object
local InputButton, super = Class(Object)

function InputButton:init(button,x,y,scale)
    scale = (scale or 1) * 2
    super.init(self,x,y,12*scale,12*scale)
    self.sprite = self:addChild(Sprite("kristal/buttons/switch/"..button))
    self.sprite:setScale(scale)
    self.sprite.y = -scale
    self.button = button
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
        print("clicked on button " .. self.button)
    end
end
function InputButton:draw()
    self.sprite.alpha = 0.2
    if self:pressed() then
        self.sprite.alpha = 1
    end
    self.x = math.floor((self.x/(self.sprite.scale_x*1))+.5)*(self.sprite.scale_x*1)
    self.y = math.floor((self.y/(self.sprite.scale_y*1))+.5)*(self.sprite.scale_y*1)
    super.draw(self)
end

return InputButton