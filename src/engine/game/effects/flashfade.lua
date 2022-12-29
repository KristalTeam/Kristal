---@class FlashFade : Sprite
---@overload fun(...) : FlashFade
local FlashFade, super = Class(Sprite)

function FlashFade:init(texture, x, y)
    super.init(self, texture, x, y)

    self.flash_speed = 1
    self.siner = 0
    self.target = nil

    self.color_mask = self:addFX(ColorMaskFX())
end

function FlashFade:update()
    self.siner = self.siner + self.flash_speed * DTMULT

    --self.color_mask_alpha = math.sin(self.siner / 3)
    self.alpha = math.sin(self.siner / 3)

    if self.siner > 4 and math.sin(self.siner / 3) < 0 then
        self:remove()
    end

    super.update(self)
end

return FlashFade