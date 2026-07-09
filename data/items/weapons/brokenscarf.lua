local item, super = Class(Item, "brokenscarf")

function item:init()
    super.init(self)

    -- Display name
    self.name = "BrokenScarf"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/scarf"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A scarf that was torn to pieces in the\nbattle, revealing it was all for show."

    -- Default shop price (sell price is halved)
    self.price = 2
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 12,
        defense = 3,
        magic = 3
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        ralsei = true
    }

    -- Character reactions
    self.reactions = {
        susie = "...",
        ralsei = "... I'll wear it.",
        noelle = "Who the HECK is Flowery?"
    }
end

function item:getStatBonuses()
    -- TODO: Stat Display callbacks?
    -- Return empty bonuses outside of battle to hide stats visually
    if Game.state ~= "BATTLE" then
        return {}
    end

    return super.getStatBonuses(self)
end

return item
