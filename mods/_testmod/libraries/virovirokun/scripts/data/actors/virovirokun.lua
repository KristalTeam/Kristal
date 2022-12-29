local actor, super = Class(Actor, "virovirokun")

function actor:init()
    super.init(self)

    self.name = "Virovirokun"

    self.width = 38
    self.height = 51

    self.hitbox = {0, 25, 38, 26}

    self.flip = "right"

    self.path = "enemies/virovirokun"
    self.default = "idle"

    self.animations = {
        ["idle"] = {"idle", 0.25, true},
        ["spared"] = {"spared", 0, false},
        ["hurt"] = {"hurt", 0, false}
    }

    self.offsets = {
        ["idle"] = {-6, -3},
        ["spared"] = {-1, 0},
        ["hurt"] = {-2, -2},
    }
end

return actor