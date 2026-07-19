--- The base class for all colliders used for Kristal's collision detection system.
---
--- New colliders must be registered to the [`CollisionRegistry`](lua://CollisionRegistry) and override
--- [`Collider:getColliderType`](lua://Collider.getColliderType) to return the registered type of the collider.
---@class Collider : Class
---@field protected owner Object? # The owner of this collider.
---@field protected collidable boolean # Whether this collider can be collided with.
---@field protected invert boolean # Whether this collider is inverted.
---@field protected inner boolean # Whether this collider only checks collisions fully inside its bounds.
---@overload fun(owner: Object?, mode: Collider.Mode?) : Collider
local Collider = Class()

---@class Collider.Mode
---@field invert boolean?
---@field inner boolean?

---@param owner Object?
---@param mode Collider.Mode?
function Collider:init(owner, mode)
    self.owner = owner

    mode = mode or {}
    self.invert = mode.invert or false
    self.inner = mode.inner or mode.inside or false ---@diagnostic disable-line: undefined-field

    self.collidable = true
end

--- Gets the type of this collider as registered to the [`CollisionRegistry`](lua://CollisionRegistry) for collision checking.
---
--- This **must** be overriden by subclasses of `Collider`, and will otherwise error if attempted to check collisions with.
---@return string collider_type # The type of this collider as registered to the [`CollisionRegistry`](lua://CollisionRegistry).
function Collider:getColliderType()
    error("\"getColliderType\" not implemented for " .. TableUtils.dump(self))
end

--- Gets the axis-aligned bounding box of the collider.
---@return number x # The X coordinate of the bounding box.
---@return number y # The Y coordinate of the bounding box.
---@return number width # The width of the bounding box.
---@return number height # The height of the bounding box.
function Collider:getBounds()
    error("\"getBounds\" not implemented for " .. TableUtils.dump(self))
end

--- Gets the object which owns this collider.
---@return Object? parent # The owner of this collider, or `nil` if it has none.
function Collider:getOwner()
    return self.owner
end

--- Sets the object which owns this collider.
---@param object Object? # The new owner of this collider, or `nil` for none.
function Collider:setOwner(object)
    self.owner = object
end

--- Gets whether this collider can be collided with.
---
--- By default, this is only `true` if the owner is also collidable.
---@return boolean collidable # Whether this collider can be collided with.
function Collider:isCollidable()
    local owner = self:getOwner()

    return self.collidable and (not owner or owner:isCollidable())
end

--- Sets whether this collider can be collided with.
---@param collidable boolean # Whether this collider can be collided with.
function Collider:setCollidable(collidable)
    self.collidable = collidable
end

--- Gets whether this collider is inverted.
---@return boolean inverted # Whether this collider is inverted.
function Collider:isInverted()
    return self.invert
end

--- Sets whether this collider is inverted.
---@param inverted boolean # Whether this collider should be inverted.
function Collider:setInverted(inverted)
    self.invert = inverted
end

--- Gets whether this collider only checks collisions fully inside its bounds.
---@return boolean inner # Whether this collider only checks collisions fully inside its bounds.
function Collider:isInner()
    return self.inner
end

--- Sets whether this collider only checks collisions fully inside its bounds.
---@param inner boolean # Whether this collider should only check collisions fully inside its bounds.
function Collider:setInner(inner)
    self.inner = inner
end

--- Gets the full transformation of this collider, or `nil` if it has no owner.
--- @return love.Transform? transform # The full transformation of this collider, or `nil` if it has no owner.
function Collider:getTransform()
    if self:getOwner() ~= nil then
        return self:getOwner():getFullTransform()
    else
        return nil
    end
end

--- Gets the transformations of this collider and another collider, relative to a common parent (or the stage if they have none).
---
--- This is useful for collision detection, allowing you to transform the points of one collider into the coordinate space of another
--- via [`Collider:getLocalPoint`](lua://Collider.getLocalPoint).
---@param other Collider # The other collider to get the transformations with.
---@return love.Transform? tf1 # The transformation of this collider relative to the common parent.
---@return love.Transform? tf2 # The transformation of the other collider relative to the common parent.
function Collider:getTransformsWith(other)
    if self:getOwner() ~= nil and other:getOwner() ~= nil and self:getOwner().parent == other:getOwner().parent then
        return self.owner:getTransform(), other.owner:getTransform()
    else
        return self:getTransform(), other:getTransform()
    end
end

--- Gets a point transformed from the coordinate space of the second collider to the first collider.
---@param tf1 love.Transform? # The transformation of the first collider relative to the common parent.
---@param tf2 love.Transform? # The transformation of the second collider relative to the common parent.
---@param x number # The X coordinate of the point to be transformed.
---@param y number # The Y coordinate of the point to be transformed.
---@return number local_x # The X coordinate of the point from the second collider, relative to the first collider.
---@return number local_y # The Y coordinate of the point from the second collider, relative to the first collider.
function Collider:getLocalPoint(tf1, tf2, x, y)
    if tf2 ~= nil then
        x, y = tf2:transformPoint(x, y)
    end

    if tf1 ~= nil then
        x, y = tf1:inverseTransformPoint(x, y)
    end

    return x, y
end

--- Gets the axis-aligned bounding box of the collider, transformed from one coordinate space to another.
---@param source_tf love.Transform? # The transform of this collider relative to the common parent.
---@param target_tf love.Transform? # The destination transform relative to the common parent.
---@return number x # The X coordinate of the bounding box relative to the second transform.
---@return number y # The Y coordinate of the bounding box relative to the second transform.
---@return number width # The width of the bounding box relative to the second transform.
---@return number height # The height of the bounding box relative to the second transform.
function Collider:getRelativeBounds(source_tf, target_tf)
    local bounds_x, bounds_y, bounds_w, bounds_h = self:getBounds()

    local ul_x, ul_y = self:getLocalPoint(source_tf, target_tf, bounds_x, bounds_y)
    local ur_x, ur_y = self:getLocalPoint(source_tf, target_tf, bounds_x + bounds_w, bounds_y)
    local dr_x, dr_y = self:getLocalPoint(source_tf, target_tf, bounds_x + bounds_w, bounds_y + bounds_h)
    local dl_x, dl_y = self:getLocalPoint(source_tf, target_tf, bounds_x, bounds_y + bounds_h)

    local min_x = math.min(ul_x, ur_x, dr_x, dl_x)
    local min_y = math.min(ul_y, ur_y, dr_y, dl_y)
    local max_x = math.max(ul_x, ur_x, dr_x, dl_x)
    local max_y = math.max(ul_y, ur_y, dr_y, dl_y)

    return min_x, min_y, max_x - min_x, max_y - min_y
end

--- Gets the axis-aligned bounding box of the collider relative to another collider.
---@param other Collider # The other collider to get the bounding box relative to.
---@return number x # The X coordinate of the bounding box relative to the other collider.
---@return number y # The Y coordinate of the bounding box relative to the other collider.
---@return number width # The width of the bounding box relative to the other collider.
---@return number height # The height of the bounding box relative to the other collider.
function Collider:getBoundsFor(other)
    local tf1, tf2 = other:getTransformsWith(self)

    return self:getRelativeBounds(tf1, tf2)
end

--- Checks collision between this collider and another collider.
---@param collider Collider # The collider to check collision with.
---@return boolean collides # Whether a collision occurs.
function Collider:meetsCollider(collider)
    return CollisionRegistry.testCollision(self, collider)
end

--- Checks collision between this collider and an object.
---@param object Object # The object to check collision with.
---@return boolean collides # Whether a collision occurs.
function Collider:meetsObject(object)
    local collider = object:getCollider()

    if collider == nil then
        return false
    end

    return self:meetsCollider(collider)
end

--- Checks collision between this collider and another collider or object.
---@param other Collider|Object # The other collider or object to check collision with.
---@return boolean collides # Whether a collision occurs.
---@deprecated Use `Collider:meetsCollider` or `Collider:meetsObject` instead.
function Collider:collidesWith(other)
    if isClass(other) then
        if other:includes(Collider) then
            return self:meetsCollider(other)
        elseif other:includes(Object) then
            return self:meetsObject(other)
        end
    end
    return false
end

--- Gets whether this collider was clicked, optionally checking a specific mouse button.
---@param button number? # The mouse button to check. If `nil`, all buttons are checked.
---@return boolean clicked # Whether the collider was clicked.
---@return number button # The mouse button that was used to click the collider.
function Collider:clicked(button)
    if not button then
        local used_button = 0
        for i=1, Input.mouse_button_max do
            local success, success_button = self:clicked(i)
            used_button = math.max(used_button, success_button)
            if success then
                return true, success_button
            end
        end
        return false, used_button
    end
    local clicked, x, y, presses = Input.mousePressed(button)
    if not clicked then
        return false, 0
    end
    local point = PointCollider(nil, x, y)
    return self:meetsCollider(point), button
end

--- Draws this collider as an outline, transforming it relative to the specified object.
---@param obj Object # The object relative to which the collider should be drawn.
---@param ... any # Additional arguments to pass to the drawing function.
function Collider:drawFor(obj, ...)
    if obj == self.owner or not self.owner then
        self:draw(...)
    else
        love.graphics.push()
        love.graphics.origin()
        love.graphics.applyTransform(self.owner:getFullTransform())
        self:draw(...)
        love.graphics.pop()
    end
end

--- Draws this collider as a filled shape, transforming it relative to the specified object.
---@param obj Object # The object relative to which the collider should be drawn.
---@param ... any # Additional arguments to pass to the drawing function.
function Collider:drawFillFor(obj, ...)
    if obj == self.owner or not self.owner then
        self:drawFill(...)
    else
        love.graphics.push()
        love.graphics.origin()
        love.graphics.applyTransform(self.owner:getFullTransform())
        self:drawFill(...)
        love.graphics.pop()
    end
end

--- Draws this collider as an outline.
---@param ... any # Additional arguments to pass to the drawing function.
function Collider:draw(...) end

--- Draws this collider as a filled shape.
---@param ... any # Additional arguments to pass to the drawing function.
function Collider:drawFill(...) end

function Collider:canDeepCopy()
    return true
end
function Collider:canDeepCopyKey(key)
    return key ~= "owner"
end

return Collider
