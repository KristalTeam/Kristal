---@class ColliderGroup : Collider
---@overload fun(...) : ColliderGroup
local ColliderGroup, super = Class(Collider)

function ColliderGroup:init(parent, colliders, mode)
    super.init(self, parent, 0, 0, mode)

    self.colliders = colliders or {}
    for _,collider in ipairs(self.colliders) do
        collider.parent = collider.parent or self.parent
    end
end

function ColliderGroup:addCollider(collider)
    collider.parent = collider.parent or self.parent
    table.insert(self.colliders, collider)
end

function ColliderGroup:collidesWith(other)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end

    for _,collider in ipairs(self.colliders) do
        if collider:collidesWith(other) then
            return self:applyInvert(other, true)
        end
    end

    return super.collidesWith(self, other)
end

function ColliderGroup:drawFor(obj,r,g,b,a)
    for _,collider in ipairs(self.colliders) do
        collider:drawFor(obj,r,g,b,a)
    end
end
function ColliderGroup:drawFillFor(obj,r,g,b,a)
    for _,collider in ipairs(self.colliders) do
        collider:drawFillFor(obj,r,g,b,a)
    end
end

function ColliderGroup:draw(r,g,b,a)
    for _,collider in ipairs(self.colliders) do
        collider:draw(r,g,b,a)
    end
end
function ColliderGroup:drawFill(r,g,b,a)
    for _,collider in ipairs(self.colliders) do
        collider:drawFill(r,g,b,a)
    end
end

return ColliderGroup