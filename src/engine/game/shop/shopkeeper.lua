local Shopkeeper, super = Class(Object)

function Shopkeeper:init()
    super:init(self)

    -- Whether the shopkeeper slides
    -- out of the way in the buy menu.
    self.slide = false

    -- Whether the shopkeeper's sprite
    -- should be animated by talking.
    self.talk_sprite = true

    self.actor = nil
    self.sprite = nil
end

function Shopkeeper:getActor()
    return self.actor or (self.sprite and self.sprite.actor)
end

function Shopkeeper:setActor(actor)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end
    if self.sprite then
        self.sprite:remove()
    end
    self.sprite = ActorSprite(actor)
    self.sprite:setScale(2, 2)
    self.sprite:setOrigin(0.5, 1)
    self:addChild(self.sprite)
    return self.sprite
end

function Shopkeeper:setSprite(sprite)
    if self.sprite then
        self.sprite:setSprite(sprite)
    else
        self.sprite = Sprite(sprite)
        self.sprite:setScale(2, 2)
        self.sprite:setOrigin(0.5, 1)
        self:addChild(self.sprite)
    end
    return self.sprite
end

function Shopkeeper:setAnimation(animation)
    if self.sprite then
        self.sprite:setAnimation(animation)
    else
        error("Attempt to set animation with no sprite")
    end
end

function Shopkeeper:onEmote(emote)
    if self.sprite then
        self.sprite:set(emote)
    else
        self:setSprite(emote)
    end
end

return Shopkeeper