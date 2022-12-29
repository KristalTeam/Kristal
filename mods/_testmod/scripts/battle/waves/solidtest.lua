local SolidTest, super = Class(Wave)

function SolidTest:init()
    super.init(self)

    self.time = -1

    self.siner = 0
    self.solid = nil
end

function SolidTest:onStart()
    self.start_x, self.start_y = Game.battle.arena:getCenter()

    self.solid = self:spawnObject(Solid(true, self.start_x, self.start_y, 8, 60))
    self.solid:setLayer(BATTLE_LAYERS["above_arena"])
    self.solid:setOrigin(0.5, 0.5)
end

function SolidTest:update()
    super.update(self)

    self.siner = self.siner + DT

    if self.solid then
        self.solid:moveTo(self.start_x + math.sin(self.siner*2) * 60, self.start_y)
    end
end

return SolidTest
