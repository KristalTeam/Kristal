local StarAct, super = Class(Wave)

function StarAct:init()
    super.init(self)
    self.time = 8
    self.starwalker = self:getAttackers()[1]
end

function StarAct:onStart()
    self.starwalker:setMode("still")
    self.starwalker.sprite:set("reaching")
    Assets.playSound("ui_select")

    self.timer:after(2, function()
        self.starwalker.sprite:set("acting")
        Assets.playSound("sparkle_glock")
        self.timer:after(0.5, function()
            Assets.playSound("awkward")
            Game.battle.soul:setScale(2)
        end)
    end)
end

function StarAct:onEnd()
    self.starwalker:setMode("normal")
    self.starwalker.sprite:set("wings")
    super.onEnd(self)
end

function StarAct:update()
    super.update(self)
end

return StarAct
