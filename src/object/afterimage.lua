local AfterImage, super = Class(Object)

function AfterImage:init(sprite, fade, lifetime)
    super:init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.fade = fade or 1
    self.lifetime = lifetime or ((5/6) * self.fade)
    self.time_alive = 0

    self.add_alpha = 0

    self.speed_x = 0
    self.speed_y = 0

    self.sprite = sprite

    self.canvas = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setCanvas(self.canvas)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.clear()
    love.graphics.applyTransform(self.sprite:getFullTransform())
    love.graphics.setColor(self.sprite:getDrawColor())
    self.sprite:draw()
    love.graphics.pop()
    love.graphics.setCanvas()
    
    local sox, soy = self.sprite:getScaleOrigin()
    local rox, roy = self.sprite:getRotateOrigin()

    local sox_p, soy_p = self.sprite:localToScreenPos(sox * self.sprite.width, soy * self.sprite.height)
    local rox_p, roy_p = self.sprite:localToScreenPos(rox * self.sprite.width, roy * self.sprite.height)

    self:setScaleOrigin(sox_p / SCREEN_WIDTH, soy_p / SCREEN_HEIGHT)
    self:setRotateOrigin(rox_p / SCREEN_WIDTH, roy_p / SCREEN_HEIGHT)
end

function AfterImage:onAdd(parent)
    local sibling

    local other_parents = self.sprite:getHierarchy()
    for _,v in ipairs(self:getHierarchy()) do
        for i,o in ipairs(other_parents) do
            if o.parent and o.parent == v then
                sibling = o
                break
            end
        end
        if sibling then break end
    end

    if sibling then
        self.layer = sibling.layer - 0.001
    end
end

function AfterImage:onRemove()
    self.canvas:release()
    self.canvas = nil
end

function AfterImage:update(dt)
    self.x = self.x + (self.speed_x * DTMULT)
    self.y = self.y + (self.speed_y * DTMULT)
    self.time_alive = Utils.approach(self.time_alive, self.lifetime, dt)
    if self.time_alive == self.lifetime then
        self:remove()
        return
    end
    self:updateChildren(dt)
end

function AfterImage:createTransform()
    local transform = super:createTransform(self)
    if self.parent then
        return self.parent:getFullTransform():inverse() * transform
    else
        return transform
    end
end

function AfterImage:draw()
    local r,g,b,a = self:getDrawColor()
    love.graphics.setColor(r, g, b, a * self.fade * (1 - (self.time_alive / self.lifetime)) + self.add_alpha)
    love.graphics.draw(self.canvas)
    love.graphics.setColor(1, 1, 1, 1)
    self:drawChildren()
end

return AfterImage