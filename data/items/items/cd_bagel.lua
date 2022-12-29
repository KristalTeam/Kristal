local item, super = Class(HealItem, "cd_bagel")

function item:init()
    super.init(self)

    -- Display name
    self.name = "CD Bagel"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Heals\n80 HP"
    -- Shop description
    self.shop = "Musical food\nwith a\ncrunch\nHeals 80HP"
    -- Menu description
    self.description = "A bagel with a reflective inside.\nMakes music with each bite. +80HP"

    -- Amount healed (HealItem variable)
    self.heal_amount = 80

    -- Default shop price (sell price is halved)
    self.price = 100
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {}
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    self.reactions = {
        susie = "It's got crunch.",
        ralsei = "How elegant!",
        noelle = "What a nice song..."
    }

    self.sounds = {
        ["kris"] = "cd_bagel/kris",
        ["susie"] = "cd_bagel/susie",
        ["ralsei"] = "cd_bagel/ralsei",
        ["noelle"] = "cd_bagel/noelle"
    }
end

function item:getShopDescription()
    -- Don't automatically add item type
    return self.shop
end

function item:onWorldUse(target)
    local sound = self.sounds[target.id] or ("cd_bagel/"..target.id)
    if Assets.getSound(sound) then
        Assets.playSound(sound)
    end
    return super.onWorldUse(self, target)
end

return item