local DamageNumber, super = Class(Object)

function DamageNumber:init(x, y)
    super:init(self, x, y)

    self.xstart = x
    self.ystart = y
    self.spec = 0
    self.delaytimer = 0
    self.delay = 2
    --self.active = false
    self.damage = Utils.round(math.random(600))
    self.bounces = 0
    self.type = -1
    self.stretch = 0.2
    self.stretchgo = 1
    self.lightf = Utils.merge_color(COLORS.purple, COLORS.white, 0.6)
    self.lightb = Utils.merge_color(COLORS.aqua,   COLORS.white, 0.5)
    self.lightg = Utils.merge_color(COLORS.lime,   COLORS.white, 0.5)
    self.lighty = Utils.merge_color(COLORS.yellow, COLORS.white, 0.3)
    self.renamed_init_lol = false
    self.kill = 0
    self.killtimer = 0
    self.killactive = false
    self.vspeed = 0
    self.hspeed = 0
    self.do_once = false
--with (obj_dmgwriter)
--{
--    if (type != 3)
--        killtimer = 0
--}
    self.specialmessage = 0
    self.stayincamera = 1
    -- self.xx = camerax()
    self.xx = 0
    self.message_sprite = {
        Assets.getTexture("ui/battle/msg/miss"),
        Assets.getTexture("ui/battle/msg/down"),
        Assets.getTexture("ui/battle/msg/max"),
        Assets.getTexture("ui/battle/msg/up"),
        Assets.getTexture("ui/battle/msg/guts"), -- TODO: remove?
        Assets.getTexture("ui/battle/msg/mercy"),
        Assets.getTexture("ui/battle/msg/recruit"),
        Assets.getTexture("ui/battle/msg/lost"),
        Assets.getTexture("ui/battle/msg/down"), -- Dancing (TODO: remove)
        Assets.getTexture("ui/battle/msg/down"), -- Dancingx2 (TODO: remove)
        Assets.getTexture("ui/battle/msg/down"), -- + BUMP (TODO: remove)
        Assets.getTexture("ui/battle/msg/down"), -- Stopped Dancing (TODO: remove)
        Assets.getTexture("ui/battle/msg/frozen")
    }

end

function DamageNumber:update(dt)
    print(self.x)
    self.x = self.x + ((self.hspeed * 2) * DTMULT)
    self.y = self.y + ((self.vspeed) * DTMULT)
    self:updateChildren(dt)
end

-- self:draw_sprite_ext(self.message_sprite, 0, (x + 30), y, (2 - stretch), (stretch + kill), 0, draw_get_color(), (1 - kill))

function DamageNumber:draw_sprite_ext(sprite, subimg, x, y, xscale, yscale, _, color, alpha)
    local new_color = color
    color[4] = alpha
    love.graphics.setColor(new_color)

    love.graphics.push()

    love.graphics.translate(math.floor(x), math.floor(y))


    love.graphics.scale(xscale, yscale)

    local index = #sprite > 1 and ((math.floor(subimg) % (#sprite - 1)) + 1) or 1
    love.graphics.draw(sprite[index], 0, 0)

    love.graphics.pop()
end

function DamageNumber:draw_get_color()
    return love.graphics.getColor()
end

function DamageNumber:draw_set_font(...) end
function DamageNumber:draw_set_alpha(...) end
function DamageNumber:draw_set_halign(...) end
function DamageNumber:draw_text_transformed(...) end

function DamageNumber:draw()
    if (self.delaytimer < self.delay) then
        -- TODO: if other DamageNumbers exist, set their `killtimer`s to 0.
        --with (obj_dmgwriter)
        --    killtimer = 0
    end
    self.delaytimer = self.delaytimer + DTMULT
    if (self.delaytimer >= self.delay) and (not self.do_once) then
        self.do_once = true
        self.vspeed = (-5 - (math.random() * 2))
        self.hspeed = 10
        self.vstart = self.vspeed
        self.flip = 90
    end
    if (self.delaytimer >= self.delay) then
        love.graphics.setColor(COLORS.white)
        if (self.type == 0) then
            love.graphics.setColor(self.lightb)
        end
        if (self.type == 1) then
            love.graphics.setColor(self.lightf)
        end
        if (self.type == 2) then
            love.graphics.setColor(self.lightg)
        end
        if (self.type == 3) then
            love.graphics.setColor(COLORS.lime)
        end
        if (self.type == 4) then
            love.graphics.setColor(COLORS.red)
        end
        if ((self.type == 5) and (self.damage < 0)) then
            love.graphics.setColor(COLORS.silver)
        end
        if (self.type == 6) then
            love.graphics.setColor(self.lighty)
        end
        self.message = self.specialmessage
        if (self.damage == 0) then
            self.message = 1
        end
        if (self.type == 4) then
            self.message = 2
        end
        if ((self.type == 5) and (self.damage == 100)) then
            self.message = 5
        end
        if (self.type ~= 5) then
            self:draw_set_font(self.damagefont)
        end
        if (self.type == 5) then
            self:draw_set_font(self.damagefontgold)
        end
        if (self.hspeed > 0) then
            self.hspeed = self.hspeed - 1 * DTMULT
            if self.hspeed < 0 then
                self.hspeed = 0
            end
        end
        if (self.hspeed < 0) then
            self.hspeed = self.hspeed + 1 * DTMULT
            if self.hspeed > 0 then
                self.hspeed = 0
            end
        end
        if (math.abs(self.hspeed) < 1) then
            self.hspeed = 0
        end
        if (not self.renamed_init_lol) then
            self.damagemessage = tostring(self.damage)
            if (self.type == 5) then
                self.damagemessage = (("+" .. tostring(self.damage)) .. "%")
            end
            if ((self.type == 5) and (self.damage < 0)) then
                self.damagemessage = (tostring(self.damage) .. "%")
            end
            self.renamed_init_lol = true
        end
        if (self.message == 0) then
            self:draw_set_alpha((1 - self.kill))
            self:draw_set_halign(self.fa_right)
            if (self.spec == 0) then
                self:draw_text_transformed(30, 0, self.damagemessage, (2 - self.stretch), (self.stretch + self.kill), 0)
            end
            if (self.spec == 1) then
                self:draw_text_transformed(30, 0, self.damagemessage, (2 - self.stretch), (self.stretch + self.kill), 90)
            end
            self:draw_set_halign(self.fa_left)
            self:draw_set_alpha(1)
        else
            if (self.message == 1) then
                self:draw_sprite_ext(self.message_sprite, 0, 30, 0, (2 - self.stretch), (self.stretch + self.kill), 0, self.draw_get_color(), (1 - self.kill))
            end
            if (self.message == 2) then
                self:draw_sprite_ext(self.message_sprite, 1, 30, 0, (2 - self.stretch), (self.stretch + self.kill), 0, COLORS.red, (1 - self.kill))
            end
            if (self.message == 3) then
                self:draw_sprite_ext(self.message_sprite, 2, 30, 0, (2 - self.stretch), (self.stretch + self.kill), 0, COLORS.lime, (1 - self.kill))
            end
            if (self.message == 4) then
                self:draw_sprite_ext(self.message_sprite, 3, 30, 0, (2 - self.stretch), (self.stretch + self.kill), 0, COLORS.lime, (1 - self.kill))
            end
            if (self.message == 5) then
                self:draw_sprite_ext(self.message_sprite, 5, 30, 0, (2 - self.stretch), (self.stretch + self.kill), 0, COLORS.lime, (1 - self.kill))
            end
            if (self.message == 6) then
                self:draw_sprite_ext(self.message_sprite, 8, 30, 0, (2 - self.stretch), (self.stretch + self.kill), 0, COLORS.white, (1 - self.kill))
            end
            if (self.message == 7) then
                self:draw_sprite_ext(self.message_sprite, 9, 30, 0, (2 - self.stretch), (self.stretch + self.kill), 0, COLORS.white, (1 - self.kill))
            end
            if (self.message == 8) then
                self:draw_sprite_ext(self.message_sprite, 10, 30, 0, (2 - self.stretch), (self.stretch + self.kill), 0, COLORS.white, (1 - self.kill))
            end
            if (self.message == 9) then
                self:draw_sprite_ext(self.message_sprite, 11, 30, 0, (2 - self.stretch), (self.stretch + self.kill), 0, COLORS.white, (1 - self.kill))
            end
        end
        if (self.bounces < 2) then
            self.vspeed = self.vspeed + 1 * DTMULT
        end
        if ((self.y > self.ystart) and (self.bounces < 2) and (self.killactive == false)) then
            self.y = self.ystart
            self.vspeed = (self.vstart / 2)
            self.bounces = self.bounces + 1
        end
        if ((self.bounces >= 2) and (self.killactive == false)) then
            self.vspeed = 0
            self.y = self.ystart
        end
        if (self.stretchgo == 1) then
            self.stretch = self.stretch + 0.4 * DTMULT
        end
        if (self.stretch >= 1.2) then
            self.stretch = 1
            self.stretchgo = 0
        end
        self.killtimer = self.killtimer + 1 * DTMULT
        if (self.killtimer > 35) then
            self.killactive = true
        end
        if (self.killactive == true) then
            self.kill = self.kill + 0.08 * DTMULT
            self.y = self.y - 4 * DTMULT
        end
        if (self.kill > 1) then
            self:remove()
        end
    end
    --if (global.fighting == true) then
    --    if (stayincamera == 1) then
    --        if (x >= (xx + 600)) then
    --            x = (xx + 600)
    --        end
    --    end
    --end



    love.graphics.setColor(1, 1, 1, 1)
    self:drawChildren()
end

return DamageNumber