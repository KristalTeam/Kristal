local Character, super = Class(Object)

function Character:init(chara, x, y)
    super:init(self, x, y, chara.width, chara.height)

    self.info = chara
    self.facing = "down"

    self.sprite = CharacterSprite(self.info)
    self.sprite.facing = self.facing
    self:addChild(self.sprite)

    self:setOrigin(0.5, 1)
    self:setScale(2)

    local hitbox = self.info.hitbox or {0, chara.height - 14, chara.width, 14}
    self.collider = Hitbox(hitbox[1], hitbox[2], hitbox[3], hitbox[4], self)

    -- 1px movement increments
    self.partial_x = (x % 1)
    self.partial_y = (y % 1)

    self.last_collided_x = false
    self.last_collided_y = false

    self.moved = 0

    self.x = math.floor(self.x)
    self.y = math.floor(self.y)

    self.noclip = false
end

function Character:onAdd(parent)
    if parent:includes(World) then
        self.world = parent
    end
end

function Character:getExactPosition(x, y)
    return self.x + self.partial_x, self.y + self.partial_y
end

function Character:moveTo(x, y)
    self:move(x - (self.x + self.partial_x), y - (self.y + self.partial_y))
end

function Character:move(x, y, speed)
    local movex, movey = x * (speed or 1), y * (speed or 1)

    local moved = false
    moved = self:moveX(movex, movey) or moved
    moved = self:moveY(movey, movex) or moved

    if moved then
        self.moved = math.max(self.moved, math.max(math.abs(movex) / DTMULT, math.abs(movey) / DTMULT))

        self.sprite.walking = true
        self.sprite.walk_speed = self.moved
    end

    if movex ~= 0 or movey ~= 0 then
        local dir = self.facing
        if movex > 0 then
            dir = (movey ~= 0 and (dir == "down" or dir == "up")) and dir or "right"
        elseif movex < 0 then
            dir = (movey ~= 0 and (dir == "down" or dir == "up")) and dir or "left"
        end
        if movey > 0 then
            dir = (movex ~= 0 and (dir == "left" or dir == "right")) and dir or "down"
        elseif movey < 0 then
            dir = (movex ~= 0 and (dir == "left" or dir == "right")) and dir or "up"
        end
    
        self.facing = dir
        self.sprite.facing = self.facing 
    end

    return moved
end

function Character:moveX(amount, move_y)
    if amount == 0 then
        return false
    end

    self.partial_x = self.partial_x + amount

    local move = math.floor(self.partial_x)
    self.partial_x = self.partial_x % 1

    if move ~= 0 then
        return self:moveXExact(move, move_y)
    else
        return not self.last_collided_x
    end
end

function Character:moveY(amount, move_x)
    if amount == 0 then
        return false
    end

    self.partial_y = self.partial_y + amount

    local move = math.floor(self.partial_y)
    self.partial_y = self.partial_y % 1

    if move ~= 0 then
        return self:moveYExact(move, move_x)
    else
        return not self.last_collided_y
    end
end

function Character:moveXExact(amount, move_y)
    local sign = Utils.sign(amount)
    for i = sign, amount, sign do
        local last_x = self.x
        local last_y = self.y

        self.x = self.x + sign

        if not self.noclip then
            local collided, target = self.world:checkCollision(self.collider)
            if collided and not (move_y > 0) then
                for i = 1, 3 do
                    self.y = self.y - i
                    collided, target = self.world:checkCollision(self.collider)
                    if not collided then break end
                end
            end
            if collided and not (move_y < 0) then
                self.y = last_y
                for i = 1, 3 do
                    self.y = self.y + i
                    collided, target = self.world:checkCollision(self.collider)
                    if not collided then break end
                end
            end
    
            if collided then
                self.x = last_x
                self.y = last_y
                
                if target and target.onCollide then
                    target:onCollide(self)
                end
    
                self.last_collided_x = true
                return false, target
            end 
        end
    end
    self.last_collided_x = false
    return true
end

function Character:moveYExact(amount, move_x)
    local sign = Utils.sign(amount)
    for i = sign, amount, sign do
        local last_x = self.x
        local last_y = self.y

        self.y = self.y + sign

        if not self.noclip then
            local collided, target = self.world:checkCollision(self.collider)
            if collided and not (move_x > 0) then
                for i = 1, 2 do
                    self.x = self.x - i
                    collided, target = self.world:checkCollision(self.collider)
                    if not collided then break end
                end
            end
            if collided and not (move_x < 0) then
                self.x = last_x
                for i = 1, 2 do
                    self.x = self.x + i
                    collided, target = self.world:checkCollision(self.collider)
                    if not collided then break end
                end
            end
    
            if collided then
                self.x = last_x
                self.y = last_y
                
                if target and target.onCollide then
                    target:onCollide(self)
                end
    
                self.last_collided_y = true
                return i ~= sign, target
            end 
        end
    end
    self.last_collided_y = false
    return true
end

function Character:walk(x, y, run, force_dir)
    self:move(x, y, (run and 8 or 4) * DTMULT)
end

function Character:setSprite(sprite)
    self.sprite:setSprite(sprite)
end

function Character:setCustomSprite(sprite, ox, oy)
    self.sprite:setCustomSprite(sprite, ox, oy)
end

function Character:play(speed, loop, reset, on_finished)
    self.sprite:play(speed, loop, reset, on_finished)
end

function Character:update(dt)
    if self.info.update then
        self.info:update(self, dt)
    end

    if self.moved > 0 then
        self.sprite.walking = true
        self.sprite.walk_speed = self.moved
        self.moved = 0
    else
        self.sprite.walking = false
    end

    self:updateChildren(dt)
end

function Character:draw()
    self:drawChildren()
    
    if self.info.draw then
        self.info:draw(self)
    end
end

return Character