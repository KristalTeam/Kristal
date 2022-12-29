local item, super = Class(Item, "dogdollar")

function item:init()
    super.init(self)

    -- Display name
    self.name = "DogDollar"
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
    self.description = "A dollar with a certain dog on it.\nIts value decreases each Chapter."

    -- Default shop price (sell price is halved)
    self.price = math.floor(200 / Game.chapter)
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

function item:onWorldUse(target)
    ---- Unused text
    -- Game.world:showText("* (Where'd this come from?)")
    return false
end

function item:onBattleSelect(user, target)
    -- Do not consume (valuable currency)
    return false
end

function item:getBattleText(user, target)
    return "* "..user.chara:getName().." admired "..self:getUseName().."!"
end

return item