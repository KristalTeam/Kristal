local FrozenEnemy, super = Class(Readable)

function FrozenEnemy:init(actor, x, y, properties)
    super:init(self, x, y, actor.width, actor.height, {"* (It's frozen solid...)"})

    self:setOrigin(0.5, 1)
    self:setScale(2)

    self.sprite = ActorSprite(actor)
    self.sprite.facing = properties and properties["facing"] or "left"
    if not self.sprite:setAnimation("frozen") then
        self.sprite:setAnimation("hurt")
    end
    self.sprite.frozen = true
    self:addChild(self.sprite)

    self.actor = actor

    local hitbox = self.actor.hitbox or {0, 0, self.actor.width, self.actor.height}
    self.collider = Hitbox(self, hitbox[1], hitbox[2], hitbox[3], hitbox[4])

    self.solid = properties and properties["solid"] or false

    self.encounter = properties and properties["encounter"]
end

function FrozenEnemy:onAdd(parent)
    super:onAdd(self, parent)

    if self.encounter then
        -- remove object if we haven't recorded a frozen encounter for this room
    end
end

return FrozenEnemy