local Shopkeeper, super = Class(Object, "shopkeeper")

function Shopkeeper:init()
    super:init(self)

    -- no idea how to do this
    self.animations = {
        ["idle"] = {"seam_idle", 0.2, true},
    }

    self.sprite = Sprite()

end

function Shopkeper:postInit()
    self.sprite:set(self.animations["idle"])
end

return Shopkeeper