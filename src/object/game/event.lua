local Event, super = Class(Object)

function Event:init(x, y, w, h, o)
    super:init(self, x, y, w, h)

    -- Whether this object should stop the player
    self.solid = false

    -- Sprite object, gets set by setSprite()
    self.sprite = nil
end

function Event:onInteract()
    -- Do stuff when the player interacts with this object (CONFIRM key)
end

function Event:onCollide()
    -- Do stuff when the player collides with this object
end

function Event:setSprite(texture, speed)
    if texture then
        if self.sprite then
            self:removeChild(self.sprite)
        end
        self.sprite = Sprite(texture)
        self.sprite:setScale(2)
        if speed then
            self.sprite:play(speed)
        end
        self:addChild(self.sprite)
        if not self.hitbox then
            self.hitbox = Hitbox(0, 0, self.sprite.width * 2, self.sprite.height * 2)
        end
    elseif self.sprite then
        self:removeChild(self.sprite)
        self.sprite = nil
    end
end

return Event