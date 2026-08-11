---@class CollisionUtils
local CollisionUtils = {}

--- Creates a hitbox that covers an object's collision bounds extended in the given directions, for sweeping collision checks.
---
--- The resulting hitbox is owned by the object's parent, and its position is relative to the parent's coordinate space.
---@param object Object # The object to get the sweep hitbox for.
---@param left number # The amount to sweep to the left.
---@param right number # The amount to sweep to the right.
---@param up number # The amount to sweep up.
---@param down number # The amount to sweep down.
---@return Hitbox? hitbox # The hitbox representing the whole sweep area, or `nil` if the object has no collider.
function CollisionUtils.getSweepHitbox(object, left, right, up, down)
    local collider = object:getCollider()

    if collider == nil then
        return nil
    end

    ---@type number, number, number, number
    local x, y, width, height

    if collider:getOwner() == object then
        x, y, width, height = collider:getRelativeBounds(object:getTransform(), nil)
    else
        x, y, width, height = collider:getRelativeBounds(collider:getTransform(), object.parent:getFullTransform())
    end

    return Hitbox(object.parent, x - left, y - up, width + left + right, height + up + down)
end

return CollisionUtils
