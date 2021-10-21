local Virovirokun = Class()

function Virovirokun:init()
    self.text = "* Virovirokun floated in!"

    self.enemies = {
        "virovirokun"
    }

    -- Also add a tired and spareable virovirokun
    local enemy = Registry.createEnemy("virovirokun")
    enemy.tired = true
    enemy.can_spare = true
    table.insert(self.enemies, enemy)

    self.background = true
    self.music = nil

    self.default_xactions = false

    Game.battle:registerXAction("susie", "Snap")
    Game.battle:registerXAction("susie", "Supercharge", "Charge faster", 80)
end

return Virovirokun