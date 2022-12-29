local item, super = Class(Item, "counter")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Counter"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Not\nso\nuseful"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Use to increase\nSaves to the save file"

    -- Default shop price (sell price is halved)
    self.price = 99999
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
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {}
end

function item:getName()
    return "Counter ["..self:getFlag("count", 0).."]"
end

function item:onWorldUse(target)
    self:addFlag("count", 1)
    return false
end

function item:onBattleSelect(user, target)
    -- Do not consume (valuable currency)
    self:addFlag("count", 1)
    return false
end

function item:onBattleDeselect(user, target)
    self:addFlag("count", -1)
end

function item:getBattleText(user, target)
    return "* "..user.chara:getName().." checked the "..self:getUseName().."!"
end

return item