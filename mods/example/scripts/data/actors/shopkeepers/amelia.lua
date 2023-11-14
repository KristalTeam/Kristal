local actor, super = Class(Actor, "shopkeepers/amelia")

function actor:init()
    super.init(self)

    self.name = "Amelia"

    self.width = 96
    self.height = 114

    self.path = "shopkeepers/amelia"
    self.default = "idle"

    self.animations = {
        ["idle"] = {"idle", function(sprite, wait)
            while true do
                sprite:setFrame(1)
                wait(2)
                sprite:setFrame(2)
                wait(3/30)
                sprite:setFrame(3)
                wait(3/30)
                sprite:setFrame(2)
                wait(3/30)
            end
        end}
    }

    self.talk_sprites = {
        ["talk"] = 0.125,
    }
end

function actor:onTalkStart(text, sprite)
    if sprite.sprite == "idle" then
        sprite:setSprite("talk")
    end
end

function actor:onTalkEnd(text, sprite)
    if sprite.sprite == "talk" then
        sprite:setAnimation("idle")
    end
end

return actor