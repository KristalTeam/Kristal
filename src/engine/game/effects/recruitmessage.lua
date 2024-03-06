---@class RecruitMessage : Object
---@overload fun(...) : RecruitMessage
local RecruitMessage, super = Class(Object)

-- Types: "mercy", "damage", "msg"
-- Arg:
--    "mercy"/"damage": amount
--    "msg": message sprite name ("down", "frozen", "lost", "max", "mercy", "miss", "recruit", and "up")

function RecruitMessage:init(type, x, y)
    super.init(self, x, y)

    self:setOrigin(1, 0)

    self.stretch_x = 4
    self.stretch_y = 0

    -- Halfway between UI and the layer above it
    self.layer = BATTLE_LAYERS["damage_numbers"]

    self.type = type or "miss"

    self.texture = Assets.getTexture("ui/battle/msg/" .. self.type)
    self.width = self.texture:getWidth()
    self.height = self.texture:getHeight()

    self.timer = 0
    self.lerp_timer = 0

    self.start_x = nil

    self.physics.speed_y = 0

    self.alpha = 1

    self.first_number = 1
    self.second_number = 1
end

function RecruitMessage:update()
    if not self.start_x then
        self.start_x = self.x
    end

    super.update(self)

    local old_timer = self.timer
    self.timer = self.timer + DTMULT

    if (self.timer <= 5) then
        self.lerp_timer = self.lerp_timer + DTMULT
        self.stretch_x = Utils.lerp(self.stretch_x, 1, (self.lerp_timer / 5))
        self.stretch_y = Utils.lerp(self.stretch_y, 1, (self.lerp_timer / 5))
    end

    if (old_timer < 5 and self.timer >= 5) then
        self.lerp_timer = 0
    end

    if (self.timer >= 5 and self.timer <= 8) then
        self.lerp_timer = self.lerp_timer + DTMULT
        self.stretch_x = Utils.lerp(self.stretch_x, 0.5, (self.lerp_timer / 3))
        self.stretch_y = Utils.lerp(self.stretch_y, 2, (self.lerp_timer / 3))
    end

    if (old_timer < 8 and self.timer >= 8) then
        self.lerp_timer = 0
    end

    if (self.timer >= 8 and self.timer <= 10) then
        self.lerp_timer = math.min(self.lerp_timer + DTMULT, 2)
        self.stretch_x = Utils.lerp(self.stretch_x, 1, (self.lerp_timer / 2))
        self.stretch_y = Utils.lerp(self.stretch_y, 1, (self.lerp_timer / 2))
    end

    self.x = self.start_x + (self.width * self.stretch_x) / 2

    if self.timer >= 35 then
        self.physics.speed_y = self.physics.speed_y - DTMULT
        self.stretch_y = self.stretch_y + DTMULT * 0.1
        self.alpha = self.alpha - DTMULT * 0.1
        if self.alpha <= 0 then
            self:remove()
        end
    end
end

function RecruitMessage:draw()
    local r, g, b, a = self:getDrawColor()
    Draw.setColor(r, g, b, a * self.alpha)

    -- TODO: figure out why this X value is like this... in gamemaker its a simple `draw_self()`
    Draw.draw(self.texture, self.texture:getWidth() -self.x + self.start_x - (self.width * self.stretch_x) / 2, 0, 0, self.stretch_x, self.stretch_y)

    if (self.second_number > 1) then
        love.graphics.setFont(Assets.getFont("goldnumbers"))
        love.graphics.print(tostring(self.first_number), self.texture:getWidth() - 70 - ((#tostring(self.first_number) - 1) * 20), 35)
        love.graphics.print(tostring(self.second_number), self.texture:getWidth() - 30, 35)
        love.graphics.print("/", self.texture:getWidth() - 50, 35)
    end
end

return RecruitMessage