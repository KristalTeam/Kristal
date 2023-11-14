local MouseHole, super = Class(Shop)

function MouseHole:init()
    super.init(self)
    self.encounter_text = "* Welcome to the Mouse Hole.\n[wait:5]* How can I help ya?"
    self.shop_text = "* Thanks for visiting the little old place I got here."
    self.leaving_text = "* Come back any time!"
    self.sell_menu_text = "I'll take that off ya!"

    self.background = "shops/mousehole_background"

    self.shopkeeper:setActor("shopkeepers/amelia")
    self.shopkeeper.sprite:setPosition(-24, 12)
    self.shopkeeper.slide = true

    self:registerItem("tensionbit")
end

function MouseHole:postInit()
    super.postInit(self)
    self.background_sprite:play(5/30, true)
end

return MouseHole