---@class SpriteCutHalfSettings
---@field flash boolean Whether the effect will flash white for a frame. Defaults to false.
---@field fade_speed number The speed at which the cut sprite will fade out, in 30 FPS frames. Defaults to 0.1
---@field fix_height boolean Whether to fix a DR bug where the width is used as a height. Defaults to false.

--- An effect which cuts a sprite in half and makes it fade out.
---@class SpriteCutHalf : Sprite
---@overload fun(...) : SpriteCutHalf
local SpriteCutHalf, super = Class(Sprite)

---@param texture string|love.Image?
---@param x number?
---@param y number?
---@param settings SpriteCutHalfSettings?
function SpriteCutHalf:init(texture, x, y, settings)
    super.init(self, texture, x, y)

    settings = settings or {}

    self.timer = 0

    self.alpha = 1
    self.flash = settings.flash
    self.fix_height = settings.fix_height
    self.fade_speed = settings.fade_speed or 0.1

    self.flash_timer = 0
    self.color_mask = nil
end

function SpriteCutHalf:update()
    super.update(self)

    if self.flash then
        if self.color_mask == nil then
            self.color_mask = self:addFX(ColorMaskFX())
        end

        self.flash_timer = self.flash_timer + DTMULT
        if self.flash_timer > 1 then
            self.flash = false
            self.flash_timer = 0
            self:removeFX(self.color_mask)
        else
            return
        end
    end

    self.timer = self.timer + DTMULT
    self.alpha = self.alpha - (self.fade_speed * DTMULT)

    if self.alpha <= 0 then
        self:remove()
    end
end

function SpriteCutHalf:draw()
    Object.draw(self)

    if self.flash then
        Draw.draw(self.texture)
        return
    end

    local height = (self.fix_height and self.height or self.width) / 2

    local offset = Ease.outSine((self.timer + 2) / 10, 0, self.height / 2, 1)

    local r, g, b, a = self:getDrawColor()
    love.graphics.setColor(r, g, b, a * self.alpha)

    Draw.drawPart(self.texture, 0, -offset, 0, 0, self.width, height)
    Draw.drawPart(self.texture, 0, height + offset, 0, height, self.width, height)
end

return SpriteCutHalf
