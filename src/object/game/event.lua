local Event, super = Class(Object)

function Event:init(x, y, w, h, o)
    super:init(self, x, y, w, h)

    -- Whether this object should stop the player
    self.solid = false

    -- Sprite object, gets set by setSprite()
    self.sprite = nil
end

function Event:onInteract(player, dir)
    -- Do stuff when the player interacts with this object (CONFIRM key)
    return false
end

function Event:onCollide(player)
    -- Do stuff when the player collides with this object
end

function Event:onAdd(parent)
    if parent:includes(World) then
        self.world = parent
    elseif parent.world then
        self.world = parent.world
    end
end

function Event:onRemove(parent)
    if parent:includes(World) or parent.world then
        self.world = nil
    end
end

function Event:update(dt)
    if self.collider and self.world and not self.solid then
        for _,v in ipairs(self.world.children) do
            if v:includes(Character) and self:collidesWith(v) then
                self:onCollide(v)
            end
        end
    end
    self:updateChildren(dt)
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
        if not self.collider then
            self.collider = Hitbox(0, 0, self.sprite.width * 2, self.sprite.height * 2, self)
        end
    elseif self.sprite then
        self:removeChild(self.sprite)
        self.sprite = nil
    end
end

return Event