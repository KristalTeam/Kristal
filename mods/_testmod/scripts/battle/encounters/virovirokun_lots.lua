local Virovirokun, super = Class(Encounter)

function Virovirokun:init()
    super.init(self)

    self.text = "* Holy FUCK"

    --self:addEnemy("virovirokun", 530, 148)
    --self:addEnemy("virovirokun", 560, 262)

    self.first_viro = self:addEnemy("virovirokun")
    self.first_viro.money = 69

    for i = 1, 500 do
        self:addEnemy("virovirokun", Utils.random(SCREEN_WIDTH/2) + SCREEN_WIDTH + 80, Utils.random(SCREEN_HEIGHT))
    end

    self.done_stupid_thing = false

    --self:addEnemy("virovirokun")
    --self:addEnemy("virovirokun")

    self.background = true
    self.music = "battle"

    --self.default_xactions = false

    --Game.battle:registerXAction("susie", "Snap")
    --Game.battle:registerXAction("susie", "Supercharge", "Charge\nfaster", 80)
end

function Virovirokun:update()
    if Game.battle.state == "DEFENDING" then
        if Input.pressed("menu") then
            local explosion = Game.battle.soul:explode()
            explosion:setLayer(BATTLE_LAYERS["top"])
        end
    end

    super.update(self)
end

function Virovirokun:getNextWaves()
    for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
        enemy.selected_wave = "vironeedle_lots"
    end
    return {"vironeedle_lots"}
end

function Virovirokun:beforeStateChange(old, new)
    if old == "INTRO" and new ~= "INTRO" and not self.done_stupid_thing then
        self.done_stupid_thing = true

        Game.battle:setState("NONE")

        for _,battler in ipairs(Game.battle.party) do
            battler:setAnimation("battle/idle")
        end

        local src = Assets.playSound("rumble")
        src:setLooping(true)
        src:setVolume(0.75)
        local src2

        local timer = 0
        local stage = 0

        Game.battle:shakeCamera(5, 5, 0)

        Game.battle.timer:every(1/30, function()
            timer = timer + 1
            if stage == 0 and timer >= 60 then
                stage = 1
                timer = 0

                src2 = Assets.playSound("rumble")
                src2:setLooping(true)
                src2:setPitch(1.5)

                for _,enemy in ipairs(Game.battle.enemies) do
                    if enemy ~= self.first_viro then
                        local x = enemy.x
                        Game.battle.timer:tween(1, enemy, {x = x - SCREEN_WIDTH/2 - 80})
                    end
                end
            elseif stage == 1 and timer >= 30 then
                stage = 2
                timer = 0
                Game.battle:shakeCamera(0)
                src:stop()
                src2:stop()
            elseif stage == 2 and timer >= 15 then
                Game.battle:setState("ACTIONSELECT")
                return false
            end
        end)
    end
end

return Virovirokun