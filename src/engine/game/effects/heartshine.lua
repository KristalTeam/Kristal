---@class HeartShine : Object
---@overload fun(...) : HeartShine
local HeartShine, super = Class(Object)

function HeartShine:init(x, y, color, speed, outline)
    super.init(self, x, y, 32, 32)

    self:setOrigin(0.5)
    self:setScale(2)

    self.layer = BATTLE_LAYERS["battlers"] + 1

    self.background = Sprite("player/heart_shine_bg")
    self.background:play(speed or 1 / 30, false, function() self:remove() end)
    self:addChild(self.background)

    self.heart = Sprite("player/heart_shine")
    local r, g, b, a = ColorUtils.unpackColor(color or {Game:getSoulColor()})
    self.heart:setColor(r, g, b, a)

    -- add an outline to the heart if the 'outline' parameter is undefined and the heart is purely white
    if outline == nil and r == 1 and g == 1 and b == 1 and a > 0 then outline = true end
    if outline then
        self.heart:addFX(OutlineFX(type(outline) == "table" and outline or { 0, 0, 0 }))
    end
    self:addChild(self.heart)

    -- set the frame of the heart to the index of the background frame
    self.heart_frame = { false, 1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 1 }
end

function HeartShine:draw()
    local heart_frame = self.heart_frame[self.background.frame]
    if heart_frame then
        self.heart.visible = true
        self.heart:setFrame(heart_frame)
    else
        self.heart.visible = false
    end

    super.draw(self)
end

return HeartShine
