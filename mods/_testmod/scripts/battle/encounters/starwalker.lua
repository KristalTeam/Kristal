local Starwalker, super = Class(Encounter)

function Starwalker:init()
    super:init(self)

    self.text = "* Star walker has      changed forms"

    self.starwalker = self:addEnemy("starwalker", 530, 238)

    self.background = true
    self.music = "pissedmeoff"

    self.timer = 0

    --self.default_xactions = false

    --Game.battle:registerXAction("susie", "Snap")
    --Game.battle:registerXAction("susie", "Supercharge", "Charge\nfaster", 80)
end

function Starwalker:update(dt)
    super:update(self, dt)

    if (Game.battle:getState() ~= "TRANSITION") then
        self.timer = self.timer + (1 * DTMULT)
        self.starwalker.x = 530 + (math.sin(self.timer * 0.08) * 20)
        self.starwalker.y = 238 + (math.sin(self.timer * 0.04) * 10)
    end

end

return Starwalker