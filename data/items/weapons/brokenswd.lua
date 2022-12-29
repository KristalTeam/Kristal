local item, super = Class(Item, "brokenswd")

function item:init()
    super.init(self)

    -- Display name
    self.name = "BrokenSwd"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/sword"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "CUT ANYTHING\n2 PIECES!\nCRIMINAL!"
    -- Menu description
    self.description = "A rejected sword cut into 2 pieces.\nNot even you can equip this..."

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
    self.bonuses = {}
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Failure"
    self.bonus_icon = "ui/menu/icon/down"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "... this is trash.",
        ralsei = "Should we fix this...?",
        noelle = "(Wh... why give this to me?)",
    }
end

function item:getShopDescription()
    -- Don't automatically add item type
    return self.shop
end

return item