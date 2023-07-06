---@class Collider : Class
---@overload fun(...) : Collider
local Collider = Class()

function Collider:init(parent, x, y, mode)
    self.parent = parent

    self.x = x or 0
    self.y = y or 0

    mode = mode or {}
    self.invert = mode.invert or false
    self.inside = mode.inside or false

    self.collidable = true
end

function Collider:collidableCheck(other)
    return self.collidable and other and other.collidable and (not self.parent or self.parent.collidable) and (not other.parent or other.parent.collidable)
end
function Collider:insideCheck(other)
    return not (self.inside and other.inside)
end

function Collider:applyInvert(other, val)
    if self.invert ~= other.invert then
        return not val
    else
        return val
    end
end

function Collider:getOtherCollider(other)
    if isClass(other) then
        if other:includes(Collider) then
            return other
        elseif other:includes(Object) and other.collidable and other.collider then
            return other.collider
        end
    end
end

function Collider:getTransform()
    if self.parent then
        return self.parent:getFullTransform()
    else
        return nil
    end
end

function Collider:getTransformsWith(other)
    if self.parent and other.parent and self.parent.parent == other.parent.parent then
        return self.parent:getTransform(), other.parent:getTransform()
    else
        return self:getTransform(), other:getTransform()
    end
end

function Collider:getPointFor(other, x, y)
    if self.parent and other.parent then
        return other.parent:getRelativePos(other.x + x, other.y + y, self.parent)
    elseif self.parent then
        return self.parent:getFullTransform():inverseTransformPoint(other.x + x, other.y + y)
    elseif other.parent then
        return other.parent:getFullTransform():transformPoint(other.x + x, other.y + y)
    else
        return other.x + x, other.y + y
    end
end

function Collider:getLocalPointsWith(other, ...)
    local tf1, tf2 = self:getTransformsWith(other)
    return self:getLocalPoints(tf1, tf2, ...)
end

function Collider:getLocalPoints(tf1,tf2, ...)
    local points = {...}
    if type(points[1]) == "table" then
        points = Utils.copy(points[1])
    end
    if type(points[1]) == "table" then
        if tf2 then
            for i,point in ipairs(points) do
                points[i] = {tf2:transformPoint(point[1], point[2])}
            end
        end
        if tf1 then
            for i,point in ipairs(points) do
                points[i] = {tf1:inverseTransformPoint(point[1], point[2])}
            end
        end
        return points
    else
        if tf2 then
            for i = 1, #points, 2 do
                points[i], points[i+1] = tf2:transformPoint(points[i], points[i+1])
            end
        end
        if tf1 then
            for i = 1, #points, 2 do
                points[i], points[i+1] = tf1:inverseTransformPoint(points[i], points[i+1])
            end
        end
        return unpack(points)
    end
end

function Collider:collidesWith(other)
    return self:applyInvert(other, false)
end

function Collider:drawFor(obj, ...)
    if obj == self.parent or not self.parent then
        self:draw(...)
    else
        love.graphics.push()
        love.graphics.origin()
        love.graphics.applyTransform(self.parent:getFullTransform())
        self:draw(...)
        love.graphics.pop()
    end
end
function Collider:drawFillFor(obj, ...)
    if obj == self.parent or not self.parent then
        self:drawFill(...)
    else
        love.graphics.push()
        love.graphics.origin()
        love.graphics.applyTransform(self.parent:getFullTransform())
        self:drawFill(...)
        love.graphics.pop()
    end
end

function Collider:draw(...) end

function Collider:drawFill(...) end

function Collider:canDeepCopy()
    return true
end
function Collider:canDeepCopyKey(key)
    return key ~= "parent"
end

return Collider