local StarAct, super = Class(Wave)

function StarAct:init()
    super.init(self)
    self.time = 8
    self.starwalker = self:getAttackers()[1]

    self.colormask = nil

    self.shake_timer = 0
    self.during_handle = nil
end

function StarAct:onStart()
    self.starwalker:setMode("still")
    self.starwalker.sprite:set("reaching")
    Assets.playSound("ui_select")

    self.timer:after(2, function()
        self.starwalker.sprite:set("acting")
        Assets.playSound("sparkle_glock")
        local afterimage = AfterImage(self.starwalker, 0.5)
        afterimage.graphics.grow_x = 0.05
        afterimage.graphics.grow_y = 0.05
        afterimage.layer = self.starwalker.layer - 1
        Game.battle:addChild(afterimage)

        self.timer:after(0.5, function()
            Assets.playSound("awkward")
            Game.battle:swapSoul(BlueSoul())

            local soulafterimage = AfterImage(Game.battle.soul.sprite, 1)
            soulafterimage.graphics.grow_x = 0.2
            soulafterimage.graphics.grow_y = 0.2
            Game.battle.soul:addChild(soulafterimage)
            soulafterimage.y = soulafterimage.y - 8
        end)

        self.timer:after(1, function()
            self.colormask = self.starwalker:addFX(ColorMaskFX())
            self.colormask.color = {1, 1, 1}
            self.colormask.amount = 0
            self.timer:tween(1, self.colormask, { amount = 1 })
            self.shake_timer = 0
            self.during_handle = self.timer:during(1, function()
                self.shake_timer = self.shake_timer + 0.1 * DTMULT
                self.starwalker.graphics.shake_x = Utils.random(-self.shake_timer, self.shake_timer)
                self.starwalker.graphics.shake_y = Utils.random(-self.shake_timer, self.shake_timer)
            end)
        end)

        self.timer:after(2, function()
            if (self.during_handle) then
                self.timer:cancel(self.during_handle)
                self.during_handle = nil
            end
            self.starwalker.graphics.shake_x = 0
            self.starwalker.graphics.shake_y = 0
            self.starwalker:removeFX(self.colormask)
            self.colormask = nil
            self.timer:everyInstant(0.25, function()
                Assets.playSound("stardrop")
                Assets.playSound("bullet", 0.5)
                local star = self:spawnBullet(self.starwalker:makeBullet(self.starwalker.x - 20 - 10, self.starwalker.y - 40 - 20))
                star.physics.direction = math.atan2(Game.battle.soul.y - star.y, Game.battle.soul.x - star.x)
                star.physics.speed = 12
            end)
        end)
    end)
end

function StarAct:onEnd()
    self.starwalker:setMode("normal")
    self.starwalker.sprite:set("wings")
    if (self.during_handle) then
        self.timer:cancel(self.during_handle)
        self.during_handle = nil
    end
    self.starwalker.graphics.shake_x = 0
    self.starwalker.graphics.shake_y = 0
    if self.colormask then
        self.starwalker:removeFX(self.colormask)
    end
    super.onEnd(self)
end

function StarAct:update()
    super.update(self)
end

return StarAct
