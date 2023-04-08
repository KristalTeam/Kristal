local item, super = Class(Item, "revivemint")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ReviveMint"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Heal\nDowned\nAlly"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Heals a fallen ally to MAX HP.\nA minty green crystal."

    -- Default shop price (sell price is halved)
    self.price = 400
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

    -- Character reactions
    self.reactions = {
        susie = {
            susie = "I'm ALIVE!!!",
            ralsei = "(You weren't dead)",
        },
        ralsei = {
            susie = "(Don't look it)",
            ralsei = "Ah, I'm refreshed!"
        },
        noelle = "Mints? I love mints!"
    }
end

function item:onWorldUse(target)
    Game.world:heal(target, math.ceil(target:getStat("health") / 2))
    return true
end

function item:onBattleUse(user, target)
    if target.chara:getHealth() <= 0 then
        target:heal(math.abs(target.chara:getHealth()) + target.chara:getStat("health"))
    else
        target:heal(math.ceil(target.chara:getStat("health") / 2))
    end
end

return item