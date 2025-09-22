local item, super = Class(HealItem, "dark_candy")

function item:init()
    super.init(self)

    local form = Game:getConfig("darkCandyForm")

    -- Display name
    if form == "darker" then
        self.name = "Darker Candy"
    else
        self.name = "Dark Candy"
    end
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Amount healed (HealItem variable)
    if form == "darker" then
        self.heal_amount = 120
    else
        self.heal_amount = 40
    end

    -- Battle description
    self.effect = "Heals\n" .. self.heal_amount .. "HP"
    -- Shop description
    self.shop = "Star-shape\ncandy that\nheals " .. self.heal_amount .. "HP"
    -- Menu description
    if form == "darker" then
        self.description = "A candy that has grown sweeter with time.\nSaid to taste like toasted marshmallow. +" .. self.heal_amount .. "HP"
    else
        self.description = "Heals " .. self.heal_amount .. " HP. A red-and-black star\nthat tastes like marshmallows."
    end

    -- Default shop price (sell price is halved)
    if form == "darker" then
        self.price = 120
    else
        self.price = 25
    end
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
        susie = "Yeahh!! That's good!",
        ralsei = {
            ralsei = "Yummy!!! Marshmallows!!",
            susie = "Hey, feed ME!!!"
        },
        noelle = "Oh, it's... sticky?"
    }
end

return item