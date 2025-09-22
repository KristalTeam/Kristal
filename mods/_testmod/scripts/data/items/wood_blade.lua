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

function item:getAttackSprite(battler, enemy, points)
    if points == 150 then -- crit
        Assets.playSound("badexplosion")
        return "misc/realistic_explosion"
    end
end

function item:getAttackSound(battler, enemy, points)
    if points == 0 then -- miss
        return "awkward"
    end
end

return item
