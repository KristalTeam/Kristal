---@class DarkFountain : Event
---@overload fun(...) : DarkFountain
local DarkFountain, super = Class(Event)

function DarkFountain:init(x, y)
    super.init(self, x, y)

    self:setOrigin(0.5, 1)

    self.width = 120 * 2
    self.height = 280 * 2

    self.bg_texture = Assets.getTexture("world/events/darkfountain/bg")
    self.edge_texture = Assets.getTexture("world/events/darkfountain/edge")
    self.bottom_texture = Assets.getTexture("world/events/darkfountain/bottom")

    -- Use the DarkFountain:drawMask() function to mask the fountain
    self.mask_fx = self:addFX(MaskFX(self))

    self.siner = 0
    self.bg_siner = 0
    self.hscroll = 0
    self.eyebody = 1 -- And this ??
    self.adjust = 0 -- Idk where this gets set
    self.slowdown = 0
    self.bg_color = {0, 1, 0}
end

function DarkFountain:update()
    self.siner = self.siner + DTMULT

    self.hscroll = self.hscroll + DTMULT
    if self.hscroll > 240 then
        self.hscroll = self.hscroll - 240
    end

    local function fcolor(h, s, v)
        self.hue = (h / 255) % 1
        return Utils.hsvToRgb((h / 255) % 1, s / 255, v / 255)
    end

    if self.adjust == 0 then
        self:setColor(fcolor(self.siner / 4, 160 + (math.sin(self.siner / 32) * 60), 255))
        self.bg_color = {fcolor(self.siner / 4, 255, (math.sin(self.siner / 16) * 40) + 60)}
    elseif self.adjust == 1 then
        self:setColor(Utils.mergeColor(self.color, COLORS.white, 0.06 * DTMULT))
        self.bg_color = Utils.mergeColor(self.bg_color, COLORS.black, 0.06 * DTMULT)
    elseif self.adjust == 2 then
        self.slowdown = Utils.approach(self.slowdown, 1, 0.02 * DTMULT)
        self.siner = self.siner - self.slowdown * DTMULT
        self.bg_siner = self.bg_siner - (self.slowdown / 16) * DTMULT
        self.bg_color = Utils.mergeColor(self.bg_color, COLORS.white, 0.03 * DTMULT)
    elseif self.adjust == 3 then
        self.slowdown = Utils.approach(self.slowdown, 1, 0.01 * DTMULT)
        self.siner = self.siner - (self.slowdown * 0.5) * DTMULT
        self.bg_siner = self.bg_siner - (self.slowdown / 24) * DTMULT
        self.hscroll = self.hscroll - (self.slowdown * 0.8) * DTMULT
        self:setColor(Utils.mergeColor(self.bg_color, {fcolor(self.siner / 16, 160 + (math.sin(self.siner / 128) * 60), 255)}, self.slowdown))
        self.bg_color = Utils.mergeColor(self.bg_color, {fcolor(self.siner / 16, 255, (math.sin(self.siner / 64) * 40) + 60)}, self.slowdown * DTMULT)
    end

    self.bg_siner = self.bg_siner + 0.0625 * DTMULT
    if self.bg_siner > 7 then
        self.bg_siner = self.bg_siner - 7
    end

    super.update(self)
end

function DarkFountain:draw()
    local color = {self:getDrawColor()}

    Draw.setColor(self.bg_color)
    love.graphics.rectangle("fill", 1, 1, self.width-2, self.height-2)
    Draw.setColor(color, 0.7 * self.eyebody)
    Draw.drawWrapped(self.bg_texture, true, true, -self.siner, -self.siner, 0, 2, 2)
    Draw.setColor(color, 0.3 * self.eyebody)
    Draw.drawWrapped(self.bg_texture, true, true, self.hscroll - 240, self.siner, 0, 2, 2)
    Draw.setColor(0, 0, 0)
    love.graphics.rectangle("fill", -100, 0, 120, self.height)
    love.graphics.rectangle("fill", self.width - 20, 0, 120, self.height)
    Draw.setColor(color, 1)
    Draw.drawWrapped(self.edge_texture, false, true, 20, self.height - (self.bg_siner * 280) / 7, 0, 2, 2)
    Draw.setColor(color, 0.5)
    Draw.drawWrapped(self.edge_texture, false, true, 20 + math.sin(self.siner / 16) * 12, self.height - (self.bg_siner * 280) / 7, 0, 2, 2)
    Draw.drawWrapped(self.edge_texture, false, true, 20 - math.sin(self.siner / 16) * 12, self.height - (self.bg_siner * 280) / 7, 0, 2, 2)
    Draw.setColor(color, 0.3)
    Draw.draw(self.bottom_texture, 0, self.height - 280 - 8 + (math.sin(self.siner / 16) * 8), 0, 2, 2)
    Draw.setColor(color, 0.5)
    Draw.draw(self.bottom_texture, 0, self.height - 280 - 4 + (math.sin(self.siner / 16) * 4), 0, 2, 2)
    Draw.setColor(color, 1)
    Draw.draw(self.bottom_texture, 0, self.height - 280, 0, 2, 2)

    super.draw(self)
end

function DarkFountain:drawMask()
    Draw.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

return DarkFountain