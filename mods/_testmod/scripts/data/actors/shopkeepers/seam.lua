local actor, super = Class(Actor, "shopkeepers/seam")

function actor:init()
    super.init(self)

    self.name = "Seam"

    self.width = 135
    self.height = 109

    self.path = "shopkeepers/seam"
    self.default = "idle"

    self.animations = {
        ["idle"] = {"idle", function(sprite, wait)
            while true do
                sprite:setFrame(1)
                wait(2)
                for i = 2, 4 do
                    sprite:setFrame(i)
                    wait(5/30)
                end
            end
        end}
    }

    self.talk_sprites = {
        ["talk"] = 0.25,
        ["impatient"] = 0.25,
        ["laugh"] = 0.25
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