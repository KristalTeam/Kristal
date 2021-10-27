local ColliderGroup, super = Class(Collider)

function ColliderGroup:init(parent, ...)
    super:init(self, 0, 0, parent)

    self.colliders = {}
    for _,v in ipairs({...}) do
        self:addCollider(v)
    end
end

function ColliderGroup:addCollider(collider)
    collider.parent = self.parent
    table.insert(self.colliders, collider)
end

function ColliderGroup:collidesWith(other)
    if not isClass(other) then return false end

    for _,collider in ipairs(self.colliders) do
        if collider:collidesWith(other) then
            return true
        end
    end

    return super:collidesWith(self, other)
end

return ColliderGroup