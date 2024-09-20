local Battle, super = Class(Battle)

function Battle:init()
    super.init(self)
end


function Battle:updateTransition()
    while self.afterimage_count < math.floor(self.transition_timer) do
        for index, battler in ipairs(self.party) do
            local target_x, target_y = unpack(self.battler_targets[index])

            local battler_x = battler.x
            local battler_y = battler.y

            battler.x = Utils.ease(self.party_beginning_positions[index][1], target_x, (self.afterimage_count + 1) / 10, "outCubic")
            battler.y = Utils.ease(self.party_beginning_positions[index][2], target_y, (self.afterimage_count + 1) / 10, "outCubic")

            local afterimage = AfterImage(battler, 0.5)
            self:addChild(afterimage)

            battler.x = battler_x
            battler.y = battler_y
        end
        self.afterimage_count = self.afterimage_count + 1
    end

    self.transition_timer = self.transition_timer + 1 * DTMULT

    if self.transition_timer >= 10 then
        self.transition_timer = 10
        self:setState("INTRO")
    end

    for index, battler in ipairs(self.party) do
        local target_x, target_y = unpack(self.battler_targets[index])

        battler.x = Utils.ease(self.party_beginning_positions[index][1], target_x, self.transition_timer / 10, "outCubic")
        battler.y = Utils.ease(self.party_beginning_positions[index][2], target_y, self.transition_timer / 10, "outCubic")
    end
    for _, enemy in ipairs(self.enemies) do
        enemy.x = Utils.ease(self.enemy_beginning_positions[enemy][1], enemy.target_x, self.transition_timer / 10, "outCubic")
        enemy.y = Utils.ease(self.enemy_beginning_positions[enemy][2], enemy.target_y, self.transition_timer / 10, "outCubic")
    end
end


function Battle:drawBackground()
    local moveby = Utils.ease(200, 0, self.transition_timer / 10, "outCubic")
    love.graphics.translate(0, moveby)
    super.drawBackground(self)
    love.graphics.translate(0, -moveby)
end

function Battle:onStateChange(old,new)
    super.onStateChange(self, old, new)
    if new == "INTRO" then

        local bx, by = self:getSoulLocation()
        local color = {Game:getSoulColor()}
        self:addChild(HeartBurst(bx, by, color))

        for index, battler in ipairs(self.party) do
            local afterimage1 = AfterImage(battler, 0.5)
            local afterimage2 = AfterImage(battler, 0.6)
            afterimage1.physics.speed_x = 2.5
            afterimage2.physics.speed_x = 5

            afterimage2:setLayer(afterimage1.layer - 1)

            self:addChild(afterimage1)
            self:addChild(afterimage2)
            battler:flash()
        end
        if #self.enemies < 10 then
            for _, enemy in ipairs(self.enemies) do
                local afterimage = AfterImage(enemy, 0.5)
                afterimage.graphics.grow = 0.05
                afterimage:setLayer(enemy.layer + 1)
                self:addChild(afterimage)
                enemy:flash()
            end
        end
    end
end

return Battle