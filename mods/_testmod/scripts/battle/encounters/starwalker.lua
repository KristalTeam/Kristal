local Starwalker, super = Class(Encounter)

function Starwalker:init()
    super:init(self)

    self.text = "* Star walker has      changed forms"

    self.starwalker = self:addEnemy("starwalker", 530, 238)

    self.background = true
    self.music = "pissedmeoff"

    self.no_end_message = true

    self.timer = 0

    self.mode = "normal"

    self.old_x = self.starwalker.x
    self.old_y = self.starwalker.y

    self.ease = false

    self.ease_timer = 0

    --self.default_xactions = false

    --Game.battle:registerXAction("susie", "Snap")
    --Game.battle:registerXAction("susie", "Supercharge", "Charge\nfaster", 80)
end

function Starwalker:setMode(mode)
    self.mode = mode
    self.old_x = self.starwalker.x
    self.old_y = self.starwalker.y
    self.ease = true
    self.ease_timer = 0
end

function Starwalker:update(dt)
    super:update(self, dt)

    if not self.starwalker.done_state and (Game.battle:getState() ~= "TRANSITION") then
        self.timer = self.timer + (1 * DTMULT)
        

        local wanted_x = self.starwalker.old_x
        local wanted_y = self.starwalker.old_y

        if self.mode == "normal" then
            wanted_x = 530 + (math.sin(self.timer * 0.08) * 20)
            wanted_y = 238 + (math.sin(self.timer * 0.04) * 10)
        elseif self.mode == "shoot" then
            wanted_x = 530 - 40 + (math.sin(self.timer * 0.08) * 10)
            wanted_y = 238 - 50 + (math.sin(self.timer * 0.04) * 40)
        end

        if not self.ease then
            self.starwalker.x = wanted_x
            self.starwalker.y = wanted_y
        else
            self.ease_timer = self.ease_timer + (0.05 * DTMULT)
            self.starwalker.x = Ease.outQuad(self.ease_timer, self.old_x, wanted_x - self.old_x, 1)
            self.starwalker.y = Ease.outQuad(self.ease_timer, self.old_y, wanted_y - self.old_y, 1)
            if self.ease_timer >= 1 then
                self.ease = false
            end
        end
    end

end

return Starwalker