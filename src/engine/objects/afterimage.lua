---@class AfterImage : Object
---@overload fun(...) : AfterImage
local AfterImage, super = Class(Object)

function AfterImage:init(sprite, fade, speed)
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.sprite = sprite

    self.alpha = fade
    self:fadeOutSpeedAndRemove(speed)

    self.canvas = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    Draw.pushCanvas(self.canvas)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.clear()
    love.graphics.applyTransform(self.sprite:getFullTransform())
    Draw.setColor(self.sprite:getDrawColor())
    self.sprite:draw()
    love.graphics.pop()
    Draw.popCanvas()

    local sox, soy = self.sprite:getScaleOrigin()
    local rox, roy = self.sprite:getRotationOrigin()

    local sox_p, soy_p = self.sprite:localToScreenPos(sox * self.sprite.width, soy * self.sprite.height)
    local rox_p, roy_p = self.sprite:localToScreenPos(rox * self.sprite.width, roy * self.sprite.height)

    self:setScaleOrigin(sox_p / SCREEN_WIDTH, soy_p / SCREEN_HEIGHT)
    self:setRotationOrigin(rox_p / SCREEN_WIDTH, roy_p / SCREEN_HEIGHT)
end

function AfterImage:onAdd(parent)
    local sibling

    local other_parents = self.sprite:getHierarchy()
    for _, v in ipairs(self:getHierarchy()) do
        for i, o in ipairs(other_parents) do
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

function AfterImage:applyTransformTo(transform)
    if self.parent then
        transform:reset()
    end
    super.applyTransformTo(self, transform)
end

function AfterImage:draw()
    Draw.draw(self.canvas)
    super.draw(self)
end

return AfterImage
