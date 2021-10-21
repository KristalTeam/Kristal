local Virovirokun = Class()

function Virovirokun:init()
    self.text = "* Virovirokun floated in!"

    self.enemies = {
        "virovirokun",
        "virovirokun"
    }

    self.background = true
    self.music = nil

    self.default_xactions = false

    Game.battle:registerXAction("susie", "Snap")
    Game.battle:registerXAction("susie", "Supercharge", "Charge faster", 80)
end

return Virovirokun