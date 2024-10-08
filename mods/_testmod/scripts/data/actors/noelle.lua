local actor, super = Class("noelle", true)

function actor:init()
    super.init(self)

    self.miniface = "face/mini/sweet"
    self.miniface_offset = {-1, -6}
end

return actor