local Starwings, super = Class(Wave)

function Starwings:init()
    super.init(self)
    self.time = -1
    self.starwalker = self:getAttackers()[1]
end

function Starwings:onStart()
    self.encounter:setMode("shoot")
    self.timer:every(2, function ()
        self.starwalker.sprite:set("starwalker_shoot_1")
        Assets.playSound("wing")

        self.timer:after(0.5, function ()
            self.starwalker.sprite:set("starwalker_shoot_2")
            Assets.playSound("stardrop")
            for i = -1, 1 do
                local offset = i * 15
                local star = self:spawnBullet("bullets/star", self.starwalker.x - 20, self.starwalker.y - 40)
                star.physics.direction = math.atan2(Game.battle.soul.y - star.y, Game.battle.soul.x - star.x) + math.rad(offset)
                star.physics.speed = 6
            end
        end)
        self.timer:after(1, function ()
            self.starwalker.sprite:set("wings")
        end)
    end)
end

function Starwings:onEnd()
    self.encounter:setMode("normal")
    self.starwalker.sprite:set("wings")
    super.onEnd(self)
end

function Starwings:update()
    super.update(self)
end

return Starwings
