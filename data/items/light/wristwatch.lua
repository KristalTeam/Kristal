local item, super = Class(LightEquipItem, "light/wristwatch")

function item:init()
    super:init(self)

    -- Display name
    self.name = "Wristwatch"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 0,
        defense = 1
    }

    -- Default dark item conversion for this item
    self.dark_item = "silver_watch"
end

function item:onCheck()
    Game.world:showText("* \"Wristwatch\" - Armor 1 DF\n* Maybe an expensive antique.\n* Stuck before half past noon.")
end

return item