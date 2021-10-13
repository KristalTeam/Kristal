local Character, super = Class(Object)

function Character:init(name, x, y, variant)
    super:init(self, x, y, 0, 0)

    self.name = name
    self.variant = variant or "dark"

    self.sprite = Sprite("party/"..self.name.."/world/"..self.variant.."/down")
    self.sprite:setOrigin(0.5, 1)
    self.sprite:setScale(2)
    self:addChild(self.sprite)

    self.collider = Hitbox(-19, -26, 38, 28, self)

    self.sprite_subdir = "world"
    self.sprite_name = "down"
    self.sprite:setFrame(1)
end

function Character:onAdd(parent)
    if parent:includes(World) then
        self.world = parent
    end
end

function Character:moveX(amount, speed)
    if amount * (speed or 1) == 0 then
        return false
    end
    self:move(amount, 0, speed)
    if self.world then
        for _,h in ipairs(self.world:getCollision()) do
            if self.collider:collidesWith(h) then
                self:move(-amount, 0, speed)
                return false
            end
        end
    end
    return true
end

function Character:moveY(amount, speed)
    if amount * (speed or 1) == 0 then
        return false
    end
    self:move(0, amount, speed)
    if self.world then
        for _,h in ipairs(self.world:getCollision()) do
            if self.collider:collidesWith(h) then
                self:move(0, -amount, speed)
                return false
            end
        end
    end
    return true
end

function Character:walk(x, y, run, force_dir)
    if x ~= 0 or y ~= 0 then
        local last_dir = self.sprite_name
        local dir = force_dir or "down"
        if not force_dir then
            if x > 0 then
                dir = (y ~= 0 and (self.sprite_name == "down" or self.sprite_name == "up")) and self.sprite_name or "right"
            elseif x < 0 then
                dir = (y ~= 0 and (self.sprite_name == "down" or self.sprite_name == "up")) and self.sprite_name or "left"
            elseif y > 0 then
                dir = (x ~= 0 and (self.sprite_name == "left" or self.sprite_name == "right")) and self.sprite_name or "down"
            elseif y < 0 then
                dir = (x ~= 0 and (self.sprite_name == "left" or self.sprite_name == "right")) and self.sprite_name or "up"
            end
        end
        local target_frame = 1
        if last_dir == "down" or last_dir == "up" or last_dir == "right" or last_dir == "left" then
            target_frame = self.sprite.frame
        end
        self:setSprite("world", dir, target_frame)
        self.sprite:play(run and 0.125 or 0.25)

        local moved = false
        moved = self:moveX(x*(run and 8 or 4), DT * 30) or moved
        moved = self:moveY(y*(run and 8 or 4), DT * 30) or moved
        if not moved then
            self.sprite:stop()
        end
    else
        if self.sprite_name == "up" or self.sprite_name == "down" or self.sprite_name == "left" or self.sprite_name == "right" then
            self.sprite:stop()
        end
    end
end

function Character:setVariant(variant)
    if self.variant ~= variant then
        self.variant = variant
        self:setSprite(self.sprite_subdir, self.sprite_name, self.sprite.frame, true)
    end
end

function Character:setSprite(subdir, sprite, frame, force)
    if self.sprite_subdir ~= subdir or self.sprite_name ~= sprite or force then
        self.sprite_subdir = subdir
        self.sprite_name = sprite
        self.sprite:set("party/"..self.name.."/"..subdir.."/"..self.variant.."/"..sprite)
        if frame then
            self.sprite:setFrame(frame)
        end
    end
end

function Character:update(dt)
    self:updateChildren(dt)
end

function Character:draw()
    --love.graphics.setColor(0, 1, 0)
    --love.graphics.rectangle("fill", self.collider.x, self.collider.y, self.collider.width, self.collider.height)
    self:drawChildren()
end

return Character