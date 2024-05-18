---@class HeadObject : Sprite
---@overload fun(...) : HeadObject
local HeadObject, super = Class(Sprite)

function HeadObject:init(texture, x, y)
    super.init(self, texture, x, y)

    self.breakcon = 0
    self.breaktimer = 0
    self.sparestar = Assets.getFrames("effects/spare/star")
    self.sparkles = 30
end

function HeadObject:update()
    if (self.breakcon == 1) then
        self.breaktimer = 0
        local flash = FlashFade(self.texture, self.x, self.y)
        self.parent:addChild(flash)

        self.breakcon = 2
    end
    if (self.breakcon == 2) then
        self.breaktimer = self.breaktimer + 1 * DTMULT
        if (self.breaktimer >= 4) then
            Assets.playSound("sparkle_glock")

            for i = 1, self.sparkles do
                local x, y = self:getRelativePos(0, 0, self.parent.parent)
                local width = self.texture:getWidth() + 3
                local height = self.texture:getHeight() + 2
                local sparkle = DarkTransitionSparkle(self.sparestar, x + (math.random() * width) - width / 2, y + (math.random() * height) - height / 2)
                sparkle:play(1 / 15)
                -- We need to get the stage...
                self.parent.parent:addChild(sparkle)
            end
            self:remove()
        end
    end

    super.update(self)
end

return HeadObject