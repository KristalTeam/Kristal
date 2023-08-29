---@class Event : Object
---@overload fun(...) : Event
local Event, super = Class(Object)

function Event:init(x, y, w, h)
    if type(x) == "table" then
        local data = x
        x, y = data.x, data.y
        w, h = data.width, data.height
    elseif type(w) == "table" then
        local data = w
        w, h = data.width, data.height
    end

    super.init(self, x, y, w, h)

    self._default_collider = Hitbox(self, 0, 0, self.width, self.height)
    if not self.collider then
        self.collider = self._default_collider
    end

    -- Whether this object should stop the player
    self.solid = false

    -- ID of the object in the current room (automatically set after init)
    self.object_id = nil
    -- User-defined ID of the object used for save variables (optional, automatically set after init)
    self.unique_id = nil

    -- Sprite object, gets set by setSprite()
    self.sprite = nil

    -- Duration that the player cannot interact with events for on finishing interaction (in seconds)
    self.interact_buffer = (5/30)
end

--[[ OPTIONAL FUNCTIONS

function Event:onInteract(player, dir)
    -- Do stuff when the player interacts with this object (CONFIRM key)
    return false
end

function Event:onCollide(player, DT)
    -- Do stuff every frame the player collides with the object
end

function Event:onEnter(player)
    -- Do stuff when the player enters this object
end

function Event:onExit(player)
    -- Do stuff when the player leaves this object
end

]]--

function Event:onLoad() end -- Do stuff after the map has been loaded
function Event:postLoad() end -- Do stuff after the entire world has been loaded

function Event:onAdd(parent)
    if parent:includes(World) then
        self.world = parent
    elseif parent.world then
        self.world = parent.world
    end
end

function Event:onRemove(parent)
    if self.data then
        if self.world.map.events_by_name[self.data.name] then
            Utils.removeFromTable(self.world.map.events_by_name[self.data.name], self)
        end
        if self.world.map.events_by_id[self.data.id] then
            Utils.removeFromTable(self.world.map.events_by_id[self.data.id], self)
        end
    end
    if parent:includes(World) or parent.world then
        self.world = nil
    end
end

function Event:getUniqueID()
    if self.unique_id then
        return self.unique_id
    elseif self.object_id then
        return (self.world or Game.world).map:getUniqueID() .. "#" .. self.object_id
    end
end

function Event:setFlag(flag, value)
    local uid = self:getUniqueID()
    if uid then
        Game:setFlag(uid..":"..flag, value)
    end
end

function Event:getFlag(flag, default)
    local uid = self:getUniqueID()
    if uid then
        return Game:getFlag(uid..":"..flag, default)
    else
        return default
    end
end

function Event:addFlag(flag, amt)
    local uid = self:getUniqueID()
    if uid then
        return Game:addFlag(uid..":"..flag, amt)
    end
end

function Event:setSprite(texture, speed, use_size)
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
        if not self.collider or self.collider == self._default_collider then
            self.collider = Hitbox(self, 0, 0, self.sprite.width * 2, self.sprite.height * 2)
        end
        if use_size or use_size == nil then
            self:setSize(self.sprite.width*2, self.sprite.height*2)
        end
    elseif self.sprite then
        self:removeChild(self.sprite)
        self.sprite = nil
    end
end

function Event:shakeSelf(x, y, friction, delay)
    super.shake(self, x, y, friction, delay)
end

function Event:stopShakeSelf()
    super.stopShake(self)
end

function Event:shake(x, y, friction, delay)
    if self.sprite then
        self.sprite:shake(x, y, friction, delay)
    else
        self:shakeSelf(x, y, friction, delay)
    end
end

function Event:stopShake()
    if self.sprite then
        self.sprite:stopShake()
    else
        self:stopShakeSelf()
    end
end

function Event:flash(sprite, offset_x, offset_y, layer)
    local sprite_to_use = sprite or self.sprite
    return sprite_to_use:flash(offset_x, offset_y, layer)
end

function Event:draw()
    super.draw(self)
    if DEBUG_RENDER then
        self.collider:draw(1, 0, 1)
    end
end

function Event:onClone(src)
    super.onClone(self, src)
    if src.world then
        self.object_id = src.world.map.next_object_id + 1
        src.world.map.next_object_id = src.world.map.next_object_id + 1
    end
end

return Event