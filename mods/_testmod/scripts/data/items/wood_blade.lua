local item, super = Class("wood_blade", true)

function item:init()
    super.init(self)

    self.name = "Epic Blade"

    self.description = " The gamer ing  sword"

    self.bonus_name = "EPIC"
    self.bonus_icon = "ui/menu/icon/smile"

    -- Effect shown above enemy after attacking with this item
    self.attack_sprite = "misc/realistic_explosion"
    -- Sound played when attacking
    self.attack_sound = "badexplosion"
    -- Pitch of the attack sound
    self.attack_pitch = 1

    self.bonuses = {
        attack = 1
    }
end

function item:getDescription()
    return super.super.getDescription(self)
end

return item
