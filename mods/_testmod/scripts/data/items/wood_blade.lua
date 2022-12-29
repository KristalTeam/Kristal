local item, super = Class("wood_blade", true)

function item:init()
    super.init(self)

    self.name = "Epic Blade"

    self.description = " The gamer ing  sword"

    self.bonus_name = "EPIC"
    self.bonus_icon = "ui/menu/icon/smile"

    self.bonuses = {
        attack = 1
    }
end

function item:getDescription()
    return super.super.getDescription(self)
end

return item
