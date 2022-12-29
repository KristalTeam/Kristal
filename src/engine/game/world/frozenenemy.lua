---@class FrozenEnemy : Interactable
---@overload fun(...) : FrozenEnemy
local FrozenEnemy, super = Class(Interactable)

function FrozenEnemy:init(actor, x, y, properties)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end
    local w, h = actor:getSize()
    super.init(self, x, y, w, h, properties)

    properties = properties or {}

    self.text = {"* (It's frozen solid...)"}

    self:setOrigin(0.5, 1)
    self:setScale(2)

    self.sprite = actor:createSprite()
    self.sprite.facing = properties and properties["facing"] or "left"
    if not self.sprite:setAnimation("frozen") then
        self.sprite:setAnimation("hurt")
    end
    self.sprite.frozen = true
    self:addChild(self.sprite)

    self.actor = actor

    self.collider = Hitbox(self, self.actor:getHitbox())

    self.solid = properties and properties["solid"] or false

    self.encounter = properties and properties["encounter"]
end

function FrozenEnemy:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "Actor: " .. self.actor)
    return info
end

function FrozenEnemy:onAdd(parent)
    super.onAdd(self, parent)

    if self.encounter then
        -- remove object if we haven't recorded a frozen encounter for this room
    end
end

return FrozenEnemy