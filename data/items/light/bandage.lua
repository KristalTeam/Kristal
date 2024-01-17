local item, super = Class(LightEquipItem, "light/bandage")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Bandage"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "It has cartoon characters on it."

    -- Light world check text
    self.check = "Heals 10 HP\n* It has cartoon characters on it."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 0,
        defense = 0
    }
end

function item:onWorldUse()

    -- Recover the stored items into the inventory
    local dark_inventory = Game.inventory:getDarkInventory()

    local armors = self:createArmorItems()
    if armors[1] then dark_inventory:addItem(armors[1]) end
    if armors[2] then dark_inventory:addItem(armors[2]) end

    -- Heal 1 HP
    Game.world:heal(Game.party[1], 1, "* You re-applied the bandage.")

    -- Consume
    return true
end

return item