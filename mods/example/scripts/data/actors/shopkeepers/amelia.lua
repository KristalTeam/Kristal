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
        ["explaining_talk"] = 0.125,
        ["left_talk"] = 0.125,
        ["happy_talk"] = 0.125
    }

    self.offsets = {
        ["explaining"] = {-26, 0},
        ["explaining_talk"] = {-26, 0}
    }
end

function actor:onTalkStart(text, sprite)
    if sprite.sprite == "idle" then
        sprite:setSprite("talk")
    elseif sprite.sprite == "left" then
        sprite:setSprite("left_talk")
    elseif sprite.sprite == "explaining" then
        sprite:setSprite("explaining_talk")
    elseif sprite.sprite == "happy" then
        sprite:setSprite("happy_talk")
    end
end

function actor:onTalkEnd(text, sprite)
    if sprite.sprite == "talk" then
        sprite:setAnimation("idle")
    elseif sprite.sprite == "left_talk" then
        sprite:setSprite("left")
    elseif sprite.sprite == "explaining_talk" then
        sprite:setSprite("explaining")
    elseif sprite.sprite == "happy_talk" then
        sprite:setSprite("happy")
    end
end

return actor