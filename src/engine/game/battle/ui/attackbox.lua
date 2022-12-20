---@class AttackBox : Object
---@overload fun(...) : AttackBox
local AttackBox, super = Class(Object)

AttackBox.BOLTSPEED = 8

function AttackBox:init(battler, offset, x, y)
    super:init(self, x, y)

    self.battler = battler
    self.offset = offset

    self.head_sprite = Sprite(battler.chara:getHeadIcons().."/head", 21, 19)
    self.head_sprite:setOrigin(0.5, 0.5)
    self:addChild(self.head_sprite)

    self.press_sprite = Sprite("ui/battle/press", 42, 0)
    self:addChild(self.press_sprite)

    self.bolt_target = 80 + 2
    self.bolt_start_x = self.bolt_target + (self.offset * AttackBox.BOLTSPEED)

    self.bolt = AttackBar(self.bolt_start_x, 0, 6, 38)
    self.bolt.layer = 1
    self:addChild(self.bolt)

    self.fade_rect = Rectangle(0, 0, SCREEN_WIDTH, 38)
    self.fade_rect:setColor(0, 0, 0, 0)
    self.fade_rect.layer = 2
    self:addChild(self.fade_rect)

    self.afterimage_timer = 0
    self.afterimage_count = -1

    self.flash = 0

    self.attacked = false
end

function AttackBox:getClose()
    return Utils.round((self.bolt.x - self.bolt_target) / AttackBox.BOLTSPEED)
end

function AttackBox:hit()
    local p = math.abs(self:getClose())

    self.attacked = true

    self.bolt:burst()
    self.bolt.layer = 1
    self.bolt:setPosition(self.bolt:getRelativePos(0, 0, self.parent))
    self.bolt:setParent(self.parent)

    if p == 0 then
        self.bolt:setColor(1, 1, 0)
        self.bolt.burst_speed = 0.2
        return 150
    elseif p == 1 then
        return 120
    elseif p == 2 then
        return 110
    elseif p >= 3 then
        self.bolt:setColor(self.battler.chara:getDamageColor())
        return 100 - (p * 2)
    end
end

function AttackBox:miss()
    self.bolt:remove()
    self.attacked = true
end

function AttackBox:update()
    if Game.battle.cancel_attack then
        self.fade_rect.alpha = Utils.approach(self.fade_rect.alpha, 1, DTMULT/20)
    end

    if not self.attacked then
        self.bolt:move(-AttackBox.BOLTSPEED * DTMULT, 0)

        self.afterimage_timer = self.afterimage_timer + DTMULT/2
        while math.floor(self.afterimage_timer) > self.afterimage_count do
            self.afterimage_count = self.afterimage_count + 1
            local afterimg = AttackBar(self.bolt_start_x - (self.afterimage_count * AttackBox.BOLTSPEED * 2), 0, 6, 38)
            afterimg.layer = 3
            afterimg.alpha = 0.4
            afterimg:fadeOutSpeedAndRemove()
            self:addChild(afterimg)
        end
    end

    if not Game.battle.cancel_attack and Input.pressed("confirm") then
        self.flash = 1
    else
        self.flash = Utils.approach(self.flash, 0, DTMULT/5)
    end

    super:update(self)
end

function AttackBox:draw()
    local target_color = {self.battler.chara:getAttackBarColor()}
    local box_color = {self.battler.chara:getAttackBoxColor()}

    if self.flash > 0 then
        box_color = Utils.lerp(box_color, {1, 1, 1}, self.flash)
    end

    love.graphics.setLineWidth(2)
    love.graphics.setLineStyle("rough")

    love.graphics.setColor(box_color)
    love.graphics.rectangle("line", 80, 1, (15 * AttackBox.BOLTSPEED) + 3, 36)
    love.graphics.setColor(target_color)
    love.graphics.rectangle("line", 83, 1, 8, 36)

    love.graphics.setLineWidth(1)

    super:draw(self)
end

return AttackBox