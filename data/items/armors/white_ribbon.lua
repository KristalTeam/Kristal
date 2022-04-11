local item, super = Class(Item, "white_ribbon")

function item:init()
    super:init(self)

    -- Display name
    self.name = "White Ribbon"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Enhances\ncuteness"
    -- Menu description
    self.description = "A crinkly hair ribbon that slightly\nincreases your defense."

    -- Shop buy price
    self.buy_price = 90
    -- Shop sell price (usually half of buy price)
    self.sell_price = 45

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    self.target = nil
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        defense = 2
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Cuteness"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        susie = false
    }

    -- Character reactions
    if Game.chapter == 1 then
        self.reactions = {
            susie = "Nope. Not in 1st grade anymore.",
            ralsei = "Um... D-do I look cute...?",
            noelle = "... feels familiar.",
        }
    else
        self.reactions = {
            susie = "I said NO! C'mon already!",
            ralsei = "It's nice being dressed up...",
            noelle = "... feels familiar.",
        }
    end
end

return item