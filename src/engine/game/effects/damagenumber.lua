---@class DamageNumber : Object
---@overload fun(...) : DamageNumber
local DamageNumber, super = Class(Object)

-- Types: "mercy", "damage", "msg"
-- Arg:
--    "mercy"/"damage": amount
--    "msg": message sprite name ("down", "frozen", "lost", "max", "mercy", "miss", "recruit", "up", "tired", and "awake")

function DamageNumber:init(type, arg, x, y, color, delay)
    super.init(self, x, y)

    self:setOrigin(1, 0)

    self.color = color or {1, 1, 1}

    -- Halfway between UI and the layer above it
    self.layer = BATTLE_LAYERS["damage_numbers"]

    self:setDisplay(type, arg, true)

    self.timer = 0
    self.delay = delay or 2
    self.kill_delay = 0

    self.bounces = 0

    self.stretch = 0.2
    self.stretch_done = false

    self.start_x = nil
    self.start_y = nil

    self.physics.speed_x = 0
    self.physics.speed_y = 0
    self.start_speed_y = 0

    self.kill_timer = 0
    self.killing = false
    self.kill = 0

    self.do_once = false

    self.kill_others = false
    self.kill_condition = function ()
        return true
    end
    self.kill_condition_succeed = false
end

function DamageNumber:setDisplay(type, arg, set_color)
    self.amount = nil
    self.message = nil
    self.texture = nil
    self.text = nil

    self.type = type or "msg"
    if self.type == "msg" then
        self.message = arg or "miss"
    else
        self.amount = arg or 0
        if self.type == "mercy" then
            self.font = Assets.getFont("goldnumbers")
            if self.amount == 100 then
                self.type = "msg"
                self.message = "mercy"
            elseif self.amount < 0 then
                self.text = self.amount.."%"
                if set_color then
                    self.color = {self.color[1] * 0.75, self.color[2] * 0.75, self.color[3] * 0.75}
                end
            else
                self.text = "+"..self.amount.."%"
            end
        else
            self.text = tostring(self.amount)
            self.font = Assets.getFont("bignumbers")
        end
    end

    if self.message then
        self.texture = Assets.getTexture("ui/battle/msg/"..self.message)
        self.width = self.texture:getWidth()
        self.height = self.texture:getHeight()
    elseif self.text then
        self.width = self.font:getWidth(self.text)
        self.height = self.font:getHeight()
    end
end

function DamageNumber:onAdd(parent)
    for _,v in ipairs(parent.children) do
        if isClass(v) and v:includes(DamageNumber) then
            if self.kill_others then
                if (v.timer >= 1) then
                    v.killing = true
                end
            else
                v.kill_timer = 0
            end
        end
    end
    self.killing = false
end

function DamageNumber:update()
    if not self.start_x then
        self.start_x = self.x
        self.start_y = self.y
    end

    super.update(self)

    self.timer = self.timer + DTMULT

    if (self.timer >= self.delay) and (not self.do_once) then
        self.do_once = true
        self.physics.speed_x = 10
        self.physics.speed_y = (-5 - (love.math.random() * 2))
        self.start_speed_y = self.physics.speed_y
    end

    if self.timer >= self.delay then
        self.physics.speed_x = Utils.approach(self.physics.speed_x, 0, DTMULT)

        if self.bounces < 2 then
            self.physics.speed_y = self.physics.speed_y + DTMULT
        end
        if (self.y > self.start_y) and (not self.killing) then
            self.y = self.start_y

            self.physics.speed_y = self.start_speed_y / 2
            self.bounces = self.bounces + 1
        end

        if (self.bounces >= 2) and (not self.killing) then
            self.physics.speed_y = 0
            self.y = self.start_y
        end

        if self.bounces < 2 or (self.kill_condition_succeed or self.kill_condition()) then
            if self.bounces >= 2 then
                self.kill_condition_succeed = true
            end
            if not self.stretch_done then
                self.stretch = self.stretch + 0.4 * DTMULT
            end

            if self.stretch >= 1.2 then
                self.stretch = 1
                self.stretch_done = true
            end

            self.kill_timer = self.kill_timer + DTMULT
            if self.kill_timer > 35 + self.kill_delay then
                self.killing = true
            end
            if self.killing then
                self.kill = self.kill + 0.08 * DTMULT
                self.y = self.y - 4 * DTMULT
            end

            if self.kill > 1 then
                self:remove()
                return
            end
        end
    end

    self:setScale(2 - self.stretch, self.stretch + self.kill)

    if Game.state == "BATTLE" then
        if self.x >= 600 then
            self.x = 600
        end
    end
end

function DamageNumber:draw()
    if self.timer >= self.delay then
        local r, g, b, a = self:getDrawColor()
        Draw.setColor(r, g, b, a * (1 - self.kill))

        if self.texture then
            Draw.draw(self.texture, 30, 0)
        elseif self.text then
            love.graphics.setFont(self.font)
            love.graphics.print(self.text, 30, 0)
        end
    end

    super.draw(self)
end

return DamageNumber