--- Events are used as the base class for objects in the Overworld (in most cases)
--- Custom events should be defined in `scripts/world/events` and extend from this class. They will receive an id based on their filepath from this location.
--- Custom events only ever recieve a `data` argument in their `init()` function that contains all of the data about the object in the map. 
--- Included in the `data` table is the `properties` table, which contains every property in the object's `Custom Properties` in Tiled.
--- Events can be placed in maps by placing a shape on any `objects` layer and setting its name to the id of the event that should be created.
---
---@class Event : Object
---
---@field collider          Collider
---@field interact_buffer   number
---@field object_id         integer
---@field solid             boolean
---@field sprite            Sprite?
---@field unique_id         string
---@field world             World       The world that this event is contained in
---@field data              table
---
---@overload fun(x: number, y: number, shape: table) : Event
---@overload fun(data: table) : Event
local Event, super = Class(Object)

---@param x?        number
---@param y?        number
---@param width?    number
---@param height?   number
---@param shape?    {[1]: number, [2]: number, [3]: table?} Shape data for this event. First two indexes are the width and height of the object. The third (optional) index is polygon data.
---@param data?     table
---@overload fun(self: Event, data?: table)
---@overload fun(self: Event, x?: number, y?: number, shape?: {[1]: number, [2]: number, [3]: table?})
function Event:init(x, y, width, height)
    local shape = { 0, 0 }
    if type(width) == "table" then
        shape = width
    elseif type(width) == "number" then
        shape = { width, height }
    end
    if type(x) == "table" then
        local data = x
        x, y = data.x, data.y
        shape[1], shape[2] = data.width, data.height
        shape[3] = data.polygon
    end

    super.init(self, x, y, shape[1], shape[2])

    if shape[3] then
        self.collider = TiledUtils.colliderFromShape(self, { shape = "polygon", polygon = shape[3] })
    end

    -- Default collider (Object width and height)
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

    -- Duration that the player cannot interact with any event after interacting with this one, in seconds (defaults to `5/30`)
    self.interact_buffer = (5 / 30)
end

--- The below callbacks are set back to `nil` to ensure collision checks are 
--- only run on objects that define collision code

--- *(Override)* Called whenever the player interacts with this event
---@param player    Player  The interacting `Player`
---@param dir       string  The direction the player is facing
---@return boolean blocking Whether this interaction should prevent other events in the interaction region activating with this frame
function Event:onInteract(player, dir)
    -- Do stuff when the player interacts with this object (CONFIRM key)
    return false
end

Event.onInteract = nil

--- *(Override)* Called every frame the player and event are colliding with each other
---@param player    Player
---@param DT        number
function Event:onCollide(player, DT)
    -- Do stuff every frame the player collides with the object
end

Event.onCollide = nil

--- *(Override)* Called whenever the player enters this event
---@param player Player
function Event:onEnter(player)
    -- Do stuff when the player enters this object
end

Event.onEnter = nil

--- *(Override)* Called whenever the player leaves this event
---@param player Player
function Event:onExit(player)
    -- Do stuff when the player leaves this object
end

Event.onExit = nil

--- Runs once the map has finished loading
function Event:onLoad() end
--- Runs once the entire world has finished loading
function Event:postLoad() end

--- Called when the event is added as the child of another object
---@param parent World|Event
function Event:onAdd(parent)
    if parent:includes(World) then
        self.world = parent
    elseif parent.world then
        self.world = parent.world
    end
end

--- Called when the event is removed
---@param parent World|Event
function Event:onRemove(parent)
    if self.data then
        if self.world.map.events_by_name[self.data.name] then
            TableUtils.removeValue(self.world.map.events_by_name[self.data.name], self)
        end
        if self.world.map.events_by_id[self.data.id] then
            TableUtils.removeValue(self.world.map.events_by_id[self.data.id], self)
        end
    end
    if parent:includes(World) or parent.world then
        self.world = nil
    end
end

--- Gets this `Event` instance's unique id within the whole mod
--- *The returned id follows the format `#[map.id](lua://Map.id)#[object_id](lua://Event.object_id)` if a custom [`unique_id`](lua://Event.unique_id) is not defined*
---@return string? id
function Event:getUniqueID()
    if self.unique_id then
        return self.unique_id
    elseif self.object_id then
        return (self.world or Game.world).map:getUniqueID() .. "#" .. self.object_id
    end
end

--- Sets the value of the flag named `flag` to `value` \
--- This variant of `Game:setFlag()` interacts with flags specific to this event's unique id
---@param flag  string
---@param value any
function Event:setFlag(flag, value)
    local uid = self:getUniqueID()
    if uid then
        Game:setFlag(uid .. ":" .. flag, value)
    end
end

--- Gets the value of the flag named `flag`, returning `default` if the flag does not exist \
--- This variant of `Game:getFlag()` interacts with flags specific to this event's unique id
---@param flag      string
---@param default?  any
function Event:getFlag(flag, default)
    local uid = self:getUniqueID()
    if uid then
        return Game:getFlag(uid .. ":" .. flag, default)
    else
        return default
    end
end

--- Adds `amount` to a numeric flag named `flag` (or defines it if it does not exist) \
--- This variant of `Game:addFlag()` interacts with flags specific to this event's unique id
---@param flag      string  The name of the flag to add to
---@param amt?      number  (Defaults to `1`)
---@return number? new_value
function Event:addFlag(flag, amt)
    local uid = self:getUniqueID()
    if uid then
        return Game:addFlag(uid .. ":" .. flag, amt)
    end
end

--- Changes the object's sprite
---@param texture?  string  The name of the new texture to set, removes the object's sprite if `nil`
---@param speed?    number  The speed at which the new sprite should animate if it has multiple frames
---@param use_size? boolean Whether to use the sprite's size for the event's size (defaults to `true`)
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
            self:setSize(self.sprite.width * 2, self.sprite.height * 2)
        end
    elseif self.sprite then
        self:removeChild(self.sprite)
        self.sprite = nil
    end
end

--- Shakes this event by the specified amount
---@param x?        number   The amount of shake in the `x` direction. (Defaults to `4`)
---@param y?        number   The amount of shake in the `y` direction. (Defaults to `0`)
---@param friction? number   The amount that the shake should decrease by, per frame at 30FPS. (Defaults to `1`)
---@param delay?    number   The time it takes for the object to invert its shake direction, in seconds. (Defaults to `1/30`)
function Event:shakeSelf(x, y, friction, delay)
    super.shake(self, x, y, friction, delay)
end

--- Stops a shake applied directly to this event
function Event:stopShakeSelf()
    super.stopShake(self)
end

--- Shakes this `Event` by the specified amount, shaking the sprite instead if it exists
---@param x?        number   The amount of shake in the `x` direction. (Defaults to `4`)
---@param y?        number   The amount of shake in the `y` direction. (Defaults to `0`)
---@param friction? number   The amount that the shake should decrease by, per frame at 30FPS. (Defaults to `1`)
---@param delay?    number   The time it takes for the object to invert its shake direction, in seconds. (Defaults to `1/30`)
function Event:shake(x, y, friction, delay)
    if self.sprite then
        self.sprite:shake(x, y, friction, delay)
    else
        self:shakeSelf(x, y, friction, delay)
    end
end

--- Stops this event or its sprite from shaking
function Event:stopShake()
    if self.sprite then
        self.sprite:stopShake()
    else
        self:stopShakeSelf()
    end
end

--- Causes this event to flash once
---@param sprite    Sprite? An optional sprite to use for the flash instead of the event's default sprite.
---@param offset_x? number
---@param offset_y? number
---@param layer?    number
---@return FlashFade
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
