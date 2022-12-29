local actor, super = Class("kris", true)

function actor:init()
    super.init(self)

    self.offsets["balling"] = {-3, -1}
end

return actor