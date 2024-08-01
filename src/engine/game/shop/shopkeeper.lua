--- An object that controls the visual representation of a Shopkeeper in a shop. \
--- The values for this object should be edited from within a Shop type as Shopkeepers do not have their own files.
---
---@class Shopkeeper : Object
---@overload fun(...) : Shopkeeper
---
---@field slide         boolean     # Whether the shopkeeper slides out of the way in the buy menu. (Defaults to `false`)
---
---@field talk_sprite   boolean     # Whether the shopkeeper's sprite should have a talk animation when they are speaking. (Defaults to `true`)
---
---@field actor         Actor       # The current Actor this shopkeeper is using.
---@field sprite        Sprite      # The current Sprite instance belonging to this shopkeeper.
local Shopkeeper, super = Class(Object)

function Shopkeeper:init()
    super.init(self)

    self.slide = false

    self.talk_sprite = true

    self.actor = nil
    self.sprite = nil
end

---@return Actor
function Shopkeeper:getActor()
    return self.actor or (self.sprite and self.sprite.actor)
end

---@param actor Actor|string 
---@return Sprite
function Shopkeeper:setActor(actor)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end
    if self.sprite then
        self.sprite:remove()
    end
    self.sprite = actor:createSprite()
    self.sprite:setScale(2, 2)
    self.sprite:setOrigin(0.5, 1)
    self:addChild(self.sprite)
    return self.sprite
end

---@param sprite string|table|love.Image
---@return ActorSprite|Sprite sprite
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

---@param animation? string|function|table
function Shopkeeper:setAnimation(animation)
    if self.sprite then
        self.sprite:setAnimation(animation)
    else
        error("Attempt to set animation with no sprite")
    end
end

--- *(Override)* Called whenever the `[emote:...]` text tag is used in Shop dialogue. Sets the sprite of this shopkeeper.
---@param emote string The path to the image to set, or id of the animation to set.
function Shopkeeper:onEmote(emote)
    if self.sprite then
        self.sprite:set(emote)
    else
        self:setSprite(emote)
    end
end

return Shopkeeper