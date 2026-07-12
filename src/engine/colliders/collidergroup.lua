--- A collider group that contains multiple colliders and manages them as a single collider.
---@class ColliderGroup : Collider
---@field protected colliders Collider[] # The list of colliders contained in the group.
---@overload fun(owner: Object?, colliders: Collider[]?, mode: Collider.Mode?) : ColliderGroup
local ColliderGroup, super = Class(Collider)

---@param owner Object?
---@param colliders Collider[]?
---@param mode Collider.Mode?
function ColliderGroup:init(owner, colliders, mode)
    super.init(self, owner, mode)

    self:setColliders(colliders or {})
end

function ColliderGroup:getColliderType()
    return CollisionRegistry.GROUP
end

function ColliderGroup:setInner(inner)
    -- Set the inner property for all colliders inside the group
    for _, collider in ipairs(self.colliders) do
        collider:setInner(inner)
    end

    super.setInner(self, inner)
end

--- Gets a list of colliders contained in the group.
--- 
--- Modifying the returned table directly will not update the collider group's list. To update its colliders,
--- use [`ColliderGroup:addCollider`](lua://ColliderGroup.addCollider) or [`ColliderGroup:setColliders`](lua://ColliderGroup.setColliders)
--- instead.
---@return Collider[] colliders # A list of colliders contained in the group.
function ColliderGroup:getColliders()
    return TableUtils.copy(self.colliders)
end

--- Gets a list of colliders contained in the group, without copying them.
---
--- This should only be called when performance is critical (e.g. collision checking). **Do not** modify the returned
--- table directly.
---@return Collider[] colliders # A list of colliders contained in the group.
function ColliderGroup:getCollidersDirect()
    return self.colliders
end

--- Replaces the colliders in the group with the given list of colliders, setting the owner of each collider to the group's
--- owner if they don't have one.
---@param colliders Collider[] # The new list of colliders.
function ColliderGroup:setColliders(colliders)
    self.colliders = {}

    for _, collider in ipairs(colliders) do
        self:addCollider(collider)
    end
end

--- Adds a collider to the group, setting its owner to the group's owner if it doesn't have one.
---@param collider Collider # The collider to add.
function ColliderGroup:addCollider(collider)
    table.insert(self.colliders, collider)

    if collider:getOwner() == nil then
        collider:setOwner(self:getOwner())
    end
end

function ColliderGroup:drawFor(obj, ...)
    for _, collider in ipairs(self.colliders) do
        collider:drawFor(obj, ...)
    end
end
function ColliderGroup:drawFillFor(obj, ...)
    for _, collider in ipairs(self.colliders) do
        collider:drawFillFor(obj, ...)
    end
end

function ColliderGroup:draw(...)
    for _, collider in ipairs(self.colliders) do
        collider:draw(...)
    end
end
function ColliderGroup:drawFill(...)
    for _, collider in ipairs(self.colliders) do
        collider:drawFill(...)
    end
end

return ColliderGroup
