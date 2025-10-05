local StarUp, super = Class(Wave)

function StarUp:init()
    super.init(self)
    self.starwalker = self:getAttackers()[1]
end

function StarUp:onStart()
    local arena_x = Game.battle.arena.x
    local arena_y = Game.battle.arena.y
    local arena_width = Game.battle.arena.width
    local arena_height = Game.battle.arena.height

    self.warning = self:addChild(
        Rectangle(
            arena_x - arena_width / 2 + 1 + 2,
            (arena_y - arena_height / 2) + (arena_height / 3) * 2,
            arena_width - 4,
            arena_height / 3
        )
    )

    self.warning.line = true
    self.warning.line_width = 1

    self.warning.color = {0.75, 0, 0}
    Assets.playSound("alert")

    self.timer:script(function (wait)
        wait(0.5)
        self.warning.visible = false

        Assets.playSound("spearrise")
        for i = arena_x - arena_width / 2, arena_x + arena_width / 2, 16 do
            local star = self:spawnBulletTo(Game.battle.mask, self.starwalker:makeBullet(i + 8, arena_y + arena_height / 2 + 20))
            star.physics.direction = math.rad(270)
            star.physics.speed = 11
            star.physics.gravity = 1
        end

        wait(0.5)
        self.starwalker.sprite:set("pointing_up")
        Game.battle.soul.rotation = math.rad(180)
        Game.battle.soul.speed_y = 11
        Assets.playSound("bell")
        wait(0.5)
        self.warning.visible = true
        Assets.playSound("alert")
        self.warning.y = (arena_y - arena_height / 2)
        wait(0.5)
        self.warning.visible = false
        Assets.playSound("spearrise")
        for i = arena_x - arena_width / 2, arena_x + arena_width / 2, 16 do
            local star = self:spawnBulletTo(Game.battle.mask, self.starwalker:makeBullet(i + 8, (arena_y - arena_height / 2) - 20))
            star.physics.direction = math.rad(90)
            star.physics.speed = 11
            star.physics.gravity = -1
        end
        wait(0.5)
        self.starwalker.sprite:set("pointing_down")
        Game.battle.soul.rotation = math.rad(0)
        Game.battle.soul.speed_y = 11
        Assets.playSound("bell")
        wait(0.5)
        self.warning.visible = true
        Assets.playSound("alert")
        self.warning.y = (arena_y - arena_height / 2) + (arena_height / 3) * 2
        wait(0.5)
        self.warning.visible = false
        Assets.playSound("spearrise")
        for i = arena_x - arena_width / 2, arena_x + arena_width / 2, 16 do
            local star = self:spawnBulletTo(Game.battle.mask, self.starwalker:makeBullet(i + 8, arena_y + arena_height / 2 + 20))
            star.physics.direction = math.rad(270)
            star.physics.speed = 11
            star.physics.gravity = 1
        end
        wait(0.5)
        self.time = 0
    end)
end

function StarUp:onEnd()
    self.starwalker:setMode("normal")
    if self.starwalker.sprite.sprite == "starwalker_pointing_up" then
        self.starwalker.sprite:set("pointing_down")
    end
    super.onEnd(self)
end

return StarUp
