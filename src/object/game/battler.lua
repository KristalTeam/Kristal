local Battler, super = Class(Object)

function Battler:init(x, y, width, height)
    super:init(self, x, y, width, height)

    self.layer = LAYERS["battlers"]

    self:setOrigin(0.5, 1)
    self:setScale(2)
end

function Battler:flash()
    local offset = self.sprite:getOffset()
    local flash = FlashFade(self.sprite.texture, -offset[1], -offset[2])
    self:addChild(flash)
end

function Battler:sparkle(r, g, b)
    Game.battle.timer:every(1/30, function()
        for i = 1, 2 do
            local x = self.x + ((love.math.random() * self.width) - (self.width / 2)) * 2
            local y = self.y - (love.math.random() * self.height) * 2
            local sparkle = HealSparkle(x, y)
            if r and g and b then
                sparkle:setColor(r, g, b)
            end
            self.parent:addChild(sparkle)
        end
    end, 4)
end

-- Shorthand for convenience
function Battler:setAnimation(animation, callback)
    return self.sprite:setAnimation(animation, callback)
end

function Battler:setCustomSprite(sprite, ox, oy, speed, loop, after)
    self.sprite:setCustomSprite(sprite, ox, oy)
    if not self.sprite.directional and speed then
        self.sprite:play(speed, loop, after)
    end
end

return Battler